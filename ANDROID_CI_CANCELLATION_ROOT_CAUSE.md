# Hydrion Android CI Cancellation Diagnosis

Assessment date: 2026-09-06/07 UTC  
Scope: Android GitHub Actions build pipeline only  
Hosted resolution state: open

## Executive conclusion

The exact mechanism that cancelled the reported approximately 55-minute run is not provable from the locally available evidence. The required GitHub final annotation, Android job start/end timestamps, step timeline, and final Android build log were not supplied. The total workflow duration cannot be treated as Android compilation duration because `build-android` waited for the quality gate before starting and had its own 45-minute timeout.

Two independent workflow defects were confirmed and corrected:

1. Normal CI built the debug APK and then the release APK serially in one 45-minute Android job. Debug compilation consumed the same runner's time and disk before release compilation began.
2. `workflow_dispatch` used the same cancellable concurrency namespace as an ordinary push on the same ref. A push could therefore supersede a manual normal-CI run.

The earlier disk-exhaustion failure is distinct and confirmed by its explicit `No space left on device` errors. The later cancellation supplied no corresponding disk error. This work improves isolation and observability but does not prove that GitHub-hosted Android CI is fixed.

## Missing run evidence

The owner must copy these items from the cancelled run:

- Workflow run URL/number, event type, ref, commit SHA, and attempt.
- Final run and Android-job annotations, including whether GitHub says cancelled or timed out.
- Quality-gate start/end timestamps.
- Android-job start/end timestamps and every Android step duration.
- The final 200 lines from the active Flutter/Gradle step.
- Any disk/inode readings and the name of the last emitted Gradle task.
- Whether another run on the same ref started immediately before cancellation.
- Audit-log/manual-cancellation evidence if GitHub exposes it.

## Failed-run timeline

| Point | Evidence | Status |
|---|---|---|
| Workflow began | Displayed total was approximately 55 minutes | Reported, exact timestamp absent |
| Quality gate | Android job depended on it | Duration absent |
| Android job began | Must have followed quality gate | Timestamp absent |
| Android compilation | Reported active when cancellation occurred | Last Gradle line absent |
| Termination | GitHub cancellation mechanism/annotation absent | Unresolved |

## Competing hypotheses

| Hypothesis | Evidence for | Evidence against/limitation | Finding |
|---|---|---|---|
| Android job hit 45-minute timeout | Job configured `timeout-minutes: 45` | Job start/end timestamps absent; 55-minute workflow duration includes prerequisites | Plausible, unproven |
| Step timeout | No Android build step timeout existed | None supplied | Rejected for previous workflow configuration |
| New run superseded it | Normal CI had `cancel-in-progress: true` by workflow/ref | No competing-run timestamp supplied | Plausible, unproven |
| Manual cancellation | GitHub allows it | No annotation/audit evidence | Possible, unproven |
| Runner shutdown | Could present as cancellation | No runner annotation | Possible, unproven |
| Disk/inode exhaustion | Earlier run explicitly exhausted disk | Latest report lacked the prior error; no final readings | Not established for latest run |
| Gradle deadlock/stall | Build was reportedly still active | No heartbeat, process sample, or unchanged-task interval | Possible, unproven |
| Network/dependency stall | Fresh runner resolves dependencies | Cancellation reportedly occurred during compilation | Less consistent, unproven |
| Packaging/signing/upload stall | These are late phases | Report says compilation was active; last task absent | Less consistent, unproven |

## Local reproduction

Host: Windows 11 Pro 10.0.26200, Intel Core i3-7100, 4 logical processors, 17,082,179,584 B RAM. Initial free C: space was 22,055,923,712 B. NTFS inode counts are not exposed through the Git Bash `df -i` view.

Toolchain: Flutter 3.44.8, Dart 3.12.2, Gradle 8.12, AGP 8.9.1, Kotlin plugin 2.1.0. Flutter selected Android Studio JBR 21.0.10 for Android builds; CI remains pinned to Temurin Java 17. No toolchain version was changed.

| Run | Workspace state | Flutter duration | Gradle phase | Result |
|---|---|---:|---:|---|
| Prior release-equivalent APK | First release compilation in warm workspace | 521.238 s endpoint measurement | Not separately retained | Passed |
| Current diagnostic APK, first run | Warm caches with invalidated release inputs | 192.819 s | `assembleRelease` 187.3 s | Flutter passed; old diagnostic wrapper later returned 1 |
| Corrected diagnostic APK | Warm | 48 s wrapper measurement / 44.848 s Flutter | `assembleRelease` 39.7 s | Passed, exit 0 |
| Corrected diagnostic AAB | Warm after APK | 28 s wrapper measurement / 23.891 s Flutter | `bundleRelease` 16.9 s | Passed, exit 0 |

