// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hydrion';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get hydrionLogoSemantics => 'Hydrion logo';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get ecoImpactTitle => 'Environmental Impact';

  @override
  String get challengesTitle => 'Challenges';

  @override
  String get chatCoachTitle => 'Hydration Coach';

  @override
  String get logTitle => 'Hydration Log';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get arTitle => 'AR Hydration View';

  @override
  String loggedVolume({required int volumeMl}) {
    return 'Logged $volumeMl ml';
  }

  @override
  String get logHydration => 'Log hydration';

  @override
  String get amountLabel => 'Amount';

  @override
  String logVolume({required int volumeMl}) {
    return 'Log $volumeMl ml';
  }

  @override
  String get savedLocally => 'Saved locally on this device.';

  @override
  String savedLocallySyncDisabled(
      {required Object syncNames, required Object verb}) {
    return 'Saved locally on this device. $syncNames sync $verb disabled.';
  }

  @override
  String get analyticsRoute => 'Analytics';

  @override
  String get logRoute => 'Log';

  @override
  String get coachRoute => 'Coach';

  @override
  String get challengesRoute => 'Challenges';

  @override
  String get remindersRoute => 'Reminders';

  @override
  String get arDisabledRoute => 'AR disabled';

  @override
  String get arUnavailableRoute => 'AR unavailable';

  @override
  String voiceIntent({required Object intent}) {
    return 'Voice intent: $intent';
  }

  @override
  String get hydrationAdviceCardSemantics => 'Hydration advice card';

  @override
  String get stayHydratedFallback => 'Stay hydrated.';

  @override
  String get failedToLoadAdvice => 'Failed to load advice';

  @override
  String get retry => 'Retry';

  @override
  String get osNotificationsAvailableSentence =>
      'OS notifications are available.';

  @override
  String get osNotificationsDisabledSentence =>
      'OS notifications are disabled.';

  @override
  String get noLocalReminderNeeded => 'No local reminder definition was needed';

  @override
  String localReminderSaved({required Object notificationStatus}) {
    return 'Local reminder definition saved. $notificationStatus';
  }

  @override
  String get failedToScheduleReminder => 'Failed to schedule reminder';

  @override
  String get localReminderDefinition => 'Local reminder definition';

  @override
  String reminderTileNoSaved({required Object notificationStatus}) {
    return 'No reminders saved. Hydrion stores reminder definitions only. $notificationStatus';
  }

  @override
  String reminderTileSaved(
      {required int count,
      required Object time,
      required Object notificationStatus}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count saved locally. Next definition: $time. $notificationStatus',
      one: '1 saved locally. Next definition: $time. $notificationStatus',
    );
    return '$_temp0';
  }

  @override
  String get saveLocalReminderDefinitionTooltip =>
      'Save local reminder definition';

  @override
  String get voiceInputAvailableSemantics => 'Voice input available';

  @override
  String get voiceInputDisabledSemantics => 'Voice input disabled';

  @override
  String get voiceCapabilityReportedNoAdapter =>
      'Voice capability reported, but no voice adapter is wired';

  @override
  String get voiceInputDisabledTooltip =>
      'Voice input disabled by app capabilities';

  @override
  String get standaloneLocalMode => 'Standalone local mode';

  @override
  String get elkaAdapterConfiguredMode => 'ELKA adapter configured';

  @override
  String get localDataNoProviderRuntime =>
      'Local data, local rules, no provider runtime.';

  @override
  String get language => 'Language';

  @override
  String get appLanguageLabel => 'App language';

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get languageChoiceSaved => 'Language choice is saved locally.';

  @override
  String get localeCoverageComplete =>
      'Hydrion strings are available for this locale.';

  @override
  String get localeCoveragePartial =>
      'Hydrion strings are available; untranslated platform text falls back safely.';

  @override
  String get futureLanguagesNote =>
      'Future languages will appear after real ARB files are added.';

  @override
  String get localeNameEnglish => 'English';

  @override
  String get localeNameSpanish => 'Spanish';

  @override
  String get localeNameFrench => 'French';

  @override
  String get permissions => 'Permissions';

  @override
  String get standalonePermissionsExplanation =>
      'Standalone mode does not request Bluetooth, Health, microphone, camera, or notification permissions.';

  @override
  String get check => 'Check';

  @override
  String get noPlatformPermissionsRequested =>
      'No platform permissions requested in standalone mode';

  @override
  String get runtimeFeatureStatus => 'Runtime feature status';

  @override
  String get localPersistence => 'Local persistence';

  @override
  String get onDevice => 'On device';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get localPersistenceDescription =>
      'Hydration logs, settings, reminders, and challenge state are stored locally.';

  @override
  String get elkaAdapter => 'ELKA adapter';

  @override
  String get configured => 'Configured';

  @override
  String get unconfigured => 'Unconfigured';

  @override
  String get elkaAdapterDescription =>
      'Adapter boundary exists, but no ELKA runtime is connected.';

  @override
  String get cloudAi => 'Cloud AI';

  @override
  String get connected => 'Connected';

  @override
  String get disabled => 'Disabled';

  @override
  String get cloudAiDescription =>
      'No provider SDK or cloud model is connected.';

  @override
  String get voiceInput => 'Voice input';

  @override
  String get available => 'Available';

  @override
  String get voiceInputDescription =>
      'Typed commands can be parsed; microphone capture is unavailable.';

  @override
  String get bleBottleSync => 'BLE bottle sync';

  @override
  String get bleSyncDescription =>
      'No Bluetooth scan, connection, or bottle level read is started.';

  @override
  String get healthSync => 'Health sync';

  @override
  String get healthSyncDescription =>
      'No HealthKit, Google Fit, or wearable read is active.';

  @override
  String get osNotifications => 'OS notifications';

  @override
  String get osNotificationsDisabledTitle => 'OS notifications disabled';

  @override
  String get osNotificationsDescription =>
      'Reminder definitions save locally; no platform notification is scheduled.';

  @override
  String get arVisualization => 'AR visualization';

  @override
  String get arVisualizationDescription =>
      'AR route is a placeholder; no camera or native AR session starts.';

  @override
  String get socialSync => 'Social sync';

  @override
  String get localOnly => 'Local only';

  @override
  String get socialSyncDescription =>
      'Challenges are local-only; no backend state is shared.';

  @override
  String get hydrationLogUpdated => 'Hydration log updated';

  @override
  String get hydrationLogDeleted => 'Hydration log deleted';

  @override
  String get logNotFound => 'Log not found';

  @override
  String get noLogs => 'No hydration logs found';

  @override
  String get logEmptyDescription =>
      'Use Home to add a local hydration entry. Logs are saved on this device.';

  @override
  String get editLogTooltip => 'Edit log';

  @override
  String get deleteLogTooltip => 'Delete log';

  @override
  String get editHydrationLog => 'Edit hydration log';

  @override
  String get amountInMl => 'Amount in ml';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get localEntry => 'Local entry';

  @override
  String logSourceTimestamp(
      {required Object source, required Object timestamp}) {
    return '$source - $timestamp';
  }

  @override
  String get noAnalyticsYet => 'No analytics yet';

  @override
  String get analyticsEmptyDescription =>
      'Log hydration on Home to build local trends.';

  @override
  String todayHydrationTitle({required int todayMl, required int targetMl}) {
    return '$todayMl / $targetMl ml today';
  }

  @override
  String localEntriesToday({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count local entries today. Data stays on this device.',
      one: '1 local entry today. Data stays on this device.',
    );
    return '$_temp0';
  }

  @override
  String get badgeTwoLiterDay => '2L day';

  @override
  String get badgeThreeLogsToday => '3 logs today';

  @override
  String get badgeSevenDayStreak => '7 day streak';

  @override
  String plasticSavedTitle({required Object value}) {
    return 'Plastic saved: $value kg';
  }

  @override
  String localEstimateFromLogs(
      {required int lifetimeMl, required int eventCount}) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount saved logs',
      one: '1 saved log',
    );
    return 'Local estimate from $lifetimeMl ml across $_temp0.';
  }

  @override
  String get hydrationScoreTitle => 'Hydration Score';

  @override
  String get hydrationScoreSemantics => 'Hydration score';

  @override
  String scoreOutOf100({required Object score}) {
    return '$score out of 100';
  }

  @override
  String get scoreSuffix => '/ 100';

  @override
  String logCount({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '1 log',
    );
    return '$_temp0';
  }

  @override
  String get hydrationTipExcellent =>
      'Excellent hydration rhythm. Keep the streak alive.';

  @override
  String get hydrationTipGreat =>
      'Great pace. Maintain consistent sips through the afternoon.';

  @override
  String get hydrationTipClose =>
      'You are close. Add a bottle in the next hour to push over the top.';

  @override
  String get hydrationTipStart =>
      'Start with 300 to 500 ml now and set a reminder.';

  @override
  String get achievementStatusUnlocked => 'unlocked';

  @override
  String get achievementStatusLocked => 'locked';

  @override
  String achievementBadgeSemantics(
      {required Object badgeName, required Object status}) {
    return 'Achievement badge: $badgeName $status';
  }

  @override
  String get hydrationProgressRing => 'Hydration progress ring';

  @override
  String percentValue({required int percent}) {
    return '$percent percent';
  }

  @override
  String consumedOfTarget({required int consumedMl, required int targetMl}) {
    return 'Consumed $consumedMl of $targetMl milliliters';
  }

  @override
  String get arCapabilityReportedNoAdapter =>
      'AR capability is reported, but no AR adapter is wired.';

  @override
  String get arDisabledStandalone => 'AR is disabled in this standalone build.';

  @override
  String get arCapabilityNoSession =>
      'Hydrion still will not start a camera or native AR session until an adapter is configured.';

  @override
  String get arNoPluginActive =>
      'No AR plugin, camera permission, or native AR session is active.';

  @override
  String get chatError => 'Could not fetch coach reply';

  @override
  String get localFallbackCoach => 'Local fallback coach';

  @override
  String coachContextBanner(
      {required Object mode,
      required int todayMl,
      required int lifetimeMl,
      required int eventCount}) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount logs',
      one: '1 log',
    );
    return '$mode. Using saved on-device hydration data. Today: $todayMl ml. Lifetime: $lifetimeMl ml across $_temp0. No cloud AI or ELKA is connected.';
  }

  @override
  String get askCoachEmpty =>
      'Ask for a hydration suggestion. Replies are deterministic local guidance based on saved logs.';

  @override
  String get chatHint => 'Ask your coach...';

  @override
  String get osNotificationsCapabilityReported =>
      'OS notifications capability reported';

  @override
  String get notificationsAdapterNotWired =>
      'No notification adapter is wired yet. Definitions remain local.';

  @override
  String get standaloneRemindersLocalOnly =>
      'Standalone mode stores reminder definitions locally only. No platform notification will fire.';

  @override
  String get noLocalRemindersSaved => 'No local reminders saved';

  @override
  String get remindersEmptyDescription =>
      'Use the Home reminder card to save a local reminder definition for later review.';

  @override
  String reminderSubtitle({required Object timestamp, required int priority}) {
    return '$timestamp - priority $priority';
  }

  @override
  String get deleteLocalReminderTooltip => 'Delete local reminder';

  @override
  String get localReminderDeleted => 'Local reminder definition deleted';

  @override
  String get noChallengesAvailable => 'No challenges available';

  @override
  String get socialChallengeCapabilityReported =>
      'Social challenge capability reported';

  @override
  String get localChallengeMode => 'Local challenge mode';

  @override
  String get socialCapabilityNoAdapter =>
      'No social adapter is wired yet. Progress is still saved on this device.';

  @override
  String get socialSyncNotConnected =>
      'Social sync is not connected yet. Challenge progress is saved on this device.';

  @override
  String get noActiveChallengeYet => 'No active challenge yet';

  @override
  String get joinLocalChallengeDescription =>
      'Join the local challenge below to start tracking progress from saved hydration logs.';

  @override
  String get challengeNameSevenDaySteadySip => 'Seven Day Steady Sip';

  @override
  String get challengeDescriptionSevenDaySteadySip =>
      'Reach your daily hydration goal for one week.';

  @override
  String challengeDetails(
      {required Object description,
      required int targetMl,
      required int durationDays}) {
    return '$description ($targetMl ml, $durationDays days)';
  }

  @override
  String challengeProgress(
      {required int completedDays,
      required int durationDays,
      required int todayMl,
      required int targetMl}) {
    return '$completedDays/$durationDays days complete. Today: $todayMl/$targetMl ml.';
  }

  @override
  String challengeTargetPerDay({required int targetMl}) {
    return '$targetMl ml/day';
  }

  @override
  String challengeDurationDays({required int durationDays}) {
    return '$durationDays days';
  }

  @override
  String get challengeJoined => 'Challenge joined';

  @override
  String challengeJoinedLocally({required Object message}) {
    return '$message locally';
  }

  @override
  String get join => 'Join';

  @override
  String get joined => 'Joined';
}
