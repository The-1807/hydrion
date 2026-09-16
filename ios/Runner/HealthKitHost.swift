import Flutter
import HealthKit
import UIKit

final class HealthKitHost {
  private static let channelName = "hydrion/health_kit"
  private static let schemaVersion = 1
  private static let pageSize = 250
  private static let supportedMetrics = Set(["workout", "activeEnergy", "steps", "distance"])

  private let store = HKHealthStore()
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "availability":
      result(["available": HKHealthStore.isHealthDataAvailable()])
    case "authorizationState":
      authorizationState(call, result: result)
    case "requestPermissions":
      requestPermissions(call, result: result)
    case "readAnchored":
      readAnchored(call, result: result)
    case "openSettings":
      openSettings(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func authorizationState(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable(), let types = readTypes(call) else {
      result(flutterError("invalid_request"))
      return
    }
    store.getRequestStatusForAuthorization(toShare: [], read: types) { status, error in
      self.finish(result) {
        if error != nil { return self.flutterError("authorization_status_failed") }
        return ["requestStatus": self.requestStatus(status)]
      }
    }
  }

  private func requestPermissions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable(), let types = readTypes(call) else {
      result(flutterError("invalid_request"))
      return
    }
    store.requestAuthorization(toShare: [], read: types) { success, error in
      self.finish(result) {
        guard success, error == nil else {
          return self.flutterError("permission_request_failed")
        }
        return ["requestStatus": "unnecessary"]
      }
    }
  }

  private func readAnchored(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable(),
          let arguments = call.arguments as? [String: Any],
          let metric = arguments["metric"] as? String,
          Self.supportedMetrics.contains(metric),
          let type = sampleType(metric),
          let historyStartText = arguments["historyStart"] as? String,
          let historyStart = Self.isoDate(historyStartText),
          let historyEndText = arguments["historyEnd"] as? String,
          let historyEnd = Self.isoDate(historyEndText),
          historyEnd >= historyStart else {
      result(flutterError("invalid_request"))
      return
    }
    let anchor: HKQueryAnchor?
    do {
      anchor = try decodeAnchor(arguments["anchor"] as? String)
    } catch {
      result(flutterError("invalid_anchor"))
      return
    }
    let predicate = HKQuery.predicateForSamples(
      withStart: historyStart,
      end: historyEnd,
      options: .strictStartDate
    )
    let query = HKAnchoredObjectQuery(
      type: type,
      predicate: predicate,
      anchor: anchor,
      limit: Self.pageSize
    ) { _, samples, deleted, nextAnchor, error in
      self.finish(result) {
        guard error == nil, let nextAnchor = nextAnchor else {
          return self.flutterError("health_kit_read_failed")
        }
        do {
          let records = try (samples ?? []).map { try self.mapSample($0, metric: metric) }
          let deletions = (deleted ?? []).map {
            [
              "schemaVersion": Self.schemaVersion,
              "recordId": $0.uuid.uuidString,
              "metric": metric,
              "deleted": true,
            ] as [String: Any]
          }
          return [
            "schemaVersion": Self.schemaVersion,
            "records": records + deletions,
            "anchor": try self.encodeAnchor(nextAnchor),
            "hasMore": records.count + deletions.count >= Self.pageSize,
          ]
        } catch {
          return self.flutterError("health_kit_mapping_failed")
        }
      }
    }
    store.execute(query)
  }

