import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @healthDataRetrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying health-data synchronization...'**
  String get healthDataRetrying;

  /// No description provided for @healthDataNoNewRecords.
  ///
  /// In en, this message translates to:
  /// **'Synchronized: no new health data'**
  String get healthDataNoNewRecords;

  /// No description provided for @healthDataLocalRecordsRetained.
  ///
  /// In en, this message translates to:
  /// **'Previously imported data is still available on this device. It may be out of date.'**
  String get healthDataLocalRecordsRetained;

  /// No description provided for @healthDataPermissionsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Current access could not be checked. Previously stored records are unaffected.'**
  String get healthDataPermissionsUnknown;

  /// No description provided for @healthDataProviderRecovery.
  ///
  /// In en, this message translates to:
  /// **'Open the health provider, return here, and retry. Check its background restrictions if the problem continues.'**
  String get healthDataProviderRecovery;

  /// No description provided for @healthDataSummaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stored health data could not be read. Retry without deleting your data.'**
  String get healthDataSummaryUnavailable;

  /// No description provided for @healthDataMetadataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Synchronization history could not be restored or saved. Stored records are separate and have not been cleared.'**
  String get healthDataMetadataUnavailable;

  /// No description provided for @healthDataDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Wearable cleanup did not fully complete. Retry; do not assume all local wearable data was deleted.'**
  String get healthDataDeletionFailed;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydrion'**
  String get appTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @hydrionLogoSemantics.
  ///
  /// In en, this message translates to:
  /// **'Hydrion logo'**
  String get hydrionLogoSemantics;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @ecoImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Environmental Impact'**
  String get ecoImpactTitle;

  /// No description provided for @challengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challengesTitle;

  /// No description provided for @chatCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration Coach'**
  String get chatCoachTitle;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration Log'**
  String get logTitle;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @loggedVolume.
  ///
  /// In en, this message translates to:
  /// **'Logged {volumeMl} ml'**
  String loggedVolume({required int volumeMl});

  /// No description provided for @logHydration.
  ///
  /// In en, this message translates to:
  /// **'Log hydration'**
  String get logHydration;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @logVolume.
  ///
  /// In en, this message translates to:
  /// **'Log {volumeMl} ml'**
  String logVolume({required int volumeMl});

  /// No description provided for @savedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally on this device.'**
  String get savedLocally;

  /// No description provided for @savedLocallySyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Saved locally on this device. {syncNames} sync {verb} disabled.'**
  String savedLocallySyncDisabled(
      {required Object syncNames, required Object verb});

  /// No description provided for @analyticsRoute.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsRoute;

  /// No description provided for @logRoute.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logRoute;

  /// No description provided for @coachRoute.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachRoute;

  /// No description provided for @challengesRoute.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challengesRoute;

  /// No description provided for @remindersRoute.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersRoute;

  /// No description provided for @voiceIntent.
  ///
  /// In en, this message translates to:
  /// **'Voice intent: {intent}'**
  String voiceIntent({required Object intent});

  /// No description provided for @hydrationAdviceCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'Hydration advice card'**
  String get hydrationAdviceCardSemantics;

  /// No description provided for @stayHydratedFallback.
  ///
  /// In en, this message translates to:
  /// **'Stay hydrated.'**
  String get stayHydratedFallback;

  /// No description provided for @homeAdviceStrong.
  ///
  /// In en, this message translates to:
  /// **'You are on a strong hydration pace. Keep taking small sips through the day.'**
  String get homeAdviceStrong;

  /// No description provided for @homeAdviceClose.
  ///
  /// In en, this message translates to:
  /// **'You are close to target. Add a glass of water in the next hour to stay steady.'**
  String get homeAdviceClose;

  /// No description provided for @homeAdviceStart.
  ///
  /// In en, this message translates to:
  /// **'Start with 300 to 500 ml now, then check in again after your next drink.'**
  String get homeAdviceStart;

  /// No description provided for @homeAdviceGoalReached.
  ///
  /// In en, this message translates to:
  /// **'You reached today\'s goal. Hydration needs vary, so keep the rest of the day steady and drink to thirst.'**
  String get homeAdviceGoalReached;

  /// No description provided for @homeAdviceHeat.
  ///
  /// In en, this message translates to:
  /// **'Warm conditions raise your fluid needs.'**
  String get homeAdviceHeat;

  /// No description provided for @homeAdviceReliableEntries.
  ///
  /// In en, this message translates to:
  /// **'You have {count} local entries today, which makes the trend more reliable.'**
  String homeAdviceReliableEntries({required int count});

  /// No description provided for @homeAdviceAddEntries.
  ///
  /// In en, this message translates to:
  /// **'Add entries when you drink so Hydrion can track the day honestly.'**
  String get homeAdviceAddEntries;

  /// No description provided for @failedToLoadAdvice.
  ///
  /// In en, this message translates to:
  /// **'Failed to load advice'**
  String get failedToLoadAdvice;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @osNotificationsAvailableSentence.
  ///
  /// In en, this message translates to:
  /// **'OS notifications are available.'**
  String get osNotificationsAvailableSentence;

  /// No description provided for @osNotificationsDisabledSentence.
  ///
  /// In en, this message translates to:
  /// **'OS notifications are disabled.'**
  String get osNotificationsDisabledSentence;

  /// No description provided for @noLocalReminderNeeded.
  ///
  /// In en, this message translates to:
  /// **'No local reminder definition was needed'**
  String get noLocalReminderNeeded;

  /// No description provided for @localReminderSaved.
  ///
  /// In en, this message translates to:
  /// **'Local reminder definition saved. {notificationStatus}'**
  String localReminderSaved({required Object notificationStatus});

  /// No description provided for @failedToScheduleReminder.
  ///
  /// In en, this message translates to:
  /// **'Failed to schedule reminder'**
  String get failedToScheduleReminder;

  /// No description provided for @localReminderDefinition.
  ///
  /// In en, this message translates to:
  /// **'Local reminder definition'**
  String get localReminderDefinition;

  /// No description provided for @reminderTileNoSaved.
  ///
  /// In en, this message translates to:
  /// **'No reminders saved. Hydrion stores reminder definitions only. {notificationStatus}'**
  String reminderTileNoSaved({required Object notificationStatus});

  /// No description provided for @reminderTileSaved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved locally. Next definition: {time}. {notificationStatus}} other{{count} saved locally. Next definition: {time}. {notificationStatus}}}'**
  String reminderTileSaved(
      {required int count,
      required Object time,
      required Object notificationStatus});

  /// No description provided for @saveLocalReminderDefinitionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save local reminder definition'**
  String get saveLocalReminderDefinitionTooltip;

  /// No description provided for @voiceInputAvailableSemantics.
  ///
  /// In en, this message translates to:
  /// **'Voice input available'**
  String get voiceInputAvailableSemantics;

  /// No description provided for @voiceInputDisabledSemantics.
  ///
  /// In en, this message translates to:
  /// **'Voice input disabled'**
  String get voiceInputDisabledSemantics;

  /// No description provided for @voiceCapabilityReportedNoAdapter.
  ///
  /// In en, this message translates to:
  /// **'Voice capability reported, but no voice adapter is wired'**
  String get voiceCapabilityReportedNoAdapter;

  /// No description provided for @voiceInputDisabledTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice input disabled by app capabilities'**
  String get voiceInputDisabledTooltip;

  /// No description provided for @standaloneLocalMode.
  ///
  /// In en, this message translates to:
  /// **'Standalone local mode'**
  String get standaloneLocalMode;

  /// No description provided for @elkaAdapterConfiguredMode.
  ///
  /// In en, this message translates to:
  /// **'ELKA adapter configured'**
  String get elkaAdapterConfiguredMode;

  /// No description provided for @geminiProviderConfiguredMode.
  ///
  /// In en, this message translates to:
  /// **'Gemini provider configured'**
  String get geminiProviderConfiguredMode;

  /// No description provided for @localDataNoProviderRuntime.
  ///
  /// In en, this message translates to:
  /// **'Private on-device hydration tracking.'**
  String get localDataNoProviderRuntime;

  /// No description provided for @geminiProviderConfiguredDescription.
  ///
  /// In en, this message translates to:
  /// **'Gemini can propose typed actions; Hydrion validates them before anything is trusted.'**
  String get geminiProviderConfiguredDescription;

  /// No description provided for @geminiProviderConfiguredLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'Gemini is configured but disabled until provider privacy consent is enabled.'**
  String get geminiProviderConfiguredLocalDescription;

  /// No description provided for @geminiProviderActiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Gemini may receive typed hydration context; Hydrion validates provider output before anything is trusted.'**
  String get geminiProviderActiveDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageLabel;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @languageChoiceSaved.
  ///
  /// In en, this message translates to:
  /// **'Language choice is saved locally.'**
  String get languageChoiceSaved;

  /// No description provided for @localeCoverageComplete.
  ///
  /// In en, this message translates to:
  /// **'Hydrion strings are available for this locale.'**
  String get localeCoverageComplete;

  /// No description provided for @localeCoveragePartial.
  ///
  /// In en, this message translates to:
  /// **'Hydrion strings are available; untranslated platform text falls back safely.'**
  String get localeCoveragePartial;

  /// No description provided for @futureLanguagesNote.
  ///
  /// In en, this message translates to:
  /// **'Additional languages will appear only after complete translations are available.'**
  String get futureLanguagesNote;

  /// No description provided for @localeNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get localeNameEnglish;

  /// No description provided for @localeNameSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get localeNameSpanish;

  /// No description provided for @localeNameFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get localeNameFrench;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @standalonePermissionsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Standalone mode does not request Bluetooth, Health, microphone, camera, or notification permissions.'**
  String get standalonePermissionsExplanation;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @noPlatformPermissionsRequested.
  ///
  /// In en, this message translates to:
  /// **'No platform permissions requested in standalone mode'**
  String get noPlatformPermissionsRequested;

  /// No description provided for @dailyGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily hydration goal'**
  String get dailyGoalTitle;

  /// No description provided for @dailyGoalDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the target Hydrion uses across Home, Analytics, Coach, and local challenges. Hydration needs vary by person and day.'**
  String get dailyGoalDescription;

  /// No description provided for @dailyGoalFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal in ml'**
  String get dailyGoalFieldLabel;

  /// No description provided for @dailyGoalRange.
  ///
  /// In en, this message translates to:
  /// **'{minMl}-{maxMl} ml'**
  String dailyGoalRange({required int minMl, required int maxMl});

  /// No description provided for @dailyGoalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Daily goal updated'**
  String get dailyGoalUpdated;

  /// No description provided for @manualGoalOverrideQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change your tailored goal?'**
  String get manualGoalOverrideQuestion;

  /// No description provided for @manualGoalOverrideConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This saves a manual daily goal. Your calculated personalized baseline stays available and will not be changed.'**
  String get manualGoalOverrideConfirmation;

  /// No description provided for @dailyGoalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a goal between 500 and 5000 ml'**
  String get dailyGoalInvalid;

  /// No description provided for @reusableContainerTitle.
  ///
  /// In en, this message translates to:
  /// **'Reusable container'**
  String get reusableContainerTitle;

  /// No description provided for @reusableContainerDescription.
  ///
  /// In en, this message translates to:
  /// **'Estimate avoided disposable plastic only when logged drinks usually come from a reusable bottle or cup.'**
  String get reusableContainerDescription;

  /// No description provided for @localFirstPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Local-first privacy'**
  String get localFirstPrivacyTitle;

  /// No description provided for @localFirstPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Hydrion works offline and keeps hydration logs, goals, language, and challenge progress on this device.'**
  String get localFirstPrivacyDescription;

  /// No description provided for @optionalProviderConsumerDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional provider features stay off until you choose to enable them. Hydrion remains usable offline.'**
  String get optionalProviderConsumerDescription;

  /// No description provided for @debugDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug diagnostics'**
  String get debugDiagnosticsTitle;

  /// No description provided for @debugDiagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Developer-only runtime details are available in debug builds.'**
  String get debugDiagnosticsDescription;

  /// No description provided for @runtimeFeatureStatus.
  ///
  /// In en, this message translates to:
  /// **'Runtime feature status'**
  String get runtimeFeatureStatus;

  /// No description provided for @providerHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'AI provider status'**
  String get providerHealthTitle;

  /// No description provided for @selectedProvider.
  ///
  /// In en, this message translates to:
  /// **'Selected provider'**
  String get selectedProvider;

  /// No description provided for @activeProvider.
  ///
  /// In en, this message translates to:
  /// **'Active provider'**
  String get activeProvider;

  /// No description provided for @localRulesProvider.
  ///
  /// In en, this message translates to:
  /// **'On-device guidance'**
  String get localRulesProvider;

  /// No description provided for @geminiProvider.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get geminiProvider;

  /// No description provided for @elkaProvider.
  ///
  /// In en, this message translates to:
  /// **'ELKA'**
  String get elkaProvider;

  /// No description provided for @providerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get providerAvailable;

  /// No description provided for @providerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get providerUnavailable;

  /// No description provided for @providerConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get providerConfigured;

  /// No description provided for @providerUnconfigured.
  ///
  /// In en, this message translates to:
  /// **'Unconfigured'**
  String get providerUnconfigured;

  /// No description provided for @providerFallbackState.
  ///
  /// In en, this message translates to:
  /// **'Fallback state'**
  String get providerFallbackState;

  /// No description provided for @providerFallbackReady.
  ///
  /// In en, this message translates to:
  /// **'On-device guidance is available'**
  String get providerFallbackReady;

  /// No description provided for @providerFallbackInUse.
  ///
  /// In en, this message translates to:
  /// **'Using on-device guidance'**
  String get providerFallbackInUse;

  /// No description provided for @providerFallbackCode.
  ///
  /// In en, this message translates to:
  /// **'Fallback code'**
  String get providerFallbackCode;

  /// No description provided for @providerFallbackReason.
  ///
  /// In en, this message translates to:
  /// **'Fallback reason'**
  String get providerFallbackReason;

  /// No description provided for @providerNoFallback.
  ///
  /// In en, this message translates to:
  /// **'No fallback needed'**
  String get providerNoFallback;

  /// No description provided for @providerLastFailure.
  ///
  /// In en, this message translates to:
  /// **'Last provider failure'**
  String get providerLastFailure;

  /// No description provided for @providerNoFailure.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get providerNoFailure;

  /// No description provided for @providerPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider privacy'**
  String get providerPrivacyTitle;

  /// No description provided for @providerPrivacyLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'On-device guidance keeps hydration context on this device.'**
  String get providerPrivacyLocalOnly;

  /// No description provided for @providerPrivacyGeminiDisclosure.
  ///
  /// In en, this message translates to:
  /// **'When Gemini is configured, Hydrion may send typed hydration context to Gemini. Do not ship a shared Gemini API key in web or mobile client artifacts.'**
  String get providerPrivacyGeminiDisclosure;

  /// No description provided for @providerConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Non-local AI requires explicit user consent before production use.'**
  String get providerConsentRequired;

  /// No description provided for @providerConsentStatus.
  ///
  /// In en, this message translates to:
  /// **'Provider consent'**
  String get providerConsentStatus;

  /// No description provided for @providerConsentToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Gemini provider processing'**
  String get providerConsentToggleTitle;

  /// No description provided for @providerConsentEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled. Typed hydration context may leave this device for Gemini requests.'**
  String get providerConsentEnabled;

  /// No description provided for @providerConsentDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled. Hydrion uses on-device guidance and does not send hydration context to Gemini.'**
  String get providerConsentDisabled;

  /// No description provided for @providerGeminiHealth.
  ///
  /// In en, this message translates to:
  /// **'Gemini health'**
  String get providerGeminiHealth;

  /// No description provided for @providerGeminiModel.
  ///
  /// In en, this message translates to:
  /// **'Gemini model'**
  String get providerGeminiModel;

  /// No description provided for @providerGeminiConfigured.
  ///
  /// In en, this message translates to:
  /// **'Gemini configured'**
  String get providerGeminiConfigured;

  /// No description provided for @providerDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Gemini diagnostics'**
  String get providerDiagnosticsTitle;

  /// No description provided for @providerEndpointHost.
  ///
  /// In en, this message translates to:
  /// **'Endpoint host'**
  String get providerEndpointHost;

  /// No description provided for @providerModelPath.
  ///
  /// In en, this message translates to:
  /// **'Model path'**
  String get providerModelPath;

  /// No description provided for @providerApiKeyPresent.
  ///
  /// In en, this message translates to:
  /// **'API key present'**
  String get providerApiKeyPresent;

  /// No description provided for @providerApiKeyLength.
  ///
  /// In en, this message translates to:
  /// **'API key length'**
  String get providerApiKeyLength;

  /// No description provided for @providerApiKeyFingerprint.
  ///
  /// In en, this message translates to:
  /// **'API key fingerprint'**
  String get providerApiKeyFingerprint;

  /// No description provided for @providerApiKeyContainsWhitespace.
  ///
  /// In en, this message translates to:
  /// **'Key has whitespace'**
  String get providerApiKeyContainsWhitespace;

  /// No description provided for @providerApiKeyWasTrimmed.
  ///
  /// In en, this message translates to:
  /// **'Key was trimmed'**
  String get providerApiKeyWasTrimmed;

  /// No description provided for @providerApiKeyStartsWithGooglePrefix.
  ///
  /// In en, this message translates to:
  /// **'Google key prefix'**
  String get providerApiKeyStartsWithGooglePrefix;

  /// No description provided for @providerAuthHeaderPresent.
  ///
  /// In en, this message translates to:
  /// **'Auth header present'**
  String get providerAuthHeaderPresent;

  /// No description provided for @providerAuthHeaderValueLength.
  ///
  /// In en, this message translates to:
  /// **'Auth header length'**
  String get providerAuthHeaderValueLength;

  /// No description provided for @providerRequestAttempted.
  ///
  /// In en, this message translates to:
  /// **'Request attempted'**
  String get providerRequestAttempted;

  /// No description provided for @providerHttpStatusClass.
  ///
  /// In en, this message translates to:
  /// **'HTTP status'**
  String get providerHttpStatusClass;

  /// No description provided for @providerErrorStatus.
  ///
  /// In en, this message translates to:
  /// **'Gemini error status'**
  String get providerErrorStatus;

  /// No description provided for @providerErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Gemini error message'**
  String get providerErrorMessage;

  /// No description provided for @providerErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Gemini error details'**
  String get providerErrorDetails;

  /// No description provided for @providerLastDiagnosticPhase.
  ///
  /// In en, this message translates to:
  /// **'Last diagnostic'**
  String get providerLastDiagnosticPhase;

  /// No description provided for @providerParserCode.
  ///
  /// In en, this message translates to:
  /// **'Parser code'**
  String get providerParserCode;

  /// No description provided for @providerValidatorCode.
  ///
  /// In en, this message translates to:
  /// **'Validator code'**
  String get providerValidatorCode;

  /// No description provided for @providerBlockedCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Blocked capabilities'**
  String get providerBlockedCapabilities;

  /// No description provided for @providerLastSuccess.
  ///
  /// In en, this message translates to:
  /// **'Last Gemini success'**
  String get providerLastSuccess;

  /// No description provided for @providerLastFailureAt.
  ///
  /// In en, this message translates to:
  /// **'Last failure time'**
  String get providerLastFailureAt;

  /// No description provided for @providerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get providerNotAvailable;

  /// No description provided for @providerDiagnosticNoApiKey.
  ///
  /// In en, this message translates to:
  /// **'No Gemini API key configured'**
  String get providerDiagnosticNoApiKey;

  /// No description provided for @providerDiagnosticConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Gemini is configured but provider privacy consent is disabled'**
  String get providerDiagnosticConsentRequired;

  /// No description provided for @providerDiagnosticHealthy.
  ///
  /// In en, this message translates to:
  /// **'Gemini is healthy; last response passed validation'**
  String get providerDiagnosticHealthy;

  /// No description provided for @providerDiagnosticFallbackActive.
  ///
  /// In en, this message translates to:
  /// **'On-device guidance is active'**
  String get providerDiagnosticFallbackActive;

  /// No description provided for @providerDiagnosticNotProven.
  ///
  /// In en, this message translates to:
  /// **'Gemini configured but not yet proven healthy'**
  String get providerDiagnosticNotProven;

  /// No description provided for @providerDiagnosticLocalRules.
  ///
  /// In en, this message translates to:
  /// **'On-device guidance is active'**
  String get providerDiagnosticLocalRules;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @localPersistence.
  ///
  /// In en, this message translates to:
  /// **'Local persistence'**
  String get localPersistence;

  /// No description provided for @onDevice.
  ///
  /// In en, this message translates to:
  /// **'On device'**
  String get onDevice;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @localPersistenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Hydration logs, settings, reminders, and challenge state are stored locally.'**
  String get localPersistenceDescription;

  /// No description provided for @elkaAdapter.
  ///
  /// In en, this message translates to:
  /// **'ELKA adapter'**
  String get elkaAdapter;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// No description provided for @unconfigured.
  ///
  /// In en, this message translates to:
  /// **'Unconfigured'**
  String get unconfigured;

  /// No description provided for @elkaAdapterDescription.
  ///
  /// In en, this message translates to:
  /// **'Adapter boundary exists, but no ELKA runtime is connected.'**
  String get elkaAdapterDescription;

  /// No description provided for @cloudAi.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI'**
  String get cloudAi;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @cloudAiDescription.
  ///
  /// In en, this message translates to:
  /// **'No provider SDK or cloud model is connected.'**
  String get cloudAiDescription;

  /// No description provided for @cloudAiConfiguredDescription.
  ///
  /// In en, this message translates to:
  /// **'Gemini is configured as an optional provider; providers cannot mutate app state.'**
  String get cloudAiConfiguredDescription;

  /// No description provided for @cloudAiConsentRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'Gemini is configured but not active until provider privacy consent is enabled.'**
  String get cloudAiConsentRequiredDescription;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get voiceInput;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @voiceInputDescription.
  ///
  /// In en, this message translates to:
  /// **'Typed commands can be parsed; microphone capture is unavailable.'**
  String get voiceInputDescription;

  /// No description provided for @bleBottleSync.
  ///
  /// In en, this message translates to:
  /// **'BLE bottle sync'**
  String get bleBottleSync;

  /// No description provided for @bleSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth scan, connection, or bottle level read is started.'**
  String get bleSyncDescription;

  /// No description provided for @healthSync.
  ///
  /// In en, this message translates to:
  /// **'Health sync'**
  String get healthSync;

  /// No description provided for @healthSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'No HealthKit, Google Fit, or wearable read is active.'**
  String get healthSyncDescription;

  /// No description provided for @osNotifications.
  ///
  /// In en, this message translates to:
  /// **'OS notifications'**
  String get osNotifications;

  /// No description provided for @osNotificationsDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'OS notifications disabled'**
  String get osNotificationsDisabledTitle;

  /// No description provided for @osNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminder definitions save locally; no platform notification is scheduled.'**
  String get osNotificationsDescription;

  /// No description provided for @socialSync.
  ///
  /// In en, this message translates to:
  /// **'Social sync'**
  String get socialSync;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get localOnly;

  /// No description provided for @socialSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Challenges are local-only; no backend state is shared.'**
  String get socialSyncDescription;

  /// No description provided for @hydrationLogUpdated.
  ///
  /// In en, this message translates to:
  /// **'Hydration log updated'**
  String get hydrationLogUpdated;

  /// No description provided for @hydrationLogDeleted.
  ///
  /// In en, this message translates to:
  /// **'Hydration log deleted'**
  String get hydrationLogDeleted;

  /// No description provided for @hydrationLogRestored.
  ///
  /// In en, this message translates to:
  /// **'Hydration log restored'**
  String get hydrationLogRestored;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @logNotFound.
  ///
  /// In en, this message translates to:
  /// **'Log not found'**
  String get logNotFound;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No hydration logs found'**
  String get noLogs;

  /// No description provided for @logEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Home to add a local hydration entry. Logs are saved on this device.'**
  String get logEmptyDescription;

  /// No description provided for @editLogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit log'**
  String get editLogTooltip;

  /// No description provided for @deleteLogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete log'**
  String get deleteLogTooltip;

  /// No description provided for @editHydrationLog.
  ///
  /// In en, this message translates to:
  /// **'Edit hydration log'**
  String get editHydrationLog;

  /// No description provided for @amountInMl.
  ///
  /// In en, this message translates to:
  /// **'Amount in mL'**
  String get amountInMl;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @localEntry.
  ///
  /// In en, this message translates to:
  /// **'Local entry'**
  String get localEntry;

  /// No description provided for @logSourceTimestamp.
  ///
  /// In en, this message translates to:
  /// **'{source} - {timestamp}'**
  String logSourceTimestamp(
      {required Object source, required Object timestamp});

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @relativeDateTime.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String relativeDateTime({required Object date, required Object time});

  /// No description provided for @noAnalyticsYet.
  ///
  /// In en, this message translates to:
  /// **'No analytics yet'**
  String get noAnalyticsYet;

  /// No description provided for @analyticsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Log hydration on Home to build local trends.'**
  String get analyticsEmptyDescription;

  /// No description provided for @todayHydrationTitle.
  ///
  /// In en, this message translates to:
  /// **'{todayMl} / {targetMl} ml today'**
  String todayHydrationTitle({required int todayMl, required int targetMl});

  /// No description provided for @localEntriesToday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 local entry today. Data stays on this device.} other{{count} local entries today. Data stays on this device.}}'**
  String localEntriesToday({required int count});

  /// No description provided for @badgeDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get badgeDailyGoal;

  /// No description provided for @badgeThreeLogsToday.
  ///
  /// In en, this message translates to:
  /// **'3 logs today'**
  String get badgeThreeLogsToday;

  /// No description provided for @badgeSevenDayStreak.
  ///
  /// In en, this message translates to:
  /// **'7 day streak'**
  String get badgeSevenDayStreak;

  /// No description provided for @plasticEstimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Plastic-saving estimate: {value} kg'**
  String plasticEstimateTitle({required Object value});

  /// No description provided for @reusableContainerEstimateFromLogs.
  ///
  /// In en, this message translates to:
  /// **'Estimate assumes logged drinks used your reusable container: {lifetimeMl} ml across {eventCount, plural, =1{1 saved log} other{{eventCount} saved logs}}.'**
  String reusableContainerEstimateFromLogs(
      {required int lifetimeMl, required int eventCount});

  /// No description provided for @reusableContainerEstimateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Enable reusable-container tracking in Settings before Hydrion estimates avoided disposable plastic.'**
  String get reusableContainerEstimateDisabled;

  /// No description provided for @hydrationScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration Score'**
  String get hydrationScoreTitle;

  /// No description provided for @hydrationScoreSemantics.
  ///
  /// In en, this message translates to:
  /// **'Hydration score'**
  String get hydrationScoreSemantics;

  /// No description provided for @scoreOutOf100.
  ///
  /// In en, this message translates to:
  /// **'{score} out of 100'**
  String scoreOutOf100({required Object score});

  /// No description provided for @scoreSuffix.
  ///
  /// In en, this message translates to:
  /// **'/ 100'**
  String get scoreSuffix;

  /// No description provided for @logCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 log} other{{count} logs}}'**
  String logCount({required int count});

  /// No description provided for @hydrationTipExcellent.
  ///
  /// In en, this message translates to:
  /// **'Goal reached. Needs vary, so keep the rest of the day steady.'**
  String get hydrationTipExcellent;

  /// No description provided for @hydrationTipGreat.
  ///
  /// In en, this message translates to:
  /// **'Great pace. Maintain comfortable, consistent sips.'**
  String get hydrationTipGreat;

  /// No description provided for @hydrationTipClose.
  ///
  /// In en, this message translates to:
  /// **'You are close. A modest drink can help you reach your target.'**
  String get hydrationTipClose;

  /// No description provided for @hydrationTipStart.
  ///
  /// In en, this message translates to:
  /// **'Start with 300 to 500 ml now and set a reminder.'**
  String get hydrationTipStart;

  /// No description provided for @achievementStatusUnlocked.
  ///
  /// In en, this message translates to:
  /// **'unlocked'**
  String get achievementStatusUnlocked;

  /// No description provided for @achievementStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get achievementStatusLocked;

  /// No description provided for @achievementBadgeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Achievement badge: {badgeName} {status}'**
  String achievementBadgeSemantics(
      {required Object badgeName, required Object status});

  /// No description provided for @hydrationProgressRing.
  ///
  /// In en, this message translates to:
  /// **'Hydration progress ring'**
  String get hydrationProgressRing;

  /// No description provided for @percentValue.
  ///
  /// In en, this message translates to:
  /// **'{percent} percent'**
  String percentValue({required int percent});

  /// No description provided for @consumedOfTarget.
  ///
  /// In en, this message translates to:
  /// **'Consumed {consumedMl} of {targetMl} milliliters'**
  String consumedOfTarget({required int consumedMl, required int targetMl});

  /// No description provided for @chatError.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch coach reply'**
  String get chatError;

  /// No description provided for @localFallbackCoach.
  ///
  /// In en, this message translates to:
  /// **'On-device coach'**
  String get localFallbackCoach;

  /// No description provided for @providerCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider coach'**
  String get providerCoachTitle;

  /// No description provided for @coachUserMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get coachUserMessageLabel;

  /// No description provided for @coachReplyMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachReplyMessageLabel;

  /// No description provided for @coachContextSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Today: {todayMl} / {targetMl} ml. Total logs: {eventCount, plural, =1{1} other{{eventCount}}}. Active: {activeProvider}.'**
  String coachContextSnapshot(
      {required int todayMl,
      required int targetMl,
      required int eventCount,
      required Object activeProvider});

  /// No description provided for @coachProviderReady.
  ///
  /// In en, this message translates to:
  /// **'{activeProvider} is active. Replies are validated before Hydrion trusts them.'**
  String coachProviderReady({required Object activeProvider});

  /// No description provided for @coachProviderFallbackActive.
  ///
  /// In en, this message translates to:
  /// **'Using on-device guidance. Provider output remains optional.'**
  String get coachProviderFallbackActive;

  /// No description provided for @coachProviderConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Gemini is configured but disabled until provider privacy consent is enabled. Hydration context stays on this device.'**
  String get coachProviderConsentRequired;

  /// No description provided for @coachLocalProviderReady.
  ///
  /// In en, this message translates to:
  /// **'On-device guidance is active. Hydration context stays on this device.'**
  String get coachLocalProviderReady;

  /// No description provided for @coachContextBanner.
  ///
  /// In en, this message translates to:
  /// **'{mode}. Using saved on-device hydration data. Today: {todayMl} ml. Lifetime: {lifetimeMl} ml across {eventCount, plural, =1{1 log} other{{eventCount} logs}}. No cloud AI or ELKA is connected.'**
  String coachContextBanner(
      {required Object mode,
      required int todayMl,
      required int lifetimeMl,
      required int eventCount});

  /// No description provided for @providerCoachContextBanner.
  ///
  /// In en, this message translates to:
  /// **'{mode}. Using saved on-device hydration data. Today: {todayMl} ml. Lifetime: {lifetimeMl} ml across {eventCount, plural, =1{1 log} other{{eventCount} logs}}. Provider output is validated before Hydrion trusts it.'**
  String providerCoachContextBanner(
      {required Object mode,
      required int todayMl,
      required int lifetimeMl,
      required int eventCount});

  /// No description provided for @askCoachEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ask for a hydration suggestion. Replies are deterministic local guidance based on saved logs.'**
  String get askCoachEmpty;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Ask your coach...'**
  String get chatHint;

  /// No description provided for @coachFallbackNoticeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fallback'**
  String get coachFallbackNoticeLabel;

  /// No description provided for @coachFallbackNotice.
  ///
  /// In en, this message translates to:
  /// **'On-device guidance handled this reply.'**
  String get coachFallbackNotice;

  /// No description provided for @suggestionHydrationLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration log suggestion'**
  String get suggestionHydrationLogTitle;

  /// No description provided for @suggestionReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder suggestion'**
  String get suggestionReminderTitle;

  /// No description provided for @suggestionChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge suggestion'**
  String get suggestionChallengeTitle;

  /// No description provided for @suggestionTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Trend insight'**
  String get suggestionTrendTitle;

  /// No description provided for @suggestionUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unavailable capability'**
  String get suggestionUnsupportedTitle;

  /// No description provided for @suggestionProviderSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {provider}'**
  String suggestionProviderSource({required Object provider});

  /// No description provided for @suggestionValidationStatus.
  ///
  /// In en, this message translates to:
  /// **'Validation: {status}'**
  String suggestionValidationStatus({required Object status});

  /// No description provided for @suggestionConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Needs confirmation'**
  String get suggestionConfirmationRequired;

  /// No description provided for @suggestionDisplayOnly.
  ///
  /// In en, this message translates to:
  /// **'Display only'**
  String get suggestionDisplayOnly;

  /// No description provided for @suggestionValidated.
  ///
  /// In en, this message translates to:
  /// **'Validated'**
  String get suggestionValidated;

  /// No description provided for @suggestionApplied.
  ///
  /// In en, this message translates to:
  /// **'Suggestion applied'**
  String get suggestionApplied;

  /// No description provided for @suggestionRejected.
  ///
  /// In en, this message translates to:
  /// **'Suggestion rejected'**
  String get suggestionRejected;

  /// No description provided for @suggestionDismissed.
  ///
  /// In en, this message translates to:
  /// **'Suggestion dismissed'**
  String get suggestionDismissed;

  /// No description provided for @suggestionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get suggestionApply;

  /// No description provided for @suggestionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get suggestionDismiss;

  /// No description provided for @suggestionDetailVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get suggestionDetailVolume;

  /// No description provided for @suggestionDetailDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get suggestionDetailDelay;

  /// No description provided for @suggestionDetailPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get suggestionDetailPriority;

  /// No description provided for @suggestionDetailChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get suggestionDetailChallenge;

  /// No description provided for @suggestionDetailTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get suggestionDetailTarget;

  /// No description provided for @suggestionDetailDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get suggestionDetailDuration;

  /// No description provided for @suggestionDetailCapability.
  ///
  /// In en, this message translates to:
  /// **'Capability'**
  String get suggestionDetailCapability;

  /// No description provided for @suggestionVolumeValue.
  ///
  /// In en, this message translates to:
  /// **'{volumeMl} ml'**
  String suggestionVolumeValue({required int volumeMl});

  /// No description provided for @suggestionDelayValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String suggestionDelayValue({required int minutes});

  /// No description provided for @suggestionTargetValue.
  ///
  /// In en, this message translates to:
  /// **'{targetMl} ml/day'**
  String suggestionTargetValue({required int targetMl});

  /// No description provided for @suggestionDurationValue.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String suggestionDurationValue({required int days});

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get cloudSync;

  /// No description provided for @osNotificationsCapabilityReported.
  ///
  /// In en, this message translates to:
  /// **'OS notifications capability reported'**
  String get osNotificationsCapabilityReported;

  /// No description provided for @notificationsAdapterNotWired.
  ///
  /// In en, this message translates to:
  /// **'No notification adapter is wired yet. Definitions remain local.'**
  String get notificationsAdapterNotWired;

  /// No description provided for @standaloneRemindersLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Standalone mode stores reminder definitions locally only. No platform notification will fire.'**
  String get standaloneRemindersLocalOnly;

  /// No description provided for @noLocalRemindersSaved.
  ///
  /// In en, this message translates to:
  /// **'No local reminders saved'**
  String get noLocalRemindersSaved;

  /// No description provided for @remindersEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the Home reminder card to save a local reminder definition for later review.'**
  String get remindersEmptyDescription;

  /// No description provided for @reminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{timestamp} - priority {priority}'**
  String reminderSubtitle({required Object timestamp, required int priority});

  /// No description provided for @deleteLocalReminderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete local reminder'**
  String get deleteLocalReminderTooltip;

  /// No description provided for @localReminderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Local reminder definition deleted'**
  String get localReminderDeleted;

  /// No description provided for @noChallengesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No challenges available'**
  String get noChallengesAvailable;

  /// No description provided for @socialChallengeCapabilityReported.
  ///
  /// In en, this message translates to:
  /// **'Social challenge capability reported'**
  String get socialChallengeCapabilityReported;

  /// No description provided for @localChallengeMode.
  ///
  /// In en, this message translates to:
  /// **'Local challenge mode'**
  String get localChallengeMode;

  /// No description provided for @socialCapabilityNoAdapter.
  ///
  /// In en, this message translates to:
  /// **'No social adapter is wired yet. Progress is still saved on this device.'**
  String get socialCapabilityNoAdapter;

  /// No description provided for @socialSyncNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Social sync is not connected yet. Challenge progress is saved on this device.'**
  String get socialSyncNotConnected;

  /// No description provided for @noActiveChallengeYet.
  ///
  /// In en, this message translates to:
  /// **'No active challenge yet'**
  String get noActiveChallengeYet;

  /// No description provided for @joinLocalChallengeDescription.
  ///
  /// In en, this message translates to:
  /// **'Join the local challenge below to start tracking progress from saved hydration logs.'**
  String get joinLocalChallengeDescription;

  /// No description provided for @challengeNameSevenDaySteadySip.
  ///
  /// In en, this message translates to:
  /// **'Seven Day Steady Sip'**
  String get challengeNameSevenDaySteadySip;

  /// No description provided for @challengeDescriptionSevenDaySteadySip.
  ///
  /// In en, this message translates to:
  /// **'Reach your daily hydration goal for one week.'**
  String get challengeDescriptionSevenDaySteadySip;

  /// No description provided for @challengeDetails.
  ///
  /// In en, this message translates to:
  /// **'{description} ({targetMl} ml, {durationDays} days)'**
  String challengeDetails(
      {required Object description,
      required int targetMl,
      required int durationDays});

  /// No description provided for @challengeProgress.
  ///
  /// In en, this message translates to:
  /// **'{completedDays}/{durationDays} days complete. Today: {todayMl}/{targetMl} ml.'**
  String challengeProgress(
      {required int completedDays,
      required int durationDays,
      required int todayMl,
      required int targetMl});

  /// No description provided for @challengeTargetPerDay.
  ///
  /// In en, this message translates to:
  /// **'{targetMl} ml/day'**
  String challengeTargetPerDay({required int targetMl});

  /// No description provided for @challengeDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{durationDays} days'**
  String challengeDurationDays({required int durationDays});

  /// No description provided for @challengeJoined.
  ///
  /// In en, this message translates to:
  /// **'Challenge joined'**
  String get challengeJoined;

  /// No description provided for @challengeJoinedLocally.
  ///
  /// In en, this message translates to:
  /// **'{message} locally'**
  String challengeJoinedLocally({required Object message});

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @bodyMetricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Body metrics'**
  String get bodyMetricsTitle;

  /// No description provided for @bodyMeasurementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Body measurements'**
  String get bodyMeasurementsTitle;

  /// No description provided for @notAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get notAdded;

  /// No description provided for @addWeight.
  ///
  /// In en, this message translates to:
  /// **'Add weight'**
  String get addWeight;

  /// No description provided for @updateWeight.
  ///
  /// In en, this message translates to:
  /// **'Update weight'**
  String get updateWeight;

  /// No description provided for @addHeight.
  ///
  /// In en, this message translates to:
  /// **'Add height'**
  String get addHeight;

  /// No description provided for @updateHeight.
  ///
  /// In en, this message translates to:
  /// **'Update height'**
  String get updateHeight;

  /// No description provided for @hydrationPacingScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration pacing schedule'**
  String get hydrationPacingScheduleTitle;

  /// No description provided for @hydrationPacingScheduleHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Tell Hydrion when you\'re usually awake so it can gently compare your pace to your day. This never changes your daily goal.'**
  String get hydrationPacingScheduleHelp;

  /// No description provided for @wakeTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Wake time'**
  String get wakeTimeLabel;

  /// No description provided for @sleepTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep time'**
  String get sleepTimeLabel;

  /// No description provided for @addWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Add wake time'**
  String get addWakeTime;

  /// No description provided for @updateWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Update wake time'**
  String get updateWakeTime;

  /// No description provided for @addSleepTime.
  ///
  /// In en, this message translates to:
  /// **'Add sleep time'**
  String get addSleepTime;

  /// No description provided for @updateSleepTime.
  ///
  /// In en, this message translates to:
  /// **'Update sleep time'**
  String get updateSleepTime;

  /// No description provided for @pacingAheadOfPace.
  ///
  /// In en, this message translates to:
  /// **'You\'re ahead of pace for this point in your day.'**
  String get pacingAheadOfPace;

  /// No description provided for @pacingOnPace.
  ///
  /// In en, this message translates to:
  /// **'You\'re on track for this point in your day.'**
  String get pacingOnPace;

  /// No description provided for @pacingSlightlyBehindPace.
  ///
  /// In en, this message translates to:
  /// **'You\'re a little behind your usual pace.'**
  String get pacingSlightlyBehindPace;

  /// No description provided for @pacingMeaningfullyBehindPace.
  ///
  /// In en, this message translates to:
  /// **'You\'re behind pace, with time left in your day.'**
  String get pacingMeaningfullyBehindPace;

  /// No description provided for @pacingGoalReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s goal.'**
  String get pacingGoalReached;

  /// No description provided for @updatedToday.
  ///
  /// In en, this message translates to:
  /// **'Updated today'**
  String get updatedToday;

  /// No description provided for @updatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedOn({required Object date});

  /// No description provided for @personalizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalizationTitle;

  /// No description provided for @editPersonalizationSettings.
  ///
  /// In en, this message translates to:
  /// **'Edit personalization settings'**
  String get editPersonalizationSettings;

  /// No description provided for @onLabel.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get onLabel;

  /// No description provided for @offLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offLabel;

  /// No description provided for @dataPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Data and privacy'**
  String get dataPrivacyTitle;

  /// No description provided for @deleteBodyMetricsExplanation.
  ///
  /// In en, this message translates to:
  /// **'This removes saved measurements and personalization settings. Hydration logs are not removed.'**
  String get deleteBodyMetricsExplanation;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @noDailyContext.
  ///
  /// In en, this message translates to:
  /// **'No activity context has been added for today.'**
  String get noDailyContext;

  /// No description provided for @setDailyContext.
  ///
  /// In en, this message translates to:
  /// **'Set today\'s context'**
  String get setDailyContext;

  /// No description provided for @savedForToday.
  ///
  /// In en, this message translates to:
  /// **'Saved for today.'**
  String get savedForToday;

  /// No description provided for @appliesTodayOnly.
  ///
  /// In en, this message translates to:
  /// **'Applies today only.'**
  String get appliesTodayOnly;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @feelingUnwellToday.
  ///
  /// In en, this message translates to:
  /// **'Feeling unwell today?'**
  String get feelingUnwellToday;

  /// No description provided for @bodyMetricsOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional, local-only measurements can improve Hydrion\'s general wellness estimate. You can skip, disable, or delete them at any time.'**
  String get bodyMetricsOptional;

  /// No description provided for @enablePersonalization.
  ///
  /// In en, this message translates to:
  /// **'Enable personalized body metrics'**
  String get enablePersonalization;

  /// No description provided for @personalizedBaselineOption.
  ///
  /// In en, this message translates to:
  /// **'Use a personalized baseline'**
  String get personalizedBaselineOption;

  /// No description provided for @personalizedBaselineHelp.
  ///
  /// In en, this message translates to:
  /// **'Hydrion will calculate a suggestion for you to review. Your existing goal is not replaced until you apply it.'**
  String get personalizedBaselineHelp;

  /// No description provided for @weatherModifierOption.
  ///
  /// In en, this message translates to:
  /// **'Use optional weather adjustments'**
  String get weatherModifierOption;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// No description provided for @kilogramsLabel.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kilogramsLabel;

  /// No description provided for @poundsLabel.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get poundsLabel;

  /// No description provided for @centimetresLabel.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get centimetresLabel;

  /// No description provided for @feetInchesLabel.
  ///
  /// In en, this message translates to:
  /// **'ft and in'**
  String get feetInchesLabel;

  /// No description provided for @feetLabel.
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get feetLabel;

  /// No description provided for @inchesLabel.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inchesLabel;

  /// No description provided for @accessibleNumericEntry.
  ///
  /// In en, this message translates to:
  /// **'Accessible numeric entry'**
  String get accessibleNumericEntry;

  /// No description provided for @reproductiveHydrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy or lactation'**
  String get reproductiveHydrationTitle;

  /// No description provided for @reproductiveNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get reproductiveNone;

  /// No description provided for @reproductivePregnant.
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get reproductivePregnant;

  /// No description provided for @reproductiveLactating.
  ///
  /// In en, this message translates to:
  /// **'Lactating'**
  String get reproductiveLactating;

  /// No description provided for @bmiTitle.
  ///
  /// In en, this message translates to:
  /// **'BMI screening estimate'**
  String get bmiTitle;

  /// No description provided for @bmiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'BMI is a screening estimate based on height and weight. It does not diagnose health conditions or measure body composition.'**
  String get bmiDisclaimer;

  /// No description provided for @bmiUnderTwenty.
  ///
  /// In en, this message translates to:
  /// **'Hydrion does not interpret adult BMI categories for people younger than 20.'**
  String get bmiUnderTwenty;

  /// No description provided for @bmiBelowRange.
  ///
  /// In en, this message translates to:
  /// **'Below standard adult range'**
  String get bmiBelowRange;

  /// No description provided for @bmiStandardRange.
  ///
  /// In en, this message translates to:
  /// **'Standard adult screening range'**
  String get bmiStandardRange;

  /// No description provided for @bmiAboveRange.
  ///
  /// In en, this message translates to:
  /// **'Above standard adult range'**
  String get bmiAboveRange;

  /// No description provided for @bmiHigherRange.
  ///
  /// In en, this message translates to:
  /// **'Higher adult screening range'**
  String get bmiHigherRange;

  /// No description provided for @fluidSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Fluid-safety setting'**
  String get fluidSafetyTitle;

  /// No description provided for @fluidSafetyNone.
  ///
  /// In en, this message translates to:
  /// **'No restriction reported'**
  String get fluidSafetyNone;

  /// No description provided for @fluidSafetyClinician.
  ///
  /// In en, this message translates to:
  /// **'I have a clinician-set target'**
  String get fluidSafetyClinician;

  /// No description provided for @fluidSafetyRestriction.
  ///
  /// In en, this message translates to:
  /// **'I have a fluid restriction without a target'**
  String get fluidSafetyRestriction;

  /// No description provided for @fluidSafetyUnsure.
  ///
  /// In en, this message translates to:
  /// **'I am unsure'**
  String get fluidSafetyUnsure;

  /// No description provided for @clinicianTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinician target in mL'**
  String get clinicianTargetLabel;

  /// No description provided for @allowAboveClinicianTarget.
  ///
  /// In en, this message translates to:
  /// **'Allow optional adjustments above this target'**
  String get allowAboveClinicianTarget;

  /// No description provided for @saveBodyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Save body metrics'**
  String get saveBodyMetrics;

  /// No description provided for @deleteBodyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Delete body metrics'**
  String get deleteBodyMetrics;

  /// No description provided for @bodyMetricsSaved.
  ///
  /// In en, this message translates to:
  /// **'Body metrics saved locally.'**
  String get bodyMetricsSaved;

  /// No description provided for @bodyMetricsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose measurements within the displayed safe input range.'**
  String get bodyMetricsInvalid;

  /// No description provided for @bodyMetricsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Body metrics deleted.'**
  String get bodyMetricsDeleted;

  /// No description provided for @profileDeletionPersonalizationDisclosure.
  ///
  /// In en, this message translates to:
  /// **'This clears your local profile, body metrics, daily contexts, hydration history, reminders, challenges, recommendation state, weather cache, imported wearable records and derived wearable context on this device. Health-provider records are unchanged. Your language and appearance preferences remain saved.'**
  String get profileDeletionPersonalizationDisclosure;

  /// No description provided for @dailyContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s context'**
  String get dailyContextTitle;

  /// No description provided for @dailyContextOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional activity and outdoor context adjusts only today\'s suggestion.'**
  String get dailyContextOptional;

  /// No description provided for @activityIntensityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity intensity'**
  String get activityIntensityLabel;

  /// No description provided for @activityMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity minutes'**
  String get activityMinutesLabel;

  /// No description provided for @environmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentLabel;

  /// No description provided for @sweatLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Sweat level'**
  String get sweatLevelLabel;

  /// No description provided for @temporaryConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Temporary condition'**
  String get temporaryConditionLabel;

  /// No description provided for @activityRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get activityRest;

  /// No description provided for @activityLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get activityLight;

  /// No description provided for @activityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get activityModerate;

  /// No description provided for @activityVigorous.
  ///
  /// In en, this message translates to:
  /// **'Vigorous'**
  String get activityVigorous;

  /// No description provided for @environmentIndoors.
  ///
  /// In en, this message translates to:
  /// **'Mostly indoors'**
  String get environmentIndoors;

  /// No description provided for @environmentMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed indoor and outdoor'**
  String get environmentMixed;

  /// No description provided for @environmentOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Mostly outdoors'**
  String get environmentOutdoors;

  /// No description provided for @sweatLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get sweatLow;

  /// No description provided for @sweatModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get sweatModerate;

  /// No description provided for @sweatHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get sweatHigh;

  /// No description provided for @sweatUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get sweatUnknown;

  /// No description provided for @conditionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get conditionNone;

  /// No description provided for @conditionFever.
  ///
  /// In en, this message translates to:
  /// **'Fever'**
  String get conditionFever;

  /// No description provided for @conditionStomachIllness.
  ///
  /// In en, this message translates to:
  /// **'Vomiting or diarrhea'**
  String get conditionStomachIllness;

  /// No description provided for @conditionRecovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get conditionRecovering;

  /// No description provided for @conditionPreferNot.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get conditionPreferNot;

  /// No description provided for @saveDailyContext.
  ///
  /// In en, this message translates to:
  /// **'Save today\'s context'**
  String get saveDailyContext;

  /// No description provided for @clearDailyContext.
  ///
  /// In en, this message translates to:
  /// **'Clear today\'s context'**
  String get clearDailyContext;

  /// No description provided for @hydrationSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalized hydration suggestion'**
  String get hydrationSuggestionTitle;

  /// No description provided for @baselineLabel.
  ///
  /// In en, this message translates to:
  /// **'Baseline'**
  String get baselineLabel;

  /// No description provided for @adjustmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get adjustmentsLabel;

  /// No description provided for @weatherAdjustmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Weather adjustment'**
  String get weatherAdjustmentLabel;

  /// No description provided for @activityAdjustmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity adjustment'**
  String get activityAdjustmentLabel;

  /// No description provided for @reproductiveAdjustmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy or lactation adjustment'**
  String get reproductiveAdjustmentLabel;

  /// No description provided for @personalizedSuggestionAccepted.
  ///
  /// In en, this message translates to:
  /// **'Personalized daily suggestion accepted after review.'**
  String get personalizedSuggestionAccepted;

  /// No description provided for @keepCurrentGoal.
  ///
  /// In en, this message translates to:
  /// **'Keep current goal'**
  String get keepCurrentGoal;

  /// No description provided for @applySuggestedGoal.
  ///
  /// In en, this message translates to:
  /// **'Apply suggested goal'**
  String get applySuggestedGoal;

  /// No description provided for @suggestedGoalApplied.
  ///
  /// In en, this message translates to:
  /// **'Suggested goal applied.'**
  String get suggestedGoalApplied;

  /// No description provided for @dailyContextSaved.
  ///
  /// In en, this message translates to:
  /// **'Today\'s context saved.'**
  String get dailyContextSaved;

  /// No description provided for @reviewSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Review suggestion'**
  String get reviewSuggestion;

  /// No description provided for @generalWellnessNotice.
  ///
  /// In en, this message translates to:
  /// **'This is a general wellness estimate, not medical advice. Do not force fluids.'**
  String get generalWellnessNotice;

  /// No description provided for @illnessSafetyNotice.
  ///
  /// In en, this message translates to:
  /// **'Fluid needs can change during illness. Keep your regular recommendation and seek professional guidance for significant symptoms.'**
  String get illnessSafetyNotice;

  /// No description provided for @restrictionSafetyNotice.
  ///
  /// In en, this message translates to:
  /// **'Hydrion will not automatically increase your goal while a fluid restriction is reported. Follow professional guidance.'**
  String get restrictionSafetyNotice;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @viewChallenge.
  ///
  /// In en, this message translates to:
  /// **'View challenge'**
  String get viewChallenge;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @noAutomaticChallenge.
  ///
  /// In en, this message translates to:
  /// **'Recommendations never start a challenge. You decide whether to review and join.'**
  String get noAutomaticChallenge;

  /// No description provided for @tailorChallengeSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Tailor challenge suggestions'**
  String get tailorChallengeSuggestions;

  /// No description provided for @challengeSuggestionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Choose the kinds of routines you would like Hydrion to consider. These choices stay on this device and never start a challenge automatically.'**
  String get challengeSuggestionPrivacy;

  /// No description provided for @timedFocusSipRoutines.
  ///
  /// In en, this message translates to:
  /// **'Timed focus and sip routines'**
  String get timedFocusSipRoutines;

  /// No description provided for @waterRichFoodHabits.
  ///
  /// In en, this message translates to:
  /// **'Water-rich food habits'**
  String get waterRichFoodHabits;

  /// No description provided for @visualDailyConsistency.
  ///
  /// In en, this message translates to:
  /// **'Visual daily consistency'**
  String get visualDailyConsistency;

  /// No description provided for @infusionFlavorVariety.
  ///
  /// In en, this message translates to:
  /// **'Infusion and flavor variety'**
  String get infusionFlavorVariety;

  /// No description provided for @recommendationWarmWeather.
  ///
  /// In en, this message translates to:
  /// **'Today\'s warm conditions make this challenge a useful match.'**
  String get recommendationWarmWeather;

  /// No description provided for @recommendationTimedRoutine.
  ///
  /// In en, this message translates to:
  /// **'Matches your preference for timed focus and sip routines.'**
  String get recommendationTimedRoutine;

  /// No description provided for @recommendationLoggingConsistency.
  ///
  /// In en, this message translates to:
  /// **'A varied logging challenge may help you build consistency.'**
  String get recommendationLoggingConsistency;

  /// No description provided for @recommendationWaterRichFood.
  ///
  /// In en, this message translates to:
  /// **'Matches your interest in adding water-rich foods to your routine.'**
  String get recommendationWaterRichFood;

  /// No description provided for @recommendationVisualConsistency.
  ///
  /// In en, this message translates to:
  /// **'Matches your preference for visual daily consistency.'**
  String get recommendationVisualConsistency;

  /// No description provided for @recommendationInfusionVariety.
  ///
  /// In en, this message translates to:
  /// **'Matches your interest in infusion and flavor variety.'**
  String get recommendationInfusionVariety;

  /// No description provided for @pregnancyDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'How far along are you?'**
  String get pregnancyDurationTitle;

  /// No description provided for @pregnancyDurationDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get pregnancyDurationDays;

  /// No description provided for @pregnancyDurationWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get pregnancyDurationWeeks;

  /// No description provided for @pregnancyDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get pregnancyDurationMonths;

  /// No description provided for @pregnancyDurationInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy duration'**
  String get pregnancyDurationInputLabel;

  /// No description provided for @pregnancyDurationHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter a pregnancy duration between 1 day and 42 weeks.'**
  String get pregnancyDurationHelp;

  /// No description provided for @pregnancyDurationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid pregnancy duration between 1 day and 42 weeks.'**
  String get pregnancyDurationInvalid;

  /// No description provided for @pregnancyDurationMonthsHelp.
  ///
  /// In en, this message translates to:
  /// **'Months are converted approximately and stored locally.'**
  String get pregnancyDurationMonthsHelp;

  /// No description provided for @pregnancyDurationSummary.
  ///
  /// In en, this message translates to:
  /// **'Approximately {weeks} weeks, {days} days.'**
  String pregnancyDurationSummary({required int weeks, required int days});

  /// No description provided for @missionTitle.
  ///
  /// In en, this message translates to:
  /// **'Why Hydrion exists'**
  String get missionTitle;

  /// No description provided for @missionSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Hydrion mission'**
  String get missionSemanticLabel;

  /// No description provided for @missionHeadline.
  ///
  /// In en, this message translates to:
  /// **'Hydration should be easier to understand and easier to manage.'**
  String get missionHeadline;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @missionDetails.
  ///
  /// In en, this message translates to:
  /// **'Hydrion supports safer, more consistent habits while keeping personal information local and under your control. Community participation may be offered later through Discord, an external service with separate account and privacy practices. Hydrion will not send profile or health information automatically.'**
  String get missionDetails;

  /// No description provided for @communityComingLater.
  ///
  /// In en, this message translates to:
  /// **'Community link coming later'**
  String get communityComingLater;

  /// No description provided for @continueToTutorial.
  ///
  /// In en, this message translates to:
  /// **'Continue to tutorial'**
  String get continueToTutorial;

  /// No description provided for @profileDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile deleted'**
  String get profileDeletedTitle;

  /// No description provided for @profileDeletionCompletedSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Local profile deletion completed'**
  String get profileDeletionCompletedSemanticLabel;

  /// No description provided for @profileDeletedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your Hydrion profile has been deleted'**
  String get profileDeletedHeadline;

  /// No description provided for @profileDeletedFarewell.
  ///
  /// In en, this message translates to:
  /// **'Wherever your hydration journey continues, please take care, stay hydrated, and share what you have learned with someone who may benefit.'**
  String get profileDeletedFarewell;

  /// No description provided for @learnAboutMission.
  ///
  /// In en, this message translates to:
  /// **'Learn about Hydrion\'s mission'**
  String get learnAboutMission;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @deleteLocalProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete local profile'**
  String get deleteLocalProfile;

  /// No description provided for @deleteLocalProfileSummary.
  ///
  /// In en, this message translates to:
  /// **'Removes profile-owned Hydrion data while preserving language and appearance preferences.'**
  String get deleteLocalProfileSummary;

  /// No description provided for @deleteLocalProfileQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete local profile?'**
  String get deleteLocalProfileQuestion;

  /// No description provided for @removeDevicePermissions.
  ///
  /// In en, this message translates to:
  /// **'Also remove Hydrion device permissions'**
  String get removeDevicePermissions;

  /// No description provided for @removeDevicePermissionsHelp.
  ///
  /// In en, this message translates to:
  /// **'Android 13 and newer can schedule removal of notification and location permissions after you finish the farewell. Exact-alarm and other special access remain controlled in system settings.'**
  String get removeDevicePermissionsHelp;

  /// No description provided for @reviewPermissions.
  ///
  /// In en, this message translates to:
  /// **'Review permissions'**
  String get reviewPermissions;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @profileDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile could not be deleted. Close Hydrion, reopen it, and try again.'**
  String get profileDeletionFailed;

  /// No description provided for @profileDeletionCleanupPending.
  ///
  /// In en, this message translates to:
  /// **'Profile deleted. Android reminder cleanup will retry automatically.'**
  String get profileDeletionCleanupPending;

  /// No description provided for @weatherSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weather hydration suggestion'**
  String get weatherSuggestionTitle;

  /// No description provided for @humidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityLabel;

  /// No description provided for @standardGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard goal'**
  String get standardGoalLabel;

  /// No description provided for @todaySuggestedGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s suggested goal'**
  String get todaySuggestedGoalLabel;

  /// No description provided for @updatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedLabel;

  /// No description provided for @weatherSuggestionDisclosure.
  ///
  /// In en, this message translates to:
  /// **'This suggestion uses your saved profile, location permission, and local weather. It is not medical advice.'**
  String get weatherSuggestionDisclosure;

  /// No description provided for @keepStandardGoal.
  ///
  /// In en, this message translates to:
  /// **'Keep standard goal'**
  String get keepStandardGoal;

  /// No description provided for @useSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Use suggestion'**
  String get useSuggestion;

  /// No description provided for @pomodoroSessionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro session'**
  String get pomodoroSessionNotificationTitle;

  /// No description provided for @homeworkSessionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework session'**
  String get homeworkSessionNotificationTitle;

  /// No description provided for @sessionPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get sessionPaused;

  /// No description provided for @pauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseAction;

  /// No description provided for @resumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeAction;

  /// No description provided for @stopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopAction;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @waterNotLoggedRetry.
  ///
  /// In en, this message translates to:
  /// **'Water was not logged. Please retry.'**
  String get waterNotLoggedRetry;

  /// No description provided for @loggedFormattedVolume.
  ///
  /// In en, this message translates to:
  /// **'Logged {amount}'**
  String loggedFormattedVolume({required String amount});

  /// No description provided for @dailyGoalReachedRecognition.
  ///
  /// In en, this message translates to:
  /// **'Daily goal reached. Nicely done.'**
  String get dailyGoalReachedRecognition;

  /// No description provided for @sevenDayStreakRecognition.
  ///
  /// In en, this message translates to:
  /// **'Seven-day hydration streak. A steady routine is taking shape.'**
  String get sevenDayStreakRecognition;

  /// No description provided for @profileMenu.
  ///
  /// In en, this message translates to:
  /// **'Profile menu'**
  String get profileMenu;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @addChallengeDetails.
  ///
  /// In en, this message translates to:
  /// **'Add challenge details'**
  String get addChallengeDetails;

  /// No description provided for @challengeDetailsAdded.
  ///
  /// In en, this message translates to:
  /// **'Challenge details added'**
  String get challengeDetailsAdded;

  /// No description provided for @challengeDetailsHelp.
  ///
  /// In en, this message translates to:
  /// **'All water counts toward your daily goal. Challenge details record what today\'s task needs.'**
  String get challengeDetailsHelp;

  /// No description provided for @challengeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge details'**
  String get challengeDetailsTitle;

  /// No description provided for @temperatureStyle.
  ///
  /// In en, this message translates to:
  /// **'Temperature style'**
  String get temperatureStyle;

  /// No description provided for @temperatureCool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get temperatureCool;

  /// No description provided for @temperatureRoom.
  ///
  /// In en, this message translates to:
  /// **'Room temperature'**
  String get temperatureRoom;

  /// No description provided for @temperatureWarm.
  ///
  /// In en, this message translates to:
  /// **'Comfortably warm'**
  String get temperatureWarm;

  /// No description provided for @infusionTheme.
  ///
  /// In en, this message translates to:
  /// **'Infusion theme'**
  String get infusionTheme;

  /// No description provided for @noAddedSugar.
  ///
  /// In en, this message translates to:
  /// **'No added sugar'**
  String get noAddedSugar;

  /// No description provided for @useDetails.
  ///
  /// In en, this message translates to:
  /// **'Use details'**
  String get useDetails;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @customAmount.
  ///
  /// In en, this message translates to:
  /// **'Custom amount'**
  String get customAmount;

  /// No description provided for @momentum.
  ///
  /// In en, this message translates to:
  /// **'Momentum'**
  String get momentum;

  /// No description provided for @applySuggestedGoalQuestion.
  ///
  /// In en, this message translates to:
  /// **'Apply suggested goal?'**
  String get applySuggestedGoalQuestion;

  /// No description provided for @applySuggestedGoalConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Apply this suggested daily goal and continue?'**
  String get applySuggestedGoalConfirmation;

  /// No description provided for @refineInputs.
  ///
  /// In en, this message translates to:
  /// **'No, refine inputs'**
  String get refineInputs;

  /// No description provided for @confirmApply.
  ///
  /// In en, this message translates to:
  /// **'Yes, apply'**
  String get confirmApply;

  /// No description provided for @enterMeasurementsWithKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Enter measurements with the keyboard'**
  String get enterMeasurementsWithKeyboard;

  /// No description provided for @recalculatedAt.
  ///
  /// In en, this message translates to:
  /// **'Recalculated {date}'**
  String recalculatedAt({required String date});

  /// No description provided for @volumeMlValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} mL'**
  String volumeMlValue({required int amount});

  /// No description provided for @baselineMlValue.
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount} mL'**
  String baselineMlValue({required String label, required int amount});

  /// No description provided for @routineFitsDay.
  ///
  /// In en, this message translates to:
  /// **'A routine that fits your day'**
  String get routineFitsDay;

  /// No description provided for @routineFitsDayBody.
  ///
  /// In en, this message translates to:
  /// **'Keep logging the water you actually drink. Small check-ins build a useful daily picture.'**
  String get routineFitsDayBody;

  /// No description provided for @amountLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String amountLeft({required String amount});

  /// No description provided for @weatherAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Weather-adjusted'**
  String get weatherAdjusted;

  /// No description provided for @noReusableContainerSaved.
  ///
  /// In en, this message translates to:
  /// **'No reusable container saved. Add one in Settings to use it here and in Bottle Bingo.'**
  String get noReusableContainerSaved;

  /// No description provided for @savedContainerHelp.
  ///
  /// In en, this message translates to:
  /// **'Saved container: {amount}. Select it here to use the same amount as Bottle Bingo.'**
  String savedContainerHelp({required String amount});

  /// No description provided for @firstLogWaiting.
  ///
  /// In en, this message translates to:
  /// **'First log waiting'**
  String get firstLogWaiting;

  /// No description provided for @momentumEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'One small entry gives the day a shape.'**
  String get momentumEmptyBody;

  /// No description provided for @momentumDataBody.
  ///
  /// In en, this message translates to:
  /// **'Your shark has real data to react to.'**
  String get momentumDataBody;

  /// No description provided for @challengePick.
  ///
  /// In en, this message translates to:
  /// **'Challenge pick'**
  String get challengePick;

  /// No description provided for @activeChallenge.
  ///
  /// In en, this message translates to:
  /// **'Active challenge'**
  String get activeChallenge;

  /// No description provided for @bottleBingoReady.
  ///
  /// In en, this message translates to:
  /// **'Bottle Bingo is ready when you want a playful routine.'**
  String get bottleBingoReady;

  /// No description provided for @activeChallengeGentle.
  ///
  /// In en, this message translates to:
  /// **'Keep today gentle; progress comes from normal logs.'**
  String get activeChallengeGentle;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @logHistory.
  ///
  /// In en, this message translates to:
  /// **'Log history'**
  String get logHistory;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String greetingMorning({required String name});

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String greetingAfternoon({required String name});

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String greetingEvening({required String name});

  /// No description provided for @greetingFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get greetingFallbackName;

  /// No description provided for @recentLogCounted.
  ///
  /// In en, this message translates to:
  /// **'Your recent {amount} log is counted. Give your routine time before deciding what comes next.'**
  String recentLogCounted({required String amount});

  /// No description provided for @noWaterLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'No water is logged yet today. Add what you have actually consumed when you are ready.'**
  String get noWaterLoggedToday;

  /// No description provided for @todayLogSummary.
  ///
  /// In en, this message translates to:
  /// **'You have {count, plural, =1{1 log} other{{count} logs}} today. About {remaining} remains.'**
  String todayLogSummary({required int count, required String remaining});

  /// No description provided for @todayLogSummaryWithContainer.
  ///
  /// In en, this message translates to:
  /// **'You have {count, plural, =1{1 log} other{{count} logs}} today. About {remaining} remains; your {container} container is available as a quick-log amount.'**
  String todayLogSummaryWithContainer(
      {required int count,
      required String remaining,
      required String container});

  /// No description provided for @goalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Goal completed'**
  String get goalCompleted;

  /// No description provided for @noHydrationLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'No hydration logged today'**
  String get noHydrationLoggedToday;

  /// No description provided for @todaysHydration.
  ///
  /// In en, this message translates to:
  /// **'Today\'s hydration'**
  String get todaysHydration;

  /// No description provided for @onboardingNicknameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname up to 32 characters.'**
  String get onboardingNicknameInvalid;

  /// No description provided for @onboardingAgeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Hydrion independent profiles require an age from 13 to 120.'**
  String get onboardingAgeInvalid;

  /// No description provided for @onboardingTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Accept the Terms and acknowledge the health disclaimer to continue.'**
  String get onboardingTermsRequired;

  /// No description provided for @onboardingGoalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check your goal and container size before continuing.'**
  String get onboardingGoalInvalid;

  /// No description provided for @onboardingCompleteRecognition.
  ///
  /// In en, this message translates to:
  /// **'Your Hydrion setup is complete.'**
  String get onboardingCompleteRecognition;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Hydrion'**
  String get onboardingWelcome;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @onboardingLocalFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydrion keeps hydration local-first'**
  String get onboardingLocalFirstTitle;

  /// No description provided for @onboardingMascotSemantics.
  ///
  /// In en, this message translates to:
  /// **'Hydrion mascot'**
  String get onboardingMascotSemantics;

  /// No description provided for @onboardingLocalFirstBody.
  ///
  /// In en, this message translates to:
  /// **'Track water, goals, reminders, and solo challenges on this device. Optional provider features stay off until you choose them.'**
  String get onboardingLocalFirstBody;

  /// No description provided for @onboardingBasicProfile.
  ///
  /// In en, this message translates to:
  /// **'Basic profile'**
  String get onboardingBasicProfile;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @requiredSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Required, saved locally.'**
  String get requiredSavedLocally;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @ageOptionalHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Used only for personalized guidance.'**
  String get ageOptionalHelp;

  /// No description provided for @sexGuidanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Sex used for hydration guidance'**
  String get sexGuidanceLabel;

  /// No description provided for @sexOptionalHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Choose prefer not to say at any time.'**
  String get sexOptionalHelp;

  /// No description provided for @onboardingProfileNeededForMetrics.
  ///
  /// In en, this message translates to:
  /// **'Save a nickname and supported age before adding body metrics.'**
  String get onboardingProfileNeededForMetrics;

  /// No description provided for @chooseDefaultAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose your default avatar'**
  String get chooseDefaultAvatar;

  /// No description provided for @goalMode.
  ///
  /// In en, this message translates to:
  /// **'Goal mode'**
  String get goalMode;

  /// No description provided for @standardOrManual.
  ///
  /// In en, this message translates to:
  /// **'Standard or manual'**
  String get standardOrManual;

  /// No description provided for @personalizedEstimate.
  ///
  /// In en, this message translates to:
  /// **'Personalized estimate'**
  String get personalizedEstimate;

  /// No description provided for @standardGoalModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the standard target or enter your own target.'**
  String get standardGoalModeHelp;

  /// No description provided for @personalizedGoalModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Use locally saved body measurements to calculate a general wellness estimate.'**
  String get personalizedGoalModeHelp;

  /// No description provided for @weatherBaselineHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional weather assistance is selected separately and never replaces your baseline.'**
  String get weatherBaselineHelp;

  /// No description provided for @hydrationSetup.
  ///
  /// In en, this message translates to:
  /// **'Hydration setup'**
  String get hydrationSetup;

  /// No description provided for @dailyGoalMlLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily goal in ml'**
  String get dailyGoalMlLabel;

  /// No description provided for @dailyGoalSupportedRange.
  ///
  /// In en, this message translates to:
  /// **'Supported range: 500-5000 ml.'**
  String get dailyGoalSupportedRange;

  /// No description provided for @displayUnit.
  ///
  /// In en, this message translates to:
  /// **'Display unit'**
  String get displayUnit;

  /// No description provided for @milliliters.
  ///
  /// In en, this message translates to:
  /// **'Milliliters'**
  String get milliliters;

  /// No description provided for @ounces.
  ///
  /// In en, this message translates to:
  /// **'Ounces'**
  String get ounces;

  /// No description provided for @containerSizeMlLabel.
  ///
  /// In en, this message translates to:
  /// **'Usual container size in ml'**
  String get containerSizeMlLabel;

  /// No description provided for @containerSupportedRange.
  ///
  /// In en, this message translates to:
  /// **'Supported range: 100-2000 ml.'**
  String get containerSupportedRange;

  /// No description provided for @usuallyReusable.
  ///
  /// In en, this message translates to:
  /// **'Usually reusable'**
  String get usuallyReusable;

  /// No description provided for @reusableHelp.
  ///
  /// In en, this message translates to:
  /// **'Only enable this if most logged drinks use a reusable bottle or cup.'**
  String get reusableHelp;

  /// No description provided for @optionalDeviceFeatures.
  ///
  /// In en, this message translates to:
  /// **'Optional device features'**
  String get optionalDeviceFeatures;

  /// No description provided for @reviewBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Review before you start'**
  String get reviewBeforeStart;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @onboardingReadySemantics.
  ///
  /// In en, this message translates to:
  /// **'Onboarding ready'**
  String get onboardingReadySemantics;

  /// No description provided for @onboardingSummary.
  ///
  /// In en, this message translates to:
  /// **'Hydrion will start with {name}, {avatar}, {goal} ml/day, and local-first tracking.'**
  String onboardingSummary(
      {required String name, required String avatar, required String goal});

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'your profile'**
  String get yourProfile;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexIntersex.
  ///
  /// In en, this message translates to:
  /// **'Intersex'**
  String get sexIntersex;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @hydrationReminders.
  ///
  /// In en, this message translates to:
  /// **'Hydration reminders'**
  String get hydrationReminders;

  /// No description provided for @remindersCapabilityHelp.
  ///
  /// In en, this message translates to:
  /// **'Hydrion can send local reminders on this device. You can enable them now or later.'**
  String get remindersCapabilityHelp;

  /// No description provided for @remindersNotNowHelp.
  ///
  /// In en, this message translates to:
  /// **'Not now - reminders can be enabled in Settings.'**
  String get remindersNotNowHelp;

  /// No description provided for @enableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get enableReminders;

  /// No description provided for @weatherAssistance.
  ///
  /// In en, this message translates to:
  /// **'Weather assistance'**
  String get weatherAssistance;

  /// No description provided for @weatherCapabilityHelp.
  ///
  /// In en, this message translates to:
  /// **'Hydrion can use approximate location to retrieve local weather and offer a temporary hydration suggestion. Your standard goal still works without it.'**
  String get weatherCapabilityHelp;

  /// No description provided for @weatherNotNowHelp.
  ///
  /// In en, this message translates to:
  /// **'Not now - your standard hydration goal remains active.'**
  String get weatherNotNowHelp;

  /// No description provided for @enableWeatherAssistance.
  ///
  /// In en, this message translates to:
  /// **'Enable weather assistance'**
  String get enableWeatherAssistance;

  /// No description provided for @waitingForDevice.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the device result...'**
  String get waitingForDevice;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @capabilityEnabled.
  ///
  /// In en, this message translates to:
  /// **'{title}: Enabled'**
  String capabilityEnabled({required String title});

  /// No description provided for @capabilityStatus.
  ///
  /// In en, this message translates to:
  /// **'{title}: {status}'**
  String capabilityStatus({required String title, required String status});

  /// No description provided for @avatarSelectedSemantics.
  ///
  /// In en, this message translates to:
  /// **'{avatar} avatar selected'**
  String avatarSelectedSemantics({required String avatar});

  /// No description provided for @selectAvatarSemantics.
  ///
  /// In en, this message translates to:
  /// **'Select {avatar} avatar'**
  String selectAvatarSemantics({required String avatar});

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @tourStepSemantics.
  ///
  /// In en, this message translates to:
  /// **'{tour} step {current} of {total}'**
  String tourStepSemantics(
      {required String tour, required int current, required int total});

  /// No description provided for @achievementSemantics.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achievementSemantics;

  /// No description provided for @noCheckInsYet.
  ///
  /// In en, this message translates to:
  /// **'No check-ins yet.'**
  String get noCheckInsYet;

  /// No description provided for @coachPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachPreviewTitle;

  /// No description provided for @coachPreviewComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Hydrion Coach is being prepared for a future update.'**
  String get coachPreviewComingSoon;

  /// No description provided for @coachPreviewGuidance.
  ///
  /// In en, this message translates to:
  /// **'For now, keep logging water and tracking your daily progress.'**
  String get coachPreviewGuidance;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydrion reminder'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Hydration reminders'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Local reminders for user-created Hydrion hydration check-ins.'**
  String get reminderChannelDescription;

  /// No description provided for @challengeAroundWorldTitle.
  ///
  /// In en, this message translates to:
  /// **'Around the World Infusion Week'**
  String get challengeAroundWorldTitle;

  /// No description provided for @challengeAroundWorldDescription.
  ///
  /// In en, this message translates to:
  /// **'Try seven no-added-sugar infusion themes while maintaining your normal hydration goal.'**
  String get challengeAroundWorldDescription;

  /// No description provided for @challengeTemperatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Temperature Roulette'**
  String get challengeTemperatureTitle;

  /// No description provided for @challengeTemperatureDescription.
  ///
  /// In en, this message translates to:
  /// **'Compare comfortable water temperatures as a preference experiment.'**
  String get challengeTemperatureDescription;

  /// No description provided for @challengeEatWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Eat Your Water Day'**
  String get challengeEatWaterTitle;

  /// No description provided for @challengeEatWaterDescription.
  ///
  /// In en, this message translates to:
  /// **'Include one selected water-rich food in a meal without inventing hydration volume.'**
  String get challengeEatWaterDescription;

  /// No description provided for @challengePomodoroTitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Sip'**
  String get challengePomodoroTitle;

  /// No description provided for @challengePomodoroDescription.
  ///
  /// In en, this message translates to:
  /// **'Pair modest hydration check-ins with manually confirmed focus-session breaks.'**
  String get challengePomodoroDescription;

  /// No description provided for @challengePlantTwinTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant Twin Challenge'**
  String get challengePlantTwinTitle;

  /// No description provided for @challengePlantTwinDescription.
  ///
  /// In en, this message translates to:
  /// **'Use one plant-care cue as a reminder to review your hydration routine.'**
  String get challengePlantTwinDescription;

  /// No description provided for @challengeBottleBingoTitle.
  ///
  /// In en, this message translates to:
  /// **'Bottle Bingo'**
  String get challengeBottleBingoTitle;

  /// No description provided for @challengeBottleBingoDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete a weekly mix of explicit hydration actions and non-hydration check-ins.'**
  String get challengeBottleBingoDescription;

  /// No description provided for @challengeLunchRefillTitle.
  ///
  /// In en, this message translates to:
  /// **'Lunch Break Refill'**
  String get challengeLunchRefillTitle;

  /// No description provided for @challengeLunchRefillDescription.
  ///
  /// In en, this message translates to:
  /// **'Use a lunch break to check and refill your bottle when useful.'**
  String get challengeLunchRefillDescription;

  /// No description provided for @challengeHomeworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework Hydration'**
  String get challengeHomeworkTitle;

  /// No description provided for @challengeHomeworkDescription.
  ///
  /// In en, this message translates to:
  /// **'Pair a comfortable hydration check with a study break.'**
  String get challengeHomeworkDescription;

  /// No description provided for @challengeAfterSchoolTitle.
  ///
  /// In en, this message translates to:
  /// **'After-School Recharge'**
  String get challengeAfterSchoolTitle;

  /// No description provided for @challengeAfterSchoolDescription.
  ///
  /// In en, this message translates to:
  /// **'Pause after your daytime routine and review your hydration.'**
  String get challengeAfterSchoolDescription;

  /// No description provided for @challengeBackpackTitle.
  ///
  /// In en, this message translates to:
  /// **'Backpack Bottle Check'**
  String get challengeBackpackTitle;

  /// No description provided for @challengeBackpackDescription.
  ///
  /// In en, this message translates to:
  /// **'Use a packing cue to prepare a reusable bottle.'**
  String get challengeBackpackDescription;

  /// No description provided for @challengeDeskResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Desk-Day Reset'**
  String get challengeDeskResetTitle;

  /// No description provided for @challengeDeskResetDescription.
  ///
  /// In en, this message translates to:
  /// **'Use an optional seated break to review your hydration.'**
  String get challengeDeskResetDescription;

  /// No description provided for @challengeShiftCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Shift Hydration Check'**
  String get challengeShiftCheckTitle;

  /// No description provided for @challengeShiftCheckDescription.
  ///
  /// In en, this message translates to:
  /// **'Add an optional hydration check midway through a work period.'**
  String get challengeShiftCheckDescription;

  /// No description provided for @challengeCommuteCupTitle.
  ///
  /// In en, this message translates to:
  /// **'Commute Cup'**
  String get challengeCommuteCupTitle;

  /// No description provided for @challengeCommuteCupDescription.
  ///
  /// In en, this message translates to:
  /// **'Use departure or arrival as an optional hydration cue.'**
  String get challengeCommuteCupDescription;

  /// No description provided for @challengeEveningReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening Goal Review'**
  String get challengeEveningReviewTitle;

  /// No description provided for @challengeEveningReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Review your day and decide whether your plan still feels right.'**
  String get challengeEveningReviewDescription;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @aboutAndLegal.
  ///
  /// In en, this message translates to:
  /// **'About & Legal'**
  String get aboutAndLegal;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @openSourceLicensesSummary.
  ///
  /// In en, this message translates to:
  /// **'Flutter and package license notices.'**
  String get openSourceLicensesSummary;

  /// No description provided for @openSourceLegalese.
  ///
  /// In en, this message translates to:
  /// **'Hydrion uses open-source components under their licenses.'**
  String get openSourceLegalese;

  /// No description provided for @legalDocument.
  ///
  /// In en, this message translates to:
  /// **'Legal document'**
  String get legalDocument;

  /// No description provided for @reviewHydrionTerms.
  ///
  /// In en, this message translates to:
  /// **'Review Hydrion terms'**
  String get reviewHydrionTerms;

  /// No description provided for @continueToHydrion.
  ///
  /// In en, this message translates to:
  /// **'Continue to Hydrion'**
  String get continueToHydrion;

  /// No description provided for @acceptHydrionTerms.
  ///
  /// In en, this message translates to:
  /// **'I accept the Hydrion Terms of Use.'**
  String get acceptHydrionTerms;

  /// No description provided for @acknowledgeHealthDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'I acknowledge the Health and Safety Disclaimer.'**
  String get acknowledgeHealthDisclaimer;

  /// No description provided for @supportEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Support email copied.'**
  String get supportEmailCopied;

  /// No description provided for @documentVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String documentVersion({required Object version});

  /// No description provided for @documentEffective.
  ///
  /// In en, this message translates to:
  /// **'Effective {date}'**
  String documentEffective({required Object date});

  /// No description provided for @documentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String documentUpdated({required Object date});

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @pausedChallengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedChallengesTitle;

  /// No description provided for @pausedChallengeSummary.
  ///
  /// In en, this message translates to:
  /// **'Progress saved. New logs are not evaluated.'**
  String get pausedChallengeSummary;

  /// No description provided for @weatherConditionTemperature.
  ///
  /// In en, this message translates to:
  /// **'{condition} - {temperature}°C'**
  String weatherConditionTemperature(
      {required Object condition, required Object temperature});

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherFog;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherStorm.
  ///
  /// In en, this message translates to:
  /// **'Storm'**
  String get weatherStorm;

  /// No description provided for @weatherMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get weatherMixed;

  /// No description provided for @weatherUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get weatherUnknown;

  /// No description provided for @tourHydrationBody.
  ///
  /// In en, this message translates to:
  /// **'Your daily hydration and remaining amount appear here.'**
  String get tourHydrationBody;

  /// No description provided for @tourLogWater.
  ///
  /// In en, this message translates to:
  /// **'Log water'**
  String get tourLogWater;

  /// No description provided for @tourLogWaterBody.
  ///
  /// In en, this message translates to:
  /// **'Log the amount you actually drink. Use a saved container or choose another amount.'**
  String get tourLogWaterBody;

  /// No description provided for @tourReviewCorrect.
  ///
  /// In en, this message translates to:
  /// **'Review and correct'**
  String get tourReviewCorrect;

  /// No description provided for @tourReviewCorrectBody.
  ///
  /// In en, this message translates to:
  /// **'Review, edit, or remove a hydration entry if you make a mistake.'**
  String get tourReviewCorrectBody;

  /// No description provided for @tourChallengesBody.
  ///
  /// In en, this message translates to:
  /// **'Challenges add optional habits and tasks. Challenge water still counts normally.'**
  String get tourChallengesBody;

  /// No description provided for @tourProgressRefresh.
  ///
  /// In en, this message translates to:
  /// **'Progress and refresh'**
  String get tourProgressRefresh;

  /// No description provided for @tourProgressRefreshBody.
  ///
  /// In en, this message translates to:
  /// **'Review your latest totals here. Pull down to refresh hydration and challenge progress.'**
  String get tourProgressRefreshBody;

  /// No description provided for @seeWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'See what\'s new'**
  String get seeWhatsNew;

  /// No description provided for @seeWhatsNewBody.
  ///
  /// In en, this message translates to:
  /// **'Take a short tour of hydration, challenges, and progress.'**
  String get seeWhatsNewBody;

  /// No description provided for @showMe.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get showMe;

  /// No description provided for @challengeOptions.
  ///
  /// In en, this message translates to:
  /// **'Challenge options'**
  String get challengeOptions;

  /// No description provided for @challengeSettings.
  ///
  /// In en, this message translates to:
  /// **'Challenge settings'**
  String get challengeSettings;

  /// No description provided for @leaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveAction;

  /// No description provided for @challengeTutorialSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title} tutorial'**
  String challengeTutorialSemantics({required Object title});

  /// No description provided for @tourOpenTile.
  ///
  /// In en, this message translates to:
  /// **'Open a tile'**
  String get tourOpenTile;

  /// No description provided for @tourOpenTileBody.
  ///
  /// In en, this message translates to:
  /// **'Open any tile to see exactly what it requires.'**
  String get tourOpenTileBody;

  /// No description provided for @tourAutomaticTiles.
  ///
  /// In en, this message translates to:
  /// **'Automatic tiles'**
  String get tourAutomaticTiles;

  /// No description provided for @tourAutomaticTilesBody.
  ///
  /// In en, this message translates to:
  /// **'Some tiles update automatically from your normal hydration logs.'**
  String get tourAutomaticTilesBody;

  /// No description provided for @tourActionsCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Actions and check-ins'**
  String get tourActionsCheckIns;

  /// No description provided for @tourActionsCheckInsBody.
  ///
  /// In en, this message translates to:
  /// **'Other tiles ask for a measured drink or a simple check-in.'**
  String get tourActionsCheckInsBody;

  /// No description provided for @tourMakeBingo.
  ///
  /// In en, this message translates to:
  /// **'Make Bingo'**
  String get tourMakeBingo;

  /// No description provided for @tourMakeBingoBody.
  ///
  /// In en, this message translates to:
  /// **'Complete five tiles in a row, column, or diagonal to make Bingo.'**
  String get tourMakeBingoBody;

  /// No description provided for @tourStartFocus.
  ///
  /// In en, this message translates to:
  /// **'Start a focus session'**
  String get tourStartFocus;

  /// No description provided for @tourStartFocusBody.
  ///
  /// In en, this message translates to:
  /// **'Start the timer when you begin a focus session.'**
  String get tourStartFocusBody;

  /// No description provided for @tourChooseAfterTimer.
  ///
  /// In en, this message translates to:
  /// **'Choose after the timer'**
  String get tourChooseAfterTimer;

  /// No description provided for @tourChooseAfterTimerBody.
  ///
  /// In en, this message translates to:
  /// **'When it ends, confirm a sip or log a measured drink.'**
  String get tourChooseAfterTimerBody;

  /// No description provided for @tourSipNoWater.
  ///
  /// In en, this message translates to:
  /// **'Sip check-ins add no water'**
  String get tourSipNoWater;

  /// No description provided for @tourSipNoWaterBody.
  ///
  /// In en, this message translates to:
  /// **'A sip check-in never adds a guessed hydration amount.'**
  String get tourSipNoWaterBody;

  /// No description provided for @tourMeasuredDrinks.
  ///
  /// In en, this message translates to:
  /// **'Measured drinks count normally'**
  String get tourMeasuredDrinks;

  /// No description provided for @tourMeasuredDrinksBody.
  ///
  /// In en, this message translates to:
  /// **'A measured drink updates normal hydration and may qualify another active challenge.'**
  String get tourMeasuredDrinksBody;

  /// No description provided for @tourTodaysTemperature.
  ///
  /// In en, this message translates to:
  /// **'Today\'s temperature'**
  String get tourTodaysTemperature;

  /// No description provided for @tourTodaysTemperatureBody.
  ///
  /// In en, this message translates to:
  /// **'Review today\'s assigned temperature style.'**
  String get tourTodaysTemperatureBody;

  /// No description provided for @tourWeatherBody.
  ///
  /// In en, this message translates to:
  /// **'When enabled, local weather may influence the recommendation.'**
  String get tourWeatherBody;

  /// No description provided for @tourLogWithContext.
  ///
  /// In en, this message translates to:
  /// **'Log with context'**
  String get tourLogWithContext;

  /// No description provided for @tourLogWithContextBody.
  ///
  /// In en, this message translates to:
  /// **'Use the challenge action or add temperature details when logging from Home.'**
  String get tourLogWithContextBody;

  /// No description provided for @tourTodaysInfusion.
  ///
  /// In en, this message translates to:
  /// **'Today\'s infusion'**
  String get tourTodaysInfusion;

  /// No description provided for @tourTodaysInfusionBody.
  ///
  /// In en, this message translates to:
  /// **'Review today\'s infusion theme.'**
  String get tourTodaysInfusionBody;

  /// No description provided for @tourPrepareNoSugar.
  ///
  /// In en, this message translates to:
  /// **'Prepare without added sugar'**
  String get tourPrepareNoSugar;

  /// No description provided for @tourPrepareNoSugarBody.
  ///
  /// In en, this message translates to:
  /// **'Use the theme without adding sugar.'**
  String get tourPrepareNoSugarBody;

  /// No description provided for @tourLogWhatYouDrink.
  ///
  /// In en, this message translates to:
  /// **'Log what you drink'**
  String get tourLogWhatYouDrink;

  /// No description provided for @tourLogWhatYouDrinkBody.
  ///
  /// In en, this message translates to:
  /// **'Record the measured amount you actually drink.'**
  String get tourLogWhatYouDrinkBody;

  /// No description provided for @whatChallengeIs.
  ///
  /// In en, this message translates to:
  /// **'What this challenge is'**
  String get whatChallengeIs;

  /// No description provided for @whatYouWillDo.
  ///
  /// In en, this message translates to:
  /// **'What you will do'**
  String get whatYouWillDo;

  /// No description provided for @whatCounts.
  ///
  /// In en, this message translates to:
  /// **'What counts'**
  String get whatCounts;

  /// No description provided for @whatDoesNotCount.
  ///
  /// In en, this message translates to:
  /// **'What does not count'**
  String get whatDoesNotCount;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @challengeDurationHelp.
  ///
  /// In en, this message translates to:
  /// **'{days} local calendar days. The challenge starts when joined. Daily requirements reset at local midnight; missed days are not silently recovered.'**
  String challengeDurationHelp({required Object days});

  /// No description provided for @completeSchedule.
  ///
  /// In en, this message translates to:
  /// **'Complete schedule'**
  String get completeSchedule;

  /// No description provided for @challengeScheduleDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}: {item}'**
  String challengeScheduleDay({required Object day, required Object item});

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @hydrationProgressPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Hydration, progress, and privacy'**
  String get hydrationProgressPrivacy;

  /// No description provided for @hydrationProgressPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your usual hydration goal stays active. Measured drinks appear throughout Hydrion, while check-ins add no water. Challenge setup and progress stay on this device.'**
  String get hydrationProgressPrivacyBody;

  /// No description provided for @requiredSetup.
  ///
  /// In en, this message translates to:
  /// **'Required setup'**
  String get requiredSetup;

  /// No description provided for @requiredSetupHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose the details that fit your routine.'**
  String get requiredSetupHelp;

  /// No description provided for @amountInFluidOunces.
  ///
  /// In en, this message translates to:
  /// **'Amount in fluid ounces'**
  String get amountInFluidOunces;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editReminder;

  /// No description provided for @reminderDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Time for a gentle hydration check-in.'**
  String get reminderDefaultMessage;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @minutesFromNow.
  ///
  /// In en, this message translates to:
  /// **'Minutes from now'**
  String get minutesFromNow;

  /// No description provided for @minutesRangeHelp.
  ///
  /// In en, this message translates to:
  /// **'Use 5 to 1440 minutes.'**
  String get minutesRangeHelp;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @reminderDetailsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check reminder details and try again.'**
  String get reminderDetailsInvalid;

  /// No description provided for @ageRangeError.
  ///
  /// In en, this message translates to:
  /// **'Enter an age from 13 to 120.'**
  String get ageRangeError;

  /// No description provided for @ageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The age could not be saved. Try again.'**
  String get ageSaveFailed;

  /// No description provided for @profileDeleteDeviceSummary.
  ///
  /// In en, this message translates to:
  /// **'This removes local Hydrion profile, hydration, reminder, and challenge data from this device.'**
  String get profileDeleteDeviceSummary;

  /// No description provided for @reviewProfileAge.
  ///
  /// In en, this message translates to:
  /// **'Review profile age'**
  String get reviewProfileAge;

  /// No description provided for @independentProfileAgeHelp.
  ///
  /// In en, this message translates to:
  /// **'Hydrion independent profiles support ages 13 and older.'**
  String get independentProfileAgeHelp;

  /// No description provided for @ageReviewExistingDataHelp.
  ///
  /// In en, this message translates to:
  /// **'Your existing local data is still here. If the saved age was entered incorrectly, correct it once below. Otherwise, delete the local profile and restart.'**
  String get ageReviewExistingDataHelp;

  /// No description provided for @correctAge.
  ///
  /// In en, this message translates to:
  /// **'Correct age'**
  String get correctAge;

  /// No description provided for @saveAgeCorrection.
  ///
  /// In en, this message translates to:
  /// **'Save age correction'**
  String get saveAgeCorrection;

  /// No description provided for @optionalDeviceAccess.
  ///
  /// In en, this message translates to:
  /// **'Optional device access'**
  String get optionalDeviceAccess;

  /// No description provided for @optionalDeviceAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'Hydrion works with a standard hydration goal even when you skip these options.'**
  String get optionalDeviceAccessHelp;

  /// No description provided for @preciseReminderTiming.
  ///
  /// In en, this message translates to:
  /// **'Precise reminder timing'**
  String get preciseReminderTiming;

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotifications;

  /// No description provided for @continueWithoutReminders.
  ///
  /// In en, this message translates to:
  /// **'Continue without reminders'**
  String get continueWithoutReminders;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get allowLocation;

  /// No description provided for @continueWithStandardGoal.
  ///
  /// In en, this message translates to:
  /// **'Continue with standard goal'**
  String get continueWithStandardGoal;

  /// No description provided for @openAlarmSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Alarms and reminders settings'**
  String get openAlarmSettings;

  /// No description provided for @continueApproximateScheduling.
  ///
  /// In en, this message translates to:
  /// **'Continue with approximate scheduling'**
  String get continueApproximateScheduling;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @requesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting'**
  String get requesting;

  /// No description provided for @waitingPermissionResult.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the device permission result...'**
  String get waitingPermissionResult;

  /// No description provided for @openDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Open device settings'**
  String get openDeviceSettings;

  /// No description provided for @permissionNotRequested.
  ///
  /// In en, this message translates to:
  /// **'Not requested'**
  String get permissionNotRequested;

  /// No description provided for @permissionApproximateEnabled.
  ///
  /// In en, this message translates to:
  /// **'Approximate location enabled'**
  String get permissionApproximateEnabled;

  /// No description provided for @permissionPreciseEnabled.
  ///
  /// In en, this message translates to:
  /// **'Precise location enabled'**
  String get permissionPreciseEnabled;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get permissionDenied;

  /// No description provided for @permissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get permissionBlocked;

  /// No description provided for @permissionRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get permissionRestricted;

  /// No description provided for @permissionNotRequired.
  ///
  /// In en, this message translates to:
  /// **'Not required'**
  String get permissionNotRequired;

  /// No description provided for @permissionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get permissionUnsupported;

  /// No description provided for @permissionTemporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get permissionTemporarilyUnavailable;

  /// No description provided for @permissionStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get permissionStatusUnavailable;

  /// No description provided for @permissionNotificationUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Notification status has not been checked yet.'**
  String get permissionNotificationUnchecked;

  /// No description provided for @permissionLocationUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Location status has not been checked yet.'**
  String get permissionLocationUnchecked;

  /// No description provided for @permissionAlarmUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Alarm scheduling status has not been checked yet.'**
  String get permissionAlarmUnchecked;

  /// No description provided for @permissionNotificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications are allowed for Hydrion.'**
  String get permissionNotificationsAllowed;

  /// No description provided for @permissionNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. You can allow them here or in device settings.'**
  String get permissionNotificationsOff;

  /// No description provided for @permissionNotificationsNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Hydrion has not asked to send notifications yet.'**
  String get permissionNotificationsNotAsked;

  /// No description provided for @permissionNotificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Open device settings to allow them.'**
  String get permissionNotificationsBlocked;

  /// No description provided for @permissionNotificationStatusUnavailableAndroid.
  ///
  /// In en, this message translates to:
  /// **'Hydrion could not read the Android notification status.'**
  String get permissionNotificationStatusUnavailableAndroid;

  /// No description provided for @permissionNotificationsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Hydrion notifications are not supported on this platform.'**
  String get permissionNotificationsUnsupported;

  /// No description provided for @permissionNotificationStatusTemporary.
  ///
  /// In en, this message translates to:
  /// **'Notification status is temporarily unavailable. Refresh to try again.'**
  String get permissionNotificationStatusTemporary;

  /// No description provided for @permissionPreciseLocationAllowed.
  ///
  /// In en, this message translates to:
  /// **'Precise foreground location is allowed. Approximate location is sufficient for Hydrion weather.'**
  String get permissionPreciseLocationAllowed;

  /// No description provided for @permissionApproximateLocationAllowed.
  ///
  /// In en, this message translates to:
  /// **'Approximate foreground location is allowed and is sufficient for weather assistance.'**
  String get permissionApproximateLocationAllowed;

  /// No description provided for @permissionLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off. Your standard hydration goal still works.'**
  String get permissionLocationOff;

  /// No description provided for @permissionLocationNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Hydrion has not asked for location yet.'**
  String get permissionLocationNotAsked;

  /// No description provided for @permissionLocationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked. Open device settings to enable weather assistance.'**
  String get permissionLocationBlocked;

  /// No description provided for @permissionLocationRestricted.
  ///
  /// In en, this message translates to:
  /// **'Location access is restricted by the device.'**
  String get permissionLocationRestricted;

  /// No description provided for @permissionLocationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Device location services are off. Your standard goal remains available.'**
  String get permissionLocationServicesOff;

  /// No description provided for @permissionLocationUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Location-based weather assistance is not supported on this platform.'**
  String get permissionLocationUnsupported;

  /// No description provided for @permissionLocationStatusTemporary.
  ///
  /// In en, this message translates to:
  /// **'Location status is temporarily unavailable. Refresh to try again.'**
  String get permissionLocationStatusTemporary;

  /// No description provided for @permissionExactAlarmNotRequired.
  ///
  /// In en, this message translates to:
  /// **'Special exact-alarm access is not required on this device.'**
  String get permissionExactAlarmNotRequired;

  /// No description provided for @permissionExactAlarmAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Exact-alarm access is Android-specific.'**
  String get permissionExactAlarmAndroidOnly;

  /// No description provided for @permissionExactSchedulingAvailable.
  ///
  /// In en, this message translates to:
  /// **'Exact reminder scheduling is available.'**
  String get permissionExactSchedulingAvailable;

  /// No description provided for @permissionExactSchedulingApproximate.
  ///
  /// In en, this message translates to:
  /// **'Exact scheduling is unavailable. Hydrion will continue with approximate reminders.'**
  String get permissionExactSchedulingApproximate;

  /// No description provided for @historyFocusEndedEarly.
  ///
  /// In en, this message translates to:
  /// **'Ended focus session {session} early'**
  String historyFocusEndedEarly({required Object session});

  /// No description provided for @historyFocusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed focus session {session}'**
  String historyFocusCompleted({required Object session});

  /// No description provided for @historyBingoTileCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed {tile}'**
  String historyBingoTileCompleted({required Object tile});

  /// No description provided for @historyBingoLineCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed Bottle Bingo line {line}'**
  String historyBingoLineCompleted({required Object line});

  /// No description provided for @historyTemperatureDrink.
  ///
  /// In en, this message translates to:
  /// **'Logged a {style} drink{amount}'**
  String historyTemperatureDrink(
      {required Object amount, required Object style});

  /// No description provided for @historyInfusionTried.
  ///
  /// In en, this message translates to:
  /// **'Tried the {theme} infusion{amount}'**
  String historyInfusionTried({required Object amount, required Object theme});

  /// No description provided for @historyPomodoroDrink.
  ///
  /// In en, this message translates to:
  /// **'Logged a Pomodoro drink{amount}'**
  String historyPomodoroDrink({required Object amount});

  /// No description provided for @historyPomodoroSession.
  ///
  /// In en, this message translates to:
  /// **'Completed a Pomodoro focus session{amount}'**
  String historyPomodoroSession({required Object amount});

  /// No description provided for @historyPomodoroSessionNumber.
  ///
  /// In en, this message translates to:
  /// **'Completed Pomodoro session {session}{amount}'**
  String historyPomodoroSessionNumber(
      {required Object amount, required Object session});

  /// No description provided for @historyFoodAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {food} to {meal}'**
  String historyFoodAdded({required Object food, required Object meal});

  /// No description provided for @historyCueCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed the {cue}'**
  String historyCueCompleted({required Object cue});

  /// No description provided for @historyChallengeTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed a challenge task'**
  String get historyChallengeTaskCompleted;

  /// No description provided for @historyChallengeDrink.
  ///
  /// In en, this message translates to:
  /// **'Logged a challenge drink{amount}'**
  String historyChallengeDrink({required Object amount});

  /// No description provided for @historyBottleBingoDrink.
  ///
  /// In en, this message translates to:
  /// **'Logged a Bottle Bingo drink{amount}'**
  String historyBottleBingoDrink({required Object amount});

  /// No description provided for @historyMeasuredFocusDrink.
  ///
  /// In en, this message translates to:
  /// **'Logged a measured focus-session drink{amount}'**
  String historyMeasuredFocusDrink({required Object amount});

  /// No description provided for @assignedTemperature.
  ///
  /// In en, this message translates to:
  /// **'assigned temperature'**
  String get assignedTemperature;

  /// No description provided for @scheduledTemperature.
  ///
  /// In en, this message translates to:
  /// **'scheduled temperature'**
  String get scheduledTemperature;

  /// No description provided for @dailyValue.
  ///
  /// In en, this message translates to:
  /// **'daily'**
  String get dailyValue;

  /// No description provided for @mealValue.
  ///
  /// In en, this message translates to:
  /// **'meal'**
  String get mealValue;

  /// No description provided for @waterRichFood.
  ///
  /// In en, this message translates to:
  /// **'water-rich food'**
  String get waterRichFood;

  /// No description provided for @plantCareCue.
  ///
  /// In en, this message translates to:
  /// **'plant-care cue'**
  String get plantCareCue;

  /// No description provided for @bottleBingoTile.
  ///
  /// In en, this message translates to:
  /// **'a Bottle Bingo tile'**
  String get bottleBingoTile;

  /// No description provided for @bottleBingoDrink.
  ///
  /// In en, this message translates to:
  /// **'a Bottle Bingo drink'**
  String get bottleBingoDrink;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @localProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Local profile photo'**
  String get localProfilePhoto;

  /// No description provided for @profilePhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo saved locally.'**
  String get profilePhotoSaved;

  /// No description provided for @profilePhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo was too large for local profile storage.'**
  String get profilePhotoTooLarge;

  /// No description provided for @profileEditorSummary.
  ///
  /// In en, this message translates to:
  /// **'Update your Hydrion identity and preferences. This does not restart onboarding or delete history.'**
  String get profileEditorSummary;

  /// No description provided for @profilePhotoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Selected photos are used only as your local profile image. You can remove the photo and return to the default avatar any time.'**
  String get profilePhotoPrivacy;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @hydrationIdentity.
  ///
  /// In en, this message translates to:
  /// **'Hydration identity'**
  String get hydrationIdentity;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get dailyGoal;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @preferredContainer.
  ///
  /// In en, this message translates to:
  /// **'Preferred container'**
  String get preferredContainer;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @noRemindersYet.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get noRemindersYet;

  /// No description provided for @savedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String savedCount({required int count});

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact: {email}'**
  String contactEmail({required String email});

  /// No description provided for @editProfileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the profile fields and try again.'**
  String get editProfileInvalid;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @useDefaultAvatar.
  ///
  /// In en, this message translates to:
  /// **'Use default avatar'**
  String get useDefaultAvatar;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @defaultProfileAvatar.
  ///
  /// In en, this message translates to:
  /// **'Default profile avatar'**
  String get defaultProfileAvatar;

  /// No description provided for @baselineDailyGoalMl.
  ///
  /// In en, this message translates to:
  /// **'Baseline daily goal in mL'**
  String get baselineDailyGoalMl;

  /// No description provided for @preferredContainerMl.
  ///
  /// In en, this message translates to:
  /// **'Preferred container in mL'**
  String get preferredContainerMl;

  /// No description provided for @personalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized'**
  String get personalized;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @whyHydrionExists.
  ///
  /// In en, this message translates to:
  /// **'Why Hydrion exists'**
  String get whyHydrionExists;

  /// No description provided for @missionAndCommunity.
  ///
  /// In en, this message translates to:
  /// **'Mission and community'**
  String get missionAndCommunity;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @replayAppTour.
  ///
  /// In en, this message translates to:
  /// **'App tour - Replay the quick guide'**
  String get replayAppTour;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @useDeviceSetting.
  ///
  /// In en, this message translates to:
  /// **'Use device setting'**
  String get useDeviceSetting;

  /// No description provided for @automaticDayNight.
  ///
  /// In en, this message translates to:
  /// **'Automatic day/night'**
  String get automaticDayNight;

  /// No description provided for @dayTheme.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayTheme;

  /// No description provided for @nightTheme.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get nightTheme;

  /// No description provided for @deviceSetting.
  ///
  /// In en, this message translates to:
  /// **'Device setting'**
  String get deviceSetting;

  /// No description provided for @autoDayNight.
  ///
  /// In en, this message translates to:
  /// **'Auto day/night'**
  String get autoDayNight;

  /// No description provided for @dailyGoalPerDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} mL/day'**
  String dailyGoalPerDay({required int amount});

  /// No description provided for @personalizedBaselineActive.
  ///
  /// In en, this message translates to:
  /// **'Personalized baseline'**
  String get personalizedBaselineActive;

  /// No description provided for @manualBaselineActive.
  ///
  /// In en, this message translates to:
  /// **'Standard or manual baseline'**
  String get manualBaselineActive;

  /// No description provided for @weatherAssistanceSelected.
  ///
  /// In en, this message translates to:
  /// **'Weather assistance selected'**
  String get weatherAssistanceSelected;

  /// No description provided for @weatherAssistanceOff.
  ///
  /// In en, this message translates to:
  /// **'Weather assistance off'**
  String get weatherAssistanceOff;

  /// No description provided for @amountInOz.
  ///
  /// In en, this message translates to:
  /// **'Amount in oz'**
  String get amountInOz;

  /// No description provided for @containerSharedHelp.
  ///
  /// In en, this message translates to:
  /// **'One saved amount is used by Home and Bottle Bingo.'**
  String get containerSharedHelp;

  /// No description provided for @containerAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount from 100 to 2000 mL.'**
  String get containerAmountInvalid;

  /// No description provided for @permissionsSummary.
  ///
  /// In en, this message translates to:
  /// **'Review reminders, weather location, and Android alarm access.'**
  String get permissionsSummary;

  /// No description provided for @legalPrivacySupport.
  ///
  /// In en, this message translates to:
  /// **'Legal, privacy, and support'**
  String get legalPrivacySupport;

  /// No description provided for @widgetNoActiveChallenge.
  ///
  /// In en, this message translates to:
  /// **'No active challenge'**
  String get widgetNoActiveChallenge;

  /// No description provided for @widgetChooseChallenge.
  ///
  /// In en, this message translates to:
  /// **'Open Hydrion to choose a challenge.'**
  String get widgetChooseChallenge;

  /// No description provided for @widgetOpenChallenges.
  ///
  /// In en, this message translates to:
  /// **'Open challenges'**
  String get widgetOpenChallenges;

  /// No description provided for @widgetChallengePaused.
  ///
  /// In en, this message translates to:
  /// **'Challenge paused'**
  String get widgetChallengePaused;

  /// No description provided for @widgetActivityActive.
  ///
  /// In en, this message translates to:
  /// **'Activity active'**
  String get widgetActivityActive;

  /// No description provided for @widgetActivityPaused.
  ///
  /// In en, this message translates to:
  /// **'Activity paused'**
  String get widgetActivityPaused;

  /// No description provided for @widgetActivityComplete.
  ///
  /// In en, this message translates to:
  /// **'Today\'s activity complete'**
  String get widgetActivityComplete;

  /// No description provided for @widgetCheckpointProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} checkpoints today'**
  String widgetCheckpointProgress({required int completed, required int total});

  /// No description provided for @widgetOpenToContinue.
  ///
  /// In en, this message translates to:
  /// **'Open Hydrion to continue'**
  String get widgetOpenToContinue;

  /// No description provided for @widgetOpenChallenge.
  ///
  /// In en, this message translates to:
  /// **'Open challenge'**
  String get widgetOpenChallenge;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration reports'**
  String get reportsTitle;

  /// No description provided for @reportsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a private summary from hydration records stored on this device.'**
  String get reportsDescription;

  /// No description provided for @reportsOpen.
  ///
  /// In en, this message translates to:
  /// **'Create report'**
  String get reportsOpen;

  /// No description provided for @reportsFrequency.
  ///
  /// In en, this message translates to:
  /// **'Reporting frequency'**
  String get reportsFrequency;

  /// No description provided for @reportsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reportsWeekly;

  /// No description provided for @reportsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get reportsMonthly;

  /// No description provided for @reportsQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get reportsQuarterly;

  /// No description provided for @reportsYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get reportsYearly;

  /// No description provided for @reportsChoosePeriod.
  ///
  /// In en, this message translates to:
  /// **'Choose period'**
  String get reportsChoosePeriod;

  /// No description provided for @reportsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportsPeriod;

  /// No description provided for @reportsGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get reportsGenerated;

  /// No description provided for @reportsPreview.
  ///
  /// In en, this message translates to:
  /// **'Report preview'**
  String get reportsPreview;

  /// No description provided for @reportsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total recorded intake'**
  String get reportsTotal;

  /// No description provided for @reportsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average on tracked days'**
  String get reportsAverage;

  /// No description provided for @reportsTrackedDays.
  ///
  /// In en, this message translates to:
  /// **'Tracked days'**
  String get reportsTrackedDays;

  /// No description provided for @reportsTargetsMet.
  ///
  /// In en, this message translates to:
  /// **'Known targets met'**
  String get reportsTargetsMet;

  /// No description provided for @reportsTarget.
  ///
  /// In en, this message translates to:
  /// **'Applicable target'**
  String get reportsTarget;

  /// No description provided for @reportsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportsDate;

  /// No description provided for @reportsIntake.
  ///
  /// In en, this message translates to:
  /// **'Recorded intake'**
  String get reportsIntake;

  /// No description provided for @reportsMissing.
  ///
  /// In en, this message translates to:
  /// **'No record'**
  String get reportsMissing;

  /// No description provided for @reportsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get reportsUnavailable;

  /// No description provided for @reportsPartial.
  ///
  /// In en, this message translates to:
  /// **'This reporting period is still in progress.'**
  String get reportsPartial;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No hydration intake was recorded for this period.'**
  String get reportsEmpty;

  /// No description provided for @reportsLegacyTarget.
  ///
  /// In en, this message translates to:
  /// **'Historical targets that were not stored are shown as unavailable.'**
  String get reportsLegacyTarget;

  /// No description provided for @reportsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This report summarizes user-tracked hydration information. It is not a medical diagnosis or a substitute for professional medical advice.'**
  String get reportsDisclaimer;

  /// No description provided for @reportsExport.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get reportsExport;

  /// No description provided for @reportsExported.
  ///
  /// In en, this message translates to:
  /// **'Report shared successfully.'**
  String get reportsExported;

  /// No description provided for @reportsDismissed.
  ///
  /// In en, this message translates to:
  /// **'Sharing was cancelled.'**
  String get reportsDismissed;

  /// No description provided for @reportsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'The report could not be exported. Please try again.'**
  String get reportsExportFailed;

  /// No description provided for @reportsPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get reportsPage;

  /// No description provided for @reportsVisualization.
  ///
  /// In en, this message translates to:
  /// **'Recorded hydration'**
  String get reportsVisualization;

  /// No description provided for @healthDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect health data'**
  String get healthDataTitle;

  /// No description provided for @healthDataSettingsSummary.
  ///
  /// In en, this message translates to:
  /// **'Import approved activity records from a provider available on this device.'**
  String get healthDataSettingsSummary;

  /// No description provided for @healthDataProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get healthDataProvider;

  /// No description provided for @healthDataHealthConnect.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get healthDataHealthConnect;

  /// No description provided for @healthDataAppleHealth.
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get healthDataAppleHealth;

  /// No description provided for @healthDataAppleAccessRequested.
  ///
  /// In en, this message translates to:
  /// **'Apple Health access was requested. Apple protects your choices, so Hydrion cannot display which read categories you allowed.'**
  String get healthDataAppleAccessRequested;

  /// No description provided for @healthDataContributingSources.
  ///
  /// In en, this message translates to:
  /// **'Contributing sources:'**
  String get healthDataContributingSources;

  /// No description provided for @healthDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'This health-data provider is available on this device.'**
  String get healthDataAvailable;

  /// No description provided for @healthDataLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking available health-data providers...'**
  String get healthDataLoading;

  /// No description provided for @healthDataInstallationRequired.
  ///
  /// In en, this message translates to:
  /// **'Install Health Connect to use Android health data.'**
  String get healthDataInstallationRequired;

  /// No description provided for @healthDataUpdateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update Health Connect before connecting.'**
  String get healthDataUpdateRequired;

  /// No description provided for @healthDataUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Health Connect is not supported in this device profile.'**
  String get healthDataUnsupported;

  /// No description provided for @healthDataPermissionNotRequested.
  ///
  /// In en, this message translates to:
  /// **'Health access has not been requested.'**
  String get healthDataPermissionNotRequested;

  /// No description provided for @healthDataPermissionPartial.
  ///
  /// In en, this message translates to:
  /// **'Some requested categories are not allowed.'**
  String get healthDataPermissionPartial;

  /// No description provided for @healthDataPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Health access is not allowed. Manual hydration remains available.'**
  String get healthDataPermissionDenied;

  /// No description provided for @healthDataConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected for read-only health data.'**
  String get healthDataConnected;

  /// No description provided for @healthDataConnectedNoData.
  ///
  /// In en, this message translates to:
  /// **'Connected, but no readable records were found.'**
  String get healthDataConnectedNoData;

  /// No description provided for @healthDataSynchronizing.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing health data...'**
  String get healthDataSynchronizing;

  /// No description provided for @healthDataSyncPartial.
  ///
  /// In en, this message translates to:
  /// **'Synchronization completed with some categories unavailable.'**
  String get healthDataSyncPartial;

  /// No description provided for @healthDataSuccessfulCategories.
  ///
  /// In en, this message translates to:
  /// **'Synchronized categories: {categories}'**
  String healthDataSuccessfulCategories({required String categories});

  /// No description provided for @healthDataFailedCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories needing attention: {categories}'**
  String healthDataFailedCategories({required String categories});

  /// No description provided for @healthDataRetryFailedCategories.
  ///
  /// In en, this message translates to:
  /// **'Retry failed categories'**
  String get healthDataRetryFailedCategories;

  /// No description provided for @healthDataSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Health data could not be synchronized.'**
  String get healthDataSyncFailed;

  /// No description provided for @healthDataStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Protected health-data storage is unavailable. No records were imported.'**
  String get healthDataStorageUnavailable;

  /// No description provided for @healthDataProviderFailure.
  ///
  /// In en, this message translates to:
  /// **'The health-data provider could not be refreshed. Try again or manage provider access.'**
  String get healthDataProviderFailure;

  /// No description provided for @healthDataDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected inside Hydrion. Source permissions remain controlled by the health-data provider.'**
  String get healthDataDisconnected;

  /// No description provided for @healthDataConsentIntro.
  ///
  /// In en, this message translates to:
  /// **'Hydrion requests read-only access from the provider shown above only after you choose Connect.'**
  String get healthDataConsentIntro;

  /// No description provided for @healthDataCategories.
  ///
  /// In en, this message translates to:
  /// **'Requested categories'**
  String get healthDataCategories;

  /// No description provided for @healthDataWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get healthDataWorkouts;

  /// No description provided for @healthDataActiveEnergy.
  ///
  /// In en, this message translates to:
  /// **'Active energy'**
  String get healthDataActiveEnergy;

  /// No description provided for @healthDataSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get healthDataSteps;

  /// No description provided for @healthDataDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get healthDataDistance;

  /// No description provided for @healthDataCategoryExplanation.
  ///
  /// In en, this message translates to:
  /// **'Workouts provide activity duration. Active energy provides exertion context. Steps and distance provide fallback activity context without being added twice.'**
  String get healthDataCategoryExplanation;

  /// No description provided for @healthDataPrivacyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Imported records remain encrypted on this device. No Hydrion account or cloud upload is required. You can decline, manage provider access, disconnect, or delete Hydrion\'s imported copy without deleting source records.'**
  String get healthDataPrivacyExplanation;

  /// No description provided for @healthDataWellnessDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is wellness information, not a medical diagnosis. Imported data does not change your hydration target in this version.'**
  String get healthDataWellnessDisclaimer;

  /// No description provided for @healthDataConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get healthDataConnect;

  /// No description provided for @healthDataRequestMissing.
  ///
  /// In en, this message translates to:
  /// **'Request missing access'**
  String get healthDataRequestMissing;

  /// No description provided for @healthDataSynchronize.
  ///
  /// In en, this message translates to:
  /// **'Synchronize'**
  String get healthDataSynchronize;

  /// No description provided for @healthDataOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Android settings'**
  String get healthDataOpenSettings;

  /// No description provided for @healthDataDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get healthDataDisconnect;

  /// No description provided for @healthDataDeleteImported.
  ///
  /// In en, this message translates to:
  /// **'Delete imported data'**
  String get healthDataDeleteImported;

  /// No description provided for @healthDataDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Hydrion\'s imported health data?'**
  String get healthDataDeleteQuestion;

  /// No description provided for @healthDataDeleteExplanation.
  ///
  /// In en, this message translates to:
  /// **'This removes Hydrion\'s encrypted imported copy, checkpoints and derived wearable context. It does not delete records from the source provider or manual hydration history.'**
  String get healthDataDeleteExplanation;

  /// No description provided for @healthDataImportedCount.
  ///
  /// In en, this message translates to:
  /// **'Imported records: {count}'**
  String healthDataImportedCount({required int count});

  /// No description provided for @healthDataGrantedCategories.
  ///
  /// In en, this message translates to:
  /// **'Granted: {categories}'**
  String healthDataGrantedCategories({required String categories});

  /// No description provided for @healthDataNoGrantedCategories.
  ///
  /// In en, this message translates to:
  /// **'Granted: none'**
  String get healthDataNoGrantedCategories;

  /// No description provided for @healthDataContributors.
  ///
  /// In en, this message translates to:
  /// **'Contributing applications: {applications}'**
  String healthDataContributors({required String applications});

  /// No description provided for @healthDataNoContributors.
  ///
  /// In en, this message translates to:
  /// **'Contributing applications: none found'**
  String get healthDataNoContributors;

  /// No description provided for @healthDataLastSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Last successful synchronization: {time}'**
  String healthDataLastSuccessful({required String time});

  /// No description provided for @healthDataNeverSynchronized.
  ///
  /// In en, this message translates to:
  /// **'Last successful synchronization: never'**
  String get healthDataNeverSynchronized;

  /// No description provided for @healthDataDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Health data'**
  String get healthDataDashboardTitle;

  /// No description provided for @healthDataPermissionRequesting.
  ///
  /// In en, this message translates to:
  /// **'Opening provider permissions...'**
  String get healthDataPermissionRequesting;

  /// No description provided for @healthDataConnectedNotSynchronized.
  ///
  /// In en, this message translates to:
  /// **'Health-data provider connected'**
  String get healthDataConnectedNotSynchronized;

  /// No description provided for @healthDataNoSyncYet.
  ///
  /// In en, this message translates to:
  /// **'No synchronization completed yet.'**
  String get healthDataNoSyncYet;

  /// No description provided for @healthDataSynchronizedWithRecords.
  ///
  /// In en, this message translates to:
  /// **'Connected and synchronized'**
  String get healthDataSynchronizedWithRecords;

  /// No description provided for @healthDataSynchronizedNoRecords.
  ///
  /// In en, this message translates to:
  /// **'Connected, but no health data was found'**
  String get healthDataSynchronizedNoRecords;

  /// No description provided for @healthDataNoDataExplanation.
  ///
  /// In en, this message translates to:
  /// **'The provider returned no readable workout, energy, step, or distance records. This can mean no matching data is available or read access was not allowed. Check the source application, then try again.'**
  String get healthDataNoDataExplanation;

  /// No description provided for @healthDataPermissionRevoked.
  ///
  /// In en, this message translates to:
  /// **'Health access needs attention'**
  String get healthDataPermissionRevoked;

  /// No description provided for @healthDataMissingCategories.
  ///
  /// In en, this message translates to:
  /// **'Missing access: {categories}'**
  String healthDataMissingCategories({required String categories});

  /// No description provided for @healthDataLastAttempt.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: {time}'**
  String healthDataLastAttempt({required String time});

  /// No description provided for @healthDataLatestAttemptFailed.
  ///
  /// In en, this message translates to:
  /// **'The latest synchronization failed. Previously imported records were not affected.'**
  String get healthDataLatestAttemptFailed;

  /// No description provided for @healthDataSyncCounts.
  ///
  /// In en, this message translates to:
  /// **'Latest sync: {read} read, {inserted} new, {updated} updated, {deleted} deleted, {rejected} rejected'**
  String healthDataSyncCounts(
      {required int read,
      required int inserted,
      required int updated,
      required int deleted,
      required int rejected});

  /// No description provided for @healthDataRecordPeriod.
  ///
  /// In en, this message translates to:
  /// **'Available period: {start} - {end}'**
  String healthDataRecordPeriod({required String start, required String end});

  /// No description provided for @healthDataSourceCount.
  ///
  /// In en, this message translates to:
  /// **'{source}: {count} records'**
  String healthDataSourceCount({required String source, required int count});

  /// No description provided for @healthDataDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'Data available'**
  String get healthDataDataAvailable;

  /// No description provided for @healthDataWhatReads.
  ///
  /// In en, this message translates to:
  /// **'What Hydrion reads'**
  String get healthDataWhatReads;

  /// No description provided for @healthDataViewImportedData.
  ///
  /// In en, this message translates to:
  /// **'View imported data'**
  String get healthDataViewImportedData;

  /// No description provided for @healthDataImportedDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Imported wearable data'**
  String get healthDataImportedDataTitle;

  /// No description provided for @healthDataWorkoutTimeline.
  ///
  /// In en, this message translates to:
  /// **'Workout timeline'**
  String get healthDataWorkoutTimeline;

  /// No description provided for @healthDataWorkoutTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts imported yet.'**
  String get healthDataWorkoutTimelineEmpty;

  /// No description provided for @healthDataWorkoutRow.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min workout'**
  String healthDataWorkoutRow({required int minutes});

  /// No description provided for @healthDataStepsTrend.
  ///
  /// In en, this message translates to:
  /// **'Steps trend (last 14 days)'**
  String get healthDataStepsTrend;

  /// No description provided for @healthDataDistanceTrend.
  ///
  /// In en, this message translates to:
  /// **'Distance trend (last 14 days)'**
  String get healthDataDistanceTrend;

  /// No description provided for @healthDataActiveEnergyTrend.
  ///
  /// In en, this message translates to:
  /// **'Active energy trend (last 14 days)'**
  String get healthDataActiveEnergyTrend;

  /// No description provided for @healthDataTrendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data in the last 14 days.'**
  String get healthDataTrendEmpty;

  /// No description provided for @healthDataTrendDayTotal.
  ///
  /// In en, this message translates to:
  /// **'{date}: {value} {unit}'**
  String healthDataTrendDayTotal(
      {required String date, required String value, required String unit});

  /// No description provided for @healthDataRecordSource.
  ///
  /// In en, this message translates to:
  /// **'{source} · {date}'**
  String healthDataRecordSource({required String source, required String date});

  /// No description provided for @healthDataSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get healthDataSyncNow;

  /// No description provided for @healthDataTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get healthDataTryAgain;

  /// No description provided for @healthDataManageAccess.
  ///
  /// In en, this message translates to:
  /// **'Manage access'**
  String get healthDataManageAccess;

  /// No description provided for @healthDataCheckHealthConnect.
  ///
  /// In en, this message translates to:
  /// **'Open Health Connect'**
  String get healthDataCheckHealthConnect;

  /// No description provided for @healthDataReadingSecurely.
  ///
  /// In en, this message translates to:
  /// **'Reading authorized records securely. Do not close Hydrion.'**
  String get healthDataReadingSecurely;

  /// No description provided for @healthDataReasonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The health-data provider was unavailable.'**
  String get healthDataReasonUnavailable;

  /// No description provided for @healthDataReasonPermission.
  ///
  /// In en, this message translates to:
  /// **'Health access was denied or revoked.'**
  String get healthDataReasonPermission;

  /// No description provided for @healthDataReasonOperation.
  ///
  /// In en, this message translates to:
  /// **'The secure synchronization operation could not complete.'**
  String get healthDataReasonOperation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
