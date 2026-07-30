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
  /// **'Amount in ml'**
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
  /// **'This clears your local profile, body metrics, daily contexts, hydration history, reminders, challenges, recommendation state, and weather cache on this device. Android notification and location permissions are not revoked and remain controlled in device settings.'**
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
