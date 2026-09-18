import Combine
import WatchConnectivity

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

  var progressFraction: Double {
    goalMl <= 0 ? 0 : min(1, max(0, Double(todayMl) / Double(goalMl)))
  }
}

final class HydrationConnectivityReceiver: NSObject, ObservableObject {
  @Published private(set) var snapshot: HydrationSnapshot?
  @Published private(set) var isReachable = false

  override init() {
    super.init()
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  private func apply(_ context: [String: Any]) {
    guard let todayMl = context["todayMl"] as? Int,
          let goalMl = context["goalMl"] as? Int,
          let progressPercent = context["progressPercent"] as? Int,
          let status = context["status"] as? String
    else { return }
    let updatedAtMs = context["updatedAtEpochMs"] as? Int
    let updatedAt = updatedAtMs.map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? Date()
    let next = HydrationSnapshot(
      todayMl: todayMl, goalMl: goalMl, progressPercent: progressPercent,
      status: status, updatedAt: updatedAt
    )
    DispatchQueue.main.async { [weak self] in
      self?.snapshot = next
    }
  }
}

extension HydrationConnectivityReceiver: WCSessionDelegate {
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    if activationState == .activated {
      apply(session.receivedApplicationContext)
    }
    DispatchQueue.main.async { [weak self] in
      self?.isReachable = session.isReachable
    }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    apply(applicationContext)
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async { [weak self] in
      self?.isReachable = session.isReachable
    }
  }
}
