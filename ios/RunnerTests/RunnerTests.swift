import Flutter
import HealthKit
import UIKit
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  private let start = Date(timeIntervalSince1970: 1_800_000_000)

  func testSecureAnchorRoundTripAndAbsentAnchor() throws {
    XCTAssertNil(try HealthKitHost.decodeAnchor(nil))
    XCTAssertNil(try HealthKitHost.decodeAnchor(NSNull()))
    let encoded = try HealthKitHost.encodeAnchor(HKQueryAnchor(fromValue: 42))
    let decoded = try XCTUnwrap(HealthKitHost.decodeAnchor(encoded))
    XCTAssertEqual(decoded, HKQueryAnchor(fromValue: 42))
  }

  func testMalformedAnchorsNeverBecomeInitialQueries() throws {
    let wrongClass = try NSKeyedArchiver.archivedData(
      withRootObject: NSString(string: "synthetic"), requiringSecureCoding: true
    ).base64EncodedString()
    let invalidAnchors: [Any] = [42, "", "not base64!", "AA==", wrongClass,
                                 String(repeating: "A", count: 16_385)]
    for invalid in invalidAnchors {
      XCTAssertThrowsError(try HealthKitHost.decodeAnchor(invalid))
    }
  }

  func testDatesAcceptDartPrecisionAndRejectMalformedOrOversizedValues() throws {
    let expected = try XCTUnwrap(HealthKitHost.isoDate("2027-01-15T08:00:00.123456Z"))
    XCTAssertEqual(expected.timeIntervalSince1970, 1_800_000_000.123, accuracy: 0.001)
    XCTAssertNotNil(HealthKitHost.isoDate("2027-01-15T08:00:00Z"))
    XCTAssertNotNil(HealthKitHost.isoDate("2027-01-15T09:00:00+01:00"))
    XCTAssertNil(HealthKitHost.isoDate("not-a-date"))
    XCTAssertNil(HealthKitHost.isoDate(String(repeating: "0", count: 65)))
  }

  func testQuantityMappingUsesCanonicalUnitsAndOptionalDeviceMetadata() throws {
    let fixtures: [(String, HKQuantityTypeIdentifier, HKUnit, Double, String)] = [
      ("steps", .stepCount, .count(), 2400, "count"),
      ("activeEnergy", .activeEnergyBurned, .kilocalorie(), 320.5, "kilocalorie"),
      ("distance", .distanceWalkingRunning, .meter(), 5000.25, "meter"),
    ]
    for (metric, identifier, unit, value, wireUnit) in fixtures {
      let sample = HKQuantitySample(
        type: try XCTUnwrap(HKQuantityType.quantityType(forIdentifier: identifier)),
        quantity: HKQuantity(unit: unit, doubleValue: value),
        start: start, end: start.addingTimeInterval(60),
        metadata: [HKMetadataKeyWasUserEntered: true, HKMetadataKeyTimeZone: "UTC"]
      )
      let record = try HealthKitHost.mapSample(sample, metric: metric)
      XCTAssertEqual(record["recordId"] as? String, sample.uuid.uuidString)
      XCTAssertEqual(record["metric"] as? String, metric)
      XCTAssertEqual(record["value"] as? Double, value)
      XCTAssertEqual(record["originalUnit"] as? String, wireUnit)
      XCTAssertEqual(record["recordingMethod"] as? String, "manual")
      XCTAssertEqual(record["startOffsetSeconds"] as? Int, 0)
      XCTAssertNil(record["physicalDeviceId"])
      XCTAssertNil(record["deviceModel"])
      XCTAssertEqual(record["deleted"] as? Bool, false)
    }
  }

  func testWorkoutMappingPreservesDurationCategoryAndDevice() throws {
    let device = HKDevice(
      name: "Synthetic fixture", manufacturer: "Hydrion tests", model: "Fixture",
      hardwareVersion: "1", firmwareVersion: nil, softwareVersion: "1",
      localIdentifier: "synthetic-device", udiDeviceIdentifier: nil
    )
    let workout = HKWorkout(
      activityType: .walking, start: start, end: start.addingTimeInterval(1800),
      workoutEvents: nil, totalEnergyBurned: nil, totalDistance: nil,
      device: device, metadata: [HKMetadataKeySyncIdentifier: "synthetic-workout", HKMetadataKeySyncVersion: 2]
    )
    let record = try HealthKitHost.mapSample(workout, metric: "workout")
    XCTAssertEqual(record["value"] as? Double, 30)
    XCTAssertEqual(record["originalUnit"] as? String, "minute")
    XCTAssertEqual(record["category"] as? String, String(HKWorkoutActivityType.walking.rawValue))
    XCTAssertEqual(record["deviceModel"] as? String, "Fixture")
    XCTAssertEqual(record["synchronizationVersion"] as? String, "\(workout.uuid.uuidString):2")
  }

  func testMetricMismatchIsRejectedBeforeIncompatibleUnitConversion() throws {
    let steps = HKQuantitySample(
      type: try XCTUnwrap(HKQuantityType.quantityType(forIdentifier: .stepCount)),
      quantity: HKQuantity(unit: .count(), doubleValue: 10),
      start: start, end: start.addingTimeInterval(60)
    )
    for metric in ["distance", "activeEnergy", "workout", "heartRate"] {
      XCTAssertThrowsError(try HealthKitHost.mapSample(steps, metric: metric))
    }
  }
}
