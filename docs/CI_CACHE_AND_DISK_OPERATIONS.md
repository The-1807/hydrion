# CI Cache And Disk Operations

## Storage Model

GitHub Actions cache storage is remote, scoped by cache key and ref, and is
restored onto a new runner when a job starts. Artifact storage is also remote,
but stores declared test evidence and final deliverables after upload; it is not
a dependency cache. Each hosted job receives a temporary local filesystem.
Flutter installations, restored caches, `$HOME/.gradle`, the checked-out
workspace, test coverage, and `build/` all consume that local filesystem.

`No space left on device` can mean disk-block exhaustion or inode exhaustion.
The reported inability to create Gradle transform parents and write
`executionHistory.bin`, diagnostics, and the GitHub step summary establishes
local runner exhaustion. It does not establish a corrupt desugaring dependency.
Remote SDK-cache duplication was a contributing design problem because every
restored SDK also occupied local runner space, but remote cache quota and local
free space are distinct limits.

## Workflow Map

| Workflow/job | Runner | Dependency | Flutter/cache policy | Outputs |
|---|---|---|---|---|
| Flutter CI `quality-gate` | Ubuntu | none | SDK off; pub on for trusted non-PR runs | audit plus coverage, 30 days |
| Flutter CI `build-android` | Ubuntu | `quality-gate` | SDK off; pub on for trusted non-PR runs | debug and CI-signed APK evidence, 14 days |
| Flutter CI `build-web` | Ubuntu | `quality-gate` | SDK off; pub on for trusted non-PR runs | Web build, 14 days |
| Flutter CI `build-ios` | macOS 14 | `quality-gate` | SDK off; pub on for trusted non-PR runs | unsigned iOS app, 14 days |
| Release `validate-source` | Ubuntu | none | SDK off; trusted pub cache on | no transferred build output |
| Release `release-candidate` | Ubuntu | `validate-source` | SDK off; trusted pub cache on | protected APK/AAB/Web candidate, 30 days |

No repository composite actions exist. No job uses `actions/cache`, a Gradle
setup/cache action, artifact downloads, restore keys, or project-output caches.
The Flutter setup action owns the only remaining cache. Ordinary CI action uses
are commit-pinned, as are protected-release action uses. Java 17 and Flutter
3.44.8 are shared workflow pins; Gradle 8.12 is wrapper-pinned, with Android
Gradle Plugin 8.9.1 and Kotlin 2.1.0 pinned in `android/settings.gradle.kts`.

## Cache Ownership

`subosito/flutter-action` installs Flutter and owns the optional Flutter SDK and
pub caches. Hydrion disables its Flutter SDK cache in every job because each
saved Linux copy was approximately 1.6 GB and each macOS copy approximately
2 GB. Pull-request merge refs caused additional remote cache entries without
providing enough benefit to justify that storage.

The small pub dependency cache remains enabled only for trusted non-PR runs.
The action keys it by operating system, Flutter channel, Flutter version,
architecture, its cache hash, and `pubspec.lock`. Linux and macOS therefore do
not share cache content. Pull-request jobs neither restore nor save caches; this
is the simplest restore/write policy available through the setup action that
also prevents untrusted cache writes.

Hydrion does not configure a Gradle cache. In particular, it never caches
`~/.gradle/caches/*/transforms`, `android/.gradle`, project `build/`, APKs,
AABs, generated reports, coverage, or CI temporary output as dependencies.
Gradle creates local disposable state during each hosted job.

## Expected Sizes And Capacity

Observed remote cache sizes before this correction were about 1.6 GB per Linux
Flutter SDK, 2 GB per macOS Flutter SDK, and 58-59 MB per pub cache. The SDK
caches are no longer written. Pub cache size should be checked after toolchain
or dependency changes.

The protected Android job temporarily requires 10 GiB free immediately before
compilation. This is a conservative provisional gate, not a measured peak.
Recalibrate it only after a successful hosted release records pre-build,
post-build, and failure-path measurements in `ci_disk_diagnostics.sh` output.
The diagnostic includes both `df -h` and `df -i`, so exhausted disk blocks can
be distinguished from exhausted inodes.

## Job And Artifact Policy

Release source validation runs in a separate job. The protected APK, AAB, and
Web builds begin on a fresh Ubuntu runner only after validation succeeds. The
ordinary CI workflow already isolates quality, Android, Web, and iOS work by
job and runner OS.

Quality evidence and coverage are uploaded together once for 30 days. Ordinary
platform artifacts are retained for 14 days. Protected release-candidate
artifacts are retained for 30 days. Build directories and caches are never
uploaded as artifacts.

## Safe Cleanup

At release-job start, the workflow removes hosted-runner .NET, GHC, Boost, and
unused Docker data because Hydrion's Android/Web release uses Flutter, Android,
and Java. It does not delete the Android SDK, active Java installation, Flutter
installation, Gradle wrapper, or dependency metadata.

Immediately before Android compilation, cleanup is restricted to these
regenerable workspace paths:

- `build/test_cache`
- `build/unit_test_assets`
- `coverage`
- `android/.gradle`

The workflow resolves the workspace and every target first, requires the
workspace to be under `/home/runner/work/`, and rejects targets that escape it.

## Remote Cache Maintenance

Repository owners may remove obsolete entries manually at **Actions >
Management > Caches**. Delete old Flutter SDK entries scoped to
`refs/pull/*/merge`, followed by redundant branch-scoped SDK entries. Retain the
current small pub cache for trusted `main` runs. Confirm the key and ref before
deletion; never automate bulk cache deletion from this workflow.

## No-Space Recovery

1. Open the failed job and inspect every grouped disk diagnostic.
2. Compare `df -h` with `df -i` to identify block or inode exhaustion.
3. Compare workspace, Gradle transform, pub-cache, Android SDK, and build sizes.
4. Confirm Android started on a fresh runner after `validate-source`.
5. Confirm the pre-build capacity gate passed and note available MiB.
6. Identify the directory growth between the last healthy and first failing
   checkpoint before changing cleanup or capacity policy.
7. Rerun the protected **Hydrion Release Candidate** workflow from `main` only
   after the workflow correction is reviewed and present on that branch.

The diagnostics are evidence only. They do not suppress Gradle, signing,
validation, or artifact failures. Hosted-runner image contents and available
capacity can change over time, and only a successful hosted run can establish
that the current release fits.
