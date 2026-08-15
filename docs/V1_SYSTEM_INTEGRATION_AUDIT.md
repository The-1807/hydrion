# Hydrion V1 System Integration Audit

Audit baseline: `main` at `9e13586283a4cabd74b283a5a916c86cdf150139`
on 2026-08-14. The pre-existing uncommitted release signing probe in
`.github/workflows/hydrion-release.yml` was preserved and audited with the
current release path.

## Executive Summary

Hydrion's core repositories are connected to their principal Flutter surfaces,
and the selected daily goal is canonical across Home, Profile, Settings,
Analytics, challenges, pacing, and Android/iOS widget snapshots. The audit
confirmed three integration defects: two midnight-invalid Pomodoro assertions,
unlocalized Profile status pills, and a stale Settings goal editor after an
external goal mutation. No hydration calculation or safety rule required
changes.

Automated evidence cannot certify OS permission prompts, notification delivery,
WidgetKit installation, upgrade installation, signing-secret correctness, or
store distribution. Those remain physical or protected-CI checks.

## Current Release State

- Version: `1.2.0+4`.
- Android application ID: `com.the1807.hydrion`.
- iOS Runner: `com.the1807.hydrion`.
- WidgetKit extension: `com.the1807.hydrion.widgets`.
- App Group: `group.com.the1807.hydrion` for Runner and extension.
- Production locales: English, French, and Spanish.
- Flutter/Dart: 3.44.8 / 3.12.2. Java: Android Studio JBR 21.0.10.
- Android SDK: 37.0.0; Chrome and Windows toolchains available.
- Xcode and CocoaPods: unavailable on this Windows host.
- Free disk at preflight: 51.72 GB.

## Feature Integration Matrix

| Capability | Domain/service | Repository/persistence | UI/navigation | Locale | Widget/notification | Restart/migration | Platform/release | Status |
|---|---|---|---|---|---|---|---|---|
| Selected daily goal | CONNECTED | CONNECTED | CONNECTED | CONNECTED | CONNECTED | CONNECTED | CONNECTED | CONNECTED |
| Personalized goal | CONNECTED | CONNECTED | CONNECTED | CONNECTED | Widget uses selected goal; notification N/A | CONNECTED | Shared Flutter | CONNECTED |
| Body Metrics | CONNECTED | CONNECTED | CONNECTED | CONNECTED | NOT APPLICABLE by privacy policy | CONNECTED | Shared Flutter | CONNECTED |
| Manual goal override | CONNECTED | CONNECTED | CONNECTED after stale-field repair | CONNECTED | Widget listener CONNECTED | CONNECTED | Shared Flutter | CONNECTED |
| Wake/sleep pacing | CONNECTED | CONNECTED | Home card CONNECTED | CONNECTED | Raw schedule excluded; no auto-reminder | CONNECTED | Shared Flutter | CONNECTED, observational |
| Permissions | CONNECTED | Prompt history CONNECTED | CONNECTED | CONNECTED | OS-owned | N/A | Physical validation required | PARTIAL PHYSICAL |
| App locale | CONNECTED | CONNECTED | CONNECTED | Authoritative | Widget and active notification listeners CONNECTED | CONNECTED | Android app-locale bridge | CONNECTED |
| Reminders | CONNECTED | CONNECTED | CONNECTED | CONNECTED | CONNECTED | Reconciliation CONNECTED | Physical delivery required | PARTIAL PHYSICAL |
| Android widgets | CONNECTED | Canonical repositories | CONNECTED deep links | Native parity | CONNECTED | Snapshot refresh | Physical host required | PARTIAL PHYSICAL |
| iOS WidgetKit | CONNECTED | App Group snapshot | CONNECTED deep links | CONNECTED | CONNECTED | Configuration tested | macOS/device required | PARTIAL PHYSICAL |
| Pomodoro Sip | CONNECTED | CONNECTED | CONNECTED | CONNECTED | Ongoing notification CONNECTED | CONNECTED | Shared Flutter | CONNECTED |
| Homework/timed challenges | CONNECTED | CONNECTED | CONNECTED | CONNECTED | Stable notification IDs | CONNECTED | Shared Flutter | CONNECTED |
| Challenge lifecycle | CONNECTED | CONNECTED | CONNECTED | Render-time localization | Active widget CONNECTED | CONNECTED | Shared Flutter | CONNECTED |
| Weather guidance | CONNECTED | Context/cache CONNECTED | Explicit apply | CONNECTED | Permission-dependent | CONNECTED | Provider/device checks remain | CONNECTED WITH FALLBACKS |
| Profile deletion | CONNECTED | Category reset CONNECTED | Confirmed flow | CONNECTED | Cannot revoke OS truth | CONNECTED | Physical permission check | PARTIAL PHYSICAL |
| Android release artifact | Validator CONNECTED | N/A | N/A | N/A | N/A | N/A | Protected CI + signing required | BLOCKED ON PROTECTED RUN |
| iOS release | Source/config CONNECTED | N/A | N/A | N/A | Widget/reminder source CONNECTED | N/A | macOS signing unavailable | PARTIAL PHYSICAL |

## Confirmed Defects

### INT-P2-001: midnight-invalid Pomodoro assertions

- Symptom: CI failed when a legitimate event occurred during hour zero.
- Root cause: UI and service tests treated `timestamp.hour != 0` as evidence of
  a real persisted timestamp.
- Correction: UI test uses an inclusive confirmation/persistence time window;
  service test retains its stronger exact fake-clock equality.
- Production impact: none. The faulty contract was test-only.

### INT-P2-002: Profile goal status bypassed localization

- Symptom: French and Spanish Profile heroes displayed English baseline and
  weather states plus hardcoded `ml/day`.
