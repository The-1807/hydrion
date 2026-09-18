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
  String get manualGoalOverrideQuestion =>
      'Voulez-vous vraiment modifier votre objectif personnalisé ?';

  @override
  String get manualGoalOverrideConfirmation =>
      'Cela enregistre un objectif quotidien manuel. Votre référence personnalisée calculée reste disponible et ne sera pas modifiée.';

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
  String get amountInMl => 'Quantité en mL';

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
      other: '$count ajouts',
      one: '1 ajout',
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

  @override
  String get bodyMetricsTitle => 'Mesures corporelles';

  @override
  String get bodyMeasurementsTitle => 'Mesures corporelles enregistrées';

  @override
  String get notAdded => 'Non ajouté';

  @override
  String get addWeight => 'Ajouter le poids';

  @override
  String get updateWeight => 'Mettre à jour le poids';

  @override
  String get addHeight => 'Ajouter la taille';

  @override
  String get updateHeight => 'Mettre à jour la taille';

  @override
  String get hydrationPacingScheduleTitle => 'Horaire de rythme d\'hydratation';

  @override
  String get hydrationPacingScheduleHelp =>
      'Facultatif. Indiquez à Hydrion vos heures de réveil habituelles afin qu\'il puisse comparer doucement votre rythme à votre journée. Cela ne change jamais votre objectif quotidien.';

  @override
  String get wakeTimeLabel => 'Heure de réveil';

  @override
  String get sleepTimeLabel => 'Heure de coucher';

  @override
  String get addWakeTime => 'Ajouter l\'heure de réveil';

  @override
  String get updateWakeTime => 'Mettre à jour l\'heure de réveil';

  @override
  String get addSleepTime => 'Ajouter l\'heure de coucher';

  @override
  String get updateSleepTime => 'Mettre à jour l\'heure de coucher';

  @override
  String get pacingAheadOfPace =>
      'Vous êtes en avance sur le rythme pour ce moment de votre journée.';

  @override
  String get pacingOnPace =>
      'Vous êtes dans le rythme pour ce moment de votre journée.';

  @override
  String get pacingSlightlyBehindPace =>
      'Vous êtes un peu en retard sur votre rythme habituel.';

  @override
  String get pacingMeaningfullyBehindPace =>
      'Vous êtes en retard, mais il vous reste du temps dans la journée.';

  @override
  String get pacingGoalReached => 'Vous avez atteint l\'objectif du jour.';

  @override
  String get updatedToday => 'Mis à jour aujourd’hui';

  @override
  String updatedOn({required Object date}) {
    return 'Mis à jour le $date';
  }

  @override
  String get personalizationTitle => 'Personnalisation';

  @override
  String get editPersonalizationSettings =>
      'Modifier les paramètres de personnalisation';

  @override
  String get onLabel => 'Activé';

  @override
  String get offLabel => 'Désactivé';

  @override
  String get dataPrivacyTitle => 'Données et confidentialité';

  @override
  String get deleteBodyMetricsExplanation =>
      'Cette action supprime les mesures enregistrées et les paramètres de personnalisation. Les journaux d’hydratation ne sont pas supprimés.';

  @override
  String get done => 'Terminé';

  @override
  String get noDailyContext =>
      'Aucun contexte d’activité n’a été ajouté pour aujourd’hui.';

  @override
  String get setDailyContext => 'Définir le contexte du jour';

  @override
  String get savedForToday => 'Enregistré pour aujourd’hui.';

  @override
  String get appliesTodayOnly => 'S’applique uniquement aujourd’hui.';

  @override
  String get edit => 'Modifier';

  @override
  String get clear => 'Effacer';

  @override
  String get feelingUnwellToday => 'Vous ne vous sentez pas bien aujourd’hui?';

  @override
  String get bodyMetricsOptional =>
      'Des mesures facultatives et stockées localement peuvent améliorer l\'estimation de bien-être général. Vous pouvez les ignorer, les désactiver ou les supprimer à tout moment.';

  @override
  String get enablePersonalization =>
      'Activer les mesures corporelles personnalisées';

  @override
  String get personalizedBaselineOption => 'Utiliser une base personnalisée';

  @override
  String get personalizedBaselineHelp =>
      'Hydrion calculera une suggestion à examiner. Votre objectif actuel n\'est pas remplacé avant que vous l\'appliquiez.';

  @override
  String get weatherModifierOption =>
      'Utiliser les ajustements météo facultatifs';

  @override
  String get weightLabel => 'Poids';

  @override
  String get heightLabel => 'Taille';

  @override
  String get kilogramsLabel => 'kg';

  @override
  String get poundsLabel => 'lb';

  @override
  String get centimetresLabel => 'cm';

  @override
  String get feetInchesLabel => 'pi et po';

  @override
  String get feetLabel => 'pi';

  @override
  String get inchesLabel => 'po';

  @override
  String get accessibleNumericEntry => 'Saisie numérique accessible';

  @override
  String get reproductiveHydrationTitle => 'Grossesse ou allaitement';

  @override
  String get reproductiveNone => 'Aucun';

  @override
  String get reproductivePregnant => 'Enceinte';

  @override
  String get reproductiveLactating => 'Allaitement';

  @override
  String get bmiTitle => 'Estimation de dépistage de l\'IMC';

  @override
  String get bmiDisclaimer =>
      'L\'IMC est une estimation de dépistage basée sur la taille et le poids. Il ne diagnostique pas de problème de santé et ne mesure pas la composition corporelle.';

  @override
  String get bmiUnderTwenty =>
      'Hydrion n\'interprète pas les catégories adultes de l\'IMC pour les personnes de moins de 20 ans.';

  @override
  String get bmiBelowRange => 'Sous la plage adulte standard';

  @override
  String get bmiStandardRange => 'Plage de dépistage adulte standard';

  @override
  String get bmiAboveRange => 'Au-dessus de la plage adulte standard';

  @override
  String get bmiHigherRange => 'Plage de dépistage adulte supérieure';

  @override
  String get fluidSafetyTitle => 'Réglage de sécurité des liquides';

  @override
  String get fluidSafetyNone => 'Aucune restriction signalée';

  @override
  String get fluidSafetyClinician => 'J\'ai une cible fixée par un clinicien';

  @override
  String get fluidSafetyRestriction =>
      'J\'ai une restriction de liquides sans cible';

  @override
  String get fluidSafetyUnsure => 'Je ne suis pas sûr';

  @override
  String get clinicianTargetLabel => 'Cible du clinicien en ml';

  @override
  String get allowAboveClinicianTarget =>
      'Autoriser des ajustements facultatifs au-dessus de cette cible';

  @override
  String get saveBodyMetrics => 'Enregistrer les mesures';

  @override
  String get deleteBodyMetrics => 'Supprimer les mesures';

  @override
  String get bodyMetricsSaved => 'Mesures enregistrées localement.';

  @override
  String get bodyMetricsInvalid =>
      'Choisissez des mesures dans la plage sécuritaire affichée.';

  @override
  String get bodyMetricsDeleted => 'Mesures corporelles supprimées.';

  @override
  String get profileDeletionPersonalizationDisclosure =>
      'Cela efface sur cet appareil votre profil local, les mesures corporelles, les contextes quotidiens, l\'historique d\'hydratation, les rappels, les défis, l\'état des recommandations et le cache météo. Vos préférences de langue et d\'apparence restent enregistrées.';

  @override
  String get dailyContextTitle => 'Contexte d\'aujourd\'hui';

  @override
  String get dailyContextOptional =>
      'Le contexte facultatif d\'activité et d\'extérieur ajuste seulement la suggestion du jour.';

  @override
  String get activityIntensityLabel => 'Intensité de l\'activité';

  @override
  String get activityMinutesLabel => 'Minutes d\'activité';

  @override
  String get environmentLabel => 'Environnement';

  @override
  String get sweatLevelLabel => 'Niveau de transpiration';

  @override
  String get temporaryConditionLabel => 'État temporaire';

  @override
  String get activityRest => 'Repos';

  @override
  String get activityLight => 'Légère';

  @override
  String get activityModerate => 'Modérée';

  @override
  String get activityVigorous => 'Vigoureuse';

  @override
  String get environmentIndoors => 'Surtout à l\'intérieur';

  @override
  String get environmentMixed => 'Intérieur et extérieur';

  @override
  String get environmentOutdoors => 'Surtout à l\'extérieur';

  @override
  String get sweatLow => 'Faible';

  @override
  String get sweatModerate => 'Modérée';

  @override
  String get sweatHigh => 'Élevée';

  @override
  String get sweatUnknown => 'Inconnu';

  @override
  String get conditionNone => 'Aucun';

  @override
  String get conditionFever => 'Fièvre';

  @override
  String get conditionStomachIllness => 'Vomissements ou diarrhée';

  @override
  String get conditionRecovering => 'Rétablissement';

  @override
  String get conditionPreferNot => 'Préfère ne pas répondre';

  @override
  String get saveDailyContext => 'Enregistrer le contexte du jour';

  @override
  String get clearDailyContext => 'Effacer le contexte du jour';

  @override
  String get hydrationSuggestionTitle =>
      'Suggestion d\'hydratation personnalisée';

  @override
  String get baselineLabel => 'Base';

  @override
  String get adjustmentsLabel => 'Ajustements';

  @override
  String get weatherAdjustmentLabel => 'Ajustement météo';

  @override
  String get activityAdjustmentLabel => 'Ajustement d\'activité';

  @override
  String get reproductiveAdjustmentLabel =>
      'Ajustement de grossesse ou d\'allaitement';

  @override
  String get personalizedSuggestionAccepted =>
      'Suggestion quotidienne personnalisée acceptée après examen.';

  @override
  String get keepCurrentGoal => 'Garder l\'objectif actuel';

  @override
  String get applySuggestedGoal => 'Appliquer l\'objectif suggéré';

  @override
  String get suggestedGoalApplied => 'Objectif suggéré appliqué.';

  @override
  String get dailyContextSaved => 'Contexte du jour enregistré.';

  @override
  String get reviewSuggestion => 'Examiner la suggestion';

  @override
  String get generalWellnessNotice =>
      'Il s\'agit d\'une estimation de bien-être général, et non d\'un avis médical. Ne forcez pas la consommation de liquides.';

  @override
  String get illnessSafetyNotice =>
      'Les besoins en liquides peuvent changer pendant une maladie. Gardez la recommandation habituelle et consultez un professionnel si les symptômes sont importants.';

  @override
  String get restrictionSafetyNotice =>
      'Hydrion n\'augmentera pas automatiquement votre objectif lorsqu\'une restriction de liquides est signalée. Suivez les conseils professionnels.';

  @override
  String get recommendedForYou => 'Recommandé pour vous';

  @override
  String get viewChallenge => 'Voir le défi';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get noAutomaticChallenge =>
      'Une recommandation ne démarre jamais un défi. Vous choisissez de l\'examiner et de le rejoindre.';

  @override
  String get tailorChallengeSuggestions =>
      'Personnaliser les suggestions de defis';

  @override
  String get challengeSuggestionPrivacy =>
      'Choisissez les types de routines que Hydrion peut prendre en compte. Ces choix restent sur cet appareil et ne lancent jamais automatiquement un defi.';

  @override
  String get timedFocusSipRoutines =>
      'Routines chronometrees de concentration et d\'hydratation';

  @override
  String get waterRichFoodHabits => 'Habitudes d\'aliments riches en eau';

  @override
  String get visualDailyConsistency => 'Regularite visuelle quotidienne';

  @override
  String get infusionFlavorVariety => 'Variete d\'infusions et de saveurs';

  @override
  String get recommendationWarmWeather =>
      'Les conditions chaudes d\'aujourd\'hui rendent ce defi pertinent.';

  @override
  String get recommendationTimedRoutine =>
      'Correspond a votre preference pour les routines chronometrees.';

  @override
  String get recommendationLoggingConsistency =>
      'Un defi de suivi varie peut vous aider a gagner en regularite.';

  @override
  String get recommendationWaterRichFood =>
      'Correspond a votre interet pour les aliments riches en eau.';

  @override
  String get recommendationVisualConsistency =>
      'Correspond a votre preference pour la regularite visuelle quotidienne.';

  @override
  String get recommendationInfusionVariety =>
      'Correspond a votre interet pour les infusions et les saveurs variees.';

  @override
  String get pregnancyDurationTitle => 'Où en êtes-vous dans votre grossesse ?';

  @override
  String get pregnancyDurationDays => 'Jours';

  @override
  String get pregnancyDurationWeeks => 'Semaines';

  @override
  String get pregnancyDurationMonths => 'Mois';

  @override
  String get pregnancyDurationInputLabel => 'Durée de la grossesse';

  @override
  String get pregnancyDurationHelp =>
      'Saisissez une durée comprise entre 1 jour et 42 semaines.';

  @override
  String get pregnancyDurationInvalid =>
      'Saisissez une durée de grossesse valide entre 1 jour et 42 semaines.';

  @override
  String get pregnancyDurationMonthsHelp =>
      'Les mois sont convertis approximativement et enregistrés localement.';

  @override
  String pregnancyDurationSummary({required int weeks, required int days}) {
    return 'Environ $weeks semaines et $days jours.';
  }

  @override
  String get missionTitle => 'Pourquoi Hydrion existe';

  @override
  String get missionSemanticLabel => 'Mission d\'Hydrion';

  @override
  String get missionHeadline =>
      'L\'hydratation devrait être plus facile à comprendre et à gérer.';

  @override
  String get learnMore => 'En savoir plus';

  @override
  String get missionDetails =>
      'Hydrion favorise des habitudes plus sûres et plus régulières tout en gardant les renseignements personnels localement et sous votre contrôle. Une participation communautaire pourra être proposée plus tard par Discord, un service externe avec ses propres pratiques de compte et de confidentialité. Hydrion n\'enverra jamais automatiquement les renseignements de profil ou de santé.';

  @override
  String get communityComingLater => 'Lien communautaire à venir';

  @override
  String get continueToTutorial => 'Continuer vers le tutoriel';

  @override
  String get profileDeletedTitle => 'Profil supprimé';

  @override
  String get profileDeletionCompletedSemanticLabel =>
      'Suppression du profil local terminée';

  @override
  String get profileDeletedHeadline => 'Votre profil Hydrion a été supprimé';

  @override
  String get profileDeletedFarewell =>
      'Où que votre parcours d\'hydratation vous mène, prenez soin de vous, restez hydraté et partagez ce que vous avez appris avec une personne qui pourrait en profiter.';

  @override
  String get learnAboutMission => 'Découvrir la mission d\'Hydrion';

  @override
  String get finish => 'Terminer';

  @override
  String get deleteLocalProfile => 'Supprimer le profil local';

  @override
  String get deleteLocalProfileSummary =>
      'Supprime les données de profil Hydrion tout en conservant les préférences de langue et d\'apparence.';

  @override
  String get deleteLocalProfileQuestion => 'Supprimer le profil local?';

  @override
  String get removeDevicePermissions =>
      'Supprimer aussi les autorisations Hydrion';

  @override
  String get removeDevicePermissionsHelp =>
      'Android 13 et les versions ultérieures peuvent planifier la suppression des autorisations de notification et de localisation après l\'écran d\'adieu. L\'accès aux alarmes exactes et les autres accès spéciaux restent gérés dans les paramètres système.';

  @override
  String get reviewPermissions => 'Vérifier les autorisations';

  @override
  String get deleteAction => 'Supprimer';

  @override
  String get profileDeletionFailed =>
      'Le profil n\'a pas pu être supprimé. Fermez Hydrion, rouvrez-le et réessayez.';

  @override
  String get profileDeletionCleanupPending =>
      'Profil supprimé. Le nettoyage des rappels Android sera réessayé automatiquement.';

  @override
  String get weatherSuggestionTitle =>
      'Suggestion d\'hydratation selon la météo du jour';

  @override
  String get humidityLabel => 'Humidité';

  @override
  String get standardGoalLabel => 'Objectif standard';

  @override
  String get todaySuggestedGoalLabel => 'Objectif suggéré aujourd\'hui';

  @override
  String get updatedLabel => 'Mis à jour';

  @override
  String get weatherSuggestionDisclosure =>
      'Cette suggestion utilise votre profil enregistré, l\'autorisation de localisation et la météo locale. Elle ne constitue pas un avis médical.';

  @override
  String get keepStandardGoal => 'Garder l\'objectif standard';

  @override
  String get useSuggestion => 'Utiliser la suggestion';

  @override
  String get pomodoroSessionNotificationTitle => 'Session Pomodoro';

  @override
  String get homeworkSessionNotificationTitle => 'Session de devoirs';

  @override
  String get sessionPaused => 'En pause';

  @override
  String get pauseAction => 'Pause';

  @override
  String get resumeAction => 'Reprendre';

  @override
  String get stopAction => 'Arrêter';

  @override
  String get openAction => 'Ouvrir';

  @override
  String get waterNotLoggedRetry =>
      'L\'eau n\'a pas été enregistrée. Réessayez.';

  @override
  String loggedFormattedVolume({required String amount}) {
    return '$amount enregistré';
  }

  @override
  String get dailyGoalReachedRecognition =>
      'Objectif quotidien atteint. Bravo.';

  @override
  String get sevenDayStreakRecognition =>
      'Série d\'hydratation de sept jours. Une routine régulière prend forme.';

  @override
  String get profileMenu => 'Menu du profil';

  @override
  String get viewProfile => 'Voir le profil';

  @override
  String get support => 'Assistance';

  @override
  String get addChallengeDetails => 'Ajouter les détails du défi';

  @override
  String get challengeDetailsAdded => 'Détails du défi ajoutés';

  @override
  String get challengeDetailsHelp =>
      'Toute l\'eau compte dans votre objectif quotidien. Les détails du défi consignent les besoins de la tâche du jour.';

  @override
  String get challengeDetailsTitle => 'Détails du défi';

  @override
  String get temperatureStyle => 'Température';

  @override
  String get temperatureCool => 'Fraîche';

  @override
  String get temperatureRoom => 'Température ambiante';

  @override
  String get temperatureWarm => 'Agréablement chaude';

  @override
  String get infusionTheme => 'Thème de l\'infusion';

  @override
  String get noAddedSugar => 'Sans sucre ajouté';

  @override
  String get useDetails => 'Utiliser ces détails';

  @override
  String get history => 'Historique';

  @override
  String get customAmount => 'Quantité personnalisée';

  @override
  String get momentum => 'Élan';

  @override
  String get applySuggestedGoalQuestion => 'Appliquer l\'objectif suggéré ?';

  @override
  String get applySuggestedGoalConfirmation =>
      'Appliquer cet objectif quotidien suggéré et continuer ?';

  @override
  String get refineInputs => 'Non, affiner les données';

  @override
  String get confirmApply => 'Oui, appliquer';

  @override
  String get enterMeasurementsWithKeyboard =>
      'Saisir les mesures avec le clavier';

  @override
  String recalculatedAt({required String date}) {
    return 'Recalculé le $date';
  }

  @override
  String volumeMlValue({required int amount}) {
    return '$amount mL';
  }

  @override
  String baselineMlValue({required String label, required int amount}) {
    return '$label : $amount mL';
  }

  @override
  String get routineFitsDay => 'Une routine adaptée à votre journée';

  @override
  String get routineFitsDayBody =>
      'Continuez à noter l\'eau réellement bue. De petits suivis donnent une image utile de la journée.';

  @override
  String amountLeft({required String amount}) {
    return '$amount restants';
  }

  @override
  String get weatherAdjusted => 'Ajusté à la météo';

  @override
  String get noReusableContainerSaved =>
      'Aucun contenant réutilisable enregistré. Ajoutez-en un dans Réglages pour l\'utiliser ici et dans Bottle Bingo.';

  @override
  String savedContainerHelp({required String amount}) {
    return 'Contenant enregistré : $amount. Sélectionnez-le ici pour utiliser la même quantité dans Bottle Bingo.';
  }

  @override
  String get firstLogWaiting => 'Premier ajout en attente';

  @override
  String get momentumEmptyBody => 'Un petit ajout donne forme à la journée.';

  @override
  String get momentumDataBody =>
      'Votre requin dispose de vraies données auxquelles réagir.';

  @override
  String get challengePick => 'Choix du défi';

  @override
  String get activeChallenge => 'Défi actif';

  @override
  String get bottleBingoReady =>
      'Bottle Bingo est prêt lorsque vous souhaitez une routine ludique.';

  @override
  String get activeChallengeGentle =>
      'Gardez un rythme doux aujourd\'hui ; les progrès viennent des ajouts normaux.';

  @override
  String get progress => 'Progression';

  @override
  String get logHistory => 'Historique des ajouts';

  @override
  String greetingMorning({required String name}) {
    return 'Bonjour, $name';
  }

  @override
  String greetingAfternoon({required String name}) {
    return 'Bon après-midi, $name';
  }

  @override
  String greetingEvening({required String name}) {
    return 'Bonsoir, $name';
  }

  @override
  String get greetingFallbackName => 'vous';

  @override
  String recentLogCounted({required String amount}) {
    return 'Votre ajout récent de $amount est comptabilisé. Laissez du temps à votre routine avant de décider de la suite.';
  }

  @override
  String get noWaterLoggedToday =>
      'Aucune eau n\'est encore enregistrée aujourd\'hui. Ajoutez ce que vous avez réellement bu lorsque vous êtes prêt.';

  @override
  String todayLogSummary({required int count, required String remaining}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ajouts',
      one: '1 ajout',
    );
    return 'Vous avez $_temp0 aujourd\'hui. Il reste environ $remaining.';
  }

  @override
  String todayLogSummaryWithContainer(
      {required int count,
      required String remaining,
      required String container}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ajouts',
      one: '1 ajout',
    );
    return 'Vous avez $_temp0 aujourd\'hui. Il reste environ $remaining ; votre contenant de $container est disponible comme quantité rapide.';
  }

  @override
  String get goalCompleted => 'Objectif atteint';

  @override
  String get noHydrationLoggedToday =>
      'Aucune hydratation enregistrée aujourd\'hui';

  @override
  String get todaysHydration => 'Hydratation du jour';

  @override
  String get onboardingNicknameInvalid =>
      'Saisissez un surnom de 32 caractères maximum.';

  @override
  String get onboardingAgeInvalid =>
      'Les profils Hydrion autonomes nécessitent un âge compris entre 13 et 120 ans.';

  @override
  String get onboardingTermsRequired =>
      'Acceptez les Conditions et reconnaissez l\'avis de santé pour continuer.';

  @override
  String get onboardingGoalInvalid =>
      'Vérifiez votre objectif et la taille du contenant avant de continuer.';

  @override
  String get onboardingCompleteRecognition =>
      'La configuration de Hydrion est terminée.';

  @override
  String get onboardingWelcome => 'Bienvenue dans Hydrion';

  @override
  String get back => 'Retour';

  @override
  String get start => 'Commencer';

  @override
  String get continueAction => 'Continuer';

  @override
  String get onboardingLocalFirstTitle =>
      'Hydrion conserve l\'hydratation localement';

  @override
  String get onboardingMascotSemantics => 'Mascotte Hydrion';

  @override
  String get onboardingLocalFirstBody =>
      'Suivez l\'eau, les objectifs, les rappels et les défis individuels sur cet appareil. Les fonctions facultatives de fournisseurs restent désactivées jusqu\'à votre choix.';

  @override
  String get onboardingBasicProfile => 'Profil de base';

  @override
  String get nickname => 'Surnom';

  @override
  String get requiredSavedLocally => 'Obligatoire, enregistré localement.';

  @override
  String get age => 'Âge';

  @override
  String get ageOptionalHelp =>
      'Facultatif. Utilisé uniquement pour des conseils personnalisés.';

  @override
  String get sexGuidanceLabel =>
      'Sexe utilisé pour les conseils d\'hydratation';

  @override
  String get sexOptionalHelp =>
      'Facultatif. Vous pouvez choisir de ne pas répondre à tout moment.';

  @override
  String get onboardingProfileNeededForMetrics =>
      'Enregistrez un surnom et un âge pris en charge avant d\'ajouter des mesures corporelles.';

  @override
  String get chooseDefaultAvatar => 'Choisissez votre avatar par défaut';

  @override
  String get goalMode => 'Mode d\'objectif';

  @override
  String get standardOrManual => 'Standard ou manuel';

  @override
  String get personalizedEstimate => 'Estimation personnalisée';

  @override
  String get standardGoalModeHelp =>
      'Utilisez l\'objectif standard ou saisissez votre propre objectif.';

  @override
  String get personalizedGoalModeHelp =>
      'Utilisez les mesures corporelles enregistrées localement pour calculer une estimation générale de bien-être.';

  @override
  String get weatherBaselineHelp =>
      'L\'assistance météo facultative est choisie séparément et ne remplace jamais votre référence.';

  @override
  String get hydrationSetup => 'Configuration de l\'hydratation';

  @override
  String get dailyGoalMlLabel => 'Objectif quotidien en ml';

  @override
  String get dailyGoalSupportedRange =>
      'Plage prise en charge : 500 à 5000 ml.';

  @override
  String get displayUnit => 'Unité d\'affichage';

  @override
  String get milliliters => 'Millilitres';

  @override
  String get ounces => 'Onces';

  @override
  String get containerSizeMlLabel => 'Taille habituelle du contenant en ml';

  @override
  String get containerSupportedRange =>
      'Plage prise en charge : 100 à 2000 ml.';

  @override
  String get usuallyReusable => 'Habituellement réutilisable';

  @override
  String get reusableHelp =>
      'Activez ceci uniquement si la plupart des boissons enregistrées utilisent une bouteille ou une tasse réutilisable.';

  @override
  String get optionalDeviceFeatures => 'Fonctions facultatives de l\'appareil';

  @override
  String get reviewBeforeStart => 'Vérification avant de commencer';

  @override
  String get ready => 'Prêt';

  @override
  String get onboardingReadySemantics => 'Configuration prête';

  @override
  String onboardingSummary(
      {required String name, required String avatar, required String goal}) {
    return 'Hydrion démarrera avec $name, $avatar, $goal ml/jour et un suivi local.';
  }

  @override
  String get yourProfile => 'votre profil';

  @override
  String get sexFemale => 'Femme';

  @override
  String get sexMale => 'Homme';

  @override
  String get sexIntersex => 'Intersexe';

  @override
  String get preferNotToSay => 'Préfère ne pas répondre';

  @override
  String get hydrationReminders => 'Rappels d\'hydratation';

  @override
  String get remindersCapabilityHelp =>
      'Hydrion peut envoyer des rappels locaux sur cet appareil. Vous pouvez les activer maintenant ou plus tard.';

  @override
  String get remindersNotNowHelp =>
      'Pas maintenant - les rappels peuvent être activés dans Réglages.';

  @override
  String get enableReminders => 'Activer les rappels';

  @override
  String get weatherAssistance => 'Assistance météo';

  @override
  String get weatherCapabilityHelp =>
      'Hydrion peut utiliser une position approximative pour obtenir la météo locale et proposer une suggestion d\'hydratation temporaire. Votre objectif standard fonctionne toujours sans cela.';

  @override
  String get weatherNotNowHelp =>
      'Pas maintenant - votre objectif d\'hydratation standard reste actif.';

  @override
  String get enableWeatherAssistance => 'Activer l\'assistance météo';

  @override
  String get waitingForDevice => 'En attente du résultat de l\'appareil...';

  @override
  String get enabled => 'Activé';

  @override
  String capabilityEnabled({required String title}) {
    return '$title : activé';
  }

  @override
  String capabilityStatus({required String title, required String status}) {
    return '$title : $status';
  }

  @override
  String avatarSelectedSemantics({required String avatar}) {
    return 'Avatar $avatar sélectionné';
  }

  @override
  String selectAvatarSemantics({required String avatar}) {
    return 'Sélectionner l\'avatar $avatar';
  }

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get pullToRefresh => 'Tirer pour actualiser';

  @override
  String tourStepSemantics(
      {required String tour, required int current, required int total}) {
    return '$tour, étape $current sur $total';
  }

  @override
  String get achievementSemantics => 'Réussite';

  @override
  String get noCheckInsYet => 'Aucun suivi pour le moment.';

  @override
  String get coachPreviewTitle => 'Coach';

  @override
  String get coachPreviewComingSoon =>
      'Le Coach Hydrion est en préparation pour une future mise à jour.';

  @override
  String get coachPreviewGuidance =>
      'Pour le moment, continuez à enregistrer votre eau et à suivre votre progression quotidienne.';

  @override
  String get reminderNotificationTitle => 'Rappel Hydrion';

  @override
  String get reminderChannelName => 'Rappels d\'hydratation';

  @override
  String get reminderChannelDescription =>
      'Rappels locaux pour les suivis d\'hydratation Hydrion créés par l\'utilisateur.';

  @override
  String get challengeAroundWorldTitle =>
      'Semaine d\'infusions autour du monde';

  @override
  String get challengeAroundWorldDescription =>
      'Essayez sept thèmes d\'infusion sans sucre ajouté tout en maintenant votre objectif d\'hydratation habituel.';

  @override
  String get challengeTemperatureTitle => 'Roulette des températures';

  @override
  String get challengeTemperatureDescription =>
      'Comparez des températures d\'eau confortables pour découvrir vos préférences.';

  @override
  String get challengeEatWaterTitle => 'Mangez votre eau';

  @override
  String get challengeEatWaterDescription =>
      'Ajoutez un aliment riche en eau choisi à un repas sans inventer de volume d\'hydratation.';

  @override
  String get challengePomodoroTitle => 'Gorgée Pomodoro';

  @override
  String get challengePomodoroDescription =>
      'Associez de modestes suivis d\'hydratation à des pauses de concentration confirmées manuellement.';

  @override
  String get challengePlantTwinTitle => 'Défi plante jumelle';

  @override
  String get challengePlantTwinDescription =>
      'Utilisez un repère d\'entretien de plante pour revoir votre routine d\'hydratation.';

  @override
  String get challengeBottleBingoTitle => 'Bingo de la gourde';

  @override
  String get challengeBottleBingoDescription =>
      'Réalisez un mélange hebdomadaire d\'actions d\'hydratation explicites et de suivis sans hydratation.';

  @override
  String get challengeLunchRefillTitle => 'Remplissage du midi';

  @override
  String get challengeLunchRefillDescription =>
      'Profitez du repas pour vérifier et remplir votre gourde au besoin.';

  @override
  String get challengeHomeworkTitle => 'Hydratation et étude';

  @override
  String get challengeHomeworkDescription =>
      'Associez une vérification confortable à une pause d\'étude.';

  @override
  String get challengeAfterSchoolTitle => 'Recharge de l\'après-midi';

  @override
  String get challengeAfterSchoolDescription =>
      'Faites une pause après votre routine et vérifiez votre hydratation.';

  @override
  String get challengeBackpackTitle => 'Vérification de la gourde';

  @override
  String get challengeBackpackDescription =>
      'Utilisez la préparation du sac pour penser à votre gourde.';

  @override
  String get challengeDeskResetTitle => 'Pause assise';

  @override
  String get challengeDeskResetDescription =>
      'Profitez d\'une pause assise facultative pour revoir votre hydratation.';

  @override
  String get challengeShiftCheckTitle => 'Vérification à mi-parcours';

  @override
  String get challengeShiftCheckDescription =>
      'Ajoutez une vérification facultative au milieu d\'une période de travail.';

  @override
  String get challengeCommuteCupTitle => 'Gourde en déplacement';

  @override
  String get challengeCommuteCupDescription =>
      'Utilisez le départ ou l\'arrivée comme rappel facultatif.';

  @override
  String get challengeEveningReviewTitle => 'Bilan du soir';

  @override
  String get challengeEveningReviewDescription =>
      'Revoyez votre journée et vérifiez si votre plan vous convient.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get aboutAndLegal => 'À propos et mentions légales';

  @override
  String get openSourceLicenses => 'Licences libres';

  @override
  String get openSourceLicensesSummary =>
      'Avis de licence de Flutter et des packages.';

  @override
  String get openSourceLegalese =>
      'Hydrion utilise des composants libres conformément à leurs licences.';

  @override
  String get legalDocument => 'Document juridique';

  @override
  String get reviewHydrionTerms => 'Vérifier les conditions Hydrion';

  @override
  String get continueToHydrion => 'Continuer vers Hydrion';

  @override
  String get acceptHydrionTerms =>
      'J\'accepte les Conditions d\'utilisation de Hydrion.';

  @override
  String get acknowledgeHealthDisclaimer =>
      'Je reconnais avoir pris connaissance de l\'Avis de santé et de sécurité.';

  @override
  String get supportEmailCopied => 'Adresse d\'assistance copiée.';

  @override
  String documentVersion({required Object version}) {
    return 'Version $version';
  }

  @override
  String documentEffective({required Object date}) {
    return 'En vigueur le $date';
  }

  @override
  String documentUpdated({required Object date}) {
    return 'Mis à jour le $date';
  }

  @override
  String get homeTitle => 'Accueil';

  @override
  String get pausedChallengesTitle => 'En pause';

  @override
  String get pausedChallengeSummary =>
      'Progression enregistrée. Les nouveaux journaux ne sont pas évalués.';

  @override
  String weatherConditionTemperature(
      {required Object condition, required Object temperature}) {
    return '$condition - $temperature °C';
  }

  @override
  String get weatherClear => 'Dégagé';

  @override
  String get weatherCloudy => 'Nuageux';

  @override
  String get weatherFog => 'Brouillard';

  @override
  String get weatherRain => 'Pluie';

  @override
  String get weatherSnow => 'Neige';

  @override
  String get weatherStorm => 'Orage';

  @override
  String get weatherMixed => 'Variable';

  @override
  String get weatherUnknown => 'Inconnu';

  @override
  String get tourHydrationBody =>
      'Votre hydratation quotidienne et la quantité restante apparaissent ici.';

  @override
  String get tourLogWater => 'Enregistrer de l\'eau';

  @override
  String get tourLogWaterBody =>
      'Enregistrez la quantité réellement bue. Utilisez un contenant enregistré ou choisissez une autre quantité.';

  @override
  String get tourReviewCorrect => 'Vérifier et corriger';

  @override
  String get tourReviewCorrectBody =>
      'Vérifiez, modifiez ou supprimez une entrée d\'hydratation en cas d\'erreur.';

  @override
  String get tourChallengesBody =>
      'Les défis ajoutent des habitudes et tâches facultatives. L\'eau des défis compte toujours normalement.';

  @override
  String get tourProgressRefresh => 'Progression et actualisation';

  @override
  String get tourProgressRefreshBody =>
      'Consultez vos derniers totaux ici. Tirez vers le bas pour actualiser l\'hydratation et la progression des défis.';

  @override
  String get seeWhatsNew => 'Voir les nouveautés';

  @override
  String get seeWhatsNewBody =>
      'Suivez une courte visite de l\'hydratation, des défis et de la progression.';

  @override
  String get showMe => 'Voir';

  @override
  String get challengeOptions => 'Options du défi';

  @override
  String get challengeSettings => 'Réglages du défi';

  @override
  String get leaveAction => 'Quitter';

  @override
  String challengeTutorialSemantics({required Object title}) {
    return 'Tutoriel $title';
  }

  @override
  String get tourOpenTile => 'Ouvrir une case';

  @override
  String get tourOpenTileBody =>
      'Ouvrez une case pour voir exactement ce qu\'elle demande.';

  @override
  String get tourAutomaticTiles => 'Cases automatiques';

  @override
  String get tourAutomaticTilesBody =>
      'Certaines cases se mettent à jour automatiquement avec vos journaux d\'hydratation habituels.';

  @override
  String get tourActionsCheckIns => 'Actions et validations';

  @override
  String get tourActionsCheckInsBody =>
      'D\'autres cases demandent une boisson mesurée ou une simple validation.';

  @override
  String get tourMakeBingo => 'Faire Bingo';

  @override
  String get tourMakeBingoBody =>
      'Terminez cinq cases sur une ligne, une colonne ou une diagonale pour faire Bingo.';

  @override
  String get tourStartFocus => 'Démarrer une session de concentration';

  @override
  String get tourStartFocusBody =>
      'Démarrez le minuteur au début de votre session de concentration.';

  @override
  String get tourChooseAfterTimer => 'Choisir après le minuteur';

  @override
  String get tourChooseAfterTimerBody =>
      'À la fin, confirmez une gorgée ou enregistrez une boisson mesurée.';

  @override
  String get tourSipNoWater =>
      'Les validations de gorgée n\'ajoutent pas d\'eau';

  @override
  String get tourSipNoWaterBody =>
      'Une validation de gorgée n\'ajoute jamais une quantité d\'hydratation estimée.';

  @override
  String get tourMeasuredDrinks => 'Les boissons mesurées comptent normalement';

  @override
  String get tourMeasuredDrinksBody =>
      'Une boisson mesurée met à jour l\'hydratation normale et peut compter pour un autre défi actif.';

  @override
  String get tourTodaysTemperature => 'Température du jour';

  @override
  String get tourTodaysTemperatureBody =>
      'Consultez le style de température attribué aujourd\'hui.';

  @override
  String get tourWeatherBody =>
      'Lorsqu\'elle est activée, la météo locale peut influencer la recommandation.';

  @override
  String get tourLogWithContext => 'Enregistrer avec le contexte';

  @override
  String get tourLogWithContextBody =>
      'Utilisez l\'action du défi ou ajoutez les détails de température lors de l\'enregistrement depuis Accueil.';

  @override
  String get tourTodaysInfusion => 'Infusion du jour';

  @override
  String get tourTodaysInfusionBody =>
      'Consultez le thème d\'infusion du jour.';

  @override
  String get tourPrepareNoSugar => 'Préparer sans sucre ajouté';

  @override
  String get tourPrepareNoSugarBody =>
      'Utilisez le thème sans ajouter de sucre.';

  @override
  String get tourLogWhatYouDrink => 'Enregistrer ce que vous buvez';

  @override
  String get tourLogWhatYouDrinkBody =>
      'Enregistrez la quantité mesurée réellement bue.';

  @override
  String get whatChallengeIs => 'Présentation du défi';

  @override
  String get whatYouWillDo => 'Ce que vous ferez';

  @override
  String get whatCounts => 'Ce qui compte';

  @override
  String get whatDoesNotCount => 'Ce qui ne compte pas';

  @override
  String get duration => 'Durée';

  @override
  String challengeDurationHelp({required Object days}) {
    return '$days jours calendaires locaux. Le défi commence à l\'inscription. Les exigences quotidiennes sont réinitialisées à minuit local; les jours manqués ne sont pas récupérés automatiquement.';
  }

  @override
  String get completeSchedule => 'Programme complet';

  @override
  String challengeScheduleDay({required Object day, required Object item}) {
    return 'Jour $day : $item';
  }

  @override
  String get howItWorks => 'Fonctionnement';

  @override
  String get hydrationProgressPrivacy =>
      'Hydratation, progression et confidentialité';

  @override
  String get hydrationProgressPrivacyBody =>
      'Votre objectif d\'hydratation habituel reste actif. Les boissons mesurées apparaissent dans Hydrion, tandis que les validations n\'ajoutent pas d\'eau. Les réglages et la progression du défi restent sur cet appareil.';

  @override
  String get requiredSetup => 'Configuration requise';

  @override
  String get requiredSetupHelp =>
      'Choisissez les détails adaptés à votre routine.';

  @override
  String get amountInFluidOunces => 'Quantité en onces liquides';

  @override
  String get dateAndTime => 'Date et heure';

  @override
  String get notSpecified => 'Non précisé';

  @override
  String get addReminder => 'Ajouter un rappel';

  @override
  String get editReminder => 'Modifier le rappel';

  @override
  String get reminderDefaultMessage =>
      'Il est temps de faire un petit point hydratation.';

  @override
  String get messageLabel => 'Message';

  @override
  String get minutesFromNow => 'Minutes à partir de maintenant';

  @override
  String get minutesRangeHelp => 'Utilisez une valeur de 5 à 1440 minutes.';

  @override
  String get priorityLabel => 'Priorité';

  @override
  String get reminderDetailsInvalid =>
      'Vérifiez les détails du rappel et réessayez.';

  @override
  String get ageRangeError => 'Saisissez un âge de 13 à 120 ans.';

  @override
  String get ageSaveFailed => 'L\'âge n\'a pas pu être enregistré. Réessayez.';

  @override
  String get profileDeleteDeviceSummary =>
      'Cette action supprime de cet appareil le profil Hydrion local ainsi que les données d\'hydratation, de rappels et de défis.';

  @override
  String get reviewProfileAge => 'Vérifier l\'âge du profil';

  @override
  String get independentProfileAgeHelp =>
      'Les profils Hydrion indépendants sont disponibles à partir de 13 ans.';

  @override
  String get ageReviewExistingDataHelp =>
      'Vos données locales sont toujours présentes. Si l\'âge enregistré est incorrect, corrigez-le une fois ci-dessous. Sinon, supprimez le profil local et recommencez.';

  @override
  String get correctAge => 'Corriger l\'âge';

  @override
  String get saveAgeCorrection => 'Enregistrer la correction de l\'âge';

  @override
  String get optionalDeviceAccess => 'Accès facultatif à l\'appareil';

  @override
  String get optionalDeviceAccessHelp =>
      'Hydrion fonctionne avec un objectif d\'hydratation standard même si vous ignorez ces options.';

  @override
  String get preciseReminderTiming => 'Horaire précis des rappels';

  @override
  String get allowNotifications => 'Autoriser les notifications';

  @override
  String get continueWithoutReminders => 'Continuer sans rappels';

  @override
  String get allowLocation => 'Autoriser la localisation';

  @override
  String get continueWithStandardGoal => 'Continuer avec l\'objectif standard';

  @override
  String get openAlarmSettings => 'Ouvrir les réglages Alarmes et rappels';

  @override
  String get continueApproximateScheduling =>
      'Continuer avec une programmation approximative';

  @override
  String get refreshStatus => 'Actualiser l\'état';

  @override
  String get requesting => 'Demande en cours';

  @override
  String get waitingPermissionResult =>
      'En attente du résultat de l\'autorisation...';

  @override
  String get openDeviceSettings => 'Ouvrir les réglages de l\'appareil';

  @override
  String get permissionNotRequested => 'Non demandé';

  @override
  String get permissionApproximateEnabled =>
      'Localisation approximative activée';

  @override
  String get permissionPreciseEnabled => 'Localisation précise activée';

  @override
  String get permissionDenied => 'Refusé';

  @override
  String get permissionBlocked => 'Bloqué';

  @override
  String get permissionRestricted => 'Restreint';

  @override
  String get permissionNotRequired => 'Non requis';

  @override
  String get permissionUnsupported => 'Non pris en charge';

  @override
  String get permissionTemporarilyUnavailable => 'Temporairement indisponible';

  @override
  String get permissionStatusUnavailable => 'État indisponible';

  @override
  String get permissionNotificationUnchecked =>
      'L\'état des notifications n\'a pas encore été vérifié.';

  @override
  String get permissionLocationUnchecked =>
      'L\'état de la localisation n\'a pas encore été vérifié.';

  @override
  String get permissionAlarmUnchecked =>
      'L\'état de la programmation des alarmes n\'a pas encore été vérifié.';

  @override
  String get permissionNotificationsAllowed =>
      'Les notifications sont autorisées pour Hydrion.';

  @override
  String get permissionNotificationsOff =>
      'Les notifications sont désactivées. Vous pouvez les autoriser ici ou dans les réglages de l\'appareil.';

  @override
  String get permissionNotificationsNotAsked =>
      'Hydrion n\'a pas encore demandé l\'autorisation d\'envoyer des notifications.';

  @override
  String get permissionNotificationsBlocked =>
      'Les notifications sont bloquées. Ouvrez les réglages de l\'appareil pour les autoriser.';

  @override
  String get permissionNotificationStatusUnavailableAndroid =>
      'Hydrion n\'a pas pu lire l\'état des notifications Android.';

  @override
  String get permissionNotificationsUnsupported =>
      'Les notifications Hydrion ne sont pas prises en charge sur cette plateforme.';

  @override
  String get permissionNotificationStatusTemporary =>
      'L\'état des notifications est temporairement indisponible. Actualisez pour réessayer.';

  @override
  String get permissionPreciseLocationAllowed =>
      'La localisation précise au premier plan est autorisée. Une localisation approximative suffit pour la météo Hydrion.';

  @override
  String get permissionApproximateLocationAllowed =>
      'La localisation approximative au premier plan est autorisée et suffit pour l\'assistance météo.';

  @override
  String get permissionLocationOff =>
      'La localisation est désactivée. Votre objectif d\'hydratation standard fonctionne toujours.';

  @override
  String get permissionLocationNotAsked =>
      'Hydrion n\'a pas encore demandé la localisation.';

  @override
  String get permissionLocationBlocked =>
      'La localisation est bloquée. Ouvrez les réglages de l\'appareil pour activer l\'assistance météo.';

  @override
  String get permissionLocationRestricted =>
      'L\'accès à la localisation est restreint par l\'appareil.';

  @override
  String get permissionLocationServicesOff =>
      'Les services de localisation sont désactivés. Votre objectif standard reste disponible.';

  @override
  String get permissionLocationUnsupported =>
      'L\'assistance météo basée sur la localisation n\'est pas prise en charge sur cette plateforme.';

  @override
  String get permissionLocationStatusTemporary =>
      'L\'état de la localisation est temporairement indisponible. Actualisez pour réessayer.';

  @override
  String get permissionExactAlarmNotRequired =>
      'L\'accès spécial aux alarmes exactes n\'est pas requis sur cet appareil.';

  @override
  String get permissionExactAlarmAndroidOnly =>
      'L\'accès aux alarmes exactes est propre à Android.';

  @override
  String get permissionExactSchedulingAvailable =>
      'La programmation précise des rappels est disponible.';

  @override
  String get permissionExactSchedulingApproximate =>
      'La programmation exacte est indisponible. Hydrion continuera avec des rappels approximatifs.';

  @override
  String historyFocusEndedEarly({required Object session}) {
    return 'Session de concentration $session terminée plus tôt';
  }

  @override
  String historyFocusCompleted({required Object session}) {
    return 'Session de concentration $session terminée';
  }

  @override
  String historyBingoTileCompleted({required Object tile}) {
    return '$tile terminé';
  }

  @override
  String historyBingoLineCompleted({required Object line}) {
    return 'Ligne $line de Bingo bouteille terminée';
  }

  @override
  String historyTemperatureDrink(
      {required Object amount, required Object style}) {
    return 'Boisson $style enregistrée$amount';
  }

  @override
  String historyInfusionTried({required Object amount, required Object theme}) {
    return 'Infusion $theme essayée$amount';
  }

  @override
  String historyPomodoroDrink({required Object amount}) {
    return 'Boisson Pomodoro enregistrée$amount';
  }

  @override
  String historyPomodoroSession({required Object amount}) {
    return 'Session de concentration Pomodoro terminée$amount';
  }

  @override
  String historyPomodoroSessionNumber(
      {required Object amount, required Object session}) {
    return 'Session Pomodoro $session terminée$amount';
  }

  @override
  String historyFoodAdded({required Object food, required Object meal}) {
    return '$food ajouté à $meal';
  }

  @override
  String historyCueCompleted({required Object cue}) {
    return '$cue terminé';
  }

  @override
  String get historyChallengeTaskCompleted => 'Tâche du défi terminée';

  @override
  String historyChallengeDrink({required Object amount}) {
    return 'Boisson du défi enregistrée$amount';
  }

  @override
  String historyBottleBingoDrink({required Object amount}) {
    return 'Boisson Bingo bouteille enregistrée$amount';
  }

  @override
  String historyMeasuredFocusDrink({required Object amount}) {
    return 'Boisson mesurée de la session enregistrée$amount';
  }

  @override
  String get assignedTemperature => 'température attribuée';

  @override
  String get scheduledTemperature => 'température prévue';

  @override
  String get dailyValue => 'du jour';

  @override
  String get mealValue => 'repas';

  @override
  String get waterRichFood => 'aliment riche en eau';

  @override
  String get plantCareCue => 'rappel d\'entretien de la plante';

  @override
  String get bottleBingoTile => 'une case de Bingo bouteille';

  @override
  String get bottleBingoDrink => 'une boisson de Bingo bouteille';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get localProfilePhoto => 'Photo de profil locale';

  @override
  String get profilePhotoSaved => 'Photo de profil enregistrée localement.';

  @override
  String get profilePhotoTooLarge =>
      'Cette photo est trop volumineuse pour le stockage local du profil.';

  @override
  String get profileEditorSummary =>
      'Modifiez votre identité Hydrion et vos préférences. Cela ne relance pas l\'accueil et ne supprime pas l\'historique.';

  @override
  String get profilePhotoPrivacy =>
      'Les photos sélectionnées servent uniquement d\'image de profil locale. Vous pouvez supprimer la photo et revenir à l\'avatar par défaut à tout moment.';

  @override
  String get legal => 'Mentions légales';

  @override
  String get hydrationIdentity => 'Profil d\'hydratation';

  @override
  String get dailyGoal => 'Objectif quotidien';

  @override
  String get units => 'Unités';

  @override
  String get preferredContainer => 'Contenant préféré';

  @override
  String get notSet => 'Non défini';

  @override
  String get noRemindersYet => 'Aucun rappel pour le moment';

  @override
  String savedCount({required int count}) {
    return '$count enregistré(s)';
  }

  @override
  String contactEmail({required String email}) {
    return 'Contact : $email';
  }

  @override
  String get editProfileInvalid =>
      'Vérifiez les champs du profil et réessayez.';

  @override
  String get choosePhoto => 'Choisir une photo';

  @override
  String get useDefaultAvatar => 'Utiliser l\'avatar par défaut';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get defaultProfileAvatar => 'Avatar de profil par défaut';

  @override
  String get baselineDailyGoalMl => 'Objectif quotidien de base en mL';

  @override
  String get preferredContainerMl => 'Contenant préféré en mL';

  @override
  String get personalized => 'Personnalisé';

  @override
  String get saveProfile => 'Enregistrer le profil';

  @override
  String get whyHydrionExists => 'Pourquoi Hydrion existe';

  @override
  String get missionAndCommunity => 'Mission et communauté';

  @override
  String get help => 'Aide';

  @override
  String get replayAppTour =>
      'Visite de l\'application - Revoir le guide rapide';

  @override
  String get appearance => 'Apparence';

  @override
  String get useDeviceSetting => 'Utiliser le réglage de l\'appareil';

  @override
  String get automaticDayNight => 'Jour/nuit automatique';

  @override
  String get dayTheme => 'Jour';

  @override
  String get nightTheme => 'Nuit';

  @override
  String get deviceSetting => 'Réglage de l\'appareil';

  @override
  String get autoDayNight => 'Jour/nuit auto';

  @override
  String dailyGoalPerDay({required int amount}) {
    return '$amount mL/jour';
  }

  @override
  String get personalizedBaselineActive => 'Référence personnalisée';

  @override
  String get manualBaselineActive => 'Référence standard ou manuelle';

  @override
  String get weatherAssistanceSelected => 'Assistance météo sélectionnée';

  @override
  String get weatherAssistanceOff => 'Assistance météo désactivée';

  @override
  String get amountInOz => 'Quantité en oz';

  @override
  String get containerSharedHelp =>
      'Une quantité enregistrée est utilisée par Accueil et Bingo bouteille.';

  @override
  String get containerAmountInvalid =>
      'Saisissez une quantité de 100 à 2000 mL.';

  @override
  String get permissionsSummary =>
      'Vérifiez les rappels, la localisation météo et l\'accès aux alarmes Android.';

  @override
  String get legalPrivacySupport =>
      'Mentions légales, confidentialité et assistance';

  @override
  String get widgetNoActiveChallenge => 'Aucun défi actif';

  @override
  String get widgetChooseChallenge => 'Ouvrez Hydrion pour choisir un défi.';

  @override
  String get widgetOpenChallenges => 'Voir les défis';

  @override
  String get widgetChallengePaused => 'Défi en pause';

  @override
  String get widgetActivityActive => 'Activité en cours';

  @override
  String get widgetActivityPaused => 'Activité en pause';

  @override
  String get widgetActivityComplete => 'Activité du jour terminée';

  @override
  String widgetCheckpointProgress(
      {required int completed, required int total}) {
    return '$completed étapes sur $total aujourd\'hui';
  }

  @override
  String get widgetOpenToContinue => 'Ouvrez Hydrion pour continuer';

  @override
  String get widgetOpenChallenge => 'Ouvrir le défi';

  @override
  String get reportsTitle => 'Rapports d\'hydratation';

  @override
  String get reportsDescription =>
      'Creez un resume prive a partir des donnees stockees sur cet appareil.';

  @override
  String get reportsOpen => 'Creer un rapport';

  @override
  String get reportsFrequency => 'Frequence du rapport';

  @override
  String get reportsWeekly => 'Hebdomadaire';

  @override
  String get reportsMonthly => 'Mensuel';

  @override
  String get reportsQuarterly => 'Trimestriel';

  @override
  String get reportsYearly => 'Annuel';

  @override
  String get reportsChoosePeriod => 'Choisir la periode';

  @override
  String get reportsPeriod => 'Periode';

  @override
  String get reportsGenerated => 'Genere';

  @override
  String get reportsPreview => 'Apercu du rapport';

  @override
  String get reportsTotal => 'Volume total enregistre';

  @override
  String get reportsAverage => 'Moyenne des jours suivis';

  @override
  String get reportsTrackedDays => 'Jours suivis';

  @override
  String get reportsTargetsMet => 'Objectifs connus atteints';

  @override
  String get reportsTarget => 'Objectif applicable';

  @override
  String get reportsDate => 'Date';

  @override
  String get reportsIntake => 'Volume enregistre';

  @override
  String get reportsMissing => 'Aucune donnee';

  @override
  String get reportsUnavailable => 'Indisponible';

  @override
  String get reportsPartial => 'Cette periode est encore en cours.';

  @override
  String get reportsEmpty =>
      'Aucune consommation d\'eau n\'a ete enregistree pour cette periode.';

  @override
  String get reportsLegacyTarget =>
      'Les anciens objectifs non stockes sont indiques comme indisponibles.';

  @override
  String get reportsDisclaimer =>
      'Ce rapport resume les donnees d\'hydratation saisies par l\'utilisateur. Il ne constitue ni un diagnostic medical ni un substitut a un avis medical professionnel.';

  @override
  String get reportsExport => 'Exporter le PDF';

  @override
  String get reportsExported => 'Rapport partage.';

  @override
  String get reportsDismissed => 'Le partage a ete annule.';

  @override
  String get reportsExportFailed =>
      'Le rapport n\'a pas pu etre exporte. Reessayez.';

  @override
  String get reportsPage => 'Page';

  @override
  String get reportsVisualization => 'Hydratation enregistree';

  @override
  String get healthDataTitle => 'Connecter les donnees de sante';

  @override
  String get healthDataSettingsSummary =>
      'Importer les activites approuvees depuis un fournisseur disponible sur cet appareil.';

  @override
  String get healthDataProvider => 'Fournisseur';

  @override
  String get healthDataHealthConnect => 'Health Connect';

  @override
  String get healthDataAppleHealth => 'Apple Health';

  @override
  String get healthDataAppleAccessRequested =>
      'L\'acces a Apple Health a ete demande. Apple protege vos choix, Hydrion ne peut donc pas afficher les categories de lecture que vous avez autorisees.';

  @override
  String get healthDataContributingSources => 'Sources contributrices :';

  @override
  String get healthDataAvailable =>
      'Ce fournisseur de donnees de sante est disponible sur cet appareil.';

  @override
  String get healthDataLoading =>
      'Verification des fournisseurs de donnees de sante disponibles...';

  @override
  String get healthDataInstallationRequired =>
      'Installez Health Connect pour utiliser les donnees de sante Android.';

  @override
  String get healthDataUpdateRequired =>
      'Mettez Health Connect a jour avant la connexion.';

  @override
  String get healthDataUnsupported =>
      'Health Connect n\'est pas pris en charge dans ce profil d\'appareil.';

  @override
  String get healthDataPermissionNotRequested =>
      'L\'acces aux donnees de sante n\'a pas ete demande.';

  @override
  String get healthDataPermissionPartial =>
      'Certaines categories demandees ne sont pas autorisees.';

  @override
  String get healthDataPermissionDenied =>
      'L\'acces aux donnees de sante n\'est pas autorise. Le suivi manuel reste disponible.';

  @override
  String get healthDataConnected =>
      'Connecte en lecture seule aux donnees de sante.';

  @override
  String get healthDataConnectedNoData =>
      'Connecte, mais aucun enregistrement lisible n\'a ete trouve.';

  @override
  String get healthDataSynchronizing =>
      'Synchronisation des donnees de sante...';

  @override
  String get healthDataSyncPartial =>
      'La synchronisation est terminee, mais certaines categories sont indisponibles.';

  @override
  String healthDataSuccessfulCategories({required String categories}) {
    return 'Categories synchronisees : $categories';
  }

  @override
  String healthDataFailedCategories({required String categories}) {
    return 'Categories necessitant une attention : $categories';
  }

  @override
  String get healthDataRetryFailedCategories =>
      'Reessayer les categories en echec';

  @override
  String get healthDataSyncFailed =>
      'Les donnees de sante n\'ont pas pu etre synchronisees.';

  @override
  String get healthDataStorageUnavailable =>
      'Le stockage protege des donnees de sante est indisponible. Aucun dossier n\'a ete importe.';

  @override
  String get healthDataProviderFailure =>
      'Le fournisseur de donnees de sante n\'a pas pu etre actualise. Reessayez ou gerez l\'acces au fournisseur.';

  @override
  String get healthDataDisconnected =>
      'Deconnecte dans Hydrion. Les autorisations sources restent gerees par le fournisseur de donnees de sante.';

  @override
  String get healthDataConsentIntro =>
      'Hydrion demande un acces en lecture seule au fournisseur affiche ci-dessus uniquement apres votre choix de connexion.';

  @override
  String get healthDataCategories => 'Categories demandees';

  @override
  String get healthDataWorkouts => 'Entrainements';

  @override
  String get healthDataActiveEnergy => 'Energie active';

  @override
  String get healthDataSteps => 'Pas';

  @override
  String get healthDataDistance => 'Distance';

  @override
  String get healthDataCategoryExplanation =>
      'Les entrainements fournissent la duree d\'activite. L\'energie active fournit le contexte d\'effort. Les pas et la distance servent de contexte de secours sans double comptage.';

  @override
  String get healthDataPrivacyExplanation =>
      'Les donnees importees restent chiffrees sur cet appareil. Aucun compte Hydrion ni envoi infonuagique n\'est requis. Vous pouvez refuser, gerer l\'acces au fournisseur, vous deconnecter ou supprimer la copie importee sans supprimer les donnees sources.';

  @override
  String get healthDataWellnessDisclaimer =>
      'Il s\'agit d\'informations de bien-etre, et non d\'un diagnostic medical. Les donnees importees ne modifient pas votre objectif d\'hydratation dans cette version.';

  @override
  String get healthDataConnect => 'Connecter';

  @override
  String get healthDataRequestMissing => 'Demander les acces manquants';

  @override
  String get healthDataSynchronize => 'Synchroniser';

  @override
  String get healthDataOpenSettings => 'Ouvrir les parametres Android';

  @override
  String get healthDataDisconnect => 'Deconnecter';

  @override
  String get healthDataDeleteImported => 'Supprimer les donnees importees';

  @override
  String get healthDataDeleteQuestion =>
      'Supprimer les donnees de sante importees par Hydrion?';

  @override
  String get healthDataDeleteExplanation =>
      'Cette action supprime la copie chiffree importee par Hydrion et les points de reprise. Elle ne supprime ni les donnees du fournisseur source ni l\'historique d\'hydratation manuel.';

  @override
  String healthDataImportedCount({required int count}) {
    return 'Enregistrements importes : $count';
  }

  @override
  String healthDataGrantedCategories({required String categories}) {
    return 'Autorisees : $categories';
  }

  @override
  String get healthDataNoGrantedCategories => 'Autorisees : aucune';

  @override
  String healthDataContributors({required String applications}) {
    return 'Applications contributrices : $applications';
  }

  @override
  String get healthDataNoContributors =>
      'Applications contributrices : aucune trouvee';

  @override
  String healthDataLastSuccessful({required String time}) {
    return 'Derniere synchronisation reussie : $time';
  }

  @override
  String get healthDataNeverSynchronized =>
      'Derniere synchronisation reussie : jamais';

  @override
  String get healthDataDashboardTitle => 'Donnees de sante';

  @override
  String get healthDataPermissionRequesting =>
      'Ouverture des autorisations du fournisseur...';

  @override
  String get healthDataConnectedNotSynchronized =>
      'Fournisseur de donnees de sante connecte';

  @override
  String get healthDataNoSyncYet =>
      'Aucune synchronisation terminee pour le moment.';

  @override
  String get healthDataSynchronizedWithRecords => 'Connecte et synchronise';

  @override
  String get healthDataSynchronizedNoRecords =>
      'Connecte, mais aucune donnee de sante n\'a ete trouvee';

  @override
  String get healthDataNoDataExplanation =>
      'Le fournisseur n\'a renvoye aucun entrainement, energie active, pas ou distance lisible. Il se peut qu\'aucune donnee correspondante ne soit disponible ou que l\'acces en lecture n\'ait pas ete autorise. Verifiez l\'application source, puis reessayez.';

  @override
  String get healthDataPermissionRevoked =>
      'L\'acces aux donnees de sante requiert votre attention';

  @override
  String healthDataMissingCategories({required String categories}) {
    return 'Acces manquants : $categories';
  }

  @override
  String healthDataLastAttempt({required String time}) {
    return 'Derniere tentative : $time';
  }

  @override
  String get healthDataLatestAttemptFailed =>
      'La derniere synchronisation a echoue. Les donnees deja importees n\'ont pas ete modifiees.';

  @override
  String healthDataSyncCounts(
      {required int read,
      required int inserted,
      required int updated,
      required int deleted,
      required int rejected}) {
    return 'Derniere synchro : $read lus, $inserted nouveaux, $updated mis a jour, $deleted supprimes, $rejected rejetes';
  }

  @override
  String healthDataRecordPeriod({required String start, required String end}) {
    return 'Periode disponible : $start - $end';
  }

  @override
  String healthDataSourceCount({required String source, required int count}) {
    return '$source : $count enregistrements';
  }

  @override
  String get healthDataDataAvailable => 'Donnees disponibles';

  @override
  String get healthDataWhatReads => 'Ce que lit Hydrion';

  @override
  String get healthDataViewImportedData => 'Voir les données importées';

  @override
  String get healthDataImportedDataTitle => 'Données wearable importées';

  @override
  String get healthDataWorkoutTimeline => 'Chronologie des entraînements';

  @override
  String get healthDataWorkoutTimelineEmpty =>
      'Aucun entraînement importé pour le moment.';

  @override
  String healthDataWorkoutRow({required int minutes}) {
    return 'Entraînement de $minutes min';
  }

  @override
  String get healthDataStepsTrend => 'Tendance des pas (14 derniers jours)';

  @override
  String get healthDataDistanceTrend =>
      'Tendance de la distance (14 derniers jours)';

  @override
  String get healthDataActiveEnergyTrend =>
      'Tendance de l\'énergie active (14 derniers jours)';

  @override
  String get healthDataTrendEmpty =>
      'Aucune donnée au cours des 14 derniers jours.';

  @override
  String healthDataTrendDayTotal(
      {required String date, required String value, required String unit}) {
    return '$date : $value $unit';
  }

  @override
  String healthDataRecordSource(
      {required String source, required String date}) {
    return '$source · $date';
  }

  @override
  String get healthDataSyncNow => 'Synchroniser';

  @override
  String get healthDataTryAgain => 'Reessayer';

  @override
  String get healthDataManageAccess => 'Gerer l\'acces';

  @override
  String get healthDataCheckHealthConnect => 'Ouvrir Health Connect';

  @override
  String get healthDataReadingSecurely =>
      'Lecture securisee des enregistrements autorises. Ne fermez pas Hydrion.';

  @override
  String get healthDataReasonUnavailable =>
      'Le fournisseur de donnees de sante etait indisponible.';

  @override
  String get healthDataReasonPermission =>
      'L\'acces aux donnees de sante a ete refuse ou revoque.';

  @override
  String get healthDataReasonOperation =>
      'L\'operation de synchronisation securisee n\'a pas pu aboutir.';
}
