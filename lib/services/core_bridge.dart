import '../repositories/hydration_repository.dart';

class CoreBridge {
  final HydrationRepository _hydrationRepository;

  CoreBridge({HydrationRepository? hydrationRepository})
      : _hydrationRepository =
            hydrationRepository ?? HydrationRepository.memory();

  Future<void> logEcoEvent(int volumeMl) async {
    if (volumeMl <= 0) {
      return;
    }
    await _hydrationRepository.addLog(
      volumeMl: volumeMl,
      timestamp: DateTime.now(),
      source: 'eco',
    );
  }

  Future<double> getTotalPlasticSavedKg() async {
    final totalMl = _hydrationRepository.totalMl;
    final avoidedHalfLiterBottles = totalMl / 500.0;
    return avoidedHalfLiterBottles * 0.01;
  }
}
