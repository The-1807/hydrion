import 'core_bridge.dart';

class EcoTracker {
  final CoreBridge _coreBridge;

  EcoTracker({required CoreBridge coreBridge}) : _coreBridge = coreBridge;

  Future<void> logHydration(int volumeMl) {
    return _coreBridge.logEcoEvent(volumeMl);
  }

  Future<double> getTotalPlasticSavedKg() {
    return _coreBridge.getTotalPlasticSavedKg();
  }
}
