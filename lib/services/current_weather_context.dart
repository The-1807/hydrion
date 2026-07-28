import 'package:flutter/foundation.dart';

import '../domain/daily_hydration_context.dart';
import 'weather_goal_service.dart';

class CurrentWeatherContext extends ChangeNotifier {
  WeatherSnapshot? _snapshot;
  String? _localDateKey;
  bool _fromCache = false;

  WeatherSnapshot? eligibleSnapshot({
    required DateTime now,
    required bool weatherEnabled,
    required bool locationPermissionGranted,
  }) {
    if (!weatherEnabled || !locationPermissionGranted) return null;
    final snapshot = _snapshot;
    if (snapshot == null || _localDateKey != hydrionLocalDateKey(now)) {
      return null;
    }
    if (now.difference(snapshot.retrievedAt).abs() >
        const Duration(hours: 18)) {
      return null;
    }
    return snapshot;
  }

  bool get fromCache => _fromCache;

  void refreshEligibility() => notifyListeners();

  void publish({
    required WeatherSnapshot snapshot,
    required String localDateKey,
    required bool fromCache,
  }) {
    if (_snapshot == snapshot &&
        _localDateKey == localDateKey &&
        _fromCache == fromCache) {
      return;
    }
    _snapshot = snapshot;
    _localDateKey = localDateKey;
    _fromCache = fromCache;
    notifyListeners();
  }

  void clear() {
    if (_snapshot == null && _localDateKey == null) return;
    _snapshot = null;
    _localDateKey = null;
    _fromCache = false;
    notifyListeners();
  }
}
