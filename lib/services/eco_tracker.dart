import 'core_bridge.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/settings_repository.dart';

class EcoTracker {
  final CoreBridge _coreBridge;
  final HydrationRepository _hydrationRepository;
  final UserSettingsRepository _settingsRepository;

  EcoTracker({
    required CoreBridge coreBridge,
    required HydrationRepository hydrationRepository,
    required UserSettingsRepository settingsRepository,
  })  : _coreBridge = coreBridge,
        _hydrationRepository = hydrationRepository,
        _settingsRepository = settingsRepository;

  Future<void> logHydration(int volumeMl) {
    return _coreBridge.logEcoEvent(volumeMl);
  }

  Future<double> getTotalPlasticSavedKg() {
    if (!_settingsRepository.settings.reusableContainerEnabled) {
      return Future<double>.value(0);
    }
    final avoidedHalfLiterBottles = _hydrationRepository.totalMl / 500.0;
    return Future<double>.value(avoidedHalfLiterBottles * 0.01);
  }
}
