import '../domain/hydration_contracts.dart';
import '../repositories/challenge_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/settings_repository.dart';

class LocalHydrationContextProvider implements HydrationContextProvider {
  final HydrationRepository _hydrationRepository;
  final ReminderRepository _reminderRepository;
  final ChallengeRepository _challengeRepository;
  final AppCapabilityReporter _capabilityReporter;
  final UserSettingsRepository _settingsRepository;

  const LocalHydrationContextProvider({
    required HydrationRepository hydrationRepository,
    required ReminderRepository reminderRepository,
    required ChallengeRepository challengeRepository,
    required AppCapabilityReporter capabilityReporter,
    required UserSettingsRepository settingsRepository,
  })  : _hydrationRepository = hydrationRepository,
        _reminderRepository = reminderRepository,
        _challengeRepository = challengeRepository,
        _capabilityReporter = capabilityReporter,
        _settingsRepository = settingsRepository;

  @override
  Future<HydrationContext> getHydrationContext({
    DateTime? now,
    HydrationCoachDigestKey digestKey = HydrationCoachDigestKey.weeklyDigest,
  }) async {
    final current = now ?? DateTime.now();
    final dayStart = DateTime(current.year, current.month, current.day);
    final dayEnd = DateTime(current.year, current.month, current.day + 1);
    final todayLogs = _hydrationRepository.fetch(dayStart, dayEnd);
    final capabilities = CapabilityContext.fromAppCapabilities(
      _capabilityReporter.capabilities,
    );
    final reminders = _reminderRepository.reminders;
    final activeChallenge = _challengeRepository.activeChallenge;
    final activeGoalMl = _settingsRepository.settings.dailyGoalMl;
    final progress = _challengeRepository.progressFor(
      _hydrationRepository,
      targetMlOverride: activeGoalMl,
    );

    return HydrationContext(
      dailySummary: DailyHydrationSummary(
        date: dayStart,
        consumedMl: _hydrationRepository.totalForDay(current),
        targetMl: activeGoalMl,
        entryCount: todayLogs.length,
      ),
      lifetimeMl: _hydrationRepository.totalMl,
      eventCount: _hydrationRepository.eventCount,
      reminder: ReminderContext(
        savedReminderCount: reminders.length,
        nextReminderAt: reminders.isEmpty ? null : reminders.first.triggerTime,
        osNotificationsAvailable: capabilities.osNotifications,
      ),
      challenge: activeChallenge == null
          ? const ChallengeContext.none()
          : ChallengeContext(
              hasActiveChallenge: true,
              activeChallengeId: activeChallenge.id,
              activeChallengeName: activeChallenge.name,
              targetMl: activeChallenge.targetMl,
              durationDays: activeChallenge.durationDays,
              completedDays: progress.completedDays,
              todayMl: progress.todayMl,
            ),
      capabilities: capabilities,
    );
  }
}
