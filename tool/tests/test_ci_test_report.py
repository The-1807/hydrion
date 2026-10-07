"""Classification tests for tool/ci_test_report.py; no Flutter required."""
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "ci_test_report", Path(__file__).parents[1] / "ci_test_report.py")
report_module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = report_module  # dataclasses resolve their module
spec.loader.exec_module(report_module)

ROOT = Path("/repo")


def start(test_id, name, line=10, url="file:///repo/test/a_test.dart", **extra):
    test = {"id": test_id, "name": name, "suiteID": 0, "line": line,
            "column": 3, "url": url}
    test.update(extra)
    return {"type": "testStart", "test": test, "time": 1}


def done(test_id, result="success", hidden=False, skipped=False):
    return {"type": "testDone", "testID": test_id, "result": result,
            "hidden": hidden, "skipped": skipped, "time": 2}


def error(test_id, text="boom", is_failure=False):
    return {"type": "error", "testID": test_id, "error": text,
            "stackTrace": "stack", "isFailure": is_failure, "time": 2}


def finished(success=True):
    return {"type": "done", "success": success, "time": 3}


def suite_header():
    return [
        {"type": "start", "protocolVersion": "0.1.1", "time": 0},
        {"type": "suite", "suite": {"id": 0, "platform": "vm",
                                    "path": "/repo/test/a_test.dart"}},
        start(0, "loading /repo/test/a_test.dart", line=None),
        done(0, hidden=True),
    ]


def lines(events):
    return [json.dumps(event) for event in events]


def run(events, exit_code):
    return report_module.analyze(lines(events), exit_code, root=ROOT, seed="7")


class ClassificationTests(unittest.TestCase):
    def test_clean_run_passes(self):
        report = run(suite_header() + [start(1, "ok"), done(1), finished()], 0)
        self.assertEqual(report.result, report_module.PASS)
        self.assertEqual(report.counts()["tests"], 1)
        self.assertEqual(report.counts()["passed"], 1)
        self.assertEqual(report.counts()["hidden"], 1)
        self.assertEqual(report.reasons, [])

    def test_error_result_fails_even_when_exit_is_zero(self):
        # The legacy summarizer only counted result == "failure".
        report = run(suite_header() + [
            start(1, "throws"), error(1), done(1, "error"), finished(False),
        ], 0)
        self.assertEqual(report.result, report_module.FAIL)
        self.assertEqual(report.counts()["errored"], 1)
        self.assertEqual(report.counts()["failed"], 0)
        self.assertEqual(report.counts()["error_events"], 1)
        self.assertTrue(report.contradictions)

    def test_failure_result_fails(self):
        report = run(suite_header() + [
            start(1, "expect"), error(1, is_failure=True), done(1, "failure"),
            finished(False),
        ], 1)
        self.assertEqual(report.result, report_module.FAIL)
        self.assertEqual([t.name for t in report.failing], ["expect"])
        self.assertEqual(report.failing[0].location, "test/a_test.dart:10")

    def test_exit_124_is_timeout_even_if_events_look_clean(self):
        report = run(suite_header() + [start(1, "ok"), done(1), finished()], 124)
        self.assertEqual(report.result, report_module.TIMEOUT)

    def test_sigalrm_exit_is_timeout(self):
        report = run(suite_header() + [start(1, "ok"), done(1)], 142)
        self.assertEqual(report.result, report_module.TIMEOUT)

    def test_missing_done_event_is_incomplete(self):
        report = run(suite_header() + [start(1, "ok"), done(1)], 0)
        self.assertEqual(report.result, report_module.INCOMPLETE)
        self.assertTrue(report.contradictions)

    def test_unfinished_tests_are_listed_with_location(self):
        report = run(suite_header() + [
            start(1, "ok"), done(1),
            start(2, "hangs", line=42,
                  url="file:///repo/test/support/helper.dart",
                  root_url="file:///repo/test/b_test.dart", root_line=77),
        ], 1)
        self.assertEqual(report.result, report_module.INCOMPLETE)
        self.assertEqual([(t.name, t.location) for t in report.unfinished],
                         [("hangs", "test/b_test.dart:77")])

    def test_unfinished_test_blocks_pass_even_with_done_success(self):
        report = run(suite_header() + [start(1, "hangs"), finished(True)], 0)
        self.assertEqual(report.result, report_module.INCOMPLETE)

    def test_missing_exit_code_is_incomplete(self):
        report = run(suite_header() + [start(1, "ok"), done(1), finished()], None)
        self.assertEqual(report.result, report_module.INCOMPLETE)
        self.assertIsNone(report_module.parse_exit_code("not-run"))
        self.assertIsNone(report_module.parse_exit_code(""))
        self.assertEqual(report_module.parse_exit_code(" 0\n"), 0)

    def test_nonzero_exit_with_clean_events_is_contradiction_fail(self):
        report = run(suite_header() + [start(1, "ok"), done(1), finished()], 1)
        self.assertEqual(report.result, report_module.FAIL)
        self.assertEqual(len(report.contradictions), 1)
        self.assertIn("exited 1", report.contradictions[0])

    def test_done_success_false_fails(self):
        report = run(suite_header() + [start(1, "ok"), done(1), finished(False)],
                     0)
        self.assertEqual(report.result, report_module.FAIL)

    def test_error_after_test_finished_fails(self):
        report = run(suite_header() + [
            start(1, "late"), done(1), error(1, "after completion"), finished(),
        ], 0)
        self.assertEqual(report.result, report_module.FAIL)
        self.assertEqual([t.name for t in report.failing], ["late"])

    def test_load_failure_of_hidden_suite_test_fails(self):
        report = run([
            {"type": "suite", "suite": {"id": 0, "path": "/repo/test/x.dart"}},
            start(0, "loading /repo/test/x.dart", line=None),
            error(0, "compile error"), done(0, "error", hidden=True),
            finished(False),
        ], 1)
        self.assertEqual(report.result, report_module.FAIL)
        self.assertEqual(report.counts()["errored"], 1)

    def test_skips_are_counted_separately_and_do_not_fail(self):
        report = run(suite_header() + [
            start(1, "ok"), done(1), start(2, "skip"), done(2, skipped=True),
            finished(),
        ], 0)
        self.assertEqual(report.result, report_module.PASS)
        self.assertEqual(report.counts()["skipped"], 1)
        self.assertEqual(report.counts()["passed"], 1)

    def test_malformed_and_nested_lines_are_retained(self):
        raw = lines(suite_header()) + [
            "not json",
            json.dumps([start(1, "ok"), done(1)]),
            json.dumps(finished()),
        ]
        report = report_module.analyze(raw, 0, root=ROOT)
        self.assertEqual(report.result, report_module.PASS)
        self.assertEqual(len(report.malformed_lines), 1)
        self.assertEqual(report.counts()["passed"], 1)

    def test_global_error_without_known_test_fails(self):
        report = run(suite_header() + [
            start(1, "ok"), done(1), error(99, "runner crashed"), finished(),
        ], 0)
        self.assertEqual(report.result, report_module.FAIL)


