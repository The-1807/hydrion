import '../repositories/challenge_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/settings_repository.dart';
import 'notifications.dart';
import 'weather_goal_service.dart';

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
  final String? message;
  final LocalProfileSubsystemStatus notificationCancellation;
  final LocalProfileSubsystemStatus reminderDeletion;
  final LocalProfileSubsystemStatus challengeDeletion;
  final LocalProfileSubsystemStatus hydrationDeletion;
  final LocalProfileSubsystemStatus weatherDeletion;
  final LocalProfileSubsystemStatus settingsReset;
  final LocalProfileSubsystemStatus providerInvalidation;
  final LocalProfileSubsystemStatus navigationReset;

  const LocalProfileResetResult({
    required this.status,
    required this.notificationCancellation,
    required this.reminderDeletion,
    required this.challengeDeletion,
    required this.hydrationDeletion,
    required this.weatherDeletion,
    required this.settingsReset,
    required this.providerInvalidation,
    required this.navigationReset,
    this.message,
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

  const LocalProfileResetService({
    required UserSettingsRepository settingsRepository,
    required HydrationRepository hydrationRepository,
    required ChallengeRepository challengeRepository,
    required ReminderRepository reminderRepository,
    required NotificationService notificationService,
    required WeatherForecastService weatherForecastService,
  })  : _settingsRepository = settingsRepository,
        _hydrationRepository = hydrationRepository,
        _challengeRepository = challengeRepository,
        _reminderRepository = reminderRepository,
        _notificationService = notificationService,
        _weatherForecastService = weatherForecastService;

  Future<LocalProfileResetResult> resetLocalProfile() async {
    final notificationsCancelled =
        await _notificationService.cancelAllReminders();
    final reminderDeletion = await _run(_reminderRepository.clear);
    final challengeDeletion = await _run(_challengeRepository.clear);
    final hydrationDeletion = await _run(_hydrationRepository.clear);
    final weatherDeletion = await _run(_weatherForecastService.clearCache);
    final settingsReset = await _run(_settingsRepository.resetLocalProfile);
    final localCleanupFailed = <LocalProfileSubsystemStatus>[
      reminderDeletion,
      challengeDeletion,
      hydrationDeletion,
      weatherDeletion,
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
      notificationCancellation: notificationStatus,
      reminderDeletion: reminderDeletion,
      challengeDeletion: challengeDeletion,
      hydrationDeletion: hydrationDeletion,
      weatherDeletion: weatherDeletion,
      settingsReset: settingsReset,
      providerInvalidation: LocalProfileSubsystemStatus.notRequired,
      navigationReset: settingsReset == LocalProfileSubsystemStatus.completed
          ? LocalProfileSubsystemStatus.completed
          : LocalProfileSubsystemStatus.failed,
      message: localCleanupFailed
          ? 'Some local profile data could not be removed. Reopen Hydrion and try again.'
          : notificationsCancelled
              ? null
              : 'Your profile was deleted. Android notification cleanup will be retried safely.',
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
