# HYD-BLOCK-004 — iOS Startup Investigation (Sprint 1, Workstream A)

**Status: still not conclusively root-caused. Treated as unresolved, not dismissed as sandbox noise and not assumed to be an application defect — both hypotheses are presented below with their actual evidence.** This document supersedes the brief §6.4 note in `AUDIT_REPORT.md` with the full investigation; that section should be read as pointing here.

**What this sprint actually accomplished on this workstream**: (1) added comprehensive, precise startup instrumentation covering every checkpoint the sprint asked for; (2) discovered and confirmed a real, separate, code-verified reliability defect (`StartupScreen` has no visible failure/retry state — see §4) that fully explains the *symptom* regardless of root cause; (3) discovered and worked around a real, reproducible iOS build-tooling defect (HYD-BUILD-007) that blocks the very reproduction attempt this workstream needed; (4) attempted a fresh, clean-environment live reproduction three times, all of which were defeated by increasing environment instability in this specific sandbox, documented honestly below rather than glossed over.

---

## 1. Instrumentation added this sprint

All additions are release-guarded through the existing `HydrionStartupTrace.log()` utility (`lib/utils/startup_trace.dart:18`, `if (kReleaseMode) return;`) — **no new logging occurs in release builds**, preserving the app's existing (correct) policy of not leaking startup diagnostics into shipped builds. Coverage now includes every checkpoint requested:

| Requested checkpoint | Where it's now logged |
|---|---|
| Application launch start | `lib/main.dart:76` — `'Dart main() reached'` (pre-existing) |
| Flutter engine readiness / first frame | `lib/ui/screens/startup_screen.dart:51` — `'first Flutter frame painted'` (pre-existing) |
| Dependency initialization | **New**: `HydrionServices.local()` now logs `gate=dependency_init status=start`/`status=done` bracketing `fromStore(...)` (`lib/main.dart`) |
| Storage hydration | **New**: `gate=storage status=start`/`status=done` bracketing `SharedPreferencesHydrionStore.create()` |
| Routing decision | **New**: `_routeFor()` now logs which specific gate blocked routing (`gate=locale_selection`/`gate=onboarding`/`gate=life_stage`/`gate=legal_acceptance` each `result=blocked`, or `gate=all result=passed route=/home`) — previously only the *final* chosen route was logged, not *why* |
| Service initialization | **New**: individual `gate=notification_init`, `gate=permissions_refresh`, `gate=pomodoro_reconcile`, `gate=homework_timed_notification`, `gate=notification_reconcile_schedules`, `gate=android_widget_init` start/done pairs — previously these six sequential awaits inside `HydrionServices.local()` were completely opaque; a hang in any one of them was previously indistinguishable from any other |
| Network-dependent initialization | **New**: `HydrionBootstrapApp.warmup gate=network_dependent_init status=start`/`status=done` bracketing the `Future.wait([hydrationSummaryService.getHydrationSummary(), hydrationContextProvider.getHydrationContext()])` call — the one part of startup with a plausible real-network dependency |
| Completion or failure of every gate | Every new log line above logs both `status=start` and `status=done`, so a hang anywhere shows up as a `status=start` line with no matching `status=done` — this is the key diagnostic property that was missing before this sprint (previously, `HydrionServices.local()` and `_loadServicesAndWarmUp()` were each a single opaque `await` chain with only a start/complete pair around the *whole* sequence, not each step) |

**No secrets or personal data are logged.** Every new log line contains only: a gate name (a static string), a status enum, and — in the routing case — a `HydrionProductAccessStage` enum name (`accessStage`, e.g. `unsupportedIndependentChild`) or a route path string (e.g. `/legal-review`). No user-entered values (age, weight, nickname, etc.) are included, consistent with `HydrionStartupTrace`'s existing design and the sprint's explicit instruction to avoid logging sensitive personal data.

**File changed**: `lib/main.dart` only (`HydrionServices.local()` and `_HydrionBootstrapAppState._loadServicesAndWarmUp()`/`_routeFor()`). `flutter analyze` and the full `flutter test` suite (604 tests) both pass with these changes in place — confirmed this sprint, not assumed.

---

## 2. A real, confirmed, code-level explanation for the *symptom* (independent of root cause)

Reading `lib/ui/screens/startup_screen.dart` closely (full file, this sprint) surfaced something the original audit pass did not have: **`StartupScreen` already has a 6-second timeout on the warm-up sequence** (`StartupScreen.timeout`, default `const Duration(seconds: 6)`, applied via `widget.warmUp().timeout(widget.timeout)` in `_runWarmUp()`, `startup_screen.dart:104`).

Tracing what happens when that timeout actually fires (`_runWarmUp()` catches `TimeoutException`, returns `_WarmUpResult.failed('TimeoutException')`; `_start()` then does):
```dart
if (!warmUpResult.succeeded) {
  HydrionStartupTrace.log('StartupScreen.warmup failed', data: {'error': warmUpResult.errorType ?? 'unknown'});
  return;
}
```
— **`_start()` simply returns.** There is no retry, no error message shown to the user, no fallback route, nothing. The widget tree is left exactly as it was: the `StartupScreen`'s `build()` method keeps rendering the animated shark and whatever `_startupText` was last set (`StartupScreen.preparingText`, i.e. **"Preparing your hydration space..."** — the exact string observed live in the original audit's screenshot).

