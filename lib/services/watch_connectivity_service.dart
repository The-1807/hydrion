import 'dart:async';

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

  /// Whether this platform has a paired-watch bridge. Unsupported platforms
  /// (Web, Android, desktop) are explicit no-ops: no listeners, no channel
  /// calls.
  final bool isSupported;

  bool _syncing = false;
  bool _listening = false;

  WatchConnectivityService({
    required this.hydrationRepository,
    required this.settingsRepository,
    required this.appLocaleRepository,
    bool? isSupported,
  }) : isSupported = isSupported ?? platformSupportsWatch;

  /// Capability check that is safe on every platform, including Web where
  /// `dart:io Platform` throws `UnsupportedError`.
  static bool get platformSupportsWatch =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> initialize() async {
    if (!isSupported) return;
    if (_listening) {
      await sync();
      return;
    }
    _listening = true;
    hydrationRepository.addListener(_scheduleSync);
    settingsRepository.addListener(_scheduleSync);
    appLocaleRepository.addListener(_scheduleSync);
    await sync();
  }

  void dispose() {
    if (!_listening) return;
    _listening = false;
    hydrationRepository.removeListener(_scheduleSync);
    settingsRepository.removeListener(_scheduleSync);
    appLocaleRepository.removeListener(_scheduleSync);
  }

  void _scheduleSync() => unawaited(sync());

  Future<void> sync() async {
    if (!settingsRepository.isKnown) return;
    if (!isSupported || _syncing) return;
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
