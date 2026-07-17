import 'dart:async';

import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';

class DynamicThemeClock extends ChangeNotifier {
  Timer? _timer;
  DateTime _now;

  DynamicThemeClock({DateTime? now}) : _now = now ?? DateTime.now() {
    _scheduleBoundary();
  }

  ThemeMode resolve(HydrionThemePreference preference) =>
      themeModeFor(preference, _now);

  static ThemeMode themeModeFor(
    HydrionThemePreference preference,
    DateTime now,
  ) {
    return switch (preference) {
      HydrionThemePreference.system => ThemeMode.system,
      HydrionThemePreference.automatic =>
        now.hour >= 7 && now.hour < 19 ? ThemeMode.light : ThemeMode.dark,
      HydrionThemePreference.light => ThemeMode.light,
      HydrionThemePreference.dark => ThemeMode.dark,
    };
  }

  void refresh([DateTime? now]) {
    final previous = resolve(HydrionThemePreference.automatic);
    _now = now ?? DateTime.now();
    _scheduleBoundary();
    if (resolve(HydrionThemePreference.automatic) != previous) {
      notifyListeners();
    }
  }

  void _scheduleBoundary() {
    _timer?.cancel();
    final next = _now.hour < 7
        ? DateTime(_now.year, _now.month, _now.day, 7)
        : _now.hour < 19
            ? DateTime(_now.year, _now.month, _now.day, 19)
            : DateTime(_now.year, _now.month, _now.day + 1, 7);
    _timer = Timer(next.difference(_now), refresh);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
