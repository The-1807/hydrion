// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Hydrion';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get hydrionLogoSemantics => 'Logotipo de Hydrion';

  @override
  String get analyticsTitle => 'Analítica';

  @override
  String get achievementsTitle => 'Logros';

  @override
  String get ecoImpactTitle => 'Impacto ambiental';

  @override
  String get challengesTitle => 'Desafíos';

  @override
  String get chatCoachTitle => 'Coach de hidratación';

  @override
  String get logTitle => 'Registro de hidratación';

  @override
  String get remindersTitle => 'Recordatorios';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String loggedVolume({required int volumeMl}) {
    return '$volumeMl ml registrados';
  }

  @override
  String get logHydration => 'Registrar hidratación';

  @override
  String get amountLabel => 'Cantidad';

  @override
  String logVolume({required int volumeMl}) {
    return 'Registrar $volumeMl ml';
  }

  @override
  String get savedLocally => 'Guardado localmente en este dispositivo.';

  @override
  String savedLocallySyncDisabled(
      {required Object syncNames, required Object verb}) {
    return 'Guardado localmente en este dispositivo. La sincronización de $syncNames está desactivada.';
  }

  @override
  String get analyticsRoute => 'Analítica';

  @override
  String get logRoute => 'Registro';

  @override
  String get coachRoute => 'Coach';

  @override
  String get challengesRoute => 'Desafíos';

  @override
  String get remindersRoute => 'Recordatorios';

  @override
  String voiceIntent({required Object intent}) {
    return 'Intención de voz: $intent';
  }

  @override
  String get hydrationAdviceCardSemantics =>
      'Tarjeta de consejo de hidratación';

  @override
  String get stayHydratedFallback => 'Mantente hidratado.';

  @override
  String get homeAdviceStrong =>
      'Llevas un ritmo de hidratación sólido. Sigue tomando sorbos pequeños durante el día.';

  @override
  String get homeAdviceClose =>
      'Estás cerca del objetivo. Añade un vaso de agua en la próxima hora para mantenerte estable.';

  @override
  String get homeAdviceStart =>
      'Empieza con 300 a 500 ml ahora y vuelve a revisar después de tu próxima bebida.';

  @override
  String get homeAdviceGoalReached =>
      'Alcanzaste el objetivo de hoy. Las necesidades de hidratación varían, así que mantén un ritmo cómodo y bebe según tu sed.';

  @override
  String get homeAdviceHeat =>
      'El calor aumenta tus necesidades de hidratación.';

  @override
  String homeAdviceReliableEntries({required int count}) {
    return 'Tienes $count entradas locales hoy, lo que hace que la tendencia sea más fiable.';
  }

  @override
  String get homeAdviceAddEntries =>
      'Añade entradas cuando bebas para que Hydrion pueda seguir el día con honestidad.';

  @override
  String get failedToLoadAdvice => 'No se pudo cargar el consejo';

  @override
  String get retry => 'Reintentar';

  @override
  String get osNotificationsAvailableSentence =>
      'Las notificaciones del sistema están disponibles.';

  @override
  String get osNotificationsDisabledSentence =>
      'Las notificaciones del sistema están desactivadas.';

  @override
  String get noLocalReminderNeeded =>
      'No se necesitó una definición local de recordatorio';

  @override
  String localReminderSaved({required Object notificationStatus}) {
    return 'Definición local de recordatorio guardada. $notificationStatus';
  }

  @override
  String get failedToScheduleReminder => 'No se pudo guardar el recordatorio';

  @override
  String get localReminderDefinition => 'Definición local de recordatorio';

  @override
  String reminderTileNoSaved({required Object notificationStatus}) {
    return 'No hay recordatorios guardados. Hydrion solo almacena definiciones de recordatorio. $notificationStatus';
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
          '$count guardados localmente. Próxima definición: $time. $notificationStatus',
      one:
          '1 guardado localmente. Próxima definición: $time. $notificationStatus',
    );
    return '$_temp0';
  }

  @override
  String get saveLocalReminderDefinitionTooltip =>
      'Guardar definición local de recordatorio';

  @override
  String get voiceInputAvailableSemantics => 'Entrada de voz disponible';

  @override
  String get voiceInputDisabledSemantics => 'Entrada de voz desactivada';

  @override
  String get voiceCapabilityReportedNoAdapter =>
      'La capacidad de voz está informada, pero no hay adaptador de voz conectado';

  @override
  String get voiceInputDisabledTooltip =>
      'Entrada de voz desactivada por las capacidades de la app';

  @override
  String get standaloneLocalMode => 'Modo local independiente';

  @override
  String get elkaAdapterConfiguredMode => 'Adaptador ELKA configurado';

  @override
  String get geminiProviderConfiguredMode => 'Proveedor Gemini configurado';

  @override
  String get localDataNoProviderRuntime =>
      'Seguimiento privado en este dispositivo.';

  @override
  String get geminiProviderConfiguredDescription =>
      'Gemini puede proponer acciones tipadas; Hydrion las valida antes de confiar en ellas.';

  @override
  String get geminiProviderConfiguredLocalDescription =>
      'Gemini está configurado, pero deshabilitado hasta que se active el consentimiento de privacidad del proveedor.';

  @override
  String get geminiProviderActiveDescription =>
      'Gemini puede recibir contexto de hidratación tipado; Hydrion valida la salida del proveedor antes de confiar en ella.';

  @override
  String get language => 'Idioma';

  @override
  String get appLanguageLabel => 'Idioma de la app';

  @override
  String get languageUpdated => 'Idioma actualizado';

  @override
  String get languageChoiceSaved =>
      'La elección de idioma se guarda localmente.';

  @override
  String get localeCoverageComplete =>
      'Las cadenas de Hydrion están disponibles para este idioma.';

  @override
  String get localeCoveragePartial =>
      'Las cadenas de Hydrion están disponibles; el texto de plataforma no traducido usa una alternativa segura.';

  @override
  String get futureLanguagesNote =>
      'Los idiomas adicionales aparecerán solo cuando las traducciones estén completas.';

  @override
  String get localeNameEnglish => 'Inglés';

  @override
  String get localeNameSpanish => 'Español';

  @override
  String get localeNameFrench => 'Francés';

  @override
  String get permissions => 'Permisos';

  @override
  String get standalonePermissionsExplanation =>
      'El modo independiente no solicita permisos de Bluetooth, Salud, micrófono, cámara ni notificaciones.';

  @override
  String get check => 'Comprobar';

  @override
  String get noPlatformPermissionsRequested =>
      'No se solicitaron permisos de plataforma en modo independiente';

  @override
  String get dailyGoalTitle => 'Objetivo diario de hidratación';

  @override
  String get dailyGoalDescription =>
      'Define el objetivo que Hydrion usa en Inicio, Analítica, Coach y desafíos locales. Las necesidades de hidratación varían por persona y día.';

  @override
  String get dailyGoalFieldLabel => 'Objetivo en ml';

  @override
  String dailyGoalRange({required int minMl, required int maxMl}) {
    return '$minMl-$maxMl ml';
  }

  @override
  String get dailyGoalUpdated => 'Objetivo diario actualizado';

  @override
  String get dailyGoalInvalid => 'Ingresa un objetivo entre 500 y 5000 ml';

  @override
  String get reusableContainerTitle => 'Recipiente reutilizable';

  @override
  String get reusableContainerDescription =>
      'Estima plástico desechable evitado solo cuando las bebidas registradas suelen venir de una botella o vaso reutilizable.';

  @override
  String get localFirstPrivacyTitle => 'Privacidad local';

  @override
  String get localFirstPrivacyDescription =>
      'Hydrion funciona sin conexión y guarda registros, objetivos, idioma y progreso de desafíos en este dispositivo.';

  @override
  String get optionalProviderConsumerDescription =>
      'Las funciones opcionales con proveedor permanecen desactivadas hasta que decidas habilitarlas. Hydrion sigue funcionando sin conexión.';

  @override
  String get debugDiagnosticsTitle => 'Diagnósticos de depuración';

  @override
  String get debugDiagnosticsDescription =>
      'Los detalles técnicos para desarrollo están disponibles solo en compilaciones de depuración.';

  @override
  String get runtimeFeatureStatus => 'Estado de funciones en ejecución';

  @override
  String get providerHealthTitle => 'Estado del proveedor de IA';

  @override
  String get selectedProvider => 'Proveedor seleccionado';

  @override
  String get activeProvider => 'Proveedor activo';

  @override
  String get localRulesProvider => 'Guía en el dispositivo';

  @override
  String get geminiProvider => 'Gemini';

  @override
  String get elkaProvider => 'ELKA';

  @override
  String get providerAvailable => 'Disponible';

  @override
  String get providerUnavailable => 'No disponible';

  @override
  String get providerConfigured => 'Configurado';

  @override
  String get providerUnconfigured => 'Sin configurar';

  @override
  String get providerFallbackState => 'Estado de respaldo';

  @override
  String get providerFallbackReady =>
      'La guía en el dispositivo está disponible';

  @override
  String get providerFallbackInUse => 'Usando guía en el dispositivo';

  @override
  String get providerFallbackCode => 'Código de respaldo';

  @override
  String get providerFallbackReason => 'Motivo de respaldo';

  @override
  String get providerNoFallback => 'No se necesita respaldo';

  @override
  String get providerLastFailure => 'Último fallo del proveedor';

  @override
  String get providerNoFailure => 'Ninguno';

  @override
  String get providerPrivacyTitle => 'Privacidad del proveedor';

  @override
  String get providerPrivacyLocalOnly =>
      'La guía en el dispositivo mantiene el contexto de hidratación en este dispositivo.';

  @override
  String get providerPrivacyGeminiDisclosure =>
      'Cuando Gemini está configurado, Hydrion puede enviar contexto de hidratación tipado a Gemini. No incluyas una clave compartida de Gemini en artefactos web o móviles.';

  @override
  String get providerConsentRequired =>
      'La IA no local requiere consentimiento explícito del usuario antes de producción.';

  @override
  String get providerConsentStatus => 'Consentimiento del proveedor';

  @override
  String get providerConsentToggleTitle =>
      'Permitir procesamiento del proveedor Gemini';

  @override
  String get providerConsentEnabled =>
      'Habilitado. El contexto de hidratación tipado puede salir de este dispositivo para solicitudes de Gemini.';

  @override
  String get providerConsentDisabled =>
      'Deshabilitado. Hydrion usa guía en el dispositivo y no envía contexto de hidratación a Gemini.';

  @override
  String get providerGeminiHealth => 'Estado de Gemini';

  @override
  String get providerGeminiModel => 'Modelo Gemini';

  @override
  String get providerGeminiConfigured => 'Gemini configurado';

  @override
  String get providerDiagnosticsTitle => 'Diagnósticos de Gemini';

  @override
  String get providerEndpointHost => 'Host del endpoint';

  @override
  String get providerModelPath => 'Ruta del modelo';

  @override
  String get providerApiKeyPresent => 'Clave API presente';

  @override
  String get providerApiKeyLength => 'Longitud de clave';

  @override
  String get providerApiKeyFingerprint => 'Huella de clave API';

  @override
  String get providerApiKeyContainsWhitespace => 'Clave con espacios';

  @override
  String get providerApiKeyWasTrimmed => 'Clave recortada';

  @override
  String get providerApiKeyStartsWithGooglePrefix => 'Prefijo de Google';

  @override
  String get providerAuthHeaderPresent => 'Encabezado auth presente';

  @override
  String get providerAuthHeaderValueLength => 'Longitud encabezado auth';

  @override
  String get providerRequestAttempted => 'Solicitud intentada';

  @override
  String get providerHttpStatusClass => 'Estado HTTP';

  @override
  String get providerErrorStatus => 'Estado de error de Gemini';

  @override
  String get providerErrorMessage => 'Mensaje de error de Gemini';

  @override
  String get providerErrorDetails => 'Detalles de error de Gemini';

  @override
  String get providerLastDiagnosticPhase => 'Último diagnóstico';

  @override
  String get providerParserCode => 'Código del analizador';

  @override
  String get providerValidatorCode => 'Código del validador';

  @override
  String get providerBlockedCapabilities => 'Capacidades bloqueadas';

  @override
  String get providerLastSuccess => 'Último éxito de Gemini';

  @override
  String get providerLastFailureAt => 'Hora del último fallo';

  @override
  String get providerNotAvailable => 'No disponible';

  @override
  String get providerDiagnosticNoApiKey =>
      'No hay clave API de Gemini configurada';

  @override
  String get providerDiagnosticConsentRequired =>
      'Gemini está configurado, pero el consentimiento de privacidad del proveedor está deshabilitado';

  @override
  String get providerDiagnosticHealthy =>
      'Gemini está saludable; la última respuesta pasó la validación';

  @override
  String get providerDiagnosticFallbackActive =>
      'La guía en el dispositivo está activa';

  @override
  String get providerDiagnosticNotProven =>
      'Gemini está configurado, pero aún no se ha comprobado como saludable';

  @override
  String get providerDiagnosticLocalRules =>
      'La guía en el dispositivo está activa';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get localPersistence => 'Persistencia local';

  @override
  String get onDevice => 'En dispositivo';

  @override
  String get unavailable => 'No disponible';

  @override
  String get localPersistenceDescription =>
      'Los registros de hidratación, ajustes, recordatorios y estado de desafíos se almacenan localmente.';

  @override
  String get elkaAdapter => 'Adaptador ELKA';

  @override
  String get configured => 'Configurado';

  @override
  String get unconfigured => 'Sin configurar';

  @override
  String get elkaAdapterDescription =>
      'El límite del adaptador existe, pero no hay runtime ELKA conectado.';

  @override
  String get cloudAi => 'IA en la nube';

  @override
  String get connected => 'Conectado';

  @override
  String get disabled => 'Desactivado';

  @override
  String get cloudAiDescription =>
      'No hay SDK de proveedor ni modelo en la nube conectado.';

  @override
  String get cloudAiConfiguredDescription =>
      'Gemini está configurado como proveedor opcional; los proveedores no pueden modificar el estado de la app.';

  @override
  String get cloudAiConsentRequiredDescription =>
      'Gemini está configurado, pero no activo hasta que se habilite el consentimiento de privacidad del proveedor.';

  @override
  String get voiceInput => 'Entrada de voz';

  @override
  String get available => 'Disponible';

  @override
  String get voiceInputDescription =>
      'Los comandos escritos se pueden analizar; la captura de micrófono no está disponible.';

  @override
  String get bleBottleSync => 'Sincronización BLE de botella';

  @override
  String get bleSyncDescription =>
      'No se inicia ningún escaneo Bluetooth, conexión ni lectura de nivel de botella.';

  @override
  String get healthSync => 'Sincronización de salud';

  @override
  String get healthSyncDescription =>
      'No hay lectura activa de HealthKit, Google Fit ni wearables.';

  @override
  String get osNotifications => 'Notificaciones del sistema';

  @override
  String get osNotificationsDisabledTitle =>
      'Notificaciones del sistema desactivadas';

  @override
  String get osNotificationsDescription =>
      'Las definiciones de recordatorio se guardan localmente; no se programa ninguna notificación de plataforma.';

  @override
  String get socialSync => 'Sincronización social';

  @override
  String get localOnly => 'Solo local';

  @override
  String get socialSyncDescription =>
      'Los desafíos son solo locales; no se comparte estado con un backend.';

  @override
  String get hydrationLogUpdated => 'Registro de hidratación actualizado';

  @override
  String get hydrationLogDeleted => 'Registro de hidratación eliminado';

  @override
  String get hydrationLogRestored => 'Registro de hidratación restaurado';

  @override
  String get undo => 'Deshacer';

  @override
  String get logNotFound => 'Registro no encontrado';

  @override
  String get noLogs => 'No se encontraron registros de hidratación';

  @override
  String get logEmptyDescription =>
      'Usa Inicio para agregar una entrada local de hidratación. Los registros se guardan en este dispositivo.';

  @override
  String get editLogTooltip => 'Editar registro';

  @override
  String get deleteLogTooltip => 'Eliminar registro';

  @override
  String get editHydrationLog => 'Editar registro de hidratación';

  @override
  String get amountInMl => 'Cantidad en ml';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get localEntry => 'Entrada local';

  @override
  String logSourceTimestamp(
      {required Object source, required Object timestamp}) {
    return '$source - $timestamp';
  }

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String relativeDateTime({required Object date, required Object time}) {
    return '$date, $time';
  }

  @override
  String get noAnalyticsYet => 'Aún no hay analítica';

  @override
  String get analyticsEmptyDescription =>
      'Registra hidratación en Inicio para crear tendencias locales.';

  @override
  String todayHydrationTitle({required int todayMl, required int targetMl}) {
    return '$todayMl / $targetMl ml hoy';
  }

  @override
  String localEntriesToday({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entradas locales hoy. Los datos permanecen en este dispositivo.',
      one: '1 entrada local hoy. Los datos permanecen en este dispositivo.',
    );
    return '$_temp0';
  }

  @override
  String get badgeDailyGoal => 'Objetivo diario';

  @override
  String get badgeThreeLogsToday => '3 registros hoy';

  @override
  String get badgeSevenDayStreak => 'Racha de 7 días';

  @override
  String plasticEstimateTitle({required Object value}) {
    return 'Estimación de plástico evitado: $value kg';
  }

  @override
  String reusableContainerEstimateFromLogs(
      {required int lifetimeMl, required int eventCount}) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount registros guardados',
      one: '1 registro guardado',
    );
    return 'La estimación asume que las bebidas registradas usaron tu recipiente reutilizable: $lifetimeMl ml en $_temp0.';
  }

  @override
  String get reusableContainerEstimateDisabled =>
      'Activa el seguimiento de recipiente reutilizable en Ajustes antes de estimar plástico desechable evitado.';

  @override
  String get hydrationScoreTitle => 'Puntuación de hidratación';

  @override
  String get hydrationScoreSemantics => 'Puntuación de hidratación';

  @override
  String scoreOutOf100({required Object score}) {
    return '$score de 100';
  }

  @override
  String get scoreSuffix => '/ 100';

  @override
  String logCount({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
    );
    return '$_temp0';
  }

  @override
  String get hydrationTipExcellent =>
      'Objetivo alcanzado. Las necesidades varían; mantén el resto del día estable.';

  @override
  String get hydrationTipGreat =>
      'Buen ritmo. Mantén sorbos cómodos y constantes.';

  @override
  String get hydrationTipClose =>
      'Estás cerca. Una bebida moderada puede ayudarte a llegar al objetivo.';

  @override
  String get hydrationTipStart =>
      'Empieza con 300 a 500 ml ahora y configura un recordatorio.';

  @override
  String get achievementStatusUnlocked => 'desbloqueado';

  @override
  String get achievementStatusLocked => 'bloqueado';

  @override
  String achievementBadgeSemantics(
      {required Object badgeName, required Object status}) {
    return 'Insignia de logro: $badgeName $status';
  }

  @override
  String get hydrationProgressRing => 'Anillo de progreso de hidratación';

  @override
  String percentValue({required int percent}) {
    return '$percent por ciento';
  }

  @override
  String consumedOfTarget({required int consumedMl, required int targetMl}) {
    return 'Consumidos $consumedMl de $targetMl mililitros';
  }

  @override
  String get chatError => 'No se pudo obtener la respuesta del coach';

  @override
  String get localFallbackCoach => 'Coach en el dispositivo';

  @override
  String get providerCoachTitle => 'Coach con proveedor';

  @override
  String get coachUserMessageLabel => 'Tú';

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
    return 'Hoy: $todayMl / $targetMl ml. Registros totales: $_temp0. Activo: $activeProvider.';
  }

  @override
  String coachProviderReady({required Object activeProvider}) {
    return '$activeProvider está activo. Las respuestas se validan antes de que Hydrion confíe en ellas.';
  }

  @override
  String get coachProviderFallbackActive =>
      'Usando guía en el dispositivo. La salida del proveedor sigue siendo opcional.';

  @override
  String get coachProviderConsentRequired =>
      'Gemini está configurado, pero deshabilitado hasta que se habilite el consentimiento de privacidad del proveedor. El contexto de hidratación permanece en este dispositivo.';

  @override
  String get coachLocalProviderReady =>
      'La guía en el dispositivo está activa. El contexto de hidratación queda en este dispositivo.';

  @override
  String coachContextBanner(
      {required Object mode,
      required int todayMl,
      required int lifetimeMl,
      required int eventCount}) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount registros',
      one: '1 registro',
    );
    return '$mode. Usando datos de hidratación guardados en el dispositivo. Hoy: $todayMl ml. Total: $lifetimeMl ml en $_temp0. No hay IA en la nube ni ELKA conectado.';
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
      other: '$eventCount registros',
      one: '1 registro',
    );
    return '$mode. Usando datos de hidratación guardados en el dispositivo. Hoy: $todayMl ml. Total: $lifetimeMl ml en $_temp0. La salida del proveedor se valida antes de que Hydrion confíe en ella.';
  }

  @override
  String get askCoachEmpty =>
      'Pide una sugerencia de hidratación. Las respuestas son guía local determinista basada en registros guardados.';

  @override
  String get chatHint => 'Pregunta a tu coach...';

  @override
  String get coachFallbackNoticeLabel => 'Respaldo';

  @override
  String get coachFallbackNotice =>
      'La guía en el dispositivo respondió este mensaje.';

  @override
  String get suggestionHydrationLogTitle =>
      'Sugerencia de registro de hidratación';

  @override
  String get suggestionReminderTitle => 'Sugerencia de recordatorio';

  @override
  String get suggestionChallengeTitle => 'Sugerencia de reto';

  @override
  String get suggestionTrendTitle => 'Lectura de tendencia';

  @override
  String get suggestionUnsupportedTitle => 'Capacidad no disponible';

  @override
  String suggestionProviderSource({required Object provider}) {
    return 'Origen: $provider';
  }

  @override
  String suggestionValidationStatus({required Object status}) {
    return 'Validación: $status';
  }

  @override
  String get suggestionConfirmationRequired => 'Necesita confirmación';

  @override
  String get suggestionDisplayOnly => 'Solo lectura';

  @override
  String get suggestionValidated => 'Validada';

  @override
  String get suggestionApplied => 'Sugerencia aplicada';

  @override
  String get suggestionRejected => 'Sugerencia rechazada';

  @override
  String get suggestionDismissed => 'Sugerencia descartada';

  @override
  String get suggestionApply => 'Aplicar';

  @override
  String get suggestionDismiss => 'Descartar';

  @override
  String get suggestionDetailVolume => 'Volumen';

  @override
  String get suggestionDetailDelay => 'Espera';

  @override
  String get suggestionDetailPriority => 'Prioridad';

  @override
  String get suggestionDetailChallenge => 'Reto';

  @override
  String get suggestionDetailTarget => 'Objetivo';

  @override
  String get suggestionDetailDuration => 'Duración';

  @override
  String get suggestionDetailCapability => 'Capacidad';

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
    return '$targetMl ml/día';
  }

  @override
  String suggestionDurationValue({required int days}) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get cloudSync => 'Sincronización en la nube';

  @override
  String get osNotificationsCapabilityReported =>
      'Capacidad de notificaciones del sistema informada';

  @override
  String get notificationsAdapterNotWired =>
      'Aún no hay adaptador de notificaciones conectado. Las definiciones siguen siendo locales.';

  @override
  String get standaloneRemindersLocalOnly =>
      'El modo independiente almacena definiciones de recordatorio solo localmente. No se disparará ninguna notificación de plataforma.';

  @override
  String get noLocalRemindersSaved => 'No hay recordatorios locales guardados';

  @override
  String get remindersEmptyDescription =>
      'Usa la tarjeta de recordatorio de Inicio para guardar una definición local para revisar después.';

  @override
  String reminderSubtitle({required Object timestamp, required int priority}) {
    return '$timestamp - prioridad $priority';
  }

  @override
  String get deleteLocalReminderTooltip => 'Eliminar recordatorio local';

  @override
  String get localReminderDeleted =>
      'Definición local de recordatorio eliminada';

  @override
  String get noChallengesAvailable => 'No hay desafíos disponibles';

  @override
  String get socialChallengeCapabilityReported =>
      'Capacidad de desafío social informada';

  @override
  String get localChallengeMode => 'Modo de desafío local';

  @override
  String get socialCapabilityNoAdapter =>
      'Aún no hay adaptador social conectado. El progreso se guarda en este dispositivo.';

  @override
  String get socialSyncNotConnected =>
      'La sincronización social aún no está conectada. El progreso del desafío se guarda en este dispositivo.';

  @override
  String get noActiveChallengeYet => 'Aún no hay desafío activo';

  @override
  String get joinLocalChallengeDescription =>
      'Únete al desafío local de abajo para empezar a seguir el progreso desde registros de hidratación guardados.';

  @override
  String get challengeNameSevenDaySteadySip =>
      'Sorbos constantes por siete días';

  @override
  String get challengeDescriptionSevenDaySteadySip =>
      'Alcanza tu objetivo diario de hidratación durante una semana.';

  @override
  String challengeDetails(
      {required Object description,
      required int targetMl,
      required int durationDays}) {
    return '$description ($targetMl ml, $durationDays días)';
  }

  @override
  String challengeProgress(
      {required int completedDays,
      required int durationDays,
      required int todayMl,
      required int targetMl}) {
    return '$completedDays/$durationDays días completos. Hoy: $todayMl/$targetMl ml.';
  }

  @override
  String challengeTargetPerDay({required int targetMl}) {
    return '$targetMl ml/día';
  }

  @override
  String challengeDurationDays({required int durationDays}) {
    return '$durationDays días';
  }

  @override
  String get challengeJoined => 'Desafío unido';

  @override
  String challengeJoinedLocally({required Object message}) {
    return '$message localmente';
  }

  @override
  String get join => 'Unirse';

  @override
  String get joined => 'Unido';
}
