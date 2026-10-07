#!/usr/bin/env python3
"""Classify a `flutter test --machine`/`--reporter json` run without trusting it.

Result vocabulary follows docs/architecture/REMEDIATION_ACCEPTANCE.md:

* TIMEOUT    - the runner was killed by a time limit (exit 124, or 142 when
               killed by SIGALRM). Never PASS, whatever the events say.
* INCOMPLETE - completion evidence is missing: no exit code, no `done` event,
               or tests that started and never finished.
* FAIL       - a nonzero exit, any test result of `failure` or `error`, an
               error reported after a test finished, a suite/load error,
               `done.success` other than true, or any contradiction between
               the event stream and the exit code.
* PASS       - exit 0, `done.success` true, every started test finished, and
               no failing result or contradiction.

The raw events and the exit code are both retained; when they disagree the
report lists the contradiction and the result is never PASS.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
import json
import os
from pathlib import Path
import sys
from typing import Any, Iterator, Optional
from urllib.parse import unquote, urlparse

PASS = "PASS"
FAIL = "FAIL"
TIMEOUT = "TIMEOUT"
INCOMPLETE = "INCOMPLETE"

# `timeout` exits 124; a process killed by SIGALRM (perl alarm) exits 128 + 14.
TIMEOUT_EXIT_CODES = frozenset({124, 142})
FAILING_RESULTS = frozenset({"failure", "error"})


@dataclass
class TestRecord:
    test_id: Any
    name: str
    location: str
    hidden: bool = False
    result: Optional[str] = None
    skipped: bool = False
    finished: bool = False
    errors: list[str] = field(default_factory=list)
    stacks: list[str] = field(default_factory=list)
    errors_after_done: int = 0


@dataclass
class RunReport:
    result: str
    exit_code: Optional[int]
    done_seen: bool
    done_success: Optional[bool]
    seed: Optional[str]
    tests: list[TestRecord]
    error_events: int
    suite_errors: list[str]
    global_errors: list[str]
    malformed_lines: list[str]
    unsupported_values: list[str]
    reasons: list[str]
    contradictions: list[str]
    readable_lines: list[str]

    @property
    def visible(self) -> list[TestRecord]:
        return [test for test in self.tests if not test.hidden]

    @property
    def passed(self) -> list[TestRecord]:
        return [
            test
            for test in self.visible
            if test.finished and test.result == "success" and not test.skipped
        ]

    @property
    def skipped(self) -> list[TestRecord]:
        return [test for test in self.visible if test.finished and test.skipped]

    @property
    def failed(self) -> list[TestRecord]:
        return [test for test in self.tests if test.result == "failure"]

    @property
    def errored(self) -> list[TestRecord]:
        return [test for test in self.tests if test.result == "error"]

    @property
    def unfinished(self) -> list[TestRecord]:
        return [test for test in self.tests if not test.finished]

    @property
    def late_errors(self) -> list[TestRecord]:
        return [test for test in self.tests if test.errors_after_done]

    @property
    def failing(self) -> list[TestRecord]:
        """Failure/error results plus tests that erred after finishing."""
        return [
            test
            for test in self.tests
            if test.result in FAILING_RESULTS or test.errors_after_done
        ]

    def counts(self) -> dict[str, int]:
        return {
            "tests": len(self.visible),
            "passed": len(self.passed),
            "failed": len(self.failed),
            "errored": len(self.errored),
            "skipped": len(self.skipped),
            "unfinished": len(self.unfinished),
            "hidden": len(self.tests) - len(self.visible),
            "error_events": self.error_events,
            "suite_errors": len(self.suite_errors),
            "malformed_lines": len(self.malformed_lines),
        }

    def to_json(self) -> dict[str, Any]:
        return {
            "result": self.result,
            "exit_code": self.exit_code,
            "done_seen": self.done_seen,
            "done_success": self.done_success,
            "seed": self.seed,
            "counts": self.counts(),
            "reasons": self.reasons,
            "contradictions": self.contradictions,
            "failing_tests": [
                {"name": t.name, "location": t.location, "result": t.result}
                for t in self.failing
            ],
            "unfinished_tests": [
                {"name": t.name, "location": t.location} for t in self.unfinished
            ],
        }


def parse_exit_code(raw: Optional[str]) -> Optional[int]:
    if raw is None:
        return None
    text = str(raw).strip()
    try:
        return int(text)
    except ValueError:
        return None


def _as_mapping(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _location(test: dict[str, Any], root: Optional[Path]) -> str:
    # root_url/root_line point at the declaring test file when `url` is a helper.
    url = test.get("root_url") or test.get("url")
    line = test.get("root_line") if test.get("root_url") else test.get("line")
    if not url:
        path = "unknown file"
    else:
        parsed = urlparse(str(url))
        path = unquote(parsed.path) if parsed.scheme == "file" else str(url)
        path = _relative(path, root)
    return f"{path}:{line}" if line is not None else path


def _relative(path: str, root: Optional[Path]) -> str:
    if root is None:
        return path
    try:
        return str(Path(path).resolve().relative_to(root.resolve()))
    except (ValueError, OSError):
        return path


def _flatten(value: Any, origin: str, unsupported: list[str]) -> Iterator[dict]:
    if isinstance(value, dict):
        yield value
    elif isinstance(value, list):
        if not value:
            unsupported.append(f"{origin}: empty list")
        for index, item in enumerate(value):
            yield from _flatten(item, f"{origin}[{index}]", unsupported)
    else:
        unsupported.append(f"{origin}: unsupported {type(value).__name__}: {value!r}")


def analyze(
    lines: Iterator[str] | list[str],
    exit_code: Optional[int],
    *,
    root: Optional[Path] = None,
    seed: Optional[str] = None,
) -> RunReport:
    tests: dict[Any, TestRecord] = {}
    order: list[Any] = []
    suites: dict[Any, str] = {}
    suite_errors: list[str] = []
    global_errors: list[str] = []
    malformed: list[str] = []
    unsupported: list[str] = []
    readable: list[str] = []
    error_events = 0
    done_seen = False
    done_success: Optional[bool] = None

    for line_number, raw_line in enumerate(lines, start=1):
        line = raw_line.strip()
        if not line:
            continue
        try:
            decoded = json.loads(line)
        except json.JSONDecodeError as error:
            malformed.append(f"Line {line_number}: {error.msg}: {line[:500]}")
            continue
        for event in _flatten(decoded, f"Line {line_number}", unsupported):
            kind = event.get("type")
            if not isinstance(kind, str):
                if event.get("event") == "test.startedProcess":
                    readable.append("PROCESS: Flutter test process started")
                else:
                    unsupported.append(
                        f"Line {line_number}: event without string type: "
                        f"{json.dumps(event, ensure_ascii=False)[:500]}"
                    )
                continue
            if kind == "suite":
                suite = _as_mapping(event.get("suite"))
                suites[suite.get("id")] = _relative(
                    str(suite.get("path", "unknown")), root
                )
                readable.append(f"SUITE: {suites[suite.get('id')]}")
            elif kind == "testStart":
                test = _as_mapping(event.get("test"))
                test_id = test.get("id")
                if test_id is None:
                    unsupported.append(f"Line {line_number}: testStart without id")
                    continue
                name = str(test.get("name", "Unknown test"))
                location = _location(test, root)
                if location == "unknown file" and test.get("suiteID") in suites:
                    location = suites[test.get("suiteID")]
                tests[test_id] = TestRecord(test_id, name, location)
                order.append(test_id)
                readable.append(f"START: {name} ({location})")
            elif kind == "testDone":
                test_id = event.get("testID")
                record = tests.get(test_id)
                if record is None:
                    unsupported.append(
                        f"Line {line_number}: testDone for unknown test {test_id}"
                    )
                    continue
                record.finished = True
                record.result = str(event.get("result", "unknown"))
                record.hidden = bool(event.get("hidden", False))
                record.skipped = bool(event.get("skipped", False))
                readable.append(f"DONE: {record.name} -> {record.result}")
            elif kind == "error":
                error_events += 1
                text = str(event.get("error", "Unknown test error"))
                stack = str(event.get("stackTrace", "") or "")
                record = tests.get(event.get("testID"))
                if record is None:
                    global_errors.append(text)
                    readable.append(f"GLOBAL ERROR: {text}")
                else:
                    record.errors.append(text)
                    if stack:
                        record.stacks.append(stack)
                    if record.finished:
                        record.errors_after_done += 1
                    readable.append(f"ERROR [{record.name}]: {text}")
                if stack:
                    readable.append(stack)
            elif kind == "print":
                record = tests.get(event.get("testID"))
                prefix = f"PRINT [{record.name}]" if record else "PRINT"
                readable.append(f"{prefix}: {event.get('message', '')}")
            elif kind == "suiteDone":
                if event.get("error"):
                    suite_errors.append(str(event.get("error")))
            elif kind == "done":
                done_seen = True
                success = event.get("success")
                done_success = success if isinstance(success, bool) else None
                readable.append(f"COMPLETE: success={success}")
            elif kind in ("start", "allSuites", "group", "debug"):
                if kind == "debug":
                    readable.append(f"DEBUG: {event.get('message', '')}")
            else:
                readable.append(f"EVENT [{kind}]: {json.dumps(event)[:500]}")

    report = RunReport(
        result=PASS,
        exit_code=exit_code,
        done_seen=done_seen,
        done_success=done_success,
        seed=seed,
        tests=[tests[test_id] for test_id in order],
        error_events=error_events,
        suite_errors=suite_errors,
        global_errors=global_errors,
        malformed_lines=malformed,
        unsupported_values=unsupported,
        reasons=[],
        contradictions=[],
        readable_lines=readable,
    )
    _classify(report)
    return report


def _classify(report: RunReport) -> None:
    reasons = report.reasons
    contradictions = report.contradictions
    code = report.exit_code
    failing = report.failed + report.errored
    event_failure = bool(
        failing
        or report.late_errors
        or report.suite_errors
        or report.global_errors
        or report.done_success is False
    )

    timeout = code in TIMEOUT_EXIT_CODES
    incomplete = False
    failed = False

    if timeout:
        reasons.append(f"runner exit {code} is a time-limit termination")
    if code is None:
        incomplete = True
        reasons.append("no test-runner exit code was recorded")
    if not report.done_seen:
        incomplete = True
        reasons.append("the event stream has no `done` event")
    elif report.done_success is None:
        incomplete = True
        reasons.append("the `done` event does not report success true/false")
    if report.unfinished:
        incomplete = True
        reasons.append(f"{len(report.unfinished)} started test(s) never finished")
    if failing:
        failed = True
        reasons.append(
            f"{len(report.failed)} failure and {len(report.errored)} error result(s)"
        )
    if report.late_errors:
        failed = True
        reasons.append(
            f"{len(report.late_errors)} test(s) reported errors after finishing"
        )
    if report.suite_errors or report.global_errors:
        failed = True
        reasons.append("suite or global runner errors were reported")
    if report.done_success is False:
        failed = True
        reasons.append("the `done` event reports success=false")
    if code is not None and code != 0 and not timeout:
        failed = True
        reasons.append(f"runner exited {code}")

    if code == 0 and (event_failure or report.unfinished or not report.done_seen):
        contradictions.append(
            "exit code 0 but the event stream shows failure or missing completion"
        )
    if (
        code not in (None, 0)
        and report.done_seen
        and report.done_success is True
        and not event_failure
        and not report.unfinished
    ):
        contradictions.append(
            f"event stream reports success but the runner exited {code}"
        )
    if contradictions:
        failed = True

    if timeout:
        report.result = TIMEOUT
    elif incomplete:
        report.result = INCOMPLETE
    elif failed:
        report.result = FAIL
    else:
        report.result = PASS


def render_markdown(report: RunReport, metadata: dict[str, str], stderr: str) -> str:
    counts = report.counts()
    out: list[str] = ["# Hydrion Flutter Test Report", ""]
    out += [f"**Result: {report.result}**", ""]
    out += ["| Field | Value |", "|---|---|"]
    for key, value in metadata.items():
        out.append(f"| {key} | `{value}` |")
    out.append(f"| Test exit code | `{report.exit_code}` |")
    out.append(f"| Random ordering seed | `{report.seed or 'not set'}` |")
    out.append(f"| `done` event | `{report.done_seen}` |")
    out.append(f"| `done.success` | `{report.done_success}` |")
    for key, value in counts.items():
        out.append(f"| {key.replace('_', ' ').capitalize()} | `{value}` |")
    out.append("")

    out += ["## Classification", ""]
    if report.reasons:
        out += [f"- {reason}" for reason in report.reasons]
    else:
        out.append("- Every started test finished and passed; exit code 0.")
    out.append("")
    if report.contradictions:
        out += ["## Contradictions (both retained)", ""]
        out += [f"- {item}" for item in report.contradictions]
        out.append("")

    def section(title: str, records: list[TestRecord], with_errors: bool) -> None:
        out.extend([f"## {title}", ""])
        if not records:
            out.extend(["None.", ""])
            return
        for record in records:
            out.append(f"- `{record.location}` {record.name}")
        out.append("")
        if not with_errors:
            return
        for record in records:
            out.append(f"### {record.name}")
            out.append("")
            out.append(f"- Location: `{record.location}`")
            out.append(f"- Result: `{record.result}`")
            out.append("")
            for text in record.errors or ["No structured error was emitted."]:
                out.extend(["```text", text.rstrip()[:8000], "```", ""])
            for stack in record.stacks:
                out.extend(["```text", stack.rstrip()[:8000], "```", ""])

    section("Unfinished tests", report.unfinished, False)
    section("Failing tests", report.failing, True)
    section("Skipped tests", report.skipped, False)

    for title, items in (
        ("Suite errors", report.suite_errors),
        ("Global runner errors", report.global_errors),
        ("Malformed machine-output lines", report.malformed_lines),
        ("Unsupported protocol values", report.unsupported_values),
    ):
        if items:
            out += [f"## {title}", "", "```text", *items, "```", ""]
    out += ["## Test runner stderr", "", "```text"]
    out.append(stderr[-20000:].rstrip() or "No stderr output was produced.")
    out += ["```", ""]
    return "\n".join(out)


def _read_lines(path: Path) -> list[str]:
    if not path.exists():
        return []
    return path.read_text(encoding="utf-8", errors="replace").splitlines()


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--machine", required=True, type=Path)
    parser.add_argument(
        "--exit-code",
        help="Exit code of the flutter test process; omit or pass a non-number "
        "when it was not recorded (classified INCOMPLETE).",
    )
    parser.add_argument("--stderr", type=Path)
    parser.add_argument("--report", type=Path, help="Markdown report output")
    parser.add_argument("--readable", type=Path, help="Readable log output")
    parser.add_argument("--json", type=Path, help="Machine summary output")
    parser.add_argument("--seed", help="Random ordering seed used for the run")
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args(argv)

    lines = _read_lines(args.machine)
    report = analyze(
        lines,
        parse_exit_code(args.exit_code),
        root=args.root,
        seed=args.seed,
    )
    if not args.machine.exists():
        report.unsupported_values.append(f"Machine output missing: {args.machine}")
    stderr = ""
    if args.stderr is not None and args.stderr.exists():
        stderr = args.stderr.read_text(encoding="utf-8", errors="replace")

    metadata = {
        "Repository": os.environ.get("GITHUB_REPOSITORY", "local"),
        "Commit": os.environ.get("GITHUB_SHA", "local"),
        "Workflow run": os.environ.get("GITHUB_RUN_ID", "local"),
    }
    if args.report is not None:
        args.report.write_text(
            render_markdown(report, metadata, stderr), encoding="utf-8"
        )
    if args.readable is not None:
        sections = ["\n".join(report.readable_lines)]
        if stderr:
            sections.append("STDERR\n======\n" + stderr)
        args.readable.write_text("\n\n".join(sections), encoding="utf-8")
    if args.json is not None:
        args.json.write_text(json.dumps(report.to_json(), indent=2), encoding="utf-8")

    counts = report.counts()
    print(
        f"result={report.result} exit_code={report.exit_code} "
        f"seed={report.seed or 'none'} "
        + " ".join(f"{key}={value}" for key, value in counts.items())
    )
    for reason in report.reasons:
        print(f"reason: {reason}")
    for item in report.contradictions:
        print(f"contradiction: {item}")
    for record in report.unfinished:
        print(f"unfinished: {record.location} {record.name}")
    for record in report.failing:
        print(f"failing ({record.result}): {record.location} {record.name}")

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as stream:
            stream.write(f"result={report.result}\n")
    return 0 if report.result == PASS else 1


if __name__ == "__main__":
    sys.exit(main())
