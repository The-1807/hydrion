import Combine
import WatchConnectivity

final class HydrationConnectivityReceiver: NSObject, ObservableObject {
  @Published private(set) var snapshot: HydrationSnapshot?
  @Published private(set) var isReachable = false
  @Published private(set) var hasError = false

  override init() {
    super.init()
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  private func apply(_ context: [String: Any]) {
    // Empty context is the normal first-launch state, not malformed data.
    guard !context.isEmpty else { return }
    let next = HydrationSnapshot.decode(context)
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      guard let next = next else {
        self.hasError = true
        return
      }
      if next.replaces(self.snapshot) {
        self.snapshot = next
      }
      self.hasError = false
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
      if error != nil || activationState != .activated {
        self?.hasError = true
      }
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