The slowest measured high-level phase was Gradle `assembleRelease` at 187.3 seconds. Verbose evidence shows configuration, Flutter AOT/assets, Android resource processing, DEX/desugaring, native-library work, lint-vital tasks, and packaging. The local host cannot reproduce hosted-runner CPU, network, or disk behavior.

The first wrapper run exposed a diagnostic defect: directory enumeration consumed about two minutes and the post-build diagnostic failure overrode a successful Flutter exit. Per-enumeration limits were reduced from 20 to 5 seconds, each whole diagnostic call is capped at one minute, and diagnostic failure now emits an explicit warning without replacing the compiler exit code.

## Artifact verification

| Artifact | Bytes | SHA-256 | Identity | Signing |
|---|---:|---|---|---|
| `build/app/outputs/flutter-apk/app-release.apk` | 98,334,246 | `829A2558F695325A79349AE8D2239D04DC52B288DEFB6397AEAEB9E35B86176D` | `com.the1807.hydrion`, `1.2.0+4`, min 24, target 36 | Unsigned local measurement |
| `build/app/outputs/bundle/release/app-release.aab` | 93,641,562 | `796532E525774E8434FACCC5B218A8C7005A5CB7426AC6C797972D4CB1AFA61F` | Release base module | Unsigned local measurement |

No production signing property, keystore, or secret was present or used. CI ephemeral signing and protected production validation remain unchanged.

## Workflow correction

Before:

- One `build-android` job ran debug then release builds under one 45-minute budget.
- Normal manual runs could be cancelled by a push sharing workflow/ref concurrency.
- Android builds emitted no bounded heartbeat/process/duration artifact.
- Release-candidate APK/AAB timing was not separated.
- Disk diagnostics allowed 20 seconds per recursive enumeration.

After:

- `build-android-debug` and `build-android-release` are separate `ubuntu-latest` jobs, each depending directly on the quality gate and each receiving a fresh 45-minute runner.
- Both debug smoke and signed ephemeral release artifacts remain required and uploaded.
- Android artifact runners restore neither Flutter SDK nor Pub caches.
- Manual normal-CI runs use an event-specific group and `cancel-in-progress: false`; pushes and PRs may still supersede obsolete equivalent runs.
- Protected release-candidate runs remain `cancel-in-progress: false`.
- APK and AAB builds use `tool/ci_run_android_build.sh`, which records UTC timestamps, duration, exact exit code, verbose phase output, minute heartbeats, processes, disk/inodes, and bounded directory sizes.
- Release-candidate APK and AAB timings are separate; Web remains a separate platform step.

## Timeout rationale

The Android debug and release jobs remain at 45 minutes. Increasing the timeout is unjustified until the missing hosted timeline is supplied. Forty-five minutes is 5.18 times the prior 521.238-second first local release build and 13.98 times the current 192.819-second compilation. Separating debug and release gives each artifact the full existing budget while preserving hang detection. The protected multi-artifact release-candidate job remains at 60 minutes.

## Concurrency rationale

Normal CI now groups by event type and ref. `workflow_dispatch` is non-cancellable, so a push or PR cannot supersede it. Pushes and PRs retain cancellation for obsolete same-event/same-ref duplicates. The protected release-candidate workflow has its own group and remains non-cancellable.

## Security implications

- Production credentials, certificate policy, APK validation, AAB signature verification, and action SHA pinning are unchanged.
- Debug and CI-ephemeral release artifacts remain clearly separate.
- No PR restores or writes an Android artifact cache because Android artifact jobs use no cache.
- Diagnostics list process names/resource use but do not print environment values or credentials.
- Upload paths are limited to explicit APK/staging/diagnostic directories, never the workspace, Gradle cache, SDK, audit output, or build tree.

## Exact local changes