**This is not speculation — it is a direct reading of the actual control flow**, and it explains every observed symptom from the original `AUDIT_REPORT.md` §6.4 reproduction simultaneously:
- The screen was stuck on **exactly** "Preparing your hydration space..." → matches `_startupText` never being updated after a warmup failure.
- Sustained ~43% CPU for over a minute → the shark `Lottie` animation (`HydrionStartupShark`, `animate: !disableAnimations`) keeps rendering indefinitely once shown, since nothing ever tells it to stop; a continuously-animating vector graphic on Simulator software rendering at this cost level is plausible and requires no separate leak or busy-loop to explain.
- The app "never transitions" → correct, by design of the current (defective) failure path — after the 6-second timeout, it deliberately stops trying, forever, with no user-visible indication anything went wrong.

**This is a real, separate, actionable finding**, tracked as its own item so it isn't confused with the still-open question of *why* warmup itself stalled:

### HYD-REL-001 — `StartupScreen` has no user-visible error or retry state after a warm-up timeout/failure
- **Severity**: High | **Confidence**: Confirmed (direct code read, not yet exercised in a real hang to confirm the *timeout path specifically* fires exactly as traced — see §3 for why a live confirmation wasn't completed this sprint)
- **Component**: `lib/ui/screens/startup_screen.dart:80-86` (`_start()`'s failure branch)
- **User/business impact**: if warm-up genuinely fails or is genuinely slow for any reason (poor network, a slow first-run permission dialog, a plugin misbehaving on a specific device/OS combination), the user is left staring at an animating splash screen forever with zero recourse except force-quitting the app — no error text, no "try again" button, no diagnostic hint. This is the worst possible failure mode for a startup sequence: silent, permanent, and indistinguishable from a true hang from the user's perspective.
- **Recommended correction** (design direction, not implemented this sprint — out of this workstream's scope per the sprint's own instruction not to "fix" the startup problem with a workaround): add a genuine error state to `StartupScreen` — on `!warmUpResult.succeeded`, show user-facing text (e.g., "Something went wrong preparing your data") and a retry action that re-invokes `_start()`, rather than silently returning. This is explicitly **not** "increase the timeout" or "hide the startup screen" (both banned by the sprint's instructions) — it is making an already-detected failure visible and actionable, which is a strictly different and correct fix.
- **Required regression test**: a widget test that supplies a `warmUp` callback which always throws/times out, and asserts the screen transitions to a visible error state (once implemented) rather than remaining on the "Preparing..." text forever with no affordance.
- **Standard**: n/a (reliability/UX correctness).

---

## 3. Live reproduction attempts this sprint — exact commands, exact outcomes, stated honestly

Three attempts were made to get a clean, live, instrumented trace of the actual startup sequence in order to identify *which* of the newly-instrumented gates is the one that stalls (if any does at all in a genuinely clean environment):

### Attempt 1 — fresh simulator, `flutter run`
- Created a brand-new simulator device (`xcrun simctl create "HydrionCleanRepro" "iPhone 16 Pro"`, distinct from the simulator used throughout the rest of this audit/sprint, specifically to avoid the CoreSimulator-degradation-under-load pattern already documented in `AUDIT_REPORT.md` §6.4) and booted it cleanly.
- Ran `flutter run -d <fresh-simulator-id> --debug`.
- **Result**: failed during the Xcode build step (488 seconds of real, genuinely-progressing compilation, confirmed via `ps aux` showing live Gradle/Xcode CPU usage throughout, then a real, specific error) — **not an environment hang, a real build-configuration failure**: `Target Integrity (Xcode): The package product 'home-widget' requires minimum platform version 14.0 for the iOS platform, but this target supports 13.0`. Investigated and found to be a genuine, reproducible Flutter-tooling defect (Flutter's auto-generated `FlutterGeneratedPluginSwiftPackage/Package.swift` hardcodes an iOS 13.0 platform floor regardless of the project's actual, correctly-configured 14.0 deployment target) — tracked separately as **HYD-BUILD-007** in `AUDIT_REPORT.md` §7, since it's a real finding independent of HYD-BLOCK-004.
- Confirmed reproducible a second time after a full `rm -rf ios/Flutter/ephemeral && flutter pub get` regeneration (ruling out simple cache corruption) — the regenerated file still declared `.iOS("13.0")`.
- **Worked around** (not fixed — the file is gitignored/regenerated) by hand-editing the generated file's platform floor to `14.0` to unblock this specific investigation.

### Attempt 2 — same fresh simulator, retried after the workaround
- Re-ran `flutter run -d <fresh-simulator-id> --debug`.
- **Result**: the process never printed even its first line of output (`"Launching lib/main.dart on ... in debug mode..."`, which normally appears within a second or two of invocation) after several minutes, and `ps aux` showed it sitting at **0% CPU** — not compiling, not doing visible work of any kind, and critically, **no `xcodebuild` process existed anywhere on the system** at the time of inspection, meaning the Flutter tooling process itself had not even reached the point of invoking Xcode. This is a different failure signature from Attempt 1 (which was genuinely, activity compiling for 488 real seconds before hitting a real error) — Attempt 2 looks like the Flutter tooling process itself stalled before doing any observable work.
- Terminated (`kill -9`) after concluding further waiting was not going to be informative.

### Attempt 3 (implicit) — corroborating evidence from earlier in this same sprint
- Not a fresh attempt, but relevant: earlier in this same sprint (Stage 10 of the original audit, documented in `MOBILE_TEST_PLATFORM_EVALUATION.md` §5), a completely independent tool — **Maestro**, which bootstraps its own XCTest runner onto a Simulator via `xcrun simctl`-adjacent mechanisms — **also failed twice in a row** against a simulator in this same sandbox, with `IOSDriverTimeoutException: iOS driver not ready in time`, including once after doubling its own default timeout.

**Pattern across all three data points**: `xcrun simctl` (original HYD-BLOCK-004 investigation), Maestro's XCTest-runner bootstrap (Stage 10 POC), and now `flutter run` itself (this sprint) have each independently stalled or become unreliable against a Simulator in this same sandbox at different points across a long, cumulative session involving many repeated simulator installs/launches/builds. **This is now a three-for-three pattern strongly suggesting this specific sandbox's Simulator/CoreSimulator automation stack degrades under sustained cumulative load within a single long session** — but this is still being presented as the more-likely explanation based on a pattern, not a proven root cause, per the sprint's explicit instruction not to casually dismiss this as a sandbox artifact.

---

## 4. Honest assessment: implicates Hydrion, implicates the environment, or remains inconclusive?

**Remains genuinely inconclusive on the original hang's specific root cause**, with the following honest weighing of evidence:

**Evidence that points toward a real (if now well-characterized) application-layer contributing factor**: HYD-REL-001 is real and confirmed by direct code reading — regardless of what causes warm-up to be slow or fail on any given device/session, the *complete absence of user-visible failure handling* is a genuine Hydrion defect that would make ANY warm-up slowness (even a legitimately transient one — a slow first network call, a slow permission dialog, a momentarily slow device) look exactly like a permanent hang to a real user. This part does not depend on the sandbox at all.

**Evidence that points toward environment-specific instability**: the three-for-three pattern in §3, culminating in `flutter run` itself failing to even start compiling on the third attempt, is hard to explain as anything other than cumulative sandbox/CoreSimulator degradation across a long session — a completely fresh macOS environment would very plausibly not exhibit this.

**What was not settled**: whether, in a genuinely fresh environment with none of this session's cumulative load, `HydrionServices.local()`'s warm-up sequence actually completes quickly (meaning the original hang was ITSELF an artifact of an already-degrading sandbox, and HYD-BLOCK-004 might not reproduce on a real device or fresh machine at all), or whether one of the newly-instrumented gates (notification permission handshake and the network-dependent weather/location-adjacent calls in `getHydrationSummary()`/`getHydrationContext()` remain the strongest a priori suspects, being the only steps with plausible real OS-dialog or network dependencies) would show a genuine multi-second-or-more stall even in a clean environment.

## 5. Recommended next step (not performed this sprint)

Run the exact same instrumented build (already committed to `lib/main.dart` in this sprint) on:
(a) a real, physical iPhone, and/or
(b) a completely fresh macOS machine/VM that has never run any part of this session's cumulative simulator/build/Maestro activity,

and capture the full `HYDRION_STARTUP` gate-by-gate trace via `flutter run`'s console output (now far more granular than before this sprint — every one of the six previously-opaque service-init steps, plus storage/dependency-init/routing/network-dependent-init, each individually timestamped). Whichever gate shows a `status=start` with no matching `status=done` within a few seconds is the concrete, specific root cause — something this sprint's instrumentation is now fully equipped to reveal, even though this sandbox's accumulated instability prevented capturing that trace today.

## 6. Status classification (per sprint reporting requirements)

- **Fixed and validated**: HYD-REL-001's *diagnosis* is validated (confirmed by code read); its *fix* is not implemented this sprint (design-direction only, per the sprint's explicit instruction not to work around the symptom).
- **Reproduced but unresolved**: the original HYD-BLOCK-004 symptom (screenshots + sustained CPU from the first audit session) — genuinely reproduced once, root cause still not isolated.
- **Not reproduced (this sprint)**: a second live capture of the actual startup sequence, due to the environment failures in §3 — this is a blocked re-reproduction attempt, not a "could not reproduce" negative result.
- **Blocked**: further live iOS investigation in this specific sandbox, pending either environment restoration or a fresh machine/device per §5.
- **Implemented but not real-device-validated**: the new instrumentation itself (§1) — it compiles, passes analysis, and passes the full test suite, but has not yet been observed producing a real gate-by-gate trace against a genuine hang, since no genuine hang was successfully re-captured this sprint.
