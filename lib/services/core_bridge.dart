import 'dart:convert';

class CoreBridge {
  final List<int> _hydrationEvents = <int>[];

  Future<void> logEcoEvent(int volumeMl) async {
    if (volumeMl <= 0) {
      return;
    }
    _hydrationEvents.add(volumeMl);
  }

  Future<double> getTotalPlasticSavedKg() async {
    final totalMl = _hydrationEvents.fold<int>(0, (sum, value) => sum + value);
    final avoidedHalfLiterBottles = totalMl / 500.0;
    return avoidedHalfLiterBottles * 0.01;
  }

  Future<String> coreGetDigest(String digestKey) async {
    final totalMl = _hydrationEvents.fold<int>(0, (sum, value) => sum + value);
    return jsonEncode({
      'digestKey': digestKey,
      'totalMl': totalMl,
      'eventCount': _hydrationEvents.length,
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