class CommandLineTests(unittest.TestCase):
    def invoke(self, events, exit_code, extra=()):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            machine = folder / "machine.jsonl"
            machine.write_text("\n".join(lines(events)), encoding="utf-8")
            output = folder / "github_output"
            argv = ["--machine", str(machine), "--exit-code", exit_code,
                    "--report", str(folder / "BUG_REPORT.md"),
                    "--json", str(folder / "summary.json"),
                    "--readable", str(folder / "readable.log"),
                    "--seed", "123", "--root", "/repo", *extra]
            with patch.dict(os.environ, {"GITHUB_OUTPUT": str(output)}), \
                    patch("sys.stdout"):
                code = report_module.main(argv)
            summary = json.loads((folder / "summary.json").read_text())
            markdown = (folder / "BUG_REPORT.md").read_text()
            return code, summary, markdown, output.read_text()

    def test_pass_exits_zero_and_records_seed(self):
        code, summary, markdown, output = self.invoke(
            suite_header() + [start(1, "ok"), done(1), finished()], "0")
        self.assertEqual(code, 0)
        self.assertEqual(summary["result"], "PASS")
        self.assertEqual(summary["seed"], "123")
        self.assertIn("**Result: PASS**", markdown)
        self.assertEqual(output, "result=PASS\n")

    def test_timeout_exits_nonzero_and_lists_unfinished(self):
        code, summary, markdown, output = self.invoke(
            suite_header() + [start(1, "hangs", line=5)], "124")
        self.assertEqual(code, 1)
        self.assertEqual(summary["result"], "TIMEOUT")
        self.assertEqual(summary["unfinished_tests"],
                         [{"name": "hangs", "location": "test/a_test.dart:5"}])
        self.assertIn("test/a_test.dart:5", markdown)
        self.assertEqual(output, "result=TIMEOUT\n")

    def test_missing_machine_file_is_incomplete(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch("sys.stdout"):
                code = report_module.main([
                    "--machine", str(Path(directory) / "absent.jsonl"),
                    "--exit-code", "0",
                    "--json", str(Path(directory) / "s.json")])
            summary = json.loads((Path(directory) / "s.json").read_text())
        self.assertEqual(code, 1)
        self.assertEqual(summary["result"], "INCOMPLETE")


if __name__ == "__main__":
    unittest.main()