  private func openSettings(result: @escaping FlutterResult) {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      result(flutterError("settings_unavailable"))
      return
    }
    UIApplication.shared.open(url, options: [:]) { opened in
      result(opened ? nil : self.flutterError("settings_unavailable"))
    }
  }

  private func readTypes(_ call: FlutterMethodCall) -> Set<HKObjectType>? {
    guard let arguments = call.arguments as? [String: Any],
          let metrics = arguments["metrics"] as? [String],
          !metrics.isEmpty,
          Set(metrics).isSubset(of: Self.supportedMetrics) else { return nil }
    let types = metrics.compactMap(sampleType)
    return types.count == metrics.count ? Set(types) : nil
  }

  private func sampleType(_ metric: String) -> HKSampleType? {
    switch metric {
    case "workout": return HKObjectType.workoutType()
    case "activeEnergy": return HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
    case "steps": return HKObjectType.quantityType(forIdentifier: .stepCount)
    case "distance": return HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
    default: return nil
    }
  }

  private func mapSample(_ sample: HKSample, metric: String) throws -> [String: Any] {
    let value: Double
    let unit: String
    var category: String?
    switch metric {
    case "workout":
      guard let workout = sample as? HKWorkout else { throw MappingError.typeMismatch }
      value = workout.duration / 60.0
      unit = "minute"
      category = String(workout.workoutActivityType.rawValue)
    case "activeEnergy":
      guard let quantity = sample as? HKQuantitySample else { throw MappingError.typeMismatch }
      value = quantity.quantity.doubleValue(for: .kilocalorie())
      unit = "kilocalorie"
    case "steps":
      guard let quantity = sample as? HKQuantitySample else { throw MappingError.typeMismatch }
      value = quantity.quantity.doubleValue(for: .count())
      unit = "count"
    case "distance":
      guard let quantity = sample as? HKQuantitySample else { throw MappingError.typeMismatch }
      value = quantity.quantity.doubleValue(for: .meter())
      unit = "meter"
    default:
      throw MappingError.typeMismatch
    }
    guard value.isFinite, value >= 0 else { throw MappingError.invalidValue }
    let source = sample.sourceRevision.source
    let metadata = sample.metadata
    let wasEnteredByUser = metadata?[HKMetadataKeyWasUserEntered] as? Bool
    let synchronizationVersion = metadata?[HKMetadataKeySyncVersion] as? NSNumber
    let sourceRevision = Self.sourceRevision(sample.sourceRevision)
    var record: [String: Any] = [
      "schemaVersion": Self.schemaVersion,
      "recordId": sample.uuid.uuidString,
      "metric": metric,
      "value": value,
      "originalUnit": unit,
      "startTime": Self.isoString(sample.startDate),
      "endTime": Self.isoString(sample.endDate),
      "synchronizationVersion": synchronizationVersion.map {
        "\(sample.uuid.uuidString):\($0.intValue)"
      } ?? sample.uuid.uuidString,
      "sourceApplicationId": source.bundleIdentifier,
      "sourceApplicationName": source.name,
      "recordingMethod": wasEnteredByUser == true ? "manual" : "unknown",
      "deleted": false,
    ]
    if !sourceRevision.isEmpty { record["sourceRevision"] = sourceRevision }
    if let category = category { record["category"] = category }
    if let timeZone = metadata?[HKMetadataKeyTimeZone] as? String {
      record["sourceTimeZone"] = timeZone
      if let zone = TimeZone(identifier: timeZone) {
        record["startOffsetSeconds"] = zone.secondsFromGMT(for: sample.startDate)
      }
    }
    if let device = sample.device {
      if let identifier = device.localIdentifier { record["physicalDeviceId"] = identifier }
      if let manufacturer = device.manufacturer { record["deviceManufacturer"] = manufacturer }
      if let model = device.model { record["deviceModel"] = model }
      if let hardware = device.hardwareVersion { record["deviceHardwareVersion"] = hardware }
      if let software = device.softwareVersion { record["deviceSoftwareVersion"] = software }
    }
    return record
  }

  private static func sourceRevision(_ revision: HKSourceRevision) -> String {
    let operatingSystem = revision.operatingSystemVersion
    let system = "\(operatingSystem.majorVersion).\(operatingSystem.minorVersion).\(operatingSystem.patchVersion)"
    return [revision.version, revision.productType, system]
      .compactMap { value in
        guard let value = value, !value.isEmpty else { return nil }
        return value
      }
      .joined(separator: "|")
  }

  private func encodeAnchor(_ anchor: HKQueryAnchor) throws -> String {
    try NSKeyedArchiver.archivedData(
      withRootObject: anchor,
      requiringSecureCoding: true
    ).base64EncodedString()
  }

  private func decodeAnchor(_ encoded: String?) throws -> HKQueryAnchor? {
    guard let encoded = encoded else { return nil }
    guard let data = Data(base64Encoded: encoded),
          let anchor = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: HKQueryAnchor.self,
            from: data
          ) else { throw MappingError.invalidAnchor }
    return anchor
  }

  private func requestStatus(_ status: HKAuthorizationRequestStatus) -> String {
    switch status {
    case .shouldRequest: return "shouldRequest"
    case .unnecessary: return "unnecessary"
    default: return "unknown"
    }
  }

  private func finish(_ result: @escaping FlutterResult, value: @escaping () -> Any) {
    DispatchQueue.main.async { result(value()) }
  }

  private func flutterError(_ code: String) -> FlutterError {
    FlutterError(code: code, message: "Apple Health could not complete the request.", details: nil)
  }

  private static func isoDate(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
  }

  private static func isoString(_ value: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: value)
  }

  private enum MappingError: Error { case typeMismatch, invalidValue, invalidAnchor }
}
