import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../repositories/hydration_repository.dart';
import '../repositories/settings_repository.dart';

class AndroidWidgetService {
  static const smallProvider = 'com.the1807.hydrion.HydrionDailyProgressWidget';
  static const mediumProvider = 'com.the1807.hydrion.HydrionQuickLogWidget';
  static const quickLogHost = 'quick-log';

  final HydrationRepository hydrationRepository;
  final UserSettingsRepository settingsRepository;

  StreamSubscription<Uri?>? _clickSubscription;
  bool _syncing = false;

  @visibleForTesting
  static Map<String, Object> snapshotData({
    required int todayMl,
    required UserSettings settings,
  }) {
    final goalMl = settings.dailyGoalMl;
    final quickAddMl = settings.usableContainerSizeMl ?? 250;
    final percent =
        goalMl <= 0 ? 0 : ((todayMl / goalMl) * 100).round().clamp(0, 999);
    final status = switch ((settings.locale.languageCode, percent)) {
      ('fr', >= 100) => 'Objectif atteint',
      ('fr', >= 75) => 'Presque terminé',
      ('fr', >= 40) => 'Bon élan',
      ('fr', _) => 'Prêt pour une gorgée',
      ('es', >= 100) => 'Objetivo alcanzado',
      ('es', >= 75) => 'Ya casi está',
      ('es', >= 40) => 'Buen progreso',
      ('es', _) => 'Listo para un sorbo',
      (_, >= 100) => 'Goal reached',
      (_, >= 75) => 'Almost there',
      (_, >= 40) => 'Building momentum',
      _ => 'Ready for a sip',
    };
    return {
      'today_ml': todayMl,
      'goal_ml': goalMl,
      'progress_percent': percent,
      'quick_add_ml': quickAddMl,
      'status': status,
    };
  }

  AndroidWidgetService({
    required this.hydrationRepository,
    required this.settingsRepository,
  });

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    hydrationRepository.addListener(_scheduleSync);
    settingsRepository.addListener(_scheduleSync);
    _clickSubscription = HomeWidget.widgetClicked.listen(_handleClick);
    await _handleClick(await HomeWidget.initiallyLaunchedFromHomeWidget());
    await sync();
  }

  void dispose() {
    hydrationRepository.removeListener(_scheduleSync);
    settingsRepository.removeListener(_scheduleSync);
    unawaited(_clickSubscription?.cancel());
  }

  void _scheduleSync() => unawaited(sync());

  Future<void> _handleClick(Uri? uri) async {
    if (uri?.host != quickLogHost) return;
    final amount = int.tryParse(uri?.queryParameters['amount'] ?? '');
    if (amount == null || amount < 100 || amount > 2000) return;
    final tapId = uri?.queryParameters['tap'];
    await hydrationRepository.addLog(
      volumeMl: amount,
      timestamp: DateTime.now(),
      source: 'android-widget',
      actionId: tapId == null || tapId.isEmpty ? null : 'widget-$tapId',
    );
  }

  Future<void> sync() async {
    if (!Platform.isAndroid || _syncing) return;
    _syncing = true;
    try {
      final now = DateTime.now();
      final todayMl = hydrationRepository.totalForDay(now);
      final settings = settingsRepository.settings;
      final data = snapshotData(todayMl: todayMl, settings: settings);

      await Future.wait([
        HomeWidget.saveWidgetData<int>('today_ml', data['today_ml']! as int),
        HomeWidget.saveWidgetData<int>('goal_ml', data['goal_ml']! as int),
        HomeWidget.saveWidgetData<int>(
          'progress_percent',
          data['progress_percent']! as int,
        ),
        HomeWidget.saveWidgetData<int>(
          'quick_add_ml',
          data['quick_add_ml']! as int,
        ),
        HomeWidget.saveWidgetData<String>(
          'status',
          data['status']! as String,
        ),
      ]);
      await Future.wait([
        HomeWidget.updateWidget(qualifiedAndroidName: smallProvider),
        HomeWidget.updateWidget(qualifiedAndroidName: mediumProvider),
      ]);
    } catch (error, stackTrace) {
      debugPrint('Android widget sync failed: $error\n$stackTrace');
    } finally {
      _syncing = false;
    }
  }
}
