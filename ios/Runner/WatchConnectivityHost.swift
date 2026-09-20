import Flutter
import UIKit
import WatchConnectivity

/// One-way hydration snapshot delivery from Runner to the paired Hydrion
/// watch app, using WCSession's application context (last-value delivery,
/// latest-value queuing, no acknowledgement). This is a passive receiver on the watch
/// side: Hydrion does not read anything back from the watch in this version,
/// and no HealthKit or sensor data is involved here.
final class WatchConnectivityHost: NSObject {
  private static let channelName = "hydrion/watch_connectivity"

  private let channel: FlutterMethodChannel
  // Confined to the main queue. Retain the latest value across activation races.
  private var pendingContext: [String: Any]?

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
          (0...1_000_000).contains(todayMl), (0...1_000_000).contains(goalMl),
          (0...999).contains(progressPercent), !status.isEmpty, status.utf8.count <= 200
    else {
      result(FlutterError(code: "invalid_arguments", message: "Malformed hydration snapshot.", details: nil))
      return
    }
    pendingContext = [
      "schemaVersion": 1,
      "todayMl": todayMl,
      "goalMl": goalMl,
      "progressPercent": progressPercent,
      "status": status,
      "updatedAtEpochMs": Int(Date().timeIntervalSince1970 * 1000),
    ]
    result(flushPendingContext())
  }

  private func flushPendingContext() -> [String: Any] {
    let session = WCSession.default
    guard session.activationState == .activated else {
      return ["delivered": false, "queued": false, "reason": "not_activated"]
    }
    guard session.isPaired else {
      return ["delivered": false, "queued": false, "reason": "not_paired"]
    }
    guard session.isWatchAppInstalled else {
      return ["delivered": false, "queued": false, "reason": "watch_app_not_installed"]
    }
    guard let context = pendingContext else {
      return ["delivered": false, "queued": false, "reason": "no_data"]
    }
    do {
      try session.updateApplicationContext(context)
      pendingContext = nil
      // updateApplicationContext confirms only queuing, never remote receipt.
      return ["delivered": false, "queued": true, "reason": "queued"]
    } catch {
      // WCErrorCode cases (e.g. watch app not installed, session not paired)
      // are expected outcomes here, not failures Flutter needs to surface.
      return ["delivered": false, "queued": false, "reason": "send_failed"]
    }
  }
}

extension WatchConnectivityHost: WCSessionDelegate {
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    DispatchQueue.main.async { [weak self] in
      _ = self?.flushPendingContext()
    }
  }

  func sessionWatchStateDidChange(_ session: WCSession) {
    DispatchQueue.main.async { [weak self] in
      _ = self?.flushPendingContext()
    }
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async { [weak self] in
      _ = self?.flushPendingContext()
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
  }

  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }
}
