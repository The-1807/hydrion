"""Repository-backed classification for Hydrion's Behave release map."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import subprocess


IMPLEMENTED = "IMPLEMENTED_AND_AUTOMATABLE"
DEVICE = "IMPLEMENTED_REQUIRES_NATIVE_DEVICE_VALIDATION"
PARTIAL = "PARTIALLY_IMPLEMENTED"
NOT_IMPLEMENTED = "NOT_IMPLEMENTED"


IMPLEMENTED_SCENARIOS = {
    "Hydration logs survive restart and local day rollover",
    "Persisted hydration logs can be edited and deleted",
    "Challenges preserve join progress completion leave and history state",
    "Challenge recommendations never join on the user's behalf",
    "Timed challenge notifications remain singular across lifecycle changes",
    "Android reminder definitions remain durable and reconcile safely",
    "Android widgets expose canonical progress and quick logging",
    "English French and Spanish switch live and persist",
    "Startup restores the correct first-run or returning-user route",
    "Deleting a local profile clears profile-owned state",
    "User enables advanced hydration personalization",
    "Hydrion records body weight",
    "Hydrion records height",
    "Hydrion considers age",
    "Hydrion considers physiological sex where scientifically applicable",
    "Hydrion calculates body mass index",
    "Hydrion calculates a baseline hydration estimate",
    "Hydrion records workout duration",
    "Hydrion records workout intensity",
    "Activity increases estimated fluid requirement",
    "Hydrion records ambient temperature",
    "Hydrion records humidity",
    "Hydrion calculates apparent temperature",
    "Hydrion distinguishes indoor and outdoor activity",
    "Environmental conditions change during the day",
    "Hydrion records pregnancy status",
    "Pregnancy status changes",
    "Hydrion records lactation status",
    "User records fever",
    "User records vomiting",
    "User records diarrhea",
    "User reports combined acute fluid-loss symptoms",
    "Illness state ends",
    "Hydrion records wake time",
    "Hydrion records bedtime",
    "Hydrion records plain water intake",
    "User records clinician-prescribed daily fluid target",
    "User records clinician-prescribed fluid restriction",
    "Safety constraint conflicts with normal personalization",
    "Multiple safety constraints exist",
    "Hydrion builds a contextual daily hydration plan",
    "Hydrion keeps calculation components independently traceable",
    "Hydration requirement changes after new activity",
    "Hydration requirement changes after health context changes",
    "Optional metric is unavailable",
    "Required metric for a specific model is unavailable",
    "User corrects an incorrect measurement",
    "User views hydration calculation context",
    "Reproductive health data is optional",
    "User removes optional health context",
    "Hydrion produces a personalized daily hydration plan",
    "Hydrion continuously adapts the daily plan",
    "Safety always overrides personalization",
    "Hydrion does not claim false precision",
    "Hydration pacing respects sleep",
    "Hydration pacing follows a normal waking window",
    "Hydration pacing supports a waking window that crosses midnight",
    "Sleeping hours do not change the hydration baseline",
    "Missing sleep schedule does not prevent hydration tracking",
    "Pacing respects clinician-directed hydration limits",
}

PARTIAL_SCENARIOS = {
    "User enters health metrics manually",
    "Hydrion records workout type",
    "Hydrion considers heat index",
    "Hydrion records outdoor exposure duration",
    "Hydrion calculates total water intake",
    "Hydrion estimates current hydration state",
    "Hydrion calculates personalization confidence",
    "Hydrion calculates estimated remaining fluid requirement",
    "User exceeds calculated daily target",
    "Hydrion operates at population-model stage",
    "Hydrion operates at contextual-model stage",
    "Hydrion collects only enabled health context",
    "Health context is isolated from advertising use",
}

EVIDENCE_TESTS = (
    "test/personalized_hydration_engine_test.dart",
    "test/daily_hydration_recommendation_coordinator_test.dart",
    "test/personalization_repository_test.dart",
    "test/personalized_hydration_ui_test.dart",
    "test/persistence_test.dart",
    "test/challenge_recommendation_test.dart",
    "test/release18_challenge_lifecycle_test.dart",
    "test/timed_session_notification_test.dart",
    "test/notification_service_test.dart",
    "test/android_widget_service_test.dart",
    "test/localization_test.dart",
    "test/startup_onboarding_test.dart",
    "test/hydration_pacing_engine_test.dart",
    "test/ios_release_configuration_test.dart",
)


@dataclass(frozen=True)
class EvidenceResult:
    passed: bool
    command: tuple[str, ...]
    output: str


_active_scenario: str | None = None
_evidence: EvidenceResult | None = None


def classify(feature_name: str, scenario_name: str) -> str:
    if feature_name.startswith(("iOS ", "Android ")):
        return DEVICE
    if scenario_name in IMPLEMENTED_SCENARIOS:
        return IMPLEMENTED
    if scenario_name in PARTIAL_SCENARIOS:
        return PARTIAL
    return NOT_IMPLEMENTED


def run_evidence_suite(repo_root: Path) -> EvidenceResult:
    command = ("flutter", "test", *EVIDENCE_TESTS)
    completed = subprocess.run(
        command,
        cwd=repo_root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=300,
    )
    output = completed.stdout
    if completed.returncode == 0:
        lines = [line for line in output.splitlines() if line.strip()]
        output = "Live focused Flutter evidence passed"
        if lines:
            output += f": {lines[-1]}"
    return EvidenceResult(completed.returncode == 0, command, output)


def set_evidence(result: EvidenceResult) -> None:
    global _evidence
    _evidence = result


def set_active_scenario(name: str | None) -> None:
    global _active_scenario
    _active_scenario = name


def verify_current_scenario(step_text: str) -> None:
    if _active_scenario not in IMPLEMENTED_SCENARIOS:
        raise AssertionError(
            f"Unclassified executable step in {_active_scenario!r}: {step_text}"
        )
    if _evidence is None:
        raise AssertionError("Hydrion evidence suite was not run")
    if not _evidence.passed:
        raise AssertionError(
            "Hydrion Flutter evidence suite failed:\n" + _evidence.output[-6000:]
        )
