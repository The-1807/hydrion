import '../repositories/challenge_repository.dart';
import '../repositories/body_metrics_repository.dart';
import '../repositories/daily_hydration_context_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/personalization_state_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/settings_repository.dart';
import 'notifications.dart';
import 'weather_goal_service.dart';
import 'timed_session_notification_service.dart';

enum LocalProfileResetStatus {
  completed,
  completedWithPendingNotificationCleanup,
  failed,
}

enum LocalProfileSubsystemStatus {
  completed,
  pendingRetry,
  failed,
  notRequired,
}

class LocalProfileResetResult {
  final LocalProfileResetStatus status;
  final LocalProfileSubsystemStatus notificationCancellation;
  final LocalProfileSubsystemStatus reminderDeletion;
  final LocalProfileSubsystemStatus challengeDeletion;
  final LocalProfileSubsystemStatus hydrationDeletion;
  final LocalProfileSubsystemStatus weatherDeletion;
  final LocalProfileSubsystemStatus bodyMetricsDeletion;
  final LocalProfileSubsystemStatus dailyContextDeletion;
  final LocalProfileSubsystemStatus personalizationStateDeletion;
  final LocalProfileSubsystemStatus settingsReset;
  final LocalProfileSubsystemStatus wearableDeletion;
  final LocalProfileSubsystemStatus providerInvalidation;
  final LocalProfileSubsystemStatus navigationReset;

  const LocalProfileResetResult({
    required this.status,
    required this.notificationCancellation,
    required this.reminderDeletion,
    required this.challengeDeletion,
    required this.hydrationDeletion,
    required this.weatherDeletion,
    this.bodyMetricsDeletion = LocalProfileSubsystemStatus.notRequired,
    this.dailyContextDeletion = LocalProfileSubsystemStatus.notRequired,
    this.personalizationStateDeletion = LocalProfileSubsystemStatus.notRequired,
    required this.settingsReset,
    this.wearableDeletion = LocalProfileSubsystemStatus.notRequired,
    required this.providerInvalidation,
    required this.navigationReset,
  });

  bool get isCompleted =>
      status == LocalProfileResetStatus.completed ||
      status == LocalProfileResetStatus.completedWithPendingNotificationCleanup;

  bool get hasPendingNotificationCleanup =>
      notificationCancellation == LocalProfileSubsystemStatus.pendingRetry;
}

class LocalProfileResetService {
  final UserSettingsRepository _settingsRepository;
  final HydrationRepository _hydrationRepository;
  final ChallengeRepository _challengeRepository;
  final ReminderRepository _reminderRepository;
  final NotificationService _notificationService;
  final WeatherForecastService _weatherForecastService;
  final BodyMetricsRepository? _bodyMetricsRepository;
  final DailyHydrationContextRepository? _dailyContextRepository;
  final PersonalizationStateRepository? _personalizationStateRepository;
  final TimedSessionNotificationService? _timedSessionNotifications;
  final Future<void> Function()? _resetWearableData;

  const LocalProfileResetService({
    required UserSettingsRepository settingsRepository,
    required HydrationRepository hydrationRepository,
    required ChallengeRepository challengeRepository,
    required ReminderRepository reminderRepository,
    required NotificationService notificationService,
    required WeatherForecastService weatherForecastService,
    BodyMetricsRepository? bodyMetricsRepository,
    DailyHydrationContextRepository? dailyHydrationContextRepository,
    PersonalizationStateRepository? personalizationStateRepository,
    TimedSessionNotificationService? timedSessionNotificationService,
    Future<void> Function()? resetWearableData,
  })  : _settingsRepository = settingsRepository,
        _hydrationRepository = hydrationRepository,
        _challengeRepository = challengeRepository,
        _reminderRepository = reminderRepository,
        _notificationService = notificationService,
        _weatherForecastService = weatherForecastService,
        _bodyMetricsRepository = bodyMetricsRepository,
        _dailyContextRepository = dailyHydrationContextRepository,
        _personalizationStateRepository = personalizationStateRepository,
        _timedSessionNotifications = timedSessionNotificationService,
        _resetWearableData = resetWearableData;

