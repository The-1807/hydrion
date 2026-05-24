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
  String get arTitle => 'Vue AR hydratation';

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
  String get arDisabledRoute => 'AR désactivée';

  @override
  String get arUnavailableRoute => 'AR indisponible';

  @override
  String voiceIntent({required Object intent}) {
    return 'Intention vocale : $intent';
  }

  @override
  String get hydrationAdviceCardSemantics => 'Carte de conseil hydratation';

  @override
  String get stayHydratedFallback => 'Restez hydraté.';

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
  String get localDataNoProviderRuntime =>
      'Données locales, règles locales, aucun runtime fournisseur.';

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
      'Les futures langues apparaîtront après ajout de vrais fichiers ARB.';

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
  String get runtimeFeatureStatus => 'État des fonctions runtime';

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
  String get arVisualization => 'Visualisation AR';

  @override
  String get arVisualizationDescription =>
      'La route AR est un espace réservé ; aucune caméra ni session AR native ne démarre.';

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
  String get badgeTwoLiterDay => 'Jour 2 L';

  @override
  String get badgeThreeLogsToday => '3 journaux aujourd\'hui';

  @override
  String get badgeSevenDayStreak => 'Série 7 jours';

  @override
  String plasticSavedTitle({required Object value}) {
    return 'Plastique économisé : $value kg';
  }

  @override
  String localEstimateFromLogs(
      {required int lifetimeMl, required int eventCount}) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount journaux enregistrés',
      one: '1 journal enregistré',
    );
    return 'Estimation locale à partir de $lifetimeMl ml sur $_temp0.';
  }

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
      'Excellent rythme hydratation. Gardez la série active.';

  @override
  String get hydrationTipGreat =>
      'Très bon rythme. Gardez des gorgées régulières pendant l\'après-midi.';

  @override
  String get hydrationTipClose =>
      'Vous êtes proche. Ajoutez une bouteille dans la prochaine heure pour dépasser l\'objectif.';

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
  String get arCapabilityReportedNoAdapter =>
      'La capacité AR est signalée, mais aucun adaptateur AR est connecté.';

  @override
  String get arDisabledStandalone =>
      'AR est désactivée dans cette version autonome.';

  @override
  String get arCapabilityNoSession =>
      'Hydrion ne démarrera pas de caméra ni de session AR native avant configuration d\'un adaptateur.';

  @override
  String get arNoPluginActive =>
      'Aucun plugin AR, autorisation caméra ni session AR native active.';

  @override
  String get chatError => 'Impossible d\'obtenir la réponse du coach';

  @override
  String get localFallbackCoach => 'Coach local de secours';

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
  String get askCoachEmpty =>
      'Demandez une suggestion hydratation. Les réponses sont une aide locale déterministe basée sur les journaux enregistrés.';

  @override
  String get chatHint => 'Demandez à votre coach...';

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
