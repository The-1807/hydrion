// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Hydrion';

  @override
  String get settingsTooltip => 'Paramètres';

  @override
  String get hydrionLogoSemantics => 'Logo Hydrion';

  @override
  String get analyticsTitle => 'Analyses';

  @override
  String get achievementsTitle => 'Réussites';

  @override
  String get ecoImpactTitle => 'Impact environnemental';

  @override
  String get challengesTitle => 'Défis';

  @override
  String get chatCoachTitle => 'Coach hydratation';

  @override
  String get logTitle => 'Journal hydratation';

  @override
  String get remindersTitle => 'Rappels';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String loggedVolume({required int volumeMl}) {
    return '$volumeMl ml enregistrés';
  }

  @override
  String get logHydration => 'Enregistrer hydratation';

  @override
  String get amountLabel => 'Quantité';

  @override
  String logVolume({required int volumeMl}) {
    return 'Enregistrer $volumeMl ml';
  }

  @override
  String get savedLocally => 'Enregistré localement sur cet appareil.';

  @override
  String savedLocallySyncDisabled(
      {required Object syncNames, required Object verb}) {
    return 'Enregistré localement sur cet appareil. La synchronisation $syncNames est désactivée.';
  }

  @override
  String get analyticsRoute => 'Analyses';

  @override
  String get logRoute => 'Journal';

  @override
  String get coachRoute => 'Coach';

  @override
  String get challengesRoute => 'Défis';

  @override
  String get remindersRoute => 'Rappels';

  @override
  String voiceIntent({required Object intent}) {
    return 'Intention vocale : $intent';
  }

  @override
  String get hydrationAdviceCardSemantics => 'Carte de conseil hydratation';

  @override
  String get stayHydratedFallback => 'Restez hydraté.';

  @override
  String get homeAdviceStrong =>
      'Votre rythme d\'hydratation est solide. Continuez avec de petites gorgées tout au long de la journée.';

  @override
  String get homeAdviceClose =>
      'Vous êtes proche de l\'objectif. Ajoutez un verre d\'eau dans la prochaine heure pour rester régulier.';

  @override
  String get homeAdviceStart =>
      'Commencez avec 300 à 500 ml maintenant, puis vérifiez après votre prochaine boisson.';

  @override
  String get homeAdviceGoalReached =>
      'Vous avez atteint l\'objectif du jour. Les besoins d\'hydratation varient, alors gardez un rythme confortable et buvez selon votre soif.';

  @override
  String get homeAdviceHeat =>
      'La chaleur augmente vos besoins en hydratation.';

  @override
  String homeAdviceReliableEntries({required int count}) {
    return 'Vous avez $count entrées locales aujourd\'hui, ce qui rend la tendance plus fiable.';
  }

  @override
  String get homeAdviceAddEntries =>
      'Ajoutez des entrées quand vous buvez pour que Hydrion suive la journée honnêtement.';

  @override
  String get failedToLoadAdvice => 'Impossible de charger le conseil';

  @override
  String get retry => 'Réessayer';

  @override
  String get osNotificationsAvailableSentence =>
      'Les notifications système sont disponibles.';

  @override
  String get osNotificationsDisabledSentence =>
      'Les notifications système sont désactivées.';

  @override
  String get noLocalReminderNeeded =>
      'Aucune définition locale de rappel nécessaire';

  @override
  String localReminderSaved({required Object notificationStatus}) {
    return 'Définition locale de rappel enregistrée. $notificationStatus';
  }

  @override
  String get failedToScheduleReminder => 'Impossible de sauvegarder le rappel';

  @override
  String get localReminderDefinition => 'Définition locale de rappel';

  @override
  String reminderTileNoSaved({required Object notificationStatus}) {
    return 'Aucun rappel enregistré. Hydrion stocke uniquement des définitions de rappel. $notificationStatus';
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
          '$count enregistrés localement. Prochaine définition : $time. $notificationStatus',
      one:
          '1 enregistré localement. Prochaine définition : $time. $notificationStatus',
    );
    return '$_temp0';
  }

  @override
  String get saveLocalReminderDefinitionTooltip =>
      'Enregistrer une définition locale de rappel';

  @override
  String get voiceInputAvailableSemantics => 'Entrée vocale disponible';

  @override
  String get voiceInputDisabledSemantics => 'Entrée vocale désactivée';

  @override
  String get voiceCapabilityReportedNoAdapter =>
      'La capacité vocale est signalée, mais aucun adaptateur vocal est connecté';

  @override
  String get voiceInputDisabledTooltip =>
      'Entrée vocale désactivée par les capacités de l\'app';

  @override
  String get standaloneLocalMode => 'Mode local autonome';

  @override
  String get elkaAdapterConfiguredMode => 'Adaptateur ELKA configuré';

  @override
  String get geminiProviderConfiguredMode => 'Fournisseur Gemini configuré';

  @override
  String get localDataNoProviderRuntime => 'Suivi privé sur cet appareil.';

  @override
  String get geminiProviderConfiguredDescription =>
      'Gemini peut proposer des actions typées ; Hydrion les valide avant de leur faire confiance.';

  @override
  String get geminiProviderConfiguredLocalDescription =>
      'Gemini est configuré, mais désactivé jusqu\'à l\'activation du consentement de confidentialité du fournisseur.';

  @override
  String get geminiProviderActiveDescription =>
      'Gemini peut recevoir un contexte d\'hydratation typé ; Hydrion valide la sortie du fournisseur avant de lui faire confiance.';

  @override
  String get language => 'Langue';

  @override
  String get appLanguageLabel => 'Langue de l\'app';

  @override
  String get languageUpdated => 'Langue mise à jour';

  @override
  String get languageChoiceSaved =>
      'Le choix de langue est enregistré localement.';

  @override
  String get localeCoverageComplete =>
      'Les textes Hydrion sont disponibles pour cette langue.';

  @override
  String get localeCoveragePartial =>
      'Les textes Hydrion sont disponibles ; le texte plateforme non traduit utilise une solution sûre.';

  @override
  String get futureLanguagesNote =>
      'Les langues supplémentaires apparaîtront seulement quand les traductions seront complètes.';

  @override
  String get localeNameEnglish => 'Anglais';

  @override
  String get localeNameSpanish => 'Espagnol';

  @override
  String get localeNameFrench => 'Français';

  @override
  String get permissions => 'Autorisations';

  @override
  String get standalonePermissionsExplanation =>
      'Le mode autonome ne demande pas les autorisations Bluetooth, Santé, microphone, caméra ni notifications.';

  @override
  String get check => 'Vérifier';

  @override
  String get noPlatformPermissionsRequested =>
      'Aucune autorisation plateforme demandée en mode autonome';

  @override
  String get dailyGoalTitle => 'Objectif quotidien d\'hydratation';

  @override
  String get dailyGoalDescription =>
      'Définissez l\'objectif utilisé par Hydrion dans Accueil, Analyses, Coach et défis locaux. Les besoins d\'hydratation varient selon la personne et le jour.';

  @override
  String get dailyGoalFieldLabel => 'Objectif en ml';

  @override
  String dailyGoalRange({required int minMl, required int maxMl}) {
    return '$minMl-$maxMl ml';
  }

  @override
  String get dailyGoalUpdated => 'Objectif quotidien mis à jour';

  @override
  String get dailyGoalInvalid => 'Saisissez un objectif entre 500 et 5000 ml';

  @override
  String get reusableContainerTitle => 'Contenant réutilisable';

  @override
  String get reusableContainerDescription =>
      'Estimez le plastique jetable évité seulement quand les boissons enregistrées viennent habituellement d\'une bouteille ou tasse réutilisable.';

  @override
  String get localFirstPrivacyTitle => 'Confidentialité locale';

  @override
  String get localFirstPrivacyDescription =>
      'Hydrion fonctionne hors ligne et garde les journaux, objectifs, langue et progression des défis sur cet appareil.';

  @override
  String get optionalProviderConsumerDescription =>
      'Les fonctions optionnelles avec fournisseur restent désactivées jusqu\'à ce que vous les activiez. Hydrion reste utilisable hors ligne.';

  @override
  String get debugDiagnosticsTitle => 'Diagnostics de débogage';

  @override
  String get debugDiagnosticsDescription =>
      'Les détails techniques de développement sont disponibles seulement dans les versions de débogage.';

  @override
  String get runtimeFeatureStatus => 'État des fonctions runtime';

  @override
  String get providerHealthTitle => 'État du fournisseur IA';

  @override
  String get selectedProvider => 'Fournisseur sélectionné';

  @override
  String get activeProvider => 'Fournisseur actif';

  @override
  String get localRulesProvider => 'Guide sur l\'appareil';

  @override
  String get geminiProvider => 'Gemini';

  @override
  String get elkaProvider => 'ELKA';

  @override
  String get providerAvailable => 'Disponible';

  @override
  String get providerUnavailable => 'Indisponible';

  @override
  String get providerConfigured => 'Configuré';

  @override
  String get providerUnconfigured => 'Non configuré';

  @override
  String get providerFallbackState => 'État du repli';

  @override
  String get providerFallbackReady => 'Le guide sur l\'appareil est disponible';

  @override
  String get providerFallbackInUse => 'Guide sur l\'appareil utilisé';

  @override
  String get providerFallbackCode => 'Code de repli';

  @override
  String get providerFallbackReason => 'Raison du repli';

  @override
  String get providerNoFallback => 'Aucun repli nécessaire';

  @override
  String get providerLastFailure => 'Dernier échec fournisseur';

  @override
  String get providerNoFailure => 'Aucun';

  @override
  String get providerPrivacyTitle => 'Confidentialité du fournisseur';

  @override
  String get providerPrivacyLocalOnly =>
      'Le guide sur l\'appareil garde le contexte d\'hydratation sur cet appareil.';

  @override
  String get providerPrivacyGeminiDisclosure =>
      'Quand Gemini est configuré, Hydrion peut envoyer un contexte d\'hydratation typé à Gemini. N\'intégrez pas de clé Gemini partagée dans les artefacts web ou mobiles.';

  @override
  String get providerConsentRequired =>
      'L\'IA non locale nécessite un consentement utilisateur explicite avant la production.';

  @override
  String get providerConsentStatus => 'Consentement fournisseur';

  @override
  String get providerConsentToggleTitle =>
      'Autoriser le traitement du fournisseur Gemini';

  @override
  String get providerConsentEnabled =>
      'Activé. Le contexte d\'hydratation typé peut quitter cet appareil pour les requêtes Gemini.';

  @override
  String get providerConsentDisabled =>
      'Désactivé. Hydrion utilise le guide sur l\'appareil et n\'envoie pas de contexte d\'hydratation à Gemini.';

  @override
  String get providerGeminiHealth => 'État Gemini';

  @override
  String get providerGeminiModel => 'Modèle Gemini';

  @override
  String get providerGeminiConfigured => 'Gemini configuré';

  @override
  String get providerDiagnosticsTitle => 'Diagnostics Gemini';

  @override
  String get providerEndpointHost => 'Hôte endpoint';

  @override
  String get providerModelPath => 'Chemin du modèle';

  @override
  String get providerApiKeyPresent => 'Clé API présente';

  @override
  String get providerApiKeyLength => 'Longueur de clé';

  @override
  String get providerApiKeyFingerprint => 'Empreinte de cle API';

  @override
  String get providerApiKeyContainsWhitespace => 'Clé avec espaces';

  @override
  String get providerApiKeyWasTrimmed => 'Clé nettoyée';

  @override
  String get providerApiKeyStartsWithGooglePrefix => 'Préfixe Google';

  @override
  String get providerAuthHeaderPresent => 'En-tête auth présent';

  @override
  String get providerAuthHeaderValueLength => 'Longueur en-tête auth';

  @override
  String get providerRequestAttempted => 'Requête tentée';

  @override
  String get providerHttpStatusClass => 'État HTTP';

  @override
  String get providerErrorStatus => 'État d\'erreur Gemini';

  @override
  String get providerErrorMessage => 'Message d\'erreur Gemini';

  @override
  String get providerErrorDetails => 'Détails d\'erreur Gemini';

  @override
  String get providerLastDiagnosticPhase => 'Dernier diagnostic';

  @override
  String get providerParserCode => 'Code analyseur';

  @override
  String get providerValidatorCode => 'Code validateur';

  @override
  String get providerBlockedCapabilities => 'Capacités bloquées';

  @override
  String get providerLastSuccess => 'Dernier succès Gemini';

  @override
  String get providerLastFailureAt => 'Heure du dernier échec';

  @override
  String get providerNotAvailable => 'Indisponible';

  @override
  String get providerDiagnosticNoApiKey => 'Aucune clé API Gemini configurée';

  @override
  String get providerDiagnosticConsentRequired =>
      'Gemini est configuré, mais le consentement de confidentialité du fournisseur est désactivé';

  @override
  String get providerDiagnosticHealthy =>
      'Gemini est sain ; la dernière réponse a passé la validation';

  @override
  String get providerDiagnosticFallbackActive =>
      'Le guide sur l\'appareil est actif';

  @override
  String get providerDiagnosticNotProven =>
      'Gemini est configuré, mais pas encore prouvé sain';

  @override
  String get providerDiagnosticLocalRules =>
      'Le guide sur l\'appareil est actif';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get localPersistence => 'Persistance locale';

  @override
  String get onDevice => 'Sur appareil';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get localPersistenceDescription =>
      'Les journaux hydratation, paramètres, rappels et états de défis sont stockés localement.';

  @override
  String get elkaAdapter => 'Adaptateur ELKA';

  @override
  String get configured => 'Configuré';

  @override
  String get unconfigured => 'Non configuré';

  @override
  String get elkaAdapterDescription =>
      'La limite adaptateur existe, mais aucun runtime ELKA est connecté.';

  @override
  String get cloudAi => 'IA cloud';

  @override
  String get connected => 'Connecté';

  @override
  String get disabled => 'Désactivé';

  @override
  String get cloudAiDescription =>
      'Aucun SDK fournisseur ni modèle cloud est connecté.';

  @override
  String get cloudAiConfiguredDescription =>
      'Gemini est configuré comme fournisseur optionnel ; les fournisseurs ne peuvent pas modifier l\'état de l\'app.';

  @override
  String get cloudAiConsentRequiredDescription =>
      'Gemini est configuré, mais inactif jusqu\'à l\'activation du consentement de confidentialité du fournisseur.';

  @override
  String get voiceInput => 'Entrée vocale';

  @override
  String get available => 'Disponible';

  @override
  String get voiceInputDescription =>
      'Les commandes saisies peuvent être analysées ; la capture microphone est indisponible.';

  @override
  String get bleBottleSync => 'Synchro BLE bouteille';

  @override
  String get bleSyncDescription =>
      'Aucun scan Bluetooth, connexion ni lecture de niveau bouteille est démarré.';

  @override
  String get healthSync => 'Synchro santé';

  @override
  String get healthSyncDescription =>
      'Aucune lecture HealthKit, Google Fit ni wearable est active.';

  @override
  String get osNotifications => 'Notifications système';

  @override
  String get osNotificationsDisabledTitle =>
      'Notifications système désactivées';

  @override
  String get osNotificationsDescription =>
      'Les définitions de rappel sont enregistrées localement ; aucune notification plateforme est planifiée.';

  @override
  String get socialSync => 'Synchro sociale';

  @override
  String get localOnly => 'Local seulement';

  @override
  String get socialSyncDescription =>
      'Les défis sont seulement locaux ; aucun état backend est partagé.';

  @override
  String get hydrationLogUpdated => 'Journal hydratation mis à jour';

  @override
  String get hydrationLogDeleted => 'Journal hydratation supprimé';

  @override
  String get hydrationLogRestored => 'Journal hydratation restauré';

  @override
  String get undo => 'Annuler';

  @override
  String get logNotFound => 'Journal introuvable';

  @override
  String get noLogs => 'Aucun journal hydratation trouvé';

  @override
  String get logEmptyDescription =>
      'Utilisez Accueil pour ajouter une entrée locale d\'hydratation. Les journaux sont enregistrés sur cet appareil.';

  @override
  String get editLogTooltip => 'Modifier le journal';

  @override
  String get deleteLogTooltip => 'Supprimer le journal';

  @override
  String get editHydrationLog => 'Modifier le journal hydratation';

  @override
  String get amountInMl => 'Quantité en ml';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get localEntry => 'Entrée locale';

  @override
  String logSourceTimestamp(
      {required Object source, required Object timestamp}) {
    return '$source - $timestamp';
  }

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String relativeDateTime({required Object date, required Object time}) {
    return '$date, $time';
  }

  @override
  String get noAnalyticsYet => 'Aucune analyse pour le moment';

  @override
  String get analyticsEmptyDescription =>
      'Enregistrez hydratation dans Accueil pour créer des tendances locales.';

  @override
  String todayHydrationTitle({required int todayMl, required int targetMl}) {
    return '$todayMl / $targetMl ml aujourd\'hui';
  }

  @override
  String localEntriesToday({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entrées locales aujourd\'hui. Les données restent sur cet appareil.',
      one:
          '1 entrée locale aujourd\'hui. Les données restent sur cet appareil.',
    );
    return '$_temp0';
  }

  @override
  String get badgeDailyGoal => 'Objectif quotidien';

  @override
  String get badgeThreeLogsToday => '3 journaux aujourd\'hui';

  @override
  String get badgeSevenDayStreak => 'Série 7 jours';

  @override
  String plasticEstimateTitle({required Object value}) {
    return 'Estimation de plastique évité : $value kg';
  }

  @override
  String reusableContainerEstimateFromLogs(
      {required int lifetimeMl, required int eventCount}) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount journaux enregistrés',
      one: '1 journal enregistré',
    );
    return 'L\'estimation suppose que les boissons enregistrées utilisaient votre contenant réutilisable : $lifetimeMl ml sur $_temp0.';
  }

  @override
  String get reusableContainerEstimateDisabled =>
      'Activez le suivi du contenant réutilisable dans Paramètres avant d\'estimer le plastique jetable évité.';

  @override
  String get hydrationScoreTitle => 'Score hydratation';

  @override
  String get hydrationScoreSemantics => 'Score hydratation';

  @override
  String scoreOutOf100({required Object score}) {
    return '$score sur 100';
  }

  @override
  String get scoreSuffix => '/ 100';

  @override
  String logCount({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count journaux',
      one: '1 journal',
    );
    return '$_temp0';
  }

  @override
  String get hydrationTipExcellent =>
      'Objectif atteint. Les besoins varient ; gardez le reste de la journée stable.';

  @override
  String get hydrationTipGreat =>
      'Très bon rythme. Gardez des gorgées confortables et régulières.';

  @override
  String get hydrationTipClose =>
      'Vous êtes proche. Une boisson modérée peut aider à atteindre l\'objectif.';

  @override
  String get hydrationTipStart =>
      'Commencez avec 300 à 500 ml maintenant et définissez un rappel.';

  @override
  String get achievementStatusUnlocked => 'débloquée';

  @override
  String get achievementStatusLocked => 'verrouillée';

  @override
  String achievementBadgeSemantics(
      {required Object badgeName, required Object status}) {
    return 'Badge de réussite : $badgeName $status';
  }

  @override
  String get hydrationProgressRing => 'Anneau de progression hydratation';

  @override
  String percentValue({required int percent}) {
    return '$percent pour cent';
  }

  @override
  String consumedOfTarget({required int consumedMl, required int targetMl}) {
    return '$consumedMl sur $targetMl millilitres consommés';
  }

  @override
  String get chatError => 'Impossible d\'obtenir la réponse du coach';

  @override
  String get localFallbackCoach => 'Coach sur l\'appareil';

  @override
  String get providerCoachTitle => 'Coach fournisseur';

  @override
  String get coachUserMessageLabel => 'Vous';

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
    return 'Aujourd\'hui : $todayMl / $targetMl ml. Journaux totaux : $_temp0. Actif : $activeProvider.';
  }

  @override
  String coachProviderReady({required Object activeProvider}) {
    return '$activeProvider est actif. Les réponses sont validées avant que Hydrion leur fasse confiance.';
  }

  @override
  String get coachProviderFallbackActive =>
      'Guide sur l\'appareil utilisé. La sortie du fournisseur reste optionnelle.';

  @override
  String get coachProviderConsentRequired =>
      'Gemini est configuré, mais désactivé jusqu\'à l\'activation du consentement de confidentialité du fournisseur. Le contexte d\'hydratation reste sur cet appareil.';

  @override
  String get coachLocalProviderReady =>
      'Le guide sur l\'appareil est actif. Le contexte hydratation reste sur cet appareil.';

  @override
  String coachContextBanner(
      {required Object mode,
      required int todayMl,
      required int lifetimeMl,
      required int eventCount}) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount journaux',
      one: '1 journal',
    );
    return '$mode. Utilisation des données hydratation enregistrées sur l\'appareil. Aujourd\'hui : $todayMl ml. Total : $lifetimeMl ml sur $_temp0. Aucune IA cloud ni ELKA est connecté.';
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
      other: '$eventCount journaux',
      one: '1 journal',
    );
    return '$mode. Utilisation des données hydratation enregistrées sur l\'appareil. Aujourd\'hui : $todayMl ml. Total : $lifetimeMl ml sur $_temp0. La sortie du fournisseur est validée avant que Hydrion lui fasse confiance.';
  }

  @override
  String get askCoachEmpty =>
      'Demandez une suggestion hydratation. Les réponses sont une aide locale déterministe basée sur les journaux enregistrés.';

  @override
  String get chatHint => 'Demandez à votre coach...';

  @override
  String get coachFallbackNoticeLabel => 'Repli';

  @override
  String get coachFallbackNotice =>
      'Le guide sur l\'appareil a traité cette réponse.';

  @override
  String get suggestionHydrationLogTitle => 'Suggestion de journal hydratation';

  @override
  String get suggestionReminderTitle => 'Suggestion de rappel';

  @override
  String get suggestionChallengeTitle => 'Suggestion de défi';

  @override
  String get suggestionTrendTitle => 'Analyse de tendance';

  @override
  String get suggestionUnsupportedTitle => 'Capacité indisponible';

  @override
  String suggestionProviderSource({required Object provider}) {
    return 'Source : $provider';
  }

  @override
  String suggestionValidationStatus({required Object status}) {
    return 'Validation : $status';
  }

  @override
  String get suggestionConfirmationRequired => 'Confirmation requise';

  @override
  String get suggestionDisplayOnly => 'Affichage seul';

  @override
  String get suggestionValidated => 'Validée';

  @override
  String get suggestionApplied => 'Suggestion appliquée';

  @override
  String get suggestionRejected => 'Suggestion rejetée';

  @override
  String get suggestionDismissed => 'Suggestion ignorée';

  @override
  String get suggestionApply => 'Appliquer';

  @override
  String get suggestionDismiss => 'Ignorer';

  @override
  String get suggestionDetailVolume => 'Volume';

  @override
  String get suggestionDetailDelay => 'Délai';

  @override
  String get suggestionDetailPriority => 'Priorité';

  @override
  String get suggestionDetailChallenge => 'Défi';

  @override
  String get suggestionDetailTarget => 'Objectif';

  @override
  String get suggestionDetailDuration => 'Durée';

  @override
  String get suggestionDetailCapability => 'Capacité';

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
    return '$targetMl ml/jour';
  }

  @override
  String suggestionDurationValue({required int days}) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get cloudSync => 'Synchronisation cloud';

  @override
  String get osNotificationsCapabilityReported =>
      'Capacité de notifications système signalée';

  @override
  String get notificationsAdapterNotWired =>
      'Aucun adaptateur de notifications est connecté. Les définitions restent locales.';

  @override
  String get standaloneRemindersLocalOnly =>
      'Le mode autonome stocke les définitions de rappel localement seulement. Aucune notification plateforme ne se déclenchera.';

  @override
  String get noLocalRemindersSaved => 'Aucun rappel local enregistré';

  @override
  String get remindersEmptyDescription =>
      'Utilisez la carte de rappel Accueil pour enregistrer une définition locale à consulter plus tard.';

  @override
  String reminderSubtitle({required Object timestamp, required int priority}) {
    return '$timestamp - priorité $priority';
  }

  @override
  String get deleteLocalReminderTooltip => 'Supprimer le rappel local';

  @override
  String get localReminderDeleted => 'Définition locale de rappel supprimée';

  @override
  String get noChallengesAvailable => 'Aucun défi disponible';

  @override
  String get socialChallengeCapabilityReported =>
      'Capacité de défi social signalée';

  @override
  String get localChallengeMode => 'Mode défi local';

  @override
  String get socialCapabilityNoAdapter =>
      'Aucun adaptateur social est connecté. La progression reste enregistrée sur cet appareil.';

  @override
  String get socialSyncNotConnected =>
      'La synchro sociale n\'est pas encore connectée. La progression du défi est enregistrée sur cet appareil.';

  @override
  String get noActiveChallengeYet => 'Aucun défi actif pour le moment';

  @override
  String get joinLocalChallengeDescription =>
      'Rejoignez le défi local ci-dessous pour commencer à suivre la progression depuis les journaux hydratation enregistrés.';

  @override
  String get challengeNameSevenDaySteadySip =>
      'Gorgées régulières sur sept jours';

  @override
  String get challengeDescriptionSevenDaySteadySip =>
      'Atteignez votre objectif hydratation quotidien pendant une semaine.';

  @override
  String challengeDetails(
      {required Object description,
      required int targetMl,
      required int durationDays}) {
    return '$description ($targetMl ml, $durationDays jours)';
  }

  @override
  String challengeProgress(
      {required int completedDays,
      required int durationDays,
      required int todayMl,
      required int targetMl}) {
    return '$completedDays/$durationDays jours terminés. Aujourd\'hui : $todayMl/$targetMl ml.';
  }

  @override
  String challengeTargetPerDay({required int targetMl}) {
    return '$targetMl ml/jour';
  }

  @override
  String challengeDurationDays({required int durationDays}) {
    return '$durationDays jours';
  }

  @override
  String get challengeJoined => 'Défi rejoint';

  @override
  String challengeJoinedLocally({required Object message}) {
    return '$message localement';
  }

  @override
  String get join => 'Rejoindre';

  @override
  String get joined => 'Rejoint';
}
