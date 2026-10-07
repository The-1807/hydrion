# Wave 0 Interrupted Handoff

Prepared 2026-10-07 on the Mr Gold Apple Mac. **Nothing in Wave 0 is accepted.**
Every Wave 0 branch below is pushed to GitHub only so that work survives the
host failure. Treat all of it as unreviewed input to be re-validated on a
healthy machine.

Plan of record: [HYDRION_REBUILD_BLUEPRINT.md](HYDRION_REBUILD_BLUEPRINT.md)
(APPROVED 2026-10-05, decisions O1–O24 at recommended defaults). Findings and
history: [HTD.md](../../HTD.md). Acceptance rules:
[REMEDIATION_ACCEPTANCE.md](REMEDIATION_ACCEPTANCE.md).

## Why work stopped (environmental interruption)

- The repository lived in `~/Documents/hydrion`, which is managed by iCloud
  Desktop & Documents with Optimize Mac Storage. macOS evicted ~38,700 repo
  files to "dataless" placeholders, including 218 files under `.git`
  (HEAD, config, index, packed-refs, pack files, worktree links), 753 tracked
  source files and `.dart_tool/package_config.json`. Reads of evicted files
  timed out (`Operation timed out`), which stalled test runs and briefly made
  git report "not a git repository". iCloud was also uploading `.git`
  internals.
- The 113 GB data volume reached effectively 100% (as low as 32 MB free).
  Agents hit `No space left on device` during compiles, test runs and
  commits; git reported I/O errors.
- During those failures one `git fsck` printed
  `refs/heads/main: invalid sha1 pointer 0000…` and
  `refs/heads/rebuild/blueprint: invalid sha1 pointer 0000…`. This is
  consistent with read failures, **not proven corruption**: both refs
  resolved and were usable afterwards. A clean `git fsck --full` must be run on
  the new machine.
- The host has 8 GB RAM / 4 cores; four parallel Flutter suites drove load
  average to ~161. Validation results produced under these conditions are not
  trustworthy evidence.
- No destructive repair was performed on the Mac. Local worktrees and
  branches were left in place.

## Branch state (all pushed; none merged; main untouched)

