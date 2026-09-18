#if !targetEnvironment(simulator)
#error("Synthetic HealthKit fixture is simulator-only")
#endif
import Flutter
import HealthKit
import UIKit

// This app is generated as a separate target by generate_project.rb. It is
// never a Runner source, dependency, scheme action or production build phase.
@main
final class FixtureApp: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = FixtureViewController()
    window.makeKeyAndVisible()
    self.window = window
    return true
  }
}

@MainActor
final class FixtureViewController: UIViewController {
  private let status = UILabel()
  private let button = UIButton(type: .system)
  private let store = HKHealthStore()
  private let messenger = FixtureMessenger()
  private var host: HealthKitHost!
  private let metrics = ["workout", "activeEnergy", "steps", "distance"]
  private var report: [String: Any] = [:]
  private let marker = UUID().uuidString

  override func viewDidLoad() {
    super.viewDidLoad()
    host = HealthKitHost(messenger: messenger)
    view.backgroundColor = .systemBackground
    button.setTitle("Run synthetic fixture", for: .normal)
    button.accessibilityIdentifier = "fixture-run"
    button.addTarget(self, action: #selector(runFixture), for: .touchUpInside)
    status.text = "Ready — synthetic data only"
    status.accessibilityIdentifier = "fixture-status"
    status.numberOfLines = 0
    let stack = UIStackView(arrangedSubviews: [button, status])
    stack.axis = .vertical
    stack.spacing = 24
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
      stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  private func type(_ metric: String) -> HKSampleType {
    switch metric {
    case "workout": return HKObjectType.workoutType()
    case "activeEnergy": return HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    case "steps": return HKQuantityType.quantityType(forIdentifier: .stepCount)!
    default: return HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    }
  }

  @objc private func runFixture() {
    button.isEnabled = false
    status.text = "Running"
    Task {
      do {
        try await run()
        try await cleanup()
        report["status"] = "passed"
        saveReport()
        status.text = "Passed"
      } catch {
        try? await cleanup()
        report["status"] = "failed"
        // Keep provider error descriptions and identifiers out of logs/files.
        report["failure"] = (error as? FixtureFailure)?.step ?? "native_operation_failed"
        saveReport()
        // Diagnostic-only: console output is not part of the persisted report.
        NSLog("hydrion.fixture diagnostic: %@", String(describing: error))
        status.text = "Failed: \(report["failure"]!)"
      }
    }
  }

  private func run() async throws {
    try require(HKHealthStore.isHealthDataAvailable(), "availability")
    let types = Set(metrics.map(type))
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      store.requestAuthorization(toShare: types, read: Set(types)) { success, error in
        if success { continuation.resume() }
        else { continuation.resume(throwing: error ?? FixtureFailure("authorization")) }
      }
    }
    let now = Date()
    let base = now.addingTimeInterval(-3600)
    let windowStart = now.addingTimeInterval(-30 * 86400)
    let windowEnd = now.addingTimeInterval(1)
    let unit: [String: HKUnit] = ["steps": .count(), "activeEnergy": .kilocalorie(), "distance": .meter()]
    func quantity(_ metric: String, _ value: Double, _ date: Date,
                  extra: [String: Any] = [:]) -> HKQuantitySample {
      var metadata: [String: Any] = ["hydrion.fixture.run": marker, HKMetadataKeyWasUserEntered: true]
      extra.forEach { metadata[$0] = $1 }
      return HKQuantitySample(type: type(metric) as! HKQuantityType,
                              quantity: HKQuantity(unit: unit[metric]!, doubleValue: value),
                              start: date, end: date.addingTimeInterval(30), metadata: metadata)
    }
    let workout = HKWorkout(activityType: .walking, start: base, end: base.addingTimeInterval(1800),
                            workoutEvents: nil, totalEnergyBurned: nil, totalDistance: nil,
                            device: nil, metadata: ["hydrion.fixture.run": marker])
    let energy = quantity("activeEnergy", 200, base,
                          extra: [HKMetadataKeySyncIdentifier: marker, HKMetadataKeySyncVersion: 1])
    let distance = quantity("distance", 1500, base)
    let steps = (0..<501).map { quantity("steps", Double($0 + 1), base.addingTimeInterval(Double($0))) }
    let duplicates = [quantity("steps", 77, base), quantity("steps", 77, base)]
    let outside = quantity("steps", 999, now.addingTimeInterval(-32 * 86400))
    try await save([workout, energy, distance, outside] + steps + duplicates)
    var anchors: [String: String] = [:]
    var imported: [String: [[String: Any]]] = [:]
    let initialStart = Date()
    for metric in metrics {
      let result = try await readAll(metric, anchor: nil, start: windowStart, end: windowEnd)
      anchors[metric] = result.anchor
      imported[metric] = result.records
      report["\(metric)InitialCount"] = result.records.count
      report["\(metric)InitialPages"] = result.pages
    }
    report["initialQueryMilliseconds"] = Date().timeIntervalSince(initialStart) * 1000
    try require(imported["workout"]!.count == 1, "workout_import")
    try require(imported["activeEnergy"]!.count == 1, "energy_import")
    try require(imported["distance"]!.count == 1, "distance_import")
    try require(imported["steps"]!.count == 503, "pagination_or_history_boundary")
    try require(!imported["steps"]!.contains { $0["recordId"] as? String == outside.uuid.uuidString }, "history_boundary")
    try require(imported["steps"]!.allSatisfy { $0["sourceApplicationId"] as? String == Bundle.main.bundleIdentifier }, "source_provenance")
    try require(imported["steps"]!.allSatisfy { $0["deviceModel"] == nil }, "optional_device")
    let corrected = quantity("activeEnergy", 321.5, base,
                             extra: [HKMetadataKeySyncIdentifier: marker, HKMetadataKeySyncVersion: 2])
    try await save([corrected])
    let correction = try await readAll("activeEnergy", anchor: anchors["activeEnergy"], start: windowStart, end: windowEnd)
    anchors["activeEnergy"] = correction.anchor
    try require(correction.records.contains { $0["value"] as? Double == 321.5 }, "correction_insert")
    try require(correction.records.contains { $0["recordId"] as? String == energy.uuid.uuidString && $0["deleted"] as? Bool == true }, "correction_tombstone")
    report["correctionReconciled"] = true
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      store.delete(distance) { success, error in
        if success { continuation.resume() }
        else { continuation.resume(throwing: error ?? FixtureFailure("delete")) }
      }
    }
    let deletion = try await readAll("distance", anchor: anchors["distance"], start: windowStart, end: windowEnd)
    anchors["distance"] = deletion.anchor
    try require(deletion.records.contains { $0["recordId"] as? String == distance.uuid.uuidString && $0["deleted"] as? Bool == true }, "deletion_tombstone")
    report["deletionReconciled"] = true
    var repeatedMilliseconds: [Double] = []
    for _ in 0..<10 {
      let started = Date()
      for metric in metrics {
        let repeated = try await readAll(metric, anchor: anchors[metric], start: windowStart, end: windowEnd)
        try require(repeated.records.isEmpty, "repeat_import")
        anchors[metric] = repeated.anchor
      }
      repeatedMilliseconds.append(Date().timeIntervalSince(started) * 1000)
    }
    report["repeatQueryMilliseconds"] = repeatedMilliseconds
    report["repeatCycles"] = 10
    report["repeatRecords"] = 0
    report["sourceApplication"] = Bundle.main.bundleIdentifier!
    report["physicalDevice"] = false
  }

