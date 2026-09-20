# ADR-0007: Passive watchOS hydration companion

Status: implementation under simulator validation; no physical certification.

HydrionWatch is an intentional, single-target SwiftUI watchOS application,
minimum watchOS 10.0. Every configuration explicitly supports `watchos watchsimulator`
to override the project-level iOS-only Release/Profile setting. It has no separate WatchKit extension. Runner embeds its
product at `Runner.app/Watch/HydrionWatch.app` and declares a target dependency.
`WKCompanionAppBundleIdentifier` identifies `com.the1807.hydrion`; the watch
bundle is `com.the1807.hydrion.watchkitapp`. The app depends on its companion.
Runner and HydrionWatch have shared schemes. HydrionWidgets remains a distinct
WidgetKit extension in `PlugIns`, with its existing App Group.

The watch displays the phone's manual hydration total, goal, progress and
localized status. It has one display screen and no navigation or entry controls.
It does not query sensors, import workouts, own an HKWorkoutSession, or change a
hydration target. HealthKit belongs exclusively to Runner. No HealthKit or App
Group entitlement is added to the watch; WatchConnectivity needs neither.

Runner sends schema-version-1 application contexts. Apple retains only the
latest context; this is not an acknowledged message queue. A successful
`updateApplicationContext` means queued, never delivered. Native results
separate unsupported, activating, unpaired, missing watch app, send failure,
no data and queued states. The latest pending snapshot survives the activation
race in memory and is retried on activation/watch-state/reachability callbacks.
On relaunch Flutter regenerates it from the phone's hydration repository.

The receiver validates the schema, types, bounds, timestamp and UTF-8 status
size. Epoch milliseconds use bounded Int64 values because watch arm64_32 has a
32-bit Int. Duplicate and older timestamps do not replace current state. The system's
received application context restores the latest value after activation.
Malformed contexts and activation failures produce an explicit update-error
label while retaining the last valid snapshot. An unreachable phone is labeled
even when a snapshot remains visible. No-data renders instructions to open the
phone app. Manual phone tracking remains independent of watch availability.

`tool/apple_simulator.py` discovers available runtime/device pairs above the
project deployment targets, boots both, checks Flutter visibility and both Xcode
schemes, and passes the **iPhone** UDID to Flutter. CI may create a compatible
pair without destroying existing devices. Every subprocess has a timeout.
No source-controlled simulator identifier is used as a destination constant.

Validation evidence and outstanding runtime gates belong in
[the Apple sprint report](../validation/apple-wearable-sprint-2026-09-19.md).
Unit-level payload ordering tests do not certify WatchConnectivity transport,
physical background delivery, battery behavior, or Apple Watch provenance.

Apple documents the [single-target watchOS application model](https://developer.apple.com/documentation/watchos-apps/setting-up-a-watchos-project)
and [runtime installation](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components).
