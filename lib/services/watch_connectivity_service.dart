import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../repositories/app_locale_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/settings_repository.dart';
import 'android_widget_service.dart';

/// Pushes a hydration snapshot (today's total, goal, progress, status text)
/// to the paired Apple Watch app whenever hydration data changes.
///
/// This is one-way and best-effort: `WCSession.updateApplicationContext`
/// keeps only the latest value. Native results distinguish unavailable and
/// queued states; queuing does not prove delivery. Hydrion never reads sensor or
/// workout data back from the watch through this channel.
class WatchConnectivityService {
  static const _channel = MethodChannel('hydrion/watch_connectivity');

  final HydrationRepository hydrationRepository;
  final UserSettingsRepository settingsRepository;
  final AppLocaleRepository appLocaleRepository;

  bool _syncing = false;

  WatchConnectivityService({
    required this.hydrationRepository,
    required this.settingsRepository,
    required this.appLocaleRepository,
  });

  Future<void> initialize() async {
    if (!Platform.isIOS) return;
    hydrationRepository.addListener(_scheduleSync);
    settingsRepository.addListener(_scheduleSync);
    appLocaleRepository.addListener(_scheduleSync);
    await sync();
  }

  void dispose() {
    hydrationRepository.removeListener(_scheduleSync);
    settingsRepository.removeListener(_scheduleSync);
    appLocaleRepository.removeListener(_scheduleSync);
  }

  void _scheduleSync() => unawaited(sync());

  Future<void> sync() async {
    if (!Platform.isIOS || _syncing) return;
    _syncing = true;
    try {
      final snapshot = AndroidWidgetService.hydrationSnapshotData(
        todayMl: hydrationRepository.totalForDay(DateTime.now()),
        settings: settingsRepository.settings,
        locale: appLocaleRepository.locale,
      );
      await _channel.invokeMethod<Map<Object?, Object?>>('updateContext', {
        'todayMl': snapshot['today_ml'],
        'goalMl': snapshot['goal_ml'],
        'progressPercent': snapshot['progress_percent'],
        'status': snapshot['status'],
      });
    } catch (_) {
      // Platform errors can include payloads; never log hydration values.
      debugPrint('Hydrion watch sync failed.');
    } finally {
      _syncing = false;
    }
  }
}
