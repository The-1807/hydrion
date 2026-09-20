import Foundation
import CoreFoundation

/// The last hydration snapshot Runner pushed via `WCSession.updateApplicationContext`,
/// or nil until the first one arrives. This receiver never sends anything back
/// to the phone and never touches HealthKit: it only displays what Runner
/// already computed from the user's local hydration log.
struct HydrationSnapshot: Equatable {
  let todayMl: Int
  let goalMl: Int
  let progressPercent: Int
  let status: String
  let updatedAt: Date

  static func decode(_ context: [String: Any]) -> HydrationSnapshot? {
    guard context["schemaVersion"] as? Int == 1,
          let today = context["todayMl"] as? Int, (0...1_000_000).contains(today),
          let goal = context["goalMl"] as? Int, (0...1_000_000).contains(goal),
          let percent = context["progressPercent"] as? Int, (0...999).contains(percent),
          let status = context["status"] as? String, !status.isEmpty, status.utf8.count <= 200,
          let timestampNumber = context["updatedAtEpochMs"] as? NSNumber,
          CFGetTypeID(timestampNumber) != CFBooleanGetTypeID(),
          // watchOS arm64_32 has a 32-bit Int; epoch milliseconds require Int64.
          let timestamp = Int64(exactly: timestampNumber.doubleValue), timestamp > 0,
          timestamp <= 253_402_300_799_000 else { return nil }
    return HydrationSnapshot(todayMl: today, goalMl: goal, progressPercent: percent,
                             status: status, updatedAt: Date(timeIntervalSince1970: Double(timestamp) / 1000))
  }

  func replaces(_ previous: HydrationSnapshot?) -> Bool {
    guard let previous = previous else { return true }
    return updatedAt > previous.updatedAt
  }

  var progressFraction: Double {
    goalMl <= 0 ? 0 : min(1, max(0, Double(todayMl) / Double(goalMl)))
  }
}
