# APK Stabilization Notes

## Android Build Toolchain

- Hydrion Android currently uses Android Gradle Plugin 8.9.1, Kotlin 2.1.0, and Gradle 8.12.
- AGP 8.9 requires JDK 17 and Gradle 8.11.1 or newer.
- Gradle 8.12 is above the AGP 8.9 minimum, but current Gradle compatibility docs list Java 25 runtime support starting at Gradle 9.1. Use JDK 17 for this AGP line unless a later toolchain upgrade is deliberate.
- The Android SDK was not installed in this environment, so APK build validation stopped before Gradle execution.
- The repository contains `android/gradle/wrapper/gradle-wrapper.properties`, but no wrapper scripts or `gradle-wrapper.jar`; direct `gradlew` validation cannot run until the wrapper is restored or the Android toolchain is installed.

## Kotlin Daemon Stability

- `android/gradle.properties` now sets repository-controlled Kotlin daemon JVM arguments instead of relying only on inherited Gradle daemon defaults.
- Gradle worker concurrency is capped at 2 to reduce daemon connection pressure on slower Windows workstations.
- Do not hide Kotlin daemon failures in logs. If `Could not connect to Kotlin compile daemon` returns, capture the full clean and incremental build logs before changing these values.

## Duplicate Flutter Plugin Registration

- Android uses the current Flutter v2 embedding with `MainActivity : FlutterActivity`.
- No manual plugin registration, cached engine, custom engine group, or generated registrant invocation is present in the Android source tree.
- If duplicate plugin registration warnings recur, first verify that only one debug run is attached and that stale app processes were stopped before treating it as a source registration defect.
