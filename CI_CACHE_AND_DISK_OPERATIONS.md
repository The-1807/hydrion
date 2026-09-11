# Hydrion CI Cache and Disk Operations

## Policy

Android artifact jobs prioritize predictable disk headroom over speculative cache speed. No measurement proves that restoring a Pub cache is necessary for the Android bottleneck, while earlier evidence proves build-space exhaustion can fail release packaging.

| State | Android debug job | Android release job | Protected release-candidate job |
|---|---|---|---|
| Flutter SDK cache | Disabled | Disabled | Disabled |
| Pub cache | Disabled | Disabled | Disabled |
| Gradle cache action | Prohibited | Prohibited | Prohibited |
| `build/` cache | Prohibited | Prohibited | Prohibited |
| `android/.gradle` cache | Prohibited | Prohibited | Prohibited |
| `.dart_tool` cache | Prohibited | Prohibited | Prohibited |
| Gradle transforms | Prohibited | Prohibited | Prohibited |
| Coverage/PDF/audit output cache | Prohibited | Prohibited | Prohibited |

Because Android artifact runners restore no cache, no cache key, restore prefix, writer trust boundary, or eviction policy applies. Quality/Web/iOS jobs retain their pre-existing policies and do not share a runner or build output with Android artifact jobs.

## Runner isolation

- Quality analysis/tests run on their own runner.
- Debug Android smoke packaging runs on a fresh runner.
- Signed ephemeral Android release packaging runs on another fresh runner.
- Web and iOS builds remain independent jobs.
- Protected release-candidate validation and artifact construction are separate jobs.
- APK then AAB stay together only in the protected release-candidate job so the AAB can reuse compatible release intermediates; Web is a separately timed step.

## Generated-data reclamation

The protected release-candidate job removes only these enumerated, regenerable paths inside the verified hosted workspace before Android compilation:

- `build/test_cache`
- `build/unit_test_assets`
- `coverage`
- `android/.gradle`

The workflow resolves every target beneath `GITHUB_WORKSPACE` and refuses cleanup outside `/home/runner/work/*`. It does not delete Flutter, Java, Android SDK, NDK, Gradle home, Pub dependency sources, production credentials, source assets, or application data.

## Capacity gates

The protected release-candidate job requires at least 10 GiB free space and 500,000 free inodes before Android construction. These remain conservative temporary thresholds until a complete hosted run supplies phase measurements. Failure messages distinguish byte and inode shortages.

## Diagnostic bounds

`tool/ci_disk_diagnostics.sh` records filesystem bytes/inodes and attempts sizes for Gradle home/transforms, Pub cache, Android SDK, workspace, Flutter output, APK outputs, and project Gradle state.

- Every `du` call is limited to five seconds.
- Largest-entry enumerations are limited to five seconds.
- Workflow/wrapper invocations are capped at one minute.
- Unavailable size readings are reported rather than hanging indefinitely.
- A diagnostic failure emits a warning and does not replace the actual compiler exit code inside the build wrapper.

The local first wrapper run showed why the bound matters: the previous 20-second scans added roughly two minutes and a post-build diagnostic failure changed a successful Flutter result into wrapper exit 1. After correction, the warm APK wrapper returned exit 0 with 48 seconds compilation, and AAB returned exit 0 with 28 seconds compilation.

## Build observability

For APK and AAB construction, `tool/ci_run_android_build.sh` records:

- Preparation, compilation-start, and end UTC timestamps.
- Compilation wall-clock seconds and exact Flutter exit code.
- Verbose Flutter and Gradle output.
- A phase-summary tail containing Gradle/packaging lines.
- Minute heartbeats with disk, inodes, relevant process CPU/RSS, workspace size, build size, and project Gradle size.
- Pre-build and post-build bounded capacity reports.
- GitHub step-summary duration/result when available.

Diagnostic uploads are limited to `ci-artifacts/android-debug/`, `ci-artifacts/android-release/`, and `ci-artifacts/android-appbundle/`. Product uploads remain limited to the exact APK, validated staging directory, size report, or release-artifact directory.

## Trust boundaries

- Pull requests cannot populate an Android artifact cache because none exists.
- Protected production signing exists only in `hydrion-release.yml`.
- Normal CI uses a newly generated ephemeral key only for clean-install smoke artifacts.
- No SDK, dependency source, cache, workspace, build directory, secret file, or audit output is uploaded.
- GitHub Actions remain commit-SHA pinned and are checked by `tool/validate_ci_workflows.dart`.

## Recovery

For another no-space failure, use the diagnostic artifacts to identify the last successful phase and largest bounded directory. Do not broadly delete runner toolchains or restore large caches. Adjust cleanup or capacity thresholds only from hosted evidence. For a timeout/cancellation, compare event/ref concurrency, job timestamps, heartbeat continuity, last Gradle task, compiler exit code, and final capacity state before changing timeouts.

