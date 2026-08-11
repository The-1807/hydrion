"""Behave hooks that make scenario status reflect implemented Hydrion reality."""

from pathlib import Path

from reality_sync import (
    DEVICE,
    IMPLEMENTED,
    NOT_IMPLEMENTED,
    PARTIAL,
    classify,
    run_evidence_suite,
    set_active_scenario,
    set_evidence,
)


def before_all(context):
    repo_root = Path(__file__).resolve().parent.parent
    result = run_evidence_suite(repo_root)
    set_evidence(result)
    context.hydrion_evidence = result
    context.reality_sync_counts = {
        IMPLEMENTED: 0,
        DEVICE: 0,
        PARTIAL: 0,
        NOT_IMPLEMENTED: 0,
    }


def before_scenario(context, scenario):
    status = classify(scenario.feature.name, scenario.name)
    context.reality_sync_counts[status] += 1
    scenario.effective_tags.add(status.lower())
    set_active_scenario(scenario.name)
    if status != IMPLEMENTED:
        scenario.skip(f"{status}: not claimed as automated Hydrion v1 behavior")


def after_scenario(context, scenario):
    set_active_scenario(None)


def after_all(context):
    counts = context.reality_sync_counts
    print("\nHydrion v1 reality-sync classification:")
    print(f"  implemented and automated: {counts[IMPLEMENTED]}")
    print(f"  implemented; native/device validation required: {counts[DEVICE]}")
    print(f"  partially implemented: {counts[PARTIAL]}")
    print(f"  not implemented: {counts[NOT_IMPLEMENTED]}")
    print(f"  evidence: {context.hydrion_evidence.output}")