- `.github/workflows/flutter-ci.yml`: isolated debug and signed ephemeral release APK builds on separate fresh runners, protected manual dispatch from superseding events, disabled Android artifact caches, and uploaded bounded diagnostics with `if: always()`.
- `.github/workflows/hydrion-release.yml`: disabled the release-candidate Pub cache, routed APK/AAB builds through the same bounded diagnostic wrapper, separated their timing, and retained all production signing and artifact validation.
- `tool/ci_run_android_build.sh`: added verbose build capture, timestamps, duration, exit-code preservation, minute heartbeats, resource snapshots, phase summaries, and bounded pre/post diagnostics.
- `tool/ci_disk_diagnostics.sh`: reduced recursive enumeration limits from 20 seconds to 5 seconds per path.
- `tool/validate_ci_workflows.dart` and `test/ci_workflow_policy_test.dart`: enforce runner isolation, cache policy, concurrency policy, diagnostics, and distinct debug/release commands.
- `CI_CACHE_AND_DISK_OPERATIONS.md`: documents runner, cache, disk-reclamation, capacity-gate, upload, and recovery policy.
- `audit-output/release-size-runtime/benchmarks/pdf_benchmark_test.dart` and `audit-output/release-size-runtime/benchmarks/storage_growth_benchmark_test.dart`: replaced two lint-only string concatenations with interpolation so the required full analyzer gate passes; benchmark behavior is unchanged.

No application source, production signing configuration, application ID, security gate, or release certificate expectation changed.

## Validation results

| Validation | Result |
|---|---|
| Workflow YAML parsing and policy validator | Passed; 2 workflows validated |
| Shell syntax, diagnostic wrapper and disk script | Passed with Git Bash `bash -n` |
| Changed-file and repository-wide Dart formatting | Passed; 207 files checked, 0 changed |
| `flutter analyze` | Passed; no issues found |
| Focused workflow/platform tests | Passed; 12 tests |
| Full `flutter test` | Passed; 630 tests in approximately 3 minutes 29 seconds |
| Secret scan | Passed; no committed credentials or private-key blocks found |
| Action SHA pinning and protected-gate policy | Passed through `validate_ci_workflows.dart` and focused policy tests |
| Local release APK wrapper | Passed; exit 0, identity/size/hash recorded above |
| Local release AAB wrapper | Passed; exit 0, size/hash recorded above |
| Android/iOS independent representation | Passed by parsed workflow structure and `platform_config_test.dart` |

Git diff/status checks were intentionally not run because this task expressly prohibits every Git operation. File inventory was performed directly through the filesystem instead.

## Hosted verification

Run `Hydrion Flutter CI` using `workflow_dispatch` on the intended commit. Do not rerun an unchanged obsolete SHA as proof of this correction. Confirm both Android jobs start after the quality gate on distinct runners, both finish within 45 minutes, both diagnostic artifacts upload, the release APK passes `validate_android_release.dart`, and Web/iOS remain independently represented. Then run `Hydrion Release Candidate` from `main` only when normal CI is green and production signing is intentionally available.

## Rollback

Restore the prior concurrency block and single Android job only if the split itself causes an evidenced regression. Remove calls to `ci_run_android_build.sh`, restore the original direct Flutter commands, and remove its policy assertions together. Do not weaken signing, artifact validation, or the separate iOS job during rollback.

## Acceptance criteria

- [x] The exact cancellation mechanism explicitly remains blocked; the missing GitHub annotation, job timeline, competing-run evidence, last Gradle line, and final capacity readings are identified.
- [x] Android release work runs on a fresh runner.
- [x] The original disk-exhaustion pattern is not reintroduced.
- [ ] Redundant Android compilation is eliminated where safely possible. Debug APK, release APK, and production AAB remain distinct required deliverables; no additional redundant invocation was proven safe to remove.
- [x] Diagnostics expose the active Gradle phase and build duration.
- [x] The unchanged 45-minute timeout has measured local headroom and still detects hangs.
- [x] PR/push activity cannot cancel a manual normal-CI run or protected release-candidate run.
- [x] Android artifact cache policy is bounded and trust-aware by restoring no cache.
- [x] No test, audit, security, packaging, signing, or release gate was removed.
- [x] The local release APK completed and its identity, size, and hash are recorded.
- [x] The local AAB completed and its size and hash are recorded.
- [x] Workflow validator and focused policy tests pass.
- [x] Full analyzer and 630-test regression suite pass.
- [x] No production credential was used.
- [x] No Git or GitHub operation was performed.
- [x] Hosted verification remains open until a complete GitHub Actions Android run succeeds.

## Remaining blockers

- Exact cause of the historical cancellation.
- Hosted evidence showing whether any remaining APK/AAB work can be safely reused rather than compiled independently.
- Hosted debug/release durations and phase/resource evidence with this workflow.
- A complete green hosted Android run proving the correction in GitHub Actions.
