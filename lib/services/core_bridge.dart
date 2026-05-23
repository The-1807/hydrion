import 'dart:convert';

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

  Future<String> coreGetDigest(String digestKey) async {
    final todayMl = _hydrationRepository.totalForDay(DateTime.now());
    return jsonEncode({
      'digestKey': digestKey,
      'totalMl': todayMl,
      'lifetimeMl': _hydrationRepository.totalMl,
      'eventCount': _hydrationRepository.eventCount,
    });
  }

  Future<String> coreValidateLlmResponse(String response) async {
    final oneLine = response.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.isEmpty) {
      return 'Hydrion is running locally. Take a steady sip and keep tracking.';
    }
    return oneLine.length > 220 ? '${oneLine.substring(0, 217)}...' : oneLine;
  }
}
