# Hydrion engineering handoff

Prepared 2026-10-05 for `audit/full-hydrion-integration` at
<https://github.com/The-1807/hydrion>. Check out this branch and record its full
HEAD before making changes. Preserve the existing remediation history.

## Read first

1. [HTD.md](../../HTD.md): authoritative findings, dependencies and latest status.
2. [Connector architecture](HYDRION_CONNECTOR_ARCHITECTURE.md).
3. [Acceptance procedure](REMEDIATION_ACCEPTANCE.md).
4. [Settings/profile receipt](SEC_001C_SETTINGS_PROFILE_IMPLEMENTATION.md),
   [I08 receipt](SEC_001D_I08_CHALLENGE_IMPLEMENTATION.md),
   [storage design](../../HYD_SEC_001_STORAGE_DESIGN.md) and
   [evidence index](evidence/README.md).
5. Relevant current source/tests. [edge_case.md](../../edge_case.md) preserves
   historical wearable findings and scoped synthetic validation.

## Current program state

- Stage 0A: ACCEPTED. Stage 1 and SEC-001: IN_PROGRESS.
- Accepted SEC-001 work: Body Containment, Protected-Store Pilot,
  SEC-001C Settings/Profile + Photo, and SEC-001D I08 Challenge State/History.
- SEC-001D remains IN_PROGRESS. I09 reminders/orphan notification IDs is the
  next repository checkpoint; I09, I13 provider connection history and private
  I05 guided-tour history are UNSTARTED.
- Remaining hydration/projection work and later stages follow current HTD.
- DATA-005, PRIV-002 and SEC-002 remain OPEN.
- Muse remains paused/read-only downstream until foundation remediation completes.

I08's final independently reviewed correction is
`a7f3104ee5c29a813824fb7f7f551fb81291e59a`; administrative acceptance is
`bf19ae6e2b793e631dcfd13c6165d7618d5fac30`, also the initial handoff HEAD.
SEC-001C's final independently reviewed correction is
`da457cad05411e29e889a6fa86018a8f232c7061`; administrative acceptance is
`32b9d3fa328e582996644964e53f6efba64898a2`.
Owner-supplied independent verdicts and validation are recorded in HTD. This
handoff adds no independent acceptance or runtime certification. Earlier BLOCKED
and pending records remain historical evidence; read the latest closure entries.

## Architectural mission

Hydrion is a local-first hydration application being incrementally rebuilt from
feature silos and connecting glue into one coherent system. Follow these goals:

- One authority per domain fact and one canonical command boundary for writes.
- One automated target calculator/committer and one time/calendar policy.
- Canonical aggregates consumed by features instead of independently recomputed truth.
- Protection and deletion following data lineage.
- Explicit unavailable/degraded states; unknown storage must not become empty state.
- Adapters downstream of domain truth.
- Preserve strong existing subsystems when they already satisfy the contracts.

The implementer cannot independently accept their own work. Follow HTD scope,
negative controls and the acceptance procedure for every later checkpoint.

## Publication and inventory

The branch was fetched before preparation. No remote branch of this name existed;
the initial HEAD contained all of `origin/main` plus 30 commits. A new branch push
preserves that lineage. The final handoff response records the exact published SHA.

Git's tracked-file inventory includes HTD, all architecture/acceptance receipts,
65 existing docs files, 165 lib files, 106 test files, 4 integration tests,
18 tool files, 7 GitHub files and platform/configuration/dependency files.
There were no untracked files at intake; the only staged change was edge_case.md.
This preparation adds documentation only, with edge evidence committed separately.
The evidence index records missing local artifacts and the photo-cap policy.

No runtime code or I09 implementation is part of this handoff. Full-suite, builds,
hosted CI, physical devices, backups and physical durability are not newly validated.
Use the committed receipts for the exact scope and limitations of earlier tests.