- Root cause: `_ProfileHero` constructed three display strings directly.
- Correction: generated EN/FR/ES messages and localized behavioral tests.

### INT-P2-003: Settings goal field retained stale canonical state

- Symptom: summaries could update after an accepted tailored goal while the
  Settings editor retained its construction-time value.
- Root cause: `_DailyGoalCardState` never synchronized its controller when the
  watched repository produced a new `UserSettings` value.
- Correction: guarded `didUpdateWidget`; untouched values refresh while active
  user input is preserved.

## Partial Integrations

- Wake/sleep pacing is intentionally observational. It is surfaced on Home but
  does not create or delete reminders.
- OS permission truth, notification delivery, widget refresh, install/upgrade,
  and signing identity require physical or protected-run validation.
- iOS source/configuration is testable here; compilation, embedding,
  provisioning, and installation require macOS/Xcode.
- Behave scenarios exist but the local Python environment lacks `behave`.

## Disproven Suspicions

- Personalized calculation does not auto-apply or auto-log.
- Goal application updates `dailyGoalMl` without rewriting the calculated
  baseline.
- Home, Analytics, challenges, pacing, and widgets consume the canonical goal.
- Widget data excludes body metrics, reproductive/safety state, location, and
  wake/sleep schedule.
- Permission requests are action-driven; Permission Center refreshes on resume.
- Pacing is consumed by Home and is not a dormant engine.
- Challenge recommendations do not join automatically.

## Android

Android configuration, native widget providers, locale resources, bounded deep
links, min/target SDK policy, and artifact validation have automated coverage.
Debug and production certificates are correctly treated as incompatible update
identities. Clean install and production upgrade remain physical checks.

## iOS

Runner and WidgetKit bundle IDs, shared App Group entitlements, embedded
extension metadata, version alignment, deployment configuration, widget sizes,
deep links, and reminder source are covered by repository tests. No signed iOS
claim is made from Windows.

## Widgets

`AndroidWidgetService` listens to hydration, settings, locale, and challenge
repositories and synchronizes Android or iOS through `home_widget`. Snapshot
tests prove canonical goal/progress and privacy exclusions. Physical widget host
refresh and stale-state behavior remain unverified.

## Notifications

Reminder and timed-session services cover permission truth, stable IDs,
reconciliation, fallback scheduling, cancellation, locale refresh, and restart.
OS delivery timing, denied/settings round trips, and OEM behavior require
devices.

## Localization

`AppLocaleRepository` is authoritative and independent from profile settings.
All six EN/FR/ES direction changes now have persistence coverage. Flutter,
native Android strings, notifications, widgets, dialogs, and status pills render
from locale-aware sources. Stable IDs remain the preferred persisted identity.

## Personalization

Calculated baseline, contextual recommendation, and selected goal remain
separate. Apply is explicit and transactional; failed persistence retains state
and navigation. Manual override confirmation preserves the baseline. Resetting
the tailored association preserves goal, profile, metrics, and history.

## Wake/Sleep Pacing

Wake/sleep values persist in Body Metrics. Circular-day arithmetic supports
overnight schedules; equal/missing schedules are unavailable. Home consumes the
result using canonical logged volume and selected goal. Pacing cannot mutate
goal, baseline, logs, restrictions, reminders, widgets, or analytics.

## Challenges

Stable catalogue IDs drive eligibility, two-active limit, explicit join,
pause/resume/leave/completion/history, repeated attempts, evidence, localized
rendering, and profile-aware artwork. Pomodoro and Homework use shared timed
notification contracts without fabricating hydration.

## Persistence/Migrations

Independent repositories recover malformed categories without requiring a full
profile reset. Tests cover settings, locale, hydration, challenges, reminders,
Body Metrics, pregnancy duration, weather state, goal source, and legacy display
records. Selected-goal writes roll back in memory after storage failure.

## Accessibility/Responsiveness

Automated layouts cover compact phones, large text, keyboard insets, safe areas,
dialogs, challenges, onboarding, legal, Settings, Profile, and Body Metrics.
Permission Enabled state is textual and disabled rather than color-only.
Screen-reader quality, contrast perception, and native widget accessibility
still require human/device review.

## DevSecOps

Normal CI has read-only permissions and uses ephemeral Android signing.
Production secrets are isolated to manual release CI. Critical actions are SHA
pinned. Secret, production-string, localization, and artwork audits are wired.
The release workflow now probes private-key accessibility before expensive work,
validates the exact APK certificate and metadata, stages the validated APK,
verifies the AAB, hashes artifacts, and records source/toolchain provenance.

Dependabot monitors configured ecosystems. Updates should be triaged rather
than bulk-applied: security patches first, low-risk patches individually, and
major compatibility changes deferred until tested.

## Test Coverage Gaps

- Physical OS permission state changes and settings-return behavior.
- Actual Android/iOS notification delivery and OEM scheduling behavior.
- Widget host refresh, accessibility, empty/stale timelines, and deep links.
- Production clean/upgrade install with the intended certificate.
- Xcode compile, archive, provisioning, TestFlight, and WidgetKit installation.
- Human accessibility and visual review.

## Physical Validation Remaining

No platform build was run in this pass. Expected incremental disk use is roughly
1-3 GB for Android APK/AAB output, 2-6 GB for iOS simulator build products, and
2-6 GB for unsigned iOS release/archive intermediates, excluding new SDKs.
Owner approval is required before these large operations.

## Final V1 Risk Assessment

Core hydration, personalization, locale authority, persistence, and challenge
integration have strong automated evidence. Release risk is concentrated in
production signing credentials/artifacts and physical Android/iOS behavior.
Hydrion should not be called fully release-verified until protected Android CI
and the listed device/iOS checks pass.