  private func readAll(_ metric: String, anchor: String?, start: Date, end: Date) async throws
    -> (records: [[String: Any]], anchor: String, pages: Int) {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var cursor = anchor
    var records: [[String: Any]] = []
    for page in 1...100 {
      var arguments: [String: Any] = ["metric": metric, "historyStart": formatter.string(from: start), "historyEnd": formatter.string(from: end)]
      if let cursor = cursor { arguments["anchor"] = cursor }
      let response = try await messenger.invoke("readAnchored", arguments: arguments)
      guard let batch = response["records"] as? [[String: Any]], let next = response["anchor"] as? String else { throw FixtureFailure("response_schema") }
      try require(batch.count <= 250, "page_limit")
      records += batch
      cursor = next
      if response["hasMore"] as? Bool != true { return (records, next, page) }
    }
    throw FixtureFailure("page_ceiling")
  }

  private func save(_ objects: [HKObject]) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      store.save(objects) { success, error in
        if success { continuation.resume() }
        else { continuation.resume(throwing: error ?? FixtureFailure("save")) }
      }
    }
  }

  private func cleanup() async throws {
    for metric in metrics {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        store.deleteObjects(of: type(metric), predicate: HKQuery.predicateForObjects(withMetadataKey: "hydrion.fixture.run", allowedValues: [marker])) { success, _, error in
          if success { continuation.resume() }
          else { continuation.resume(throwing: error ?? FixtureFailure("cleanup")) }
        }
      }
    }
    report["syntheticHealthKitRecordsCleaned"] = true
  }

  private func saveReport() {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("result.json")
    if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
      try? data.write(to: url, options: .atomic)
    }
  }
  private func require(_ condition: Bool, _ step: String) throws {
    if !condition { throw FixtureFailure(step) }
  }
}

private struct FixtureFailure: Error {
  let step: String
  init(_ step: String) { self.step = step }
}

// Standard method-codec transport into the unchanged production host. HealthKit
// operations are real; this replaces only the Dart engine transport in this app.
private final class FixtureMessenger: NSObject, FlutterBinaryMessenger {
  private var handler: FlutterBinaryMessageHandler?
  func send(onChannel channel: String, message: Data?) {}
  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) { callback?(nil) }
  func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?) -> FlutterBinaryMessengerConnection {
    self.handler = handler
    return 1
  }
  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) { handler = nil }
  @MainActor func invoke(_ method: String, arguments: [String: Any]) async throws -> [String: Any] {
    try await withCheckedThrowingContinuation { continuation in
      let codec = FlutterStandardMethodCodec.sharedInstance()
      guard let handler = handler else { continuation.resume(throwing: FixtureFailure("channel_missing")); return }
      handler(codec.encode(FlutterMethodCall(methodName: method, arguments: arguments))) { data in
        guard let data = data, let result = codec.decodeEnvelope(data) as? [String: Any] else {
          continuation.resume(throwing: FixtureFailure("native_query_failed")); return
        }
        continuation.resume(returning: result)
      }
    }
  }
}
