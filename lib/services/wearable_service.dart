import '../repositories/hydration_repository.dart';

export '../repositories/hydration_repository.dart' show HydrationLog;

class WearableService {
  final HydrationRepository _hydrationRepository;

  WearableService({HydrationRepository? hydrationRepository})
      : _hydrationRepository =
            hydrationRepository ?? HydrationRepository.memory();

  bool get supportsBleSync => false;

  bool get supportsHealthSync => false;

  Future<bool> syncHydration(int volumeMl, DateTime timestamp) async {
    if (volumeMl <= 0) {
      return false;
    }

    await _hydrationRepository.addLog(
      volumeMl: volumeMl,
      timestamp: timestamp,
      source: 'local',
    );
    return true;
  }

  Future<List<HydrationLog>> fetchHydrationData(
      DateTime start, DateTime end) async {
    return _hydrationRepository.fetch(start, end);
  }
}