All Wave 0 branches fork from `rebuild/blueprint`
(`b173930908ecc84b0b1684ce2dbfe16dcd905b9a`), itself based on `origin/main`
`e7d805d` (includes I09, PR #141). No independent review has occurred on any
Wave 0 branch.

### rebuild/blueprint (handoff branch)
- Purpose: approved rebuild blueprint and this handoff.
- Commits: `71db05e683814a81a11c5742261c95c7cad6ac1f` (blueprint draft),
  `b173930908ecc84b0b1684ce2dbfe16dcd905b9a` (owner approval, O1–O24), plus
  the commit adding this file.
- State: DOCUMENTATION, APPROVED PLAN. Not merged to main.

### chore/coderabbit-config
- Purpose: `.coderabbit.yaml` (assertive reviews, request-changes workflow,
  HTD invariants as path rules, blocking pre-merge checks, security/workflow
  linters).
- Commit: `1deda2597d178ea88aab2d1eeeb13c57a6ee73a5`.
- Validation actually run: schema validation against
  `https://coderabbit.ai/integrations/schema.v2.json` (0 errors) and yamllint
  (pass). Secret-pattern scan: 0 hits.
- State: IMPLEMENTED_UNVALIDATED in production (CodeRabbit has not yet
  reviewed a Hydrion PR). Not merged. Separately, GitHub ruleset "CPRAM" on
  main was enabled on 2026-10-05 (PR required, resolved threads, required
  check "Analyze, Test, and Audit", no force push/deletion, admin bypass).
  CodeRabbit is NOT yet a required check: add it once its exact check name is
  observed on a real PR.

### wave0/safety-data (W0-B: D1, D3, D4, D6)
- Commits:
  - `ec3a6e2af065915153bfce7a854ae51a4e6ab9cf` D1 clinician mode without a
    valid target now adds the fluid-restriction notice and blocks auto-apply.
  - `856f12665a57a848cba43f4f1bf7f23a4e59affe` D6 weather confirmation keeps
    the user's auto-apply preference.
  - `3d2b9ca85eaf86f3d59c9e65323a5dd813da0227` D4 single-flight AI suggestion
    confirmation (no double logging).
  - `c99a6eed24aaa6ed591a5bdde4363c5e4f5b4b05` D3 daily-context authority
    marker and verified deletion intent. **Committed after the stop request;
    its tests were not run before commit.**
- Tests actually run (agent-reported, on the Mac): D1 new 12 tests (10 failed
  on old code, 12 pass on new) + 113 regression tests passed; D6 3 tests
  (negative control confirmed) + 45 regression tests passed; D4 5 tests
  (negative control confirmed) + existing coach tests (8 total) passed.
- NOT RUN: D3 tests (old and new code), updates to existing
  `protected_daily_context_test.dart` snapshot assertions expected to need the
  new marker, scoped regression list, analyzer, full suite, secret scan.
- Known open items: AI hydration logs still lack a stable idempotency/action
  ID (needs `lib/domain/hydration_contracts.dart` and
  `lib/services/hydration_ai_action_executor.dart`, owned by intake work).
- State: D1/D4/D6 IMPLEMENTED_UNVALIDATED (focused evidence only); D3 PARTIAL.

### wave0/widget-time (W0-D: D5, D7, D8, D11-widget)
- Commits:
  - `87eec75ccd188754a5a2256d7f9170d0c4d5d3a2` D8 civil-day arithmetic with
    new `lib/domain/time/local_date.dart` (K1 seed); fixes DST off-by-ones in
    challenge schedules, history, day number and "yesterday" labels.
  - `43d09f53c9baee27e149a442b679a87a2962597a` WIP snapshot: D7 shared
    `ChallengeRepository.activityDayToken` used by the widget plus
    `test/android_widget_activity_day_test.dart`; D5 native per-tap nonce
    trampoline (`WidgetQuickLogActivity.kt`, `HydrionWidgets.kt`,
    `AndroidManifest.xml`) and related `android_widget_service.dart` changes.
- Tests actually run: D8 16/16 pass under America/New_York, UTC,
  Australia/Lord_Howe and Europe/London; negative controls failed on old logic
  as expected. D7 negative control failed on old logic as expected.
- NOT RUN: D7 post-fix run (an ENOSPC-killed task falsely reported exit 0),
  D5 Dart tests (not written), device test of the native trampoline,
  regression list (two SQLCipher reminder tests failed in a disk-starved batch
  but passed alone), full suite, `flutter build apk`.
- NOT STARTED: D11 widget platform guard (`android_widget_service.dart`
  `dart:io Platform` at ~128-129, ~282, ~310).
- State: D8 IMPLEMENTED_UNVALIDATED; D7 WIP; D5 WIP (native draft); D11
  NOT_STARTED.

### wave0/startup-platform (W0-C: D2, D11-watch)
- Commit: `701b124c5a95b778e45e0b99564b9415b247e847` WIP snapshot: D2
  degraded startup (class (a) composition failure shows a localized error
  with Retry; class (b) post-composition steps are contained and recorded,
  routing continues with a degraded notice and Retry), D11 watch platform
  guard (`kIsWeb`-safe, injectable support, idempotent initialize), EN/FR/ES
  strings, `test/startup_degraded_routing_test.dart`,
  `test/watch_connectivity_platform_test.dart`.
- Tests actually run: pre-fix negative controls (4 expected failures);
  first post-fix run 8 passed, 1 failed (banner tooltip without Overlay),
  after which the layout was changed. Analyzer, scoped format, localization
  audit (980/980) and mixed-language audit passed at that point.
- NOT RUN: post-fix tests after the layout change, regression list, full
  suite, `flutter build web`.
- Known open items: `AndroidWidgetService.initialize` is not idempotent
  (retry could double-register listeners); class (a) retry does not dispose
  partially opened resources; `_healthProviderForPlatform` lacks `kIsWeb`.
- State: WIP.

### wave0/ci-platform (W0-A: K12, D9, D10)
- Commits:
  - `c021483868fd706db18d52a72f978e9011cd9af9` CI summarizer moved to
    `tool/ci_test_report.py` with unit tests; TIMEOUT/INCOMPLETE/FAIL
    classification; logged random test-order seed; workflow validator and
    policy test.
  - `8ac6b77cedd20fd3cc4c73bd9501f6d75981e717` literal-audit classifier rules
    with negative controls; audit made a blocking gate.
  - `abf8295f78dccf518610003fe03600b6c2d4078a` WIP snapshot: injectable
    composition in `lib/main.dart`, `test/support/test_services.dart`
    (`composeTestServices`), `test/flutter_test_config.dart` and
    `platform_channel_guard.dart` (fail fast on unmocked channels),
    controllable fakes, legal screen Future fix (D9), migration of tests away
    from the `runAsync` workaround.
- Tests actually run (local JSON evidence, not committed): a 5-suite run of
  migrated tests passed 37/37 (complete); a 7-suite baseline (111 passed) and
  a legal seed-0 run (13 passed) never completed (INCOMPLETE); a 15-suite
  survey recorded 25 failures and 1 error and never completed (INCOMPLETE),
  most likely from the new fail-fast channel guard.
- NOT RUN: full suite in default and random order, Python unit tests' final
  run, analyzer and format on the final tree, secret scan, literal audit on
  the final tree, workflow validator on the final tree.
- The agent stalled mid-task (no final report).
- State: c021483/8ac6b77 IMPLEMENTED_UNVALIDATED; abf8295 WIP.

### Other branches touched this session
- `remediation/sec-001d-i09-reminders` (`c88b8969be86da8140f9d31efb0bb7cf5bc7eb23`):
  I09 implementation, pushed earlier and merged to main via PR #141 by the
  owner's account without independent review. Blueprint Wave 1 refactors it
  onto the shared protected-dataset component.

## Files intentionally not committed
Local test-run logs in `/private/tmp/claude-501/w0-ci-evidence/`, agent
scratch evidence folders, `build/`, `.dart_tool/`, `ios/DerivedData/`, and any
temporary databases or Flutter temp directories. No credentials were found or
committed.

## New-machine recovery instructions

Place the clone **outside** iCloud Drive, OneDrive or Dropbox managed folders
(for example `~/Developer/hydrion`).

1. Clone or fetch Hydrion: `git clone https://github.com/The-1807/hydrion.git`.
2. Verify remotes: `git remote -v`.
3. Fetch all branches: `git fetch --all --prune`.
4. Run `git fsck --full` and resolve any reported problem before continuing.
5. Check out `rebuild/blueprint`.
6. Read, in order: `docs/architecture/CLAUDE_HANDOFF.md`, `HTD.md`,
   `docs/architecture/HYDRION_REBUILD_BLUEPRINT.md`,
   `docs/architecture/REMEDIATION_ACCEPTANCE.md`, and this file.
7. Inspect every `wave0/*` branch (`git log rebuild/blueprint..wave0/<name>`)
   and confirm the SHAs above.
8. Reproduce and validate each branch's work from a clean checkout before
   integration: focused tests with negative controls, analyzer, format,
   secret scan, localization and literal audits, then the full suite in
   default and logged random order. Finish the items marked NOT RUN,
   PARTIAL, WIP and NOT_STARTED.
9. Do not trust validation produced on the Mac during the interruption.
10. Resume the multi-agent rebuild (independent auditors per workstream, then
    integration and owner sign-off) only after repository integrity and
    machine health are confirmed. Limit parallel full Flutter suites to what
    the new machine can sustain.
