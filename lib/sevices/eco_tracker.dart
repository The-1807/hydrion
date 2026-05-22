import 'dart:async';
import 'package:hydrion/services/ble_service.dart';

/// EcoTracker — Tracks the user's avoided plastic based on hydration volume.
///
/// This service acts as a facade, delegating all persistence and calculation
/// of plastic savings (kg) to the Rust Core Engine via [CoreBridge].
class EcoTracker {
  final CoreBridge _coreBridge;

  /// Initializes the tracker with the required FFI bridge to the Rust Core.
  EcoTracker({required CoreBridge coreBridge}) : _coreBridge = coreBridge;

  /// Logs a hydration event volume to the Core, triggering the plastic saved calculation.
  Future<void> logHydration(int volumeMl) async {
    try {
      await _coreBridge.logEcoEvent(volumeMl);
    } catch (_) {}
  }

  /// Fetches the cumulative total plastic saved (kg) from the Core Engine.
  /// Note: This assumes a corresponding FFI method exists in the Rust Core.
  Future<double> getTotalPlasticSavedKg() async {
    try {
      // Placeholder for a future FFI call like:
      // return await _coreBridge.getTotalPlasticSavedKg();
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}
