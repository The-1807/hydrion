import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/challenge_activity.dart';
import '../l10n/app_localizations.dart';
import '../l10n/challenge_localizations.dart';
import '../repositories/challenge_repository.dart';
import '../repositories/app_locale_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/settings_repository.dart';

class AndroidWidgetService {
  static const dailyProvider = 'com.the1807.hydrion.HydrionDailyProgressWidget';
  static const quickLogProvider = 'com.the1807.hydrion.HydrionQuickLogWidget';
  static const challengeProvider =
      'com.the1807.hydrion.HydrionActiveChallengeWidget';
  static const quickLogHost = 'quick-log';

  final HydrationRepository hydrationRepository;
  final UserSettingsRepository settingsRepository;
  final ChallengeRepository challengeRepository;
  final AppLocaleRepository appLocaleRepository;

  StreamSubscription<Uri?>? _clickSubscription;
  ValueChanged<String?>? _challengeOpener;
  Future<void> Function(String challengeId, String action)?
      _timedSessionActionHandler;
  String? _pendingChallengeId;
  ({String challengeId, String action})? _pendingTimedSessionAction;
  bool _syncing = false;

  AndroidWidgetService({
    required this.hydrationRepository,
    required this.settingsRepository,
    required this.challengeRepository,
    required this.appLocaleRepository,
  });

  @visibleForTesting
  static Map<String, Object> hydrationSnapshotData({
    required int todayMl,
    required UserSettings settings,
    Locale? locale,
  }) {
    final goalMl = settings.dailyGoalMl;
    final savedAmount = settings.usableContainerSizeMl ?? 250;
    final percent =
        goalMl <= 0 ? 0 : ((todayMl / goalMl) * 100).round().clamp(0, 999);
    final remaining = (goalMl - todayMl).clamp(0, goalMl);
    final l10n = lookupAppLocalizations(locale ?? settings.locale);
    final status = percent >= 100
        ? l10n.goalCompleted
        : l10n.amountLeft(
            amount: l10n.volumeMlValue(amount: remaining),
          );
    return {
      'today_ml': todayMl,
      'goal_ml': goalMl,
      'progress_percent': percent,
      'quick_add_ml': savedAmount,
      'quick_add_small_ml': 150,
      'quick_add_large_ml': 500,
      'status': status,
    };
  }