  Future<LocalProfileResetResult> resetLocalProfile() async {
    final wearableDeletion = _resetWearableData == null
        ? LocalProfileSubsystemStatus.notRequired
        : await _run(_resetWearableData);
    // Abort before resetting the profile if its private wearable copy remains.
    if (wearableDeletion == LocalProfileSubsystemStatus.failed) {
      return const LocalProfileResetResult(
        status: LocalProfileResetStatus.failed,
        wearableDeletion: LocalProfileSubsystemStatus.failed,
        notificationCancellation: LocalProfileSubsystemStatus.notRequired,
        reminderDeletion: LocalProfileSubsystemStatus.notRequired,
        challengeDeletion: LocalProfileSubsystemStatus.notRequired,
        hydrationDeletion: LocalProfileSubsystemStatus.notRequired,
        weatherDeletion: LocalProfileSubsystemStatus.notRequired,
        settingsReset: LocalProfileSubsystemStatus.notRequired,
        providerInvalidation: LocalProfileSubsystemStatus.notRequired,
        navigationReset: LocalProfileSubsystemStatus.notRequired,
      );
    }
    await _timedSessionNotifications?.cancelAll();
    final notificationsCancelled =
        await _notificationService.cancelAllReminders();
    final reminderDeletion = await _run(_reminderRepository.clear);
    final challengeDeletion = await _run(_challengeRepository.clear);
    final hydrationDeletion = await _run(_hydrationRepository.clear);
    final weatherDeletion = await _run(_weatherForecastService.clearCache);
    final bodyMetricsDeletion = _bodyMetricsRepository == null
        ? LocalProfileSubsystemStatus.notRequired
        : await _run(_bodyMetricsRepository.clear);
    final dailyContextDeletion = _dailyContextRepository == null
        ? LocalProfileSubsystemStatus.notRequired
        : await _run(_dailyContextRepository.clear);
    final personalizationStateDeletion = _personalizationStateRepository == null
        ? LocalProfileSubsystemStatus.notRequired
        : await _run(_personalizationStateRepository.clear);
    final settingsReset = await _run(_settingsRepository.resetLocalProfile);
    final localCleanupFailed = <LocalProfileSubsystemStatus>[
      reminderDeletion,
      challengeDeletion,
      hydrationDeletion,
      weatherDeletion,
      bodyMetricsDeletion,
      dailyContextDeletion,
      personalizationStateDeletion,
      settingsReset,
    ].contains(LocalProfileSubsystemStatus.failed);
    final notificationStatus = notificationsCancelled
        ? LocalProfileSubsystemStatus.completed
        : LocalProfileSubsystemStatus.pendingRetry;
    final status = localCleanupFailed
        ? LocalProfileResetStatus.failed
        : notificationsCancelled
            ? LocalProfileResetStatus.completed
            : LocalProfileResetStatus.completedWithPendingNotificationCleanup;
    return LocalProfileResetResult(
      status: status,
      wearableDeletion: wearableDeletion,
      notificationCancellation: notificationStatus,
      reminderDeletion: reminderDeletion,
      challengeDeletion: challengeDeletion,
      hydrationDeletion: hydrationDeletion,
      weatherDeletion: weatherDeletion,
      bodyMetricsDeletion: bodyMetricsDeletion,
      dailyContextDeletion: dailyContextDeletion,
      personalizationStateDeletion: personalizationStateDeletion,
      settingsReset: settingsReset,
      providerInvalidation: LocalProfileSubsystemStatus.notRequired,
      navigationReset: settingsReset == LocalProfileSubsystemStatus.completed
          ? LocalProfileSubsystemStatus.completed
          : LocalProfileSubsystemStatus.failed,
    );
  }

  Future<LocalProfileSubsystemStatus> _run(
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
      return LocalProfileSubsystemStatus.completed;
    } catch (_) {
      return LocalProfileSubsystemStatus.failed;
    }
  }
}
