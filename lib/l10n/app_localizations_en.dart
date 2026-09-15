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
  String voiceIntent({required Object intent}) {
    return 'Voice intent: $intent';
  }

  @override
  String get hydrationAdviceCardSemantics => 'Hydration advice card';

  @override
  String get stayHydratedFallback => 'Stay hydrated.';

  @override
  String get homeAdviceStrong =>
      'You are on a strong hydration pace. Keep taking small sips through the day.';

  @override
  String get homeAdviceClose =>
      'You are close to target. Add a glass of water in the next hour to stay steady.';

  @override
  String get homeAdviceStart =>
      'Start with 300 to 500 ml now, then check in again after your next drink.';

  @override
  String get homeAdviceGoalReached =>
      'You reached today\'s goal. Hydration needs vary, so keep the rest of the day steady and drink to thirst.';

  @override
  String get homeAdviceHeat => 'Warm conditions raise your fluid needs.';

  @override
  String homeAdviceReliableEntries({required int count}) {
    return 'You have $count local entries today, which makes the trend more reliable.';
  }

  @override
  String get homeAdviceAddEntries =>
      'Add entries when you drink so Hydrion can track the day honestly.';

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
  String get geminiProviderConfiguredMode => 'Gemini provider configured';

  @override
  String get localDataNoProviderRuntime =>
      'Private on-device hydration tracking.';

  @override
  String get geminiProviderConfiguredDescription =>
      'Gemini can propose typed actions; Hydrion validates them before anything is trusted.';

  @override
  String get geminiProviderConfiguredLocalDescription =>
      'Gemini is configured but disabled until provider privacy consent is enabled.';

  @override
  String get geminiProviderActiveDescription =>
      'Gemini may receive typed hydration context; Hydrion validates provider output before anything is trusted.';

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
      'Additional languages will appear only after complete translations are available.';

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
  String get dailyGoalTitle => 'Daily hydration goal';

  @override
  String get dailyGoalDescription =>
      'Set the target Hydrion uses across Home, Analytics, Coach, and local challenges. Hydration needs vary by person and day.';

  @override
  String get dailyGoalFieldLabel => 'Goal in ml';

  @override
  String dailyGoalRange({required int minMl, required int maxMl}) {
    return '$minMl-$maxMl ml';
  }

  @override
  String get dailyGoalUpdated => 'Daily goal updated';

  @override
  String get manualGoalOverrideQuestion =>
      'Are you sure you want to change your tailored goal?';

  @override
  String get manualGoalOverrideConfirmation =>
      'This saves a manual daily goal. Your calculated personalized baseline stays available and will not be changed.';

  @override
  String get dailyGoalInvalid => 'Enter a goal between 500 and 5000 ml';

  @override
  String get reusableContainerTitle => 'Reusable container';

  @override
  String get reusableContainerDescription =>
      'Estimate avoided disposable plastic only when logged drinks usually come from a reusable bottle or cup.';

  @override
  String get localFirstPrivacyTitle => 'Local-first privacy';

  @override
  String get localFirstPrivacyDescription =>
      'Hydrion works offline and keeps hydration logs, goals, language, and challenge progress on this device.';

  @override
  String get optionalProviderConsumerDescription =>
      'Optional provider features stay off until you choose to enable them. Hydrion remains usable offline.';

  @override
  String get debugDiagnosticsTitle => 'Debug diagnostics';

  @override
  String get debugDiagnosticsDescription =>
      'Developer-only runtime details are available in debug builds.';

  @override
  String get runtimeFeatureStatus => 'Runtime feature status';

  @override
  String get providerHealthTitle => 'AI provider status';

  @override
  String get selectedProvider => 'Selected provider';

  @override
  String get activeProvider => 'Active provider';

  @override
  String get localRulesProvider => 'On-device guidance';

  @override
  String get geminiProvider => 'Gemini';

  @override
  String get elkaProvider => 'ELKA';

  @override
  String get providerAvailable => 'Available';

  @override
  String get providerUnavailable => 'Unavailable';

  @override
  String get providerConfigured => 'Configured';

  @override
  String get providerUnconfigured => 'Unconfigured';

  @override
  String get providerFallbackState => 'Fallback state';

  @override
  String get providerFallbackReady => 'On-device guidance is available';

  @override
  String get providerFallbackInUse => 'Using on-device guidance';

  @override
  String get providerFallbackCode => 'Fallback code';

  @override
  String get providerFallbackReason => 'Fallback reason';

  @override
  String get providerNoFallback => 'No fallback needed';

  @override
  String get providerLastFailure => 'Last provider failure';

  @override
  String get providerNoFailure => 'None';

  @override
  String get providerPrivacyTitle => 'Provider privacy';

  @override
  String get providerPrivacyLocalOnly =>
      'On-device guidance keeps hydration context on this device.';

  @override
  String get providerPrivacyGeminiDisclosure =>
      'When Gemini is configured, Hydrion may send typed hydration context to Gemini. Do not ship a shared Gemini API key in web or mobile client artifacts.';

  @override
  String get providerConsentRequired =>
      'Non-local AI requires explicit user consent before production use.';

  @override
  String get providerConsentStatus => 'Provider consent';

  @override
  String get providerConsentToggleTitle => 'Allow Gemini provider processing';

  @override
  String get providerConsentEnabled =>
      'Enabled. Typed hydration context may leave this device for Gemini requests.';

  @override
  String get providerConsentDisabled =>
      'Disabled. Hydrion uses on-device guidance and does not send hydration context to Gemini.';

  @override
  String get providerGeminiHealth => 'Gemini health';

  @override
  String get providerGeminiModel => 'Gemini model';

  @override
  String get providerGeminiConfigured => 'Gemini configured';

  @override
  String get providerDiagnosticsTitle => 'Gemini diagnostics';

  @override
  String get providerEndpointHost => 'Endpoint host';

  @override
  String get providerModelPath => 'Model path';

  @override
  String get providerApiKeyPresent => 'API key present';

  @override
  String get providerApiKeyLength => 'API key length';

  @override
  String get providerApiKeyFingerprint => 'API key fingerprint';

  @override
  String get providerApiKeyContainsWhitespace => 'Key has whitespace';

  @override
  String get providerApiKeyWasTrimmed => 'Key was trimmed';

  @override
  String get providerApiKeyStartsWithGooglePrefix => 'Google key prefix';

  @override
  String get providerAuthHeaderPresent => 'Auth header present';

  @override
  String get providerAuthHeaderValueLength => 'Auth header length';

  @override
  String get providerRequestAttempted => 'Request attempted';

  @override
  String get providerHttpStatusClass => 'HTTP status';

  @override
  String get providerErrorStatus => 'Gemini error status';

  @override
  String get providerErrorMessage => 'Gemini error message';

  @override
  String get providerErrorDetails => 'Gemini error details';

  @override
  String get providerLastDiagnosticPhase => 'Last diagnostic';

  @override
  String get providerParserCode => 'Parser code';

  @override
  String get providerValidatorCode => 'Validator code';

  @override
  String get providerBlockedCapabilities => 'Blocked capabilities';

  @override
  String get providerLastSuccess => 'Last Gemini success';

  @override
  String get providerLastFailureAt => 'Last failure time';

  @override
  String get providerNotAvailable => 'Not available';

  @override
  String get providerDiagnosticNoApiKey => 'No Gemini API key configured';

  @override
  String get providerDiagnosticConsentRequired =>
      'Gemini is configured but provider privacy consent is disabled';

  @override
  String get providerDiagnosticHealthy =>
      'Gemini is healthy; last response passed validation';

  @override
  String get providerDiagnosticFallbackActive => 'On-device guidance is active';

  @override
  String get providerDiagnosticNotProven =>
      'Gemini configured but not yet proven healthy';

  @override
  String get providerDiagnosticLocalRules => 'On-device guidance is active';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

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
  String get cloudAiConfiguredDescription =>
      'Gemini is configured as an optional provider; providers cannot mutate app state.';

  @override
  String get cloudAiConsentRequiredDescription =>
      'Gemini is configured but not active until provider privacy consent is enabled.';

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
  String get hydrationLogRestored => 'Hydration log restored';

  @override
  String get undo => 'Undo';

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
  String get amountInMl => 'Amount in mL';

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
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String relativeDateTime({required Object date, required Object time}) {
    return '$date, $time';
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
  String get badgeDailyGoal => 'Daily goal';

  @override
  String get badgeThreeLogsToday => '3 logs today';

  @override
  String get badgeSevenDayStreak => '7 day streak';

  @override
  String plasticEstimateTitle({required Object value}) {
    return 'Plastic-saving estimate: $value kg';
  }

  @override
  String reusableContainerEstimateFromLogs(
      {required int lifetimeMl, required int eventCount}) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount saved logs',
      one: '1 saved log',
    );
    return 'Estimate assumes logged drinks used your reusable container: $lifetimeMl ml across $_temp0.';
  }

  @override
  String get reusableContainerEstimateDisabled =>
      'Enable reusable-container tracking in Settings before Hydrion estimates avoided disposable plastic.';

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
      'Goal reached. Needs vary, so keep the rest of the day steady.';

  @override
  String get hydrationTipGreat =>
      'Great pace. Maintain comfortable, consistent sips.';

  @override
  String get hydrationTipClose =>
      'You are close. A modest drink can help you reach your target.';

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
  String get chatError => 'Could not fetch coach reply';

  @override
  String get localFallbackCoach => 'On-device coach';

  @override
  String get providerCoachTitle => 'Provider coach';

  @override
  String get coachUserMessageLabel => 'You';

  @override
  String get coachReplyMessageLabel => 'Coach';

  @override
  String coachContextSnapshot(
      {required int todayMl,
      required int targetMl,
      required int eventCount,
      required Object activeProvider}) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount',
      one: '1',
    );
    return 'Today: $todayMl / $targetMl ml. Total logs: $_temp0. Active: $activeProvider.';
  }

  @override
  String coachProviderReady({required Object activeProvider}) {
    return '$activeProvider is active. Replies are validated before Hydrion trusts them.';
  }

  @override
  String get coachProviderFallbackActive =>
      'Using on-device guidance. Provider output remains optional.';

  @override
  String get coachProviderConsentRequired =>
      'Gemini is configured but disabled until provider privacy consent is enabled. Hydration context stays on this device.';

  @override
  String get coachLocalProviderReady =>
      'On-device guidance is active. Hydration context stays on this device.';

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
  String providerCoachContextBanner(
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
    return '$mode. Using saved on-device hydration data. Today: $todayMl ml. Lifetime: $lifetimeMl ml across $_temp0. Provider output is validated before Hydrion trusts it.';
  }

  @override
  String get askCoachEmpty =>
      'Ask for a hydration suggestion. Replies are deterministic local guidance based on saved logs.';

  @override
  String get chatHint => 'Ask your coach...';

  @override
  String get coachFallbackNoticeLabel => 'Fallback';

  @override
  String get coachFallbackNotice => 'On-device guidance handled this reply.';

  @override
  String get suggestionHydrationLogTitle => 'Hydration log suggestion';

  @override
  String get suggestionReminderTitle => 'Reminder suggestion';

  @override
  String get suggestionChallengeTitle => 'Challenge suggestion';

  @override
  String get suggestionTrendTitle => 'Trend insight';

  @override
  String get suggestionUnsupportedTitle => 'Unavailable capability';

  @override
  String suggestionProviderSource({required Object provider}) {
    return 'Source: $provider';
  }

  @override
  String suggestionValidationStatus({required Object status}) {
    return 'Validation: $status';
  }

  @override
  String get suggestionConfirmationRequired => 'Needs confirmation';

  @override
  String get suggestionDisplayOnly => 'Display only';

  @override
  String get suggestionValidated => 'Validated';

  @override
  String get suggestionApplied => 'Suggestion applied';

  @override
  String get suggestionRejected => 'Suggestion rejected';

  @override
  String get suggestionDismissed => 'Suggestion dismissed';

  @override
  String get suggestionApply => 'Apply';

  @override
  String get suggestionDismiss => 'Dismiss';

  @override
  String get suggestionDetailVolume => 'Volume';

  @override
  String get suggestionDetailDelay => 'Delay';

  @override
  String get suggestionDetailPriority => 'Priority';

  @override
  String get suggestionDetailChallenge => 'Challenge';

  @override
  String get suggestionDetailTarget => 'Target';

  @override
  String get suggestionDetailDuration => 'Duration';

  @override
  String get suggestionDetailCapability => 'Capability';

  @override
  String suggestionVolumeValue({required int volumeMl}) {
    return '$volumeMl ml';
  }

  @override
  String suggestionDelayValue({required int minutes}) {
    return '$minutes min';
  }

  @override
  String suggestionTargetValue({required int targetMl}) {
    return '$targetMl ml/day';
  }

  @override
  String suggestionDurationValue({required int days}) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get cloudSync => 'Cloud sync';

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

  @override
  String get bodyMetricsTitle => 'Body metrics';

  @override
  String get bodyMeasurementsTitle => 'Body measurements';

  @override
  String get notAdded => 'Not added';

  @override
  String get addWeight => 'Add weight';

  @override
  String get updateWeight => 'Update weight';

  @override
  String get addHeight => 'Add height';

  @override
  String get updateHeight => 'Update height';

  @override
  String get hydrationPacingScheduleTitle => 'Hydration pacing schedule';

  @override
  String get hydrationPacingScheduleHelp =>
      'Optional. Tell Hydrion when you\'re usually awake so it can gently compare your pace to your day. This never changes your daily goal.';

  @override
  String get wakeTimeLabel => 'Wake time';

  @override
  String get sleepTimeLabel => 'Sleep time';

  @override
  String get addWakeTime => 'Add wake time';

  @override
  String get updateWakeTime => 'Update wake time';

  @override
  String get addSleepTime => 'Add sleep time';

  @override
  String get updateSleepTime => 'Update sleep time';

  @override
  String get pacingAheadOfPace =>
      'You\'re ahead of pace for this point in your day.';

  @override
  String get pacingOnPace => 'You\'re on track for this point in your day.';

  @override
  String get pacingSlightlyBehindPace =>
      'You\'re a little behind your usual pace.';

  @override
  String get pacingMeaningfullyBehindPace =>
      'You\'re behind pace, with time left in your day.';

  @override
  String get pacingGoalReached => 'You\'ve reached today\'s goal.';

  @override
  String get updatedToday => 'Updated today';

  @override
  String updatedOn({required Object date}) {
    return 'Updated $date';
  }

  @override
  String get personalizationTitle => 'Personalization';

  @override
  String get editPersonalizationSettings => 'Edit personalization settings';

  @override
  String get onLabel => 'On';

  @override
  String get offLabel => 'Off';

  @override
  String get dataPrivacyTitle => 'Data and privacy';

  @override
  String get deleteBodyMetricsExplanation =>
      'This removes saved measurements and personalization settings. Hydration logs are not removed.';

  @override
  String get done => 'Done';

  @override
  String get noDailyContext => 'No activity context has been added for today.';

  @override
  String get setDailyContext => 'Set today\'s context';

  @override
  String get savedForToday => 'Saved for today.';

  @override
  String get appliesTodayOnly => 'Applies today only.';

  @override
  String get edit => 'Edit';

  @override
  String get clear => 'Clear';

  @override
  String get feelingUnwellToday => 'Feeling unwell today?';

  @override
  String get bodyMetricsOptional =>
      'Optional, local-only measurements can improve Hydrion\'s general wellness estimate. You can skip, disable, or delete them at any time.';

  @override
  String get enablePersonalization => 'Enable personalized body metrics';

  @override
  String get personalizedBaselineOption => 'Use a personalized baseline';

  @override
  String get personalizedBaselineHelp =>
      'Hydrion will calculate a suggestion for you to review. Your existing goal is not replaced until you apply it.';

  @override
  String get weatherModifierOption => 'Use optional weather adjustments';

  @override
  String get weightLabel => 'Weight';

  @override
  String get heightLabel => 'Height';

  @override
  String get kilogramsLabel => 'kg';

  @override
  String get poundsLabel => 'lb';

  @override
  String get centimetresLabel => 'cm';

  @override
  String get feetInchesLabel => 'ft and in';

  @override
  String get feetLabel => 'ft';

  @override
  String get inchesLabel => 'in';

  @override
  String get accessibleNumericEntry => 'Accessible numeric entry';

  @override
  String get reproductiveHydrationTitle => 'Pregnancy or lactation';

  @override
  String get reproductiveNone => 'None';

  @override
  String get reproductivePregnant => 'Pregnant';

  @override
  String get reproductiveLactating => 'Lactating';

  @override
  String get bmiTitle => 'BMI screening estimate';

  @override
  String get bmiDisclaimer =>
      'BMI is a screening estimate based on height and weight. It does not diagnose health conditions or measure body composition.';

  @override
  String get bmiUnderTwenty =>
      'Hydrion does not interpret adult BMI categories for people younger than 20.';

  @override
  String get bmiBelowRange => 'Below standard adult range';

  @override
  String get bmiStandardRange => 'Standard adult screening range';

  @override
  String get bmiAboveRange => 'Above standard adult range';

  @override
  String get bmiHigherRange => 'Higher adult screening range';

  @override
  String get fluidSafetyTitle => 'Fluid-safety setting';

  @override
  String get fluidSafetyNone => 'No restriction reported';

  @override
  String get fluidSafetyClinician => 'I have a clinician-set target';

  @override
  String get fluidSafetyRestriction =>
      'I have a fluid restriction without a target';

  @override
  String get fluidSafetyUnsure => 'I am unsure';

  @override
  String get clinicianTargetLabel => 'Clinician target in mL';

  @override
  String get allowAboveClinicianTarget =>
      'Allow optional adjustments above this target';

  @override
  String get saveBodyMetrics => 'Save body metrics';

  @override
  String get deleteBodyMetrics => 'Delete body metrics';

  @override
  String get bodyMetricsSaved => 'Body metrics saved locally.';

  @override
  String get bodyMetricsInvalid =>
      'Choose measurements within the displayed safe input range.';

  @override
  String get bodyMetricsDeleted => 'Body metrics deleted.';

  @override
  String get profileDeletionPersonalizationDisclosure =>
      'This clears your local profile, body metrics, daily contexts, hydration history, reminders, challenges, recommendation state, and weather cache on this device. Your language and appearance preferences remain saved.';

  @override
  String get dailyContextTitle => 'Today\'s context';

  @override
  String get dailyContextOptional =>
      'Optional activity and outdoor context adjusts only today\'s suggestion.';

  @override
  String get activityIntensityLabel => 'Activity intensity';

  @override
  String get activityMinutesLabel => 'Activity minutes';

  @override
  String get environmentLabel => 'Environment';

  @override
  String get sweatLevelLabel => 'Sweat level';

  @override
  String get temporaryConditionLabel => 'Temporary condition';

  @override
  String get activityRest => 'Rest';

  @override
  String get activityLight => 'Light';

  @override
  String get activityModerate => 'Moderate';

  @override
  String get activityVigorous => 'Vigorous';

  @override
  String get environmentIndoors => 'Mostly indoors';

  @override
  String get environmentMixed => 'Mixed indoor and outdoor';

  @override
  String get environmentOutdoors => 'Mostly outdoors';

  @override
  String get sweatLow => 'Low';

  @override
  String get sweatModerate => 'Moderate';

  @override
  String get sweatHigh => 'High';

  @override
  String get sweatUnknown => 'Unknown';

  @override
  String get conditionNone => 'None';

  @override
  String get conditionFever => 'Fever';

  @override
  String get conditionStomachIllness => 'Vomiting or diarrhea';

  @override
  String get conditionRecovering => 'Recovering';

  @override
  String get conditionPreferNot => 'Prefer not to say';

  @override
  String get saveDailyContext => 'Save today\'s context';

  @override
  String get clearDailyContext => 'Clear today\'s context';

  @override
  String get hydrationSuggestionTitle => 'Personalized hydration suggestion';

  @override
  String get baselineLabel => 'Baseline';

  @override
  String get adjustmentsLabel => 'Adjustments';

  @override
  String get weatherAdjustmentLabel => 'Weather adjustment';

  @override
  String get activityAdjustmentLabel => 'Activity adjustment';

  @override
  String get reproductiveAdjustmentLabel => 'Pregnancy or lactation adjustment';

  @override
  String get personalizedSuggestionAccepted =>
      'Personalized daily suggestion accepted after review.';

  @override
  String get keepCurrentGoal => 'Keep current goal';

  @override
  String get applySuggestedGoal => 'Apply suggested goal';

  @override
  String get suggestedGoalApplied => 'Suggested goal applied.';

  @override
  String get dailyContextSaved => 'Today\'s context saved.';

  @override
  String get reviewSuggestion => 'Review suggestion';

  @override
  String get generalWellnessNotice =>
      'This is a general wellness estimate, not medical advice. Do not force fluids.';

  @override
  String get illnessSafetyNotice =>
      'Fluid needs can change during illness. Keep your regular recommendation and seek professional guidance for significant symptoms.';

  @override
  String get restrictionSafetyNotice =>
      'Hydrion will not automatically increase your goal while a fluid restriction is reported. Follow professional guidance.';

  @override
  String get recommendedForYou => 'Recommended for you';

  @override
  String get viewChallenge => 'View challenge';

  @override
  String get notNow => 'Not now';

  @override
  String get noAutomaticChallenge =>
      'Recommendations never start a challenge. You decide whether to review and join.';

  @override
  String get tailorChallengeSuggestions => 'Tailor challenge suggestions';

  @override
  String get challengeSuggestionPrivacy =>
      'Choose the kinds of routines you would like Hydrion to consider. These choices stay on this device and never start a challenge automatically.';

  @override
  String get timedFocusSipRoutines => 'Timed focus and sip routines';

  @override
  String get waterRichFoodHabits => 'Water-rich food habits';

  @override
  String get visualDailyConsistency => 'Visual daily consistency';

  @override
  String get infusionFlavorVariety => 'Infusion and flavor variety';

  @override
  String get recommendationWarmWeather =>
      'Today\'s warm conditions make this challenge a useful match.';

  @override
  String get recommendationTimedRoutine =>
      'Matches your preference for timed focus and sip routines.';

  @override
  String get recommendationLoggingConsistency =>
      'A varied logging challenge may help you build consistency.';

  @override
  String get recommendationWaterRichFood =>
      'Matches your interest in adding water-rich foods to your routine.';

  @override
  String get recommendationVisualConsistency =>
      'Matches your preference for visual daily consistency.';

  @override
  String get recommendationInfusionVariety =>
      'Matches your interest in infusion and flavor variety.';

  @override
  String get pregnancyDurationTitle => 'How far along are you?';

  @override
  String get pregnancyDurationDays => 'Days';

  @override
  String get pregnancyDurationWeeks => 'Weeks';

  @override
  String get pregnancyDurationMonths => 'Months';

  @override
  String get pregnancyDurationInputLabel => 'Pregnancy duration';

  @override
  String get pregnancyDurationHelp =>
      'Enter a pregnancy duration between 1 day and 42 weeks.';

  @override
  String get pregnancyDurationInvalid =>
      'Enter a valid pregnancy duration between 1 day and 42 weeks.';

  @override
  String get pregnancyDurationMonthsHelp =>
      'Months are converted approximately and stored locally.';

  @override
  String pregnancyDurationSummary({required int weeks, required int days}) {
    return 'Approximately $weeks weeks, $days days.';
  }

  @override
  String get missionTitle => 'Why Hydrion exists';

  @override
  String get missionSemanticLabel => 'Hydrion mission';

  @override
  String get missionHeadline =>
      'Hydration should be easier to understand and easier to manage.';

  @override
  String get learnMore => 'Learn more';

  @override
  String get missionDetails =>
      'Hydrion supports safer, more consistent habits while keeping personal information local and under your control. Community participation may be offered later through Discord, an external service with separate account and privacy practices. Hydrion will not send profile or health information automatically.';

  @override
  String get communityComingLater => 'Community link coming later';

  @override
  String get continueToTutorial => 'Continue to tutorial';

  @override
  String get profileDeletedTitle => 'Profile deleted';

  @override
  String get profileDeletionCompletedSemanticLabel =>
      'Local profile deletion completed';

  @override
  String get profileDeletedHeadline => 'Your Hydrion profile has been deleted';

  @override
  String get profileDeletedFarewell =>
      'Wherever your hydration journey continues, please take care, stay hydrated, and share what you have learned with someone who may benefit.';

  @override
  String get learnAboutMission => 'Learn about Hydrion\'s mission';

  @override
  String get finish => 'Finish';

  @override
  String get deleteLocalProfile => 'Delete local profile';

  @override
  String get deleteLocalProfileSummary =>
      'Removes profile-owned Hydrion data while preserving language and appearance preferences.';

  @override
  String get deleteLocalProfileQuestion => 'Delete local profile?';

  @override
  String get removeDevicePermissions =>
      'Also remove Hydrion device permissions';

  @override
  String get removeDevicePermissionsHelp =>
      'Android 13 and newer can schedule removal of notification and location permissions after you finish the farewell. Exact-alarm and other special access remain controlled in system settings.';

  @override
  String get reviewPermissions => 'Review permissions';

  @override
  String get deleteAction => 'Delete';

  @override
  String get profileDeletionFailed =>
      'Profile could not be deleted. Close Hydrion, reopen it, and try again.';

  @override
  String get profileDeletionCleanupPending =>
      'Profile deleted. Android reminder cleanup will retry automatically.';

  @override
  String get weatherSuggestionTitle => 'Today\'s weather hydration suggestion';

  @override
  String get humidityLabel => 'Humidity';

  @override
  String get standardGoalLabel => 'Standard goal';

  @override
  String get todaySuggestedGoalLabel => 'Today\'s suggested goal';

  @override
  String get updatedLabel => 'Updated';

  @override
  String get weatherSuggestionDisclosure =>
      'This suggestion uses your saved profile, location permission, and local weather. It is not medical advice.';

  @override
  String get keepStandardGoal => 'Keep standard goal';

  @override
  String get useSuggestion => 'Use suggestion';

  @override
  String get pomodoroSessionNotificationTitle => 'Pomodoro session';

  @override
  String get homeworkSessionNotificationTitle => 'Homework session';

  @override
  String get sessionPaused => 'Paused';

  @override
  String get pauseAction => 'Pause';

  @override
  String get resumeAction => 'Resume';

  @override
  String get stopAction => 'Stop';

  @override
  String get openAction => 'Open';

  @override
  String get waterNotLoggedRetry => 'Water was not logged. Please retry.';

  @override
  String loggedFormattedVolume({required String amount}) {
    return 'Logged $amount';
  }

  @override
  String get dailyGoalReachedRecognition => 'Daily goal reached. Nicely done.';

  @override
  String get sevenDayStreakRecognition =>
      'Seven-day hydration streak. A steady routine is taking shape.';

  @override
  String get profileMenu => 'Profile menu';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get support => 'Support';

  @override
  String get addChallengeDetails => 'Add challenge details';

  @override
  String get challengeDetailsAdded => 'Challenge details added';

  @override
  String get challengeDetailsHelp =>
      'All water counts toward your daily goal. Challenge details record what today\'s task needs.';

  @override
  String get challengeDetailsTitle => 'Challenge details';

  @override
  String get temperatureStyle => 'Temperature style';

  @override
  String get temperatureCool => 'Cool';

  @override
  String get temperatureRoom => 'Room temperature';

  @override
  String get temperatureWarm => 'Comfortably warm';

  @override
  String get infusionTheme => 'Infusion theme';

  @override
  String get noAddedSugar => 'No added sugar';

  @override
  String get useDetails => 'Use details';

  @override
  String get history => 'History';

  @override
  String get customAmount => 'Custom amount';

  @override
  String get momentum => 'Momentum';

  @override
  String get applySuggestedGoalQuestion => 'Apply suggested goal?';

  @override
  String get applySuggestedGoalConfirmation =>
      'Apply this suggested daily goal and continue?';

  @override
  String get refineInputs => 'No, refine inputs';

  @override
  String get confirmApply => 'Yes, apply';

  @override
  String get enterMeasurementsWithKeyboard =>
      'Enter measurements with the keyboard';

  @override
  String recalculatedAt({required String date}) {
    return 'Recalculated $date';
  }

  @override
  String volumeMlValue({required int amount}) {
    return '$amount mL';
  }

  @override
  String baselineMlValue({required String label, required int amount}) {
    return '$label: $amount mL';
  }

  @override
  String get routineFitsDay => 'A routine that fits your day';

  @override
  String get routineFitsDayBody =>
      'Keep logging the water you actually drink. Small check-ins build a useful daily picture.';

  @override
  String amountLeft({required String amount}) {
    return '$amount left';
  }

  @override
  String get weatherAdjusted => 'Weather-adjusted';

  @override
  String get noReusableContainerSaved =>
      'No reusable container saved. Add one in Settings to use it here and in Bottle Bingo.';

  @override
  String savedContainerHelp({required String amount}) {
    return 'Saved container: $amount. Select it here to use the same amount as Bottle Bingo.';
  }

  @override
  String get firstLogWaiting => 'First log waiting';

  @override
  String get momentumEmptyBody => 'One small entry gives the day a shape.';

  @override
  String get momentumDataBody => 'Your shark has real data to react to.';

  @override
  String get challengePick => 'Challenge pick';

  @override
  String get activeChallenge => 'Active challenge';

  @override
  String get bottleBingoReady =>
      'Bottle Bingo is ready when you want a playful routine.';

  @override
  String get activeChallengeGentle =>
      'Keep today gentle; progress comes from normal logs.';

  @override
  String get progress => 'Progress';

  @override
  String get logHistory => 'Log history';

  @override
  String greetingMorning({required String name}) {
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon({required String name}) {
    return 'Good afternoon, $name';
  }

  @override
  String greetingEvening({required String name}) {
    return 'Good evening, $name';
  }

  @override
  String get greetingFallbackName => 'there';

  @override
  String recentLogCounted({required String amount}) {
    return 'Your recent $amount log is counted. Give your routine time before deciding what comes next.';
  }

  @override
  String get noWaterLoggedToday =>
      'No water is logged yet today. Add what you have actually consumed when you are ready.';

  @override
  String todayLogSummary({required int count, required String remaining}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '1 log',
    );
    return 'You have $_temp0 today. About $remaining remains.';
  }

  @override
  String todayLogSummaryWithContainer(
      {required int count,
      required String remaining,
      required String container}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '1 log',
    );
    return 'You have $_temp0 today. About $remaining remains; your $container container is available as a quick-log amount.';
  }

  @override
  String get goalCompleted => 'Goal completed';

  @override
  String get noHydrationLoggedToday => 'No hydration logged today';

  @override
  String get todaysHydration => 'Today\'s hydration';

  @override
  String get onboardingNicknameInvalid =>
      'Enter a nickname up to 32 characters.';

  @override
  String get onboardingAgeInvalid =>
      'Hydrion independent profiles require an age from 13 to 120.';

  @override
  String get onboardingTermsRequired =>
      'Accept the Terms and acknowledge the health disclaimer to continue.';

  @override
  String get onboardingGoalInvalid =>
      'Check your goal and container size before continuing.';

  @override
  String get onboardingCompleteRecognition => 'Your Hydrion setup is complete.';

  @override
  String get onboardingWelcome => 'Welcome to Hydrion';

  @override
  String get back => 'Back';

  @override
  String get start => 'Start';

  @override
  String get continueAction => 'Continue';

  @override
  String get onboardingLocalFirstTitle => 'Hydrion keeps hydration local-first';

  @override
  String get onboardingMascotSemantics => 'Hydrion mascot';

  @override
  String get onboardingLocalFirstBody =>
      'Track water, goals, reminders, and solo challenges on this device. Optional provider features stay off until you choose them.';

  @override
  String get onboardingBasicProfile => 'Basic profile';

  @override
  String get nickname => 'Nickname';

  @override
  String get requiredSavedLocally => 'Required, saved locally.';

  @override
  String get age => 'Age';

  @override
  String get ageOptionalHelp =>
      'Optional. Used only for personalized guidance.';

  @override
  String get sexGuidanceLabel => 'Sex used for hydration guidance';

  @override
  String get sexOptionalHelp =>
      'Optional. Choose prefer not to say at any time.';

  @override
  String get onboardingProfileNeededForMetrics =>
      'Save a nickname and supported age before adding body metrics.';

  @override
  String get chooseDefaultAvatar => 'Choose your default avatar';

  @override
  String get goalMode => 'Goal mode';

  @override
  String get standardOrManual => 'Standard or manual';

  @override
  String get personalizedEstimate => 'Personalized estimate';

  @override
  String get standardGoalModeHelp =>
      'Use the standard target or enter your own target.';

  @override
  String get personalizedGoalModeHelp =>
      'Use locally saved body measurements to calculate a general wellness estimate.';

  @override
  String get weatherBaselineHelp =>
      'Optional weather assistance is selected separately and never replaces your baseline.';

  @override
  String get hydrationSetup => 'Hydration setup';

  @override
  String get dailyGoalMlLabel => 'Daily goal in ml';

  @override
  String get dailyGoalSupportedRange => 'Supported range: 500-5000 ml.';

  @override
  String get displayUnit => 'Display unit';

  @override
  String get milliliters => 'Milliliters';

  @override
  String get ounces => 'Ounces';

  @override
  String get containerSizeMlLabel => 'Usual container size in ml';

  @override
  String get containerSupportedRange => 'Supported range: 100-2000 ml.';

  @override
  String get usuallyReusable => 'Usually reusable';

  @override
  String get reusableHelp =>
      'Only enable this if most logged drinks use a reusable bottle or cup.';

  @override
  String get optionalDeviceFeatures => 'Optional device features';

  @override
  String get reviewBeforeStart => 'Review before you start';

  @override
  String get ready => 'Ready';

  @override
  String get onboardingReadySemantics => 'Onboarding ready';

  @override
  String onboardingSummary(
      {required String name, required String avatar, required String goal}) {
    return 'Hydrion will start with $name, $avatar, $goal ml/day, and local-first tracking.';
  }

  @override
  String get yourProfile => 'your profile';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexMale => 'Male';

  @override
  String get sexIntersex => 'Intersex';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get hydrationReminders => 'Hydration reminders';

  @override
  String get remindersCapabilityHelp =>
      'Hydrion can send local reminders on this device. You can enable them now or later.';

  @override
  String get remindersNotNowHelp =>
      'Not now - reminders can be enabled in Settings.';

  @override
  String get enableReminders => 'Enable reminders';

  @override
  String get weatherAssistance => 'Weather assistance';

  @override
  String get weatherCapabilityHelp =>
      'Hydrion can use approximate location to retrieve local weather and offer a temporary hydration suggestion. Your standard goal still works without it.';

  @override
  String get weatherNotNowHelp =>
      'Not now - your standard hydration goal remains active.';

  @override
  String get enableWeatherAssistance => 'Enable weather assistance';

  @override
  String get waitingForDevice => 'Waiting for the device result...';

  @override
  String get enabled => 'Enabled';

  @override
  String capabilityEnabled({required String title}) {
    return '$title: Enabled';
  }

  @override
  String capabilityStatus({required String title, required String status}) {
    return '$title: $status';
  }

  @override
  String avatarSelectedSemantics({required String avatar}) {
    return '$avatar avatar selected';
  }

  @override
  String selectAvatarSemantics({required String avatar}) {
    return 'Select $avatar avatar';
  }

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String tourStepSemantics(
      {required String tour, required int current, required int total}) {
    return '$tour step $current of $total';
  }

  @override
  String get achievementSemantics => 'Achievement';

  @override
  String get noCheckInsYet => 'No check-ins yet.';

  @override
  String get coachPreviewTitle => 'Coach';

  @override
  String get coachPreviewComingSoon =>
      'Hydrion Coach is being prepared for a future update.';

  @override
  String get coachPreviewGuidance =>
      'For now, keep logging water and tracking your daily progress.';

  @override
  String get reminderNotificationTitle => 'Hydrion reminder';

  @override
  String get reminderChannelName => 'Hydration reminders';

  @override
  String get reminderChannelDescription =>
      'Local reminders for user-created Hydrion hydration check-ins.';

  @override
  String get challengeAroundWorldTitle => 'Around the World Infusion Week';

  @override
  String get challengeAroundWorldDescription =>
      'Try seven no-added-sugar infusion themes while maintaining your normal hydration goal.';

  @override
  String get challengeTemperatureTitle => 'Temperature Roulette';

  @override
  String get challengeTemperatureDescription =>
      'Compare comfortable water temperatures as a preference experiment.';

  @override
  String get challengeEatWaterTitle => 'Eat Your Water Day';

  @override
  String get challengeEatWaterDescription =>
      'Include one selected water-rich food in a meal without inventing hydration volume.';

  @override
  String get challengePomodoroTitle => 'Pomodoro Sip';

  @override
  String get challengePomodoroDescription =>
      'Pair modest hydration check-ins with manually confirmed focus-session breaks.';

  @override
  String get challengePlantTwinTitle => 'Plant Twin Challenge';

  @override
  String get challengePlantTwinDescription =>
      'Use one plant-care cue as a reminder to review your hydration routine.';

  @override
  String get challengeBottleBingoTitle => 'Bottle Bingo';

  @override
  String get challengeBottleBingoDescription =>
      'Complete a weekly mix of explicit hydration actions and non-hydration check-ins.';

  @override
  String get challengeLunchRefillTitle => 'Lunch Break Refill';

  @override
  String get challengeLunchRefillDescription =>
      'Use a lunch break to check and refill your bottle when useful.';

  @override
  String get challengeHomeworkTitle => 'Homework Hydration';

  @override
  String get challengeHomeworkDescription =>
      'Pair a comfortable hydration check with a study break.';

  @override
  String get challengeAfterSchoolTitle => 'After-School Recharge';

  @override
  String get challengeAfterSchoolDescription =>
      'Pause after your daytime routine and review your hydration.';

  @override
  String get challengeBackpackTitle => 'Backpack Bottle Check';

  @override
  String get challengeBackpackDescription =>
      'Use a packing cue to prepare a reusable bottle.';

  @override
  String get challengeDeskResetTitle => 'Desk-Day Reset';

  @override
  String get challengeDeskResetDescription =>
      'Use an optional seated break to review your hydration.';

  @override
  String get challengeShiftCheckTitle => 'Shift Hydration Check';

  @override
  String get challengeShiftCheckDescription =>
      'Add an optional hydration check midway through a work period.';

  @override
  String get challengeCommuteCupTitle => 'Commute Cup';

  @override
  String get challengeCommuteCupDescription =>
      'Use departure or arrival as an optional hydration cue.';

  @override
  String get challengeEveningReviewTitle => 'Evening Goal Review';

  @override
  String get challengeEveningReviewDescription =>
      'Review your day and decide whether your plan still feels right.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get aboutAndLegal => 'About & Legal';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get openSourceLicensesSummary =>
      'Flutter and package license notices.';

  @override
  String get openSourceLegalese =>
      'Hydrion uses open-source components under their licenses.';

  @override
  String get legalDocument => 'Legal document';

  @override
  String get reviewHydrionTerms => 'Review Hydrion terms';

  @override
  String get continueToHydrion => 'Continue to Hydrion';

  @override
  String get acceptHydrionTerms => 'I accept the Hydrion Terms of Use.';

  @override
  String get acknowledgeHealthDisclaimer =>
      'I acknowledge the Health and Safety Disclaimer.';

  @override
  String get supportEmailCopied => 'Support email copied.';

  @override
  String documentVersion({required Object version}) {
    return 'Version $version';
  }

  @override
  String documentEffective({required Object date}) {
    return 'Effective $date';
  }

  @override
  String documentUpdated({required Object date}) {
    return 'Updated $date';
  }

  @override
  String get homeTitle => 'Home';

  @override
  String get pausedChallengesTitle => 'Paused';

  @override
  String get pausedChallengeSummary =>
      'Progress saved. New logs are not evaluated.';

  @override
  String weatherConditionTemperature(
      {required Object condition, required Object temperature}) {
    return '$condition - $temperature°C';
  }

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherStorm => 'Storm';

  @override
  String get weatherMixed => 'Mixed';

  @override
  String get weatherUnknown => 'Unknown';

  @override
  String get tourHydrationBody =>
      'Your daily hydration and remaining amount appear here.';

  @override
  String get tourLogWater => 'Log water';

  @override
  String get tourLogWaterBody =>
      'Log the amount you actually drink. Use a saved container or choose another amount.';

  @override
  String get tourReviewCorrect => 'Review and correct';

  @override
  String get tourReviewCorrectBody =>
      'Review, edit, or remove a hydration entry if you make a mistake.';

  @override
  String get tourChallengesBody =>
      'Challenges add optional habits and tasks. Challenge water still counts normally.';

  @override
  String get tourProgressRefresh => 'Progress and refresh';

  @override
  String get tourProgressRefreshBody =>
      'Review your latest totals here. Pull down to refresh hydration and challenge progress.';

  @override
  String get seeWhatsNew => 'See what\'s new';

  @override
  String get seeWhatsNewBody =>
      'Take a short tour of hydration, challenges, and progress.';

  @override
  String get showMe => 'Show me';

  @override
  String get challengeOptions => 'Challenge options';

  @override
  String get challengeSettings => 'Challenge settings';

  @override
  String get leaveAction => 'Leave';

  @override
  String challengeTutorialSemantics({required Object title}) {
    return '$title tutorial';
  }

  @override
  String get tourOpenTile => 'Open a tile';

  @override
  String get tourOpenTileBody =>
      'Open any tile to see exactly what it requires.';

  @override
  String get tourAutomaticTiles => 'Automatic tiles';

  @override
  String get tourAutomaticTilesBody =>
      'Some tiles update automatically from your normal hydration logs.';

  @override
  String get tourActionsCheckIns => 'Actions and check-ins';

  @override
  String get tourActionsCheckInsBody =>
      'Other tiles ask for a measured drink or a simple check-in.';

  @override
  String get tourMakeBingo => 'Make Bingo';

  @override
  String get tourMakeBingoBody =>
      'Complete five tiles in a row, column, or diagonal to make Bingo.';

  @override
  String get tourStartFocus => 'Start a focus session';

  @override
  String get tourStartFocusBody =>
      'Start the timer when you begin a focus session.';

  @override
  String get tourChooseAfterTimer => 'Choose after the timer';

  @override
  String get tourChooseAfterTimerBody =>
      'When it ends, confirm a sip or log a measured drink.';

  @override
  String get tourSipNoWater => 'Sip check-ins add no water';

  @override
  String get tourSipNoWaterBody =>
      'A sip check-in never adds a guessed hydration amount.';

  @override
  String get tourMeasuredDrinks => 'Measured drinks count normally';

  @override
  String get tourMeasuredDrinksBody =>
      'A measured drink updates normal hydration and may qualify another active challenge.';

  @override
  String get tourTodaysTemperature => 'Today\'s temperature';

  @override
  String get tourTodaysTemperatureBody =>
      'Review today\'s assigned temperature style.';

  @override
  String get tourWeatherBody =>
      'When enabled, local weather may influence the recommendation.';

  @override
  String get tourLogWithContext => 'Log with context';

  @override
  String get tourLogWithContextBody =>
      'Use the challenge action or add temperature details when logging from Home.';

  @override
  String get tourTodaysInfusion => 'Today\'s infusion';

  @override
  String get tourTodaysInfusionBody => 'Review today\'s infusion theme.';

  @override
  String get tourPrepareNoSugar => 'Prepare without added sugar';

  @override
  String get tourPrepareNoSugarBody => 'Use the theme without adding sugar.';

  @override
  String get tourLogWhatYouDrink => 'Log what you drink';

  @override
  String get tourLogWhatYouDrinkBody =>
      'Record the measured amount you actually drink.';

  @override
  String get whatChallengeIs => 'What this challenge is';

  @override
  String get whatYouWillDo => 'What you will do';

  @override
  String get whatCounts => 'What counts';

  @override
  String get whatDoesNotCount => 'What does not count';

  @override
  String get duration => 'Duration';

  @override
  String challengeDurationHelp({required Object days}) {
    return '$days local calendar days. The challenge starts when joined. Daily requirements reset at local midnight; missed days are not silently recovered.';
  }

  @override
  String get completeSchedule => 'Complete schedule';

  @override
  String challengeScheduleDay({required Object day, required Object item}) {
    return 'Day $day: $item';
  }

  @override
  String get howItWorks => 'How it works';

  @override
  String get hydrationProgressPrivacy => 'Hydration, progress, and privacy';

  @override
  String get hydrationProgressPrivacyBody =>
      'Your usual hydration goal stays active. Measured drinks appear throughout Hydrion, while check-ins add no water. Challenge setup and progress stay on this device.';

  @override
  String get requiredSetup => 'Required setup';

  @override
  String get requiredSetupHelp => 'Choose the details that fit your routine.';

  @override
  String get amountInFluidOunces => 'Amount in fluid ounces';

  @override
  String get dateAndTime => 'Date and time';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get editReminder => 'Edit reminder';

  @override
  String get reminderDefaultMessage => 'Time for a gentle hydration check-in.';

  @override
  String get messageLabel => 'Message';

  @override
  String get minutesFromNow => 'Minutes from now';

  @override
  String get minutesRangeHelp => 'Use 5 to 1440 minutes.';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get reminderDetailsInvalid => 'Check reminder details and try again.';

  @override
  String get ageRangeError => 'Enter an age from 13 to 120.';

  @override
  String get ageSaveFailed => 'The age could not be saved. Try again.';

  @override
  String get profileDeleteDeviceSummary =>
      'This removes local Hydrion profile, hydration, reminder, and challenge data from this device.';

  @override
  String get reviewProfileAge => 'Review profile age';

  @override
  String get independentProfileAgeHelp =>
      'Hydrion independent profiles support ages 13 and older.';

  @override
  String get ageReviewExistingDataHelp =>
      'Your existing local data is still here. If the saved age was entered incorrectly, correct it once below. Otherwise, delete the local profile and restart.';

  @override
  String get correctAge => 'Correct age';

  @override
  String get saveAgeCorrection => 'Save age correction';

  @override
  String get optionalDeviceAccess => 'Optional device access';

  @override
  String get optionalDeviceAccessHelp =>
      'Hydrion works with a standard hydration goal even when you skip these options.';

  @override
  String get preciseReminderTiming => 'Precise reminder timing';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String get continueWithoutReminders => 'Continue without reminders';

  @override
  String get allowLocation => 'Allow location';

  @override
  String get continueWithStandardGoal => 'Continue with standard goal';

  @override
  String get openAlarmSettings => 'Open Alarms and reminders settings';

  @override
  String get continueApproximateScheduling =>
      'Continue with approximate scheduling';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get requesting => 'Requesting';

  @override
  String get waitingPermissionResult =>
      'Waiting for the device permission result...';

  @override
  String get openDeviceSettings => 'Open device settings';

  @override
  String get permissionNotRequested => 'Not requested';

  @override
  String get permissionApproximateEnabled => 'Approximate location enabled';

  @override
  String get permissionPreciseEnabled => 'Precise location enabled';

  @override
  String get permissionDenied => 'Denied';

  @override
  String get permissionBlocked => 'Blocked';

  @override
  String get permissionRestricted => 'Restricted';

  @override
  String get permissionNotRequired => 'Not required';

  @override
  String get permissionUnsupported => 'Unsupported';

  @override
  String get permissionTemporarilyUnavailable => 'Temporarily unavailable';

  @override
  String get permissionStatusUnavailable => 'Status unavailable';

  @override
  String get permissionNotificationUnchecked =>
      'Notification status has not been checked yet.';

  @override
  String get permissionLocationUnchecked =>
      'Location status has not been checked yet.';

  @override
  String get permissionAlarmUnchecked =>
      'Alarm scheduling status has not been checked yet.';

  @override
  String get permissionNotificationsAllowed =>
      'Notifications are allowed for Hydrion.';

  @override
  String get permissionNotificationsOff =>
      'Notifications are off. You can allow them here or in device settings.';

  @override
  String get permissionNotificationsNotAsked =>
      'Hydrion has not asked to send notifications yet.';

  @override
  String get permissionNotificationsBlocked =>
      'Notifications are blocked. Open device settings to allow them.';

  @override
  String get permissionNotificationStatusUnavailableAndroid =>
      'Hydrion could not read the Android notification status.';

  @override
  String get permissionNotificationsUnsupported =>
      'Hydrion notifications are not supported on this platform.';

  @override
  String get permissionNotificationStatusTemporary =>
      'Notification status is temporarily unavailable. Refresh to try again.';

  @override
  String get permissionPreciseLocationAllowed =>
      'Precise foreground location is allowed. Approximate location is sufficient for Hydrion weather.';

  @override
  String get permissionApproximateLocationAllowed =>
      'Approximate foreground location is allowed and is sufficient for weather assistance.';

  @override
  String get permissionLocationOff =>
      'Location is off. Your standard hydration goal still works.';

  @override
  String get permissionLocationNotAsked =>
      'Hydrion has not asked for location yet.';

  @override
  String get permissionLocationBlocked =>
      'Location is blocked. Open device settings to enable weather assistance.';

  @override
  String get permissionLocationRestricted =>
      'Location access is restricted by the device.';

  @override
  String get permissionLocationServicesOff =>
      'Device location services are off. Your standard goal remains available.';

  @override
  String get permissionLocationUnsupported =>
      'Location-based weather assistance is not supported on this platform.';

  @override
  String get permissionLocationStatusTemporary =>
      'Location status is temporarily unavailable. Refresh to try again.';

  @override
  String get permissionExactAlarmNotRequired =>
      'Special exact-alarm access is not required on this device.';

  @override
  String get permissionExactAlarmAndroidOnly =>
      'Exact-alarm access is Android-specific.';

  @override
  String get permissionExactSchedulingAvailable =>
      'Exact reminder scheduling is available.';

  @override
  String get permissionExactSchedulingApproximate =>
      'Exact scheduling is unavailable. Hydrion will continue with approximate reminders.';

  @override
  String historyFocusEndedEarly({required Object session}) {
    return 'Ended focus session $session early';
  }

  @override
  String historyFocusCompleted({required Object session}) {
    return 'Completed focus session $session';
  }

  @override
  String historyBingoTileCompleted({required Object tile}) {
    return 'Completed $tile';
  }

  @override
  String historyBingoLineCompleted({required Object line}) {
    return 'Completed Bottle Bingo line $line';
  }

  @override
  String historyTemperatureDrink(
      {required Object amount, required Object style}) {
    return 'Logged a $style drink$amount';
  }

  @override
  String historyInfusionTried({required Object amount, required Object theme}) {
    return 'Tried the $theme infusion$amount';
  }

  @override
  String historyPomodoroDrink({required Object amount}) {
    return 'Logged a Pomodoro drink$amount';
  }

  @override
  String historyPomodoroSession({required Object amount}) {
    return 'Completed a Pomodoro focus session$amount';
  }

  @override
  String historyPomodoroSessionNumber(
      {required Object amount, required Object session}) {
    return 'Completed Pomodoro session $session$amount';
  }

  @override
  String historyFoodAdded({required Object food, required Object meal}) {
    return 'Added $food to $meal';
  }

  @override
  String historyCueCompleted({required Object cue}) {
    return 'Completed the $cue';
  }

  @override
  String get historyChallengeTaskCompleted => 'Completed a challenge task';

  @override
  String historyChallengeDrink({required Object amount}) {
    return 'Logged a challenge drink$amount';
  }

  @override
  String historyBottleBingoDrink({required Object amount}) {
    return 'Logged a Bottle Bingo drink$amount';
  }

  @override
  String historyMeasuredFocusDrink({required Object amount}) {
    return 'Logged a measured focus-session drink$amount';
  }

  @override
  String get assignedTemperature => 'assigned temperature';

  @override
  String get scheduledTemperature => 'scheduled temperature';

  @override
  String get dailyValue => 'daily';

  @override
  String get mealValue => 'meal';

  @override
  String get waterRichFood => 'water-rich food';

  @override
  String get plantCareCue => 'plant-care cue';

  @override
  String get bottleBingoTile => 'a Bottle Bingo tile';

  @override
  String get bottleBingoDrink => 'a Bottle Bingo drink';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get localProfilePhoto => 'Local profile photo';

  @override
  String get profilePhotoSaved => 'Profile photo saved locally.';

  @override
  String get profilePhotoTooLarge =>
      'That photo was too large for local profile storage.';

  @override
  String get profileEditorSummary =>
      'Update your Hydrion identity and preferences. This does not restart onboarding or delete history.';

  @override
  String get profilePhotoPrivacy =>
      'Selected photos are used only as your local profile image. You can remove the photo and return to the default avatar any time.';

  @override
  String get legal => 'Legal';

  @override
  String get hydrationIdentity => 'Hydration identity';

  @override
  String get dailyGoal => 'Daily goal';

  @override
  String get units => 'Units';

  @override
  String get preferredContainer => 'Preferred container';

  @override
  String get notSet => 'Not set';

  @override
  String get noRemindersYet => 'No reminders yet';

  @override
  String savedCount({required int count}) {
    return '$count saved';
  }

  @override
  String contactEmail({required String email}) {
    return 'Contact: $email';
  }

  @override
  String get editProfileInvalid => 'Check the profile fields and try again.';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get useDefaultAvatar => 'Use default avatar';

  @override
  String get displayName => 'Display name';

  @override
  String get defaultProfileAvatar => 'Default profile avatar';

  @override
  String get baselineDailyGoalMl => 'Baseline daily goal in mL';

  @override
  String get preferredContainerMl => 'Preferred container in mL';

  @override
  String get personalized => 'Personalized';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get whyHydrionExists => 'Why Hydrion exists';

  @override
  String get missionAndCommunity => 'Mission and community';

  @override
  String get help => 'Help';

  @override
  String get replayAppTour => 'App tour - Replay the quick guide';

  @override
  String get appearance => 'Appearance';

  @override
  String get useDeviceSetting => 'Use device setting';

  @override
  String get automaticDayNight => 'Automatic day/night';

  @override
  String get dayTheme => 'Day';

  @override
  String get nightTheme => 'Night';

  @override
  String get deviceSetting => 'Device setting';

  @override
  String get autoDayNight => 'Auto day/night';

  @override
  String dailyGoalPerDay({required int amount}) {
    return '$amount mL/day';
  }

  @override
  String get personalizedBaselineActive => 'Personalized baseline';

  @override
  String get manualBaselineActive => 'Standard or manual baseline';

  @override
  String get weatherAssistanceSelected => 'Weather assistance selected';

  @override
  String get weatherAssistanceOff => 'Weather assistance off';

  @override
  String get amountInOz => 'Amount in oz';

  @override
  String get containerSharedHelp =>
      'One saved amount is used by Home and Bottle Bingo.';

  @override
  String get containerAmountInvalid => 'Enter an amount from 100 to 2000 mL.';

  @override
  String get permissionsSummary =>
      'Review reminders, weather location, and Android alarm access.';

  @override
  String get legalPrivacySupport => 'Legal, privacy, and support';

  @override
  String get widgetNoActiveChallenge => 'No active challenge';

  @override
  String get widgetChooseChallenge => 'Open Hydrion to choose a challenge.';

  @override
  String get widgetOpenChallenges => 'Open challenges';

  @override
  String get widgetChallengePaused => 'Challenge paused';

  @override
  String get widgetActivityActive => 'Activity active';

  @override
  String get widgetActivityPaused => 'Activity paused';

  @override
  String get widgetActivityComplete => 'Today\'s activity complete';

  @override
  String widgetCheckpointProgress(
      {required int completed, required int total}) {
    return '$completed of $total checkpoints today';
  }

  @override
  String get widgetOpenToContinue => 'Open Hydrion to continue';

  @override
  String get widgetOpenChallenge => 'Open challenge';

  @override
  String get reportsTitle => 'Hydration reports';

  @override
  String get reportsDescription =>
      'Create a private summary from hydration records stored on this device.';

  @override
  String get reportsOpen => 'Create report';

  @override
  String get reportsFrequency => 'Reporting frequency';

  @override
  String get reportsWeekly => 'Weekly';

  @override
  String get reportsMonthly => 'Monthly';

  @override
  String get reportsQuarterly => 'Quarterly';

  @override
  String get reportsYearly => 'Yearly';

  @override
  String get reportsChoosePeriod => 'Choose period';

  @override
  String get reportsPeriod => 'Period';

  @override
  String get reportsGenerated => 'Generated';

  @override
  String get reportsPreview => 'Report preview';

  @override
  String get reportsTotal => 'Total recorded intake';

  @override
  String get reportsAverage => 'Average on tracked days';

  @override
  String get reportsTrackedDays => 'Tracked days';

  @override
  String get reportsTargetsMet => 'Known targets met';

  @override
  String get reportsTarget => 'Applicable target';

  @override
  String get reportsDate => 'Date';

  @override
  String get reportsIntake => 'Recorded intake';

  @override
  String get reportsMissing => 'No record';

  @override
  String get reportsUnavailable => 'Unavailable';

  @override
  String get reportsPartial => 'This reporting period is still in progress.';

  @override
  String get reportsEmpty =>
      'No hydration intake was recorded for this period.';

  @override
  String get reportsLegacyTarget =>
      'Historical targets that were not stored are shown as unavailable.';

  @override
  String get reportsDisclaimer =>
      'This report summarizes user-tracked hydration information. It is not a medical diagnosis or a substitute for professional medical advice.';

  @override
  String get reportsExport => 'Export PDF';

  @override
  String get reportsExported => 'Report shared successfully.';

  @override
  String get reportsDismissed => 'Sharing was cancelled.';

  @override
  String get reportsExportFailed =>
      'The report could not be exported. Please try again.';

  @override
  String get reportsPage => 'Page';

  @override
  String get reportsVisualization => 'Recorded hydration';

  @override
  String get healthDataTitle => 'Connect health data';

  @override
  String get healthDataSettingsSummary =>
      'Import approved activity records from a provider available on this device.';

  @override
  String get healthDataProvider => 'Provider';

  @override
  String get healthDataHealthConnect => 'Health Connect';

  @override
  String get healthDataAppleHealth => 'Apple Health';

  @override
  String get healthDataAppleAccessRequested =>
      'Apple Health access was requested. Apple protects your choices, so Hydrion cannot display which read categories you allowed.';

  @override
  String get healthDataContributingSources => 'Contributing sources:';

  @override
  String get healthDataAvailable =>
      'Health Connect is available on this device.';

  @override
  String get healthDataLoading => 'Checking available health-data providers...';

  @override
  String get healthDataInstallationRequired =>
      'Install Health Connect to use Android health data.';

  @override
  String get healthDataUpdateRequired =>
      'Update Health Connect before connecting.';

  @override
  String get healthDataUnsupported =>
      'Health Connect is not supported in this device profile.';

  @override
  String get healthDataPermissionNotRequested =>
      'Health access has not been requested.';

  @override
  String get healthDataPermissionPartial =>
      'Some requested categories are not allowed.';

  @override
  String get healthDataPermissionDenied =>
      'Health access is not allowed. Manual hydration remains available.';

  @override
  String get healthDataConnected => 'Connected for read-only health data.';

  @override
  String get healthDataConnectedNoData =>
      'Connected, but no readable records were found.';

  @override
  String get healthDataSynchronizing => 'Synchronizing health data...';

  @override
  String get healthDataSyncPartial =>
      'Synchronization completed with some categories unavailable.';

  @override
  String healthDataSuccessfulCategories({required String categories}) {
    return 'Synchronized categories: $categories';
  }

  @override
  String healthDataFailedCategories({required String categories}) {
    return 'Categories needing attention: $categories';
  }

  @override
  String get healthDataRetryFailedCategories => 'Retry failed categories';

  @override
  String get healthDataSyncFailed => 'Health data could not be synchronized.';

  @override
  String get healthDataStorageUnavailable =>
      'Protected health-data storage is unavailable. No records were imported.';

  @override
  String get healthDataProviderFailure =>
      'The health-data provider could not be refreshed. Try again or open Android settings.';

  @override
  String get healthDataDisconnected =>
      'Disconnected locally. Health Connect permissions are controlled in Android settings.';

  @override
  String get healthDataConsentIntro =>
      'Health Connect is the available provider on this device. Hydrion requests read-only access only after you choose Connect.';

  @override
  String get healthDataCategories => 'Requested categories';

  @override
  String get healthDataWorkouts => 'Workouts';

  @override
  String get healthDataActiveEnergy => 'Active energy';

  @override
  String get healthDataSteps => 'Steps';

  @override
  String get healthDataDistance => 'Distance';

  @override
  String get healthDataCategoryExplanation =>
      'Workouts provide activity duration. Active energy provides exertion context. Steps and distance provide fallback activity context without being added twice.';

  @override
  String get healthDataPrivacyExplanation =>
      'Imported records remain encrypted on this device. No Hydrion account or cloud upload is required. You can decline, revoke access in Android settings, disconnect, or delete Hydrion\'s imported copy without deleting source records.';

  @override
  String get healthDataWellnessDisclaimer =>
      'This is wellness information, not a medical diagnosis. Imported data does not change your hydration target in this version.';

  @override
  String get healthDataConnect => 'Connect';

  @override
  String get healthDataRequestMissing => 'Request missing access';

  @override
  String get healthDataSynchronize => 'Synchronize';

  @override
  String get healthDataOpenSettings => 'Open Android settings';

  @override
  String get healthDataDisconnect => 'Disconnect';

  @override
  String get healthDataDeleteImported => 'Delete imported data';

  @override
  String get healthDataDeleteQuestion =>
      'Delete Hydrion\'s imported health data?';

  @override
  String get healthDataDeleteExplanation =>
      'This removes Hydrion\'s encrypted imported copy and checkpoints. It does not delete Health Connect source records or manual hydration history.';

  @override
  String healthDataImportedCount({required int count}) {
    return 'Imported records: $count';
  }

  @override
  String healthDataGrantedCategories({required String categories}) {
    return 'Granted: $categories';
  }

  @override
  String get healthDataNoGrantedCategories => 'Granted: none';

  @override
  String healthDataContributors({required String applications}) {
    return 'Contributing applications: $applications';
  }

  @override
  String get healthDataNoContributors =>
      'Contributing applications: none found';

  @override
  String healthDataLastSuccessful({required String time}) {
    return 'Last successful synchronization: $time';
  }

  @override
  String get healthDataNeverSynchronized =>
      'Last successful synchronization: never';

  @override
  String get healthDataDashboardTitle => 'Health data';

  @override
  String get healthDataPermissionRequesting =>
      'Opening Health Connect permissions...';

  @override
  String get healthDataConnectedNotSynchronized => 'Health Connect connected';

  @override
  String get healthDataNoSyncYet => 'No synchronization completed yet.';

  @override
  String get healthDataSynchronizedWithRecords => 'Connected and synchronized';

  @override
  String get healthDataSynchronizedNoRecords =>
      'Connected, but no health data was found';

  @override
  String get healthDataNoDataExplanation =>
      'Hydrion has permission, but Health Connect returned no workout, energy, step, or distance records. Make sure your wearable application is sharing data with Health Connect, then try again.';

  @override
  String get healthDataPermissionRevoked => 'Health access needs attention';

  @override
  String healthDataMissingCategories({required String categories}) {
    return 'Missing access: $categories';
  }

  @override
  String healthDataLastAttempt({required String time}) {
    return 'Last attempt: $time';
  }

  @override
  String get healthDataLatestAttemptFailed =>
      'The latest synchronization failed. Previously imported records were not affected.';

  @override
  String healthDataSyncCounts(
      {required int read,
      required int inserted,
      required int updated,
      required int deleted,
      required int rejected}) {
    return 'Latest sync: $read read, $inserted new, $updated updated, $deleted deleted, $rejected rejected';
  }

  @override
  String healthDataRecordPeriod({required String start, required String end}) {
    return 'Available period: $start - $end';
  }

  @override
  String healthDataSourceCount({required String source, required int count}) {
    return '$source: $count records';
  }

  @override
  String get healthDataDataAvailable => 'Data available';

  @override
  String get healthDataWhatReads => 'What Hydrion reads';

  @override
  String get healthDataSyncNow => 'Sync now';

  @override
  String get healthDataTryAgain => 'Try again';

  @override
  String get healthDataManageAccess => 'Manage access';

  @override
  String get healthDataCheckHealthConnect => 'Open Health Connect';

  @override
  String get healthDataReadingSecurely =>
      'Reading authorized records securely. Do not close Hydrion.';

  @override
  String get healthDataReasonUnavailable => 'Health Connect was unavailable.';

  @override
  String get healthDataReasonPermission =>
      'Health access was denied or revoked.';

  @override
  String get healthDataReasonOperation =>
      'The secure synchronization operation could not complete.';
}