  @visibleForTesting
  static Map<String, Object> snapshotData(
    JoinedChallenge? challenge, {
    Locale locale = const Locale('en'),
  }) {
    final l10n = lookupAppLocalizations(locale);
    if (challenge == null) {
      return {
        'active_challenge_id': '',
        'active_challenge_title': l10n.widgetNoActiveChallenge,
        'active_challenge_status': l10n.widgetChooseChallenge,
        'active_challenge_progress': 0,
        'active_challenge_action': l10n.widgetOpenChallenges,
      };
    }
    final activity = HydrionChallengeActivities.forId(challenge.id);
    final today = DateTime.now();
    final dayToken = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final completed = activity == null
        ? 0
        : activity.checkpoints
            .where(
              (checkpoint) => challenge.completedActionIds.contains(
                '${challenge.instanceId}:$dayToken:activity:${checkpoint.id}',
              ),
            )
            .length;
    final total = activity?.checkpoints.length ?? 1;
    final progress = ((completed / total) * 100).round().clamp(0, 100);
    final sessionStatus =
        challenge.parameters['activitySessionStatus']?.toString();
    final status = switch (challenge.lifecycleStatus) {
      ChallengeLifecycleStatus.paused => l10n.widgetChallengePaused,
      _ when sessionStatus == 'running' => l10n.widgetActivityActive,
      _ when sessionStatus == 'paused' => l10n.widgetActivityPaused,
      _ when activity != null && completed >= total =>
        l10n.widgetActivityComplete,
      _ when activity != null => l10n.widgetCheckpointProgress(
          completed: completed,
          total: total,
        ),
      _ => l10n.widgetOpenToContinue,
    };
    return {
      'active_challenge_id': challenge.id,
      'active_challenge_title': l10n.challengeCopy(challenge.id).title,
      'active_challenge_status': status,
      'active_challenge_progress': progress,
      'active_challenge_action': l10n.widgetOpenChallenge,
    };
  }

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    hydrationRepository.addListener(_scheduleSync);
    settingsRepository.addListener(_scheduleSync);
    appLocaleRepository.addListener(_scheduleSync);
    challengeRepository.addListener(_scheduleSync);
    _clickSubscription = HomeWidget.widgetClicked.listen(_handleClick);
    await _handleClick(await HomeWidget.initiallyLaunchedFromHomeWidget());
    await sync();
  }

  void attachChallengeOpener(ValueChanged<String?> opener) {
    _challengeOpener = opener;
    final pending = _pendingChallengeId;
    if (pending != null) {
      _pendingChallengeId = null;
      opener(pending.isEmpty ? null : pending);
    }
  }

  void attachTimedSessionActionHandler(
    Future<void> Function(String challengeId, String action) handler,
  ) {
    _timedSessionActionHandler = handler;
    final pending = _pendingTimedSessionAction;
    if (pending != null) {
      _pendingTimedSessionAction = null;
      unawaited(handler(pending.challengeId, pending.action));
    }
  }

  void dispose() {
    hydrationRepository.removeListener(_scheduleSync);
    settingsRepository.removeListener(_scheduleSync);
    appLocaleRepository.removeListener(_scheduleSync);
    challengeRepository.removeListener(_scheduleSync);
    unawaited(_clickSubscription?.cancel());
  }

  void _scheduleSync() => unawaited(sync());

  Future<void> _handleClick(Uri? uri) async {
    if (uri == null) return;
    if (uri.host == quickLogHost) {
      final amount = int.tryParse(uri.queryParameters['amount'] ?? '');
      if (amount == null || amount < 50 || amount > 2000) return;
      final tapId = uri.queryParameters['tap'];
      await hydrationRepository.addLog(
        volumeMl: amount,
        timestamp: DateTime.now(),
        source: 'android-widget',
        actionId: tapId == null || tapId.isEmpty ? null : 'widget-$tapId',
      );
      return;
    }
    if (uri.host == 'log') {
      final opener = _challengeOpener;
      if (opener == null) {
        _pendingChallengeId = '__log__';
      } else {
        opener('__log__');
      }
      return;
    }
    if (uri.host == 'session') {
      final id = uri.queryParameters['id']?.trim() ?? '';
      final action = uri.queryParameters['action']?.trim() ?? 'open';
      if (id.isEmpty) return;
      final handler = _timedSessionActionHandler;
      if (handler == null) {
        _pendingTimedSessionAction = (challengeId: id, action: action);
      } else {
        await handler(id, action);
      }
      final opener = _challengeOpener;
      if (opener == null) {
        _pendingChallengeId = id;
      } else {
        opener(id);
      }
      return;
    }
    if (uri.host != 'challenge' && uri.host != 'challenges') {
      return;
    }
    final id =
        uri.host == 'challenge' ? uri.queryParameters['id']?.trim() ?? '' : '';
    final opener = _challengeOpener;
    if (opener == null) {
      _pendingChallengeId = id;
    } else {
      opener(id.isEmpty ? null : id);
    }
  }

  Future<void> sync() async {
    if (!Platform.isAndroid || _syncing) return;
    _syncing = true;
    try {
      final now = DateTime.now();
      final hydrationData = hydrationSnapshotData(
        todayMl: hydrationRepository.totalForDay(now),
        settings: settingsRepository.settings,
        locale: appLocaleRepository.locale,
      );
      final challengeData = snapshotData(
        challengeRepository.activeChallenge,
        locale: appLocaleRepository.locale,
      );
      final data = {...hydrationData, ...challengeData};
      await Future.wait([
        for (final entry in data.entries)
          switch (entry.value) {
            final int value => HomeWidget.saveWidgetData<int>(entry.key, value),
            final String value =>
              HomeWidget.saveWidgetData<String>(entry.key, value),
            _ => Future<bool?>.value(false),
          },
      ]);
      await Future.wait([
        HomeWidget.updateWidget(qualifiedAndroidName: dailyProvider),
        HomeWidget.updateWidget(qualifiedAndroidName: quickLogProvider),
        HomeWidget.updateWidget(qualifiedAndroidName: challengeProvider),
      ]);
    } catch (error, stackTrace) {
      debugPrint('Android widget sync failed: $error\n$stackTrace');
    } finally {
      _syncing = false;
    }
  }
}
