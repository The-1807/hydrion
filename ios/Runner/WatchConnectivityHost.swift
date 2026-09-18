import Flutter
import UIKit
import WatchConnectivity

/// One-way hydration snapshot delivery from Runner to the paired Hydrion
/// watch app, using WCSession's application context (last-value delivery,
/// no queuing, no acknowledgement). This is a passive receiver on the watch
/// side: Hydrion does not read anything back from the watch in this version,
/// and no HealthKit or sensor data is involved here.
final class WatchConnectivityHost: NSObject {
  private static let channelName = "hydrion/watch_connectivity"

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(["supported": WCSession.isSupported()])
    case "connectionState":
      result(connectionState())
    case "updateContext":
      updateContext(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func connectionState() -> [String: Any] {
    guard WCSession.isSupported() else {
      return ["supported": false, "paired": false, "watchAppInstalled": false, "reachable": false]
    }
    let session = WCSession.default
    return [
      "supported": true,
      "paired": session.isPaired,
      "watchAppInstalled": session.isWatchAppInstalled,
      "reachable": session.isReachable,
    ]
  }

  private func updateContext(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard WCSession.isSupported() else {
      result(["delivered": false, "reason": "unsupported"])
      return
    }
    guard let arguments = call.arguments as? [String: Any],
          let todayMl = arguments["todayMl"] as? Int,
          let goalMl = arguments["goalMl"] as? Int,
          let progressPercent = arguments["progressPercent"] as? Int,
          let status = arguments["status"] as? String,
          status.utf8.count <= 200
    else {
      result(FlutterError(code: "invalid_arguments", message: "Malformed hydration snapshot.", details: nil))
      return
    }
    let session = WCSession.default
    guard session.activationState == .activated else {
      result(["delivered": false, "reason": "not_activated"])
      return
    }
    do {
      try session.updateApplicationContext([
        "schemaVersion": 1,
        "todayMl": todayMl,
        "goalMl": goalMl,
        "progressPercent": progressPercent,
        "status": status,
        "updatedAtEpochMs": Int(Date().timeIntervalSince1970 * 1000),
      ])
      result(["delivered": true])
    } catch {
      // WCErrorCode cases (e.g. watch app not installed, session not paired)
      // are expected outcomes here, not failures Flutter needs to surface.
      result(["delivered": false, "reason": "send_failed"])
    }
  }
}

extension WatchConnectivityHost: WCSessionDelegate {
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
  }

  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }
}
