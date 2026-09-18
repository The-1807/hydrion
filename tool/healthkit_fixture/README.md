# Synthetic HealthKit simulator fixture

This is a separate UIKit application and XCUITest target. It compiles the real
`ios/Runner/HealthKitHost.swift`, invokes it through Flutter's standard method
codec, and uses the simulator's actual HealthKit store. Only the Dart transport
is replaced; the store, anchored queries and native mapper are real.

The fixture has bundle ID `com.the1807.hydrion.healthkitfixture`. Its generated
project supports only `iphonesimulator`, and `FixtureApp.swift` rejects a device
build at compile time. Runner has no reference or dependency on this fixture.
The write usage description and HealthKit write requests belong only to this
separate application. Production remains read-only.

Use a fresh simulator containing no personal data. This test app does not write
or inspect a production Hydrion database, Keychain item, or app group.

## Build and run

Generate the project with the Ruby/xcodeproj installation already supplied by
CocoaPods. On the validated Mac:

```sh
GEM_HOME=/usr/local/Cellar/cocoapods/1.17.0/libexec ruby tool/healthkit_fixture/generate_project.rb /usr/local/share/flutter
xcodebuild build-for-testing \
  -project build/healthkit-fixture/HealthKitFixture.xcodeproj \
  -scheme HealthKitFixture -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -jobs 1 \
  -derivedDataPath build/healthkit-fixture/DerivedData \
  COMPILER_INDEX_STORE_ENABLE=NO
```

Run the generated `.xctestrun` with `xcodebuild test-without-building`, selecting
the fresh simulator by its exact UDID and disabling parallel testing. The UI
test taps the fixture's Run button, enables its synthetic read/write categories,
and waits for the app's result. The app never requests access before that tap.

## Dataset and assertions

The test writes a workout, active energy, distance, 501 step intervals, two
identical overlapping step intervals, and one step record outside the 30-day
window. It reads all four categories through the production native host,
checks 250-object pagination, checks application provenance and missing optional
device metadata, replaces an energy sample using a HealthKit synchronization
identifier/version, deletes a distance sample, and performs ten incremental
query cycles requiring zero repeated records.

The duplicate samples deliberately remain separate native source records.
Canonical deduplication, transaction boundaries and cross-metric retry are
covered by the shared coordinator tests; this fixture does not reimplement that
coordinator or claim to certify it from native query counts.

## Cleanup and evidence

Each sample has a unique per-run `hydrion.fixture.run` metadata marker. The app
attempts to delete exactly that run's records on both success and failure.
`Documents/result.json` contains only synthetic counts, categorical outcomes,
query timings and the test app's bundle ID. It contains no UUIDs, anchors, health
values, database keys or personal records. Extract only this file for evidence.

If the app is force-killed before cleanup, retain the isolated simulator for
inspection or discard that test simulator manually; do not run this fixture in
a simulator containing personal data. No cleanup targets other applications'
records. Simulator timings are not physical-iPhone, battery or wearable evidence.
