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
}
