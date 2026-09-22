// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get healthDataRetrying =>
      'Reintentando la sincronización de datos de salud...';

  @override
  String get healthDataNoNewRecords =>
      'Sincronizado: no hay datos de salud nuevos';

  @override
  String get healthDataLocalRecordsRetained =>
      'Los datos importados siguen disponibles en este dispositivo. Puede que no estén actualizados.';

  @override
  String get healthDataPermissionsUnknown =>
      'No se pudo comprobar el acceso actual. Los registros guardados no se han modificado.';

  @override
  String get healthDataProviderRecovery =>
      'Abre el proveedor de salud, vuelve aquí y reintenta. Revisa sus restricciones en segundo plano si el problema continúa.';

  @override
  String get healthDataSummaryUnavailable =>
      'No se pudieron leer los datos de salud guardados. Reintenta sin borrar tus datos.';

  @override
  String get healthDataMetadataUnavailable =>
      'No se pudo restaurar o guardar el historial de sincronización. Los registros almacenados están separados y no se han borrado.';

  @override
  String get healthDataDeletionFailed =>
      'La limpieza de datos del dispositivo no se completó. Reintenta; no asumas que se borraron todos los datos locales.';

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
  String get manualGoalOverrideQuestion =>
      '¿Seguro que quieres cambiar tu objetivo personalizado?';

  @override
  String get manualGoalOverrideConfirmation =>
      'Esto guarda un objetivo diario manual. Tu referencia personalizada calculada seguirá disponible y no cambiará.';

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
  String get amountInMl => 'Cantidad en mL';

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

  @override
  String get bodyMetricsTitle => 'Medidas corporales';

  @override
  String get bodyMeasurementsTitle => 'Medidas corporales guardadas';

  @override
  String get notAdded => 'No añadido';

  @override
  String get addWeight => 'Añadir peso';

  @override
  String get updateWeight => 'Actualizar peso';

  @override
  String get addHeight => 'Añadir estatura';

  @override
  String get updateHeight => 'Actualizar estatura';

  @override
  String get hydrationPacingScheduleTitle => 'Horario de ritmo de hidratación';

  @override
  String get hydrationPacingScheduleHelp =>
      'Opcional. Indica a Hydrion cuándo sueles estar despierto para que pueda comparar suavemente tu ritmo con tu día. Esto nunca cambia tu meta diaria.';

  @override
  String get wakeTimeLabel => 'Hora de despertar';

  @override
  String get sleepTimeLabel => 'Hora de dormir';

  @override
  String get addWakeTime => 'Añadir hora de despertar';

  @override
  String get updateWakeTime => 'Actualizar hora de despertar';

  @override
  String get addSleepTime => 'Añadir hora de dormir';

  @override
  String get updateSleepTime => 'Actualizar hora de dormir';

  @override
  String get pacingAheadOfPace => 'Vas adelantado para este momento de tu día.';

  @override
  String get pacingOnPace =>
      'Vas al ritmo esperado para este momento de tu día.';

  @override
  String get pacingSlightlyBehindPace =>
      'Vas un poco por detrás de tu ritmo habitual.';

  @override
  String get pacingMeaningfullyBehindPace =>
      'Vas retrasado, pero aún te queda tiempo en el día.';

  @override
  String get pacingGoalReached => 'Has alcanzado la meta de hoy.';

  @override
  String get updatedToday => 'Actualizado hoy';

  @override
  String updatedOn({required Object date}) {
    return 'Actualizado el $date';
  }

  @override
  String get personalizationTitle => 'Personalización';

  @override
  String get editPersonalizationSettings => 'Editar ajustes de personalización';

  @override
  String get onLabel => 'Activado';

  @override
  String get offLabel => 'Desactivado';

  @override
  String get dataPrivacyTitle => 'Datos y privacidad';

  @override
  String get deleteBodyMetricsExplanation =>
      'Esto elimina las medidas guardadas y los ajustes de personalización. No elimina los registros de hidratación.';

  @override
  String get done => 'Listo';

  @override
  String get noDailyContext =>
      'No se ha añadido contexto de actividad para hoy.';

  @override
  String get setDailyContext => 'Definir el contexto de hoy';

  @override
  String get savedForToday => 'Guardado para hoy.';

  @override
  String get appliesTodayOnly => 'Se aplica solo hoy.';

  @override
  String get edit => 'Editar';

  @override
  String get clear => 'Borrar';

  @override
  String get feelingUnwellToday => '¿Te sientes mal hoy?';

  @override
  String get bodyMetricsOptional =>
      'Las medidas opcionales y almacenadas localmente pueden mejorar la estimación de bienestar general. Puedes omitirlas, desactivarlas o eliminarlas cuando quieras.';

  @override
  String get enablePersonalization =>
      'Activar medidas corporales personalizadas';

  @override
  String get personalizedBaselineOption => 'Usar una base personalizada';

  @override
  String get personalizedBaselineHelp =>
      'Hydrion calculará una sugerencia para revisar. Tu objetivo actual no se reemplaza hasta que lo apliques.';

  @override
  String get weatherModifierOption => 'Usar ajustes meteorológicos opcionales';

  @override
  String get weightLabel => 'Peso';

  @override
  String get heightLabel => 'Altura';

  @override
  String get kilogramsLabel => 'kg';

  @override
  String get poundsLabel => 'lb';

  @override
  String get centimetresLabel => 'cm';

  @override
  String get feetInchesLabel => 'pies y pulgadas';

  @override
  String get feetLabel => 'pies';

  @override
  String get inchesLabel => 'pulg';

  @override
  String get accessibleNumericEntry => 'Entrada numérica accesible';

  @override
  String get reproductiveHydrationTitle => 'Embarazo o lactancia';

  @override
  String get reproductiveNone => 'Ninguno';

  @override
  String get reproductivePregnant => 'Embarazo';

  @override
  String get reproductiveLactating => 'Lactancia';

  @override
  String get bmiTitle => 'Estimación de detección del IMC';

  @override
  String get bmiDisclaimer =>
      'El IMC es una estimación de detección basada en la altura y el peso. No diagnostica afecciones ni mide la composición corporal.';

  @override
  String get bmiUnderTwenty =>
      'Hydrion no interpreta categorías adultas de IMC para menores de 20 años.';

  @override
  String get bmiBelowRange => 'Por debajo del rango adulto estándar';

  @override
  String get bmiStandardRange => 'Rango estándar de detección para adultos';

  @override
  String get bmiAboveRange => 'Por encima del rango adulto estándar';

  @override
  String get bmiHigherRange => 'Rango superior de detección para adultos';

  @override
  String get fluidSafetyTitle => 'Configuración de seguridad de líquidos';

  @override
  String get fluidSafetyNone => 'No se informó ninguna restricción';

  @override
  String get fluidSafetyClinician =>
      'Tengo un objetivo establecido por un profesional';

  @override
  String get fluidSafetyRestriction =>
      'Tengo una restricción de líquidos sin objetivo';

  @override
  String get fluidSafetyUnsure => 'No estoy seguro';

  @override
  String get clinicianTargetLabel => 'Objetivo profesional en ml';

  @override
  String get allowAboveClinicianTarget =>
      'Permitir ajustes opcionales por encima de este objetivo';

  @override
  String get saveBodyMetrics => 'Guardar medidas';

  @override
  String get deleteBodyMetrics => 'Eliminar medidas';

  @override
  String get bodyMetricsSaved => 'Medidas guardadas localmente.';

  @override
  String get bodyMetricsInvalid =>
      'Elige medidas dentro del rango seguro mostrado.';

  @override
  String get bodyMetricsDeleted => 'Medidas corporales eliminadas.';

  @override
  String get profileDeletionPersonalizationDisclosure =>
      'Esto borra de este dispositivo el perfil local, las medidas corporales, los contextos diarios, el historial de hidratación, los recordatorios, los desafíos, el estado de recomendaciones, la caché meteorológica, los registros importados de dispositivos y su contexto derivado. Los registros del proveedor de salud no cambian. Tus preferencias de idioma y apariencia permanecen guardadas.';

  @override
  String get dailyContextTitle => 'Contexto de hoy';

  @override
  String get dailyContextOptional =>
      'El contexto opcional de actividad y exterior ajusta solo la sugerencia de hoy.';

  @override
  String get activityIntensityLabel => 'Intensidad de actividad';

  @override
  String get activityMinutesLabel => 'Minutos de actividad';

  @override
  String get environmentLabel => 'Entorno';

  @override
  String get sweatLevelLabel => 'Nivel de sudor';

  @override
  String get temporaryConditionLabel => 'Condición temporal';

  @override
  String get activityRest => 'Descanso';

  @override
  String get activityLight => 'Ligera';

  @override
  String get activityModerate => 'Moderada';

  @override
  String get activityVigorous => 'Vigorosa';

  @override
  String get environmentIndoors => 'Principalmente interiores';

  @override
  String get environmentMixed => 'Interiores y exteriores';

  @override
  String get environmentOutdoors => 'Principalmente exteriores';

  @override
  String get sweatLow => 'Bajo';

  @override
  String get sweatModerate => 'Moderado';

  @override
  String get sweatHigh => 'Alto';

  @override
  String get sweatUnknown => 'Desconocido';

  @override
  String get conditionNone => 'Ninguna';

  @override
  String get conditionFever => 'Fiebre';

  @override
  String get conditionStomachIllness => 'Vómitos o diarrea';

  @override
  String get conditionRecovering => 'Recuperación';

  @override
  String get conditionPreferNot => 'Prefiero no decirlo';

  @override
  String get saveDailyContext => 'Guardar el contexto de hoy';

  @override
  String get clearDailyContext => 'Borrar el contexto de hoy';

  @override
  String get hydrationSuggestionTitle =>
      'Sugerencia de hidratación personalizada';

  @override
  String get baselineLabel => 'Base';

  @override
  String get adjustmentsLabel => 'Ajustes';

  @override
  String get weatherAdjustmentLabel => 'Ajuste por clima';

  @override
  String get activityAdjustmentLabel => 'Ajuste de actividad';

  @override
  String get reproductiveAdjustmentLabel => 'Ajuste de embarazo o lactancia';

  @override
  String get personalizedSuggestionAccepted =>
      'Sugerencia diaria personalizada aceptada después de revisarla.';

  @override
  String get keepCurrentGoal => 'Mantener objetivo actual';

  @override
  String get applySuggestedGoal => 'Aplicar objetivo sugerido';

  @override
  String get suggestedGoalApplied => 'Objetivo sugerido aplicado.';

  @override
  String get dailyContextSaved => 'Contexto de hoy guardado.';

  @override
  String get reviewSuggestion => 'Revisar sugerencia';

  @override
  String get generalWellnessNotice =>
      'Esta es una estimación de bienestar general, no un consejo médico. No fuerces el consumo de líquidos.';

  @override
  String get illnessSafetyNotice =>
      'Las necesidades de líquidos pueden cambiar durante una enfermedad. Mantén la recomendación habitual y busca orientación profesional si los síntomas son importantes.';

  @override
  String get restrictionSafetyNotice =>
      'Hydrion no aumentará automáticamente tu objetivo mientras informes una restricción de líquidos. Sigue la orientación profesional.';

  @override
  String get recommendedForYou => 'Recomendado para ti';

  @override
  String get viewChallenge => 'Ver desafío';

  @override
  String get notNow => 'Ahora no';

  @override
  String get noAutomaticChallenge =>
      'Las recomendaciones nunca inician un desafío. Tú decides si quieres revisarlo y unirte.';

  @override
  String get tailorChallengeSuggestions => 'Personalizar sugerencias de retos';

  @override
  String get challengeSuggestionPrivacy =>
      'Elige los tipos de rutinas que quieres que Hydrion considere. Estas opciones permanecen en este dispositivo y nunca inician un reto automaticamente.';

  @override
  String get timedFocusSipRoutines =>
      'Rutinas cronometradas de enfoque e hidratacion';

  @override
  String get waterRichFoodHabits => 'Habitos con alimentos ricos en agua';

  @override
  String get visualDailyConsistency => 'Constancia visual diaria';

  @override
  String get infusionFlavorVariety => 'Variedad de infusiones y sabores';

  @override
  String get recommendationWarmWeather =>
      'Las condiciones calidas de hoy hacen que este reto sea una buena opcion.';

  @override
  String get recommendationTimedRoutine =>
      'Coincide con tu preferencia por rutinas cronometradas.';

  @override
  String get recommendationLoggingConsistency =>
      'Un reto de registro variado puede ayudarte a ganar constancia.';

  @override
  String get recommendationWaterRichFood =>
      'Coincide con tu interes en anadir alimentos ricos en agua.';

  @override
  String get recommendationVisualConsistency =>
      'Coincide con tu preferencia por la constancia visual diaria.';

  @override
  String get recommendationInfusionVariety =>
      'Coincide con tu interes en la variedad de infusiones y sabores.';

  @override
  String get pregnancyDurationTitle => '¿De cuánto tiempo estás?';

  @override
  String get pregnancyDurationDays => 'Días';

  @override
  String get pregnancyDurationWeeks => 'Semanas';

  @override
  String get pregnancyDurationMonths => 'Meses';

  @override
  String get pregnancyDurationInputLabel => 'Duración del embarazo';

  @override
  String get pregnancyDurationHelp =>
      'Introduce una duración entre 1 día y 42 semanas.';

  @override
  String get pregnancyDurationInvalid =>
      'Introduce una duración válida entre 1 día y 42 semanas.';

  @override
  String get pregnancyDurationMonthsHelp =>
      'Los meses se convierten de forma aproximada y se guardan localmente.';

  @override
  String pregnancyDurationSummary({required int weeks, required int days}) {
    return 'Aproximadamente $weeks semanas y $days días.';
  }

  @override
  String get missionTitle => 'Por qué existe Hydrion';

  @override
  String get missionSemanticLabel => 'Misión de Hydrion';

  @override
  String get missionHeadline =>
      'La hidratación debería ser más fácil de entender y gestionar.';

  @override
  String get learnMore => 'Más información';

  @override
  String get missionDetails =>
      'Hydrion fomenta hábitos más seguros y constantes, manteniendo la información personal de forma local y bajo tu control. En el futuro podrá ofrecerse participación comunitaria mediante Discord, un servicio externo con prácticas de cuenta y privacidad independientes. Hydrion no enviará automáticamente información del perfil ni de salud.';

  @override
  String get communityComingLater => 'Enlace comunitario próximamente';

  @override
  String get continueToTutorial => 'Continuar al tutorial';

  @override
  String get profileDeletedTitle => 'Perfil eliminado';

  @override
  String get profileDeletionCompletedSemanticLabel =>
      'Eliminación del perfil local completada';

  @override
  String get profileDeletedHeadline => 'Tu perfil de Hydrion se ha eliminado';

  @override
  String get profileDeletedFarewell =>
      'Dondequiera que continúe tu camino de hidratación, cuídate, mantente hidratado y comparte lo aprendido con alguien a quien pueda ayudar.';

  @override
  String get learnAboutMission => 'Conoce la misión de Hydrion';

  @override
  String get finish => 'Finalizar';

  @override
  String get deleteLocalProfile => 'Eliminar perfil local';

  @override
  String get deleteLocalProfileSummary =>
      'Elimina los datos del perfil de Hydrion y conserva las preferencias de idioma y apariencia.';

  @override
  String get deleteLocalProfileQuestion => '¿Eliminar el perfil local?';

  @override
  String get removeDevicePermissions =>
      'Eliminar también los permisos de Hydrion';

  @override
  String get removeDevicePermissionsHelp =>
      'Android 13 y versiones posteriores pueden programar la eliminación de los permisos de notificación y ubicación después de terminar la despedida. El acceso a alarmas exactas y otros accesos especiales siguen controlándose en los ajustes del sistema.';

  @override
  String get reviewPermissions => 'Revisar permisos';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get profileDeletionFailed =>
      'No se pudo eliminar el perfil. Cierra Hydrion, vuelve a abrirlo e inténtalo de nuevo.';

  @override
  String get profileDeletionCleanupPending =>
      'Perfil eliminado. La limpieza de recordatorios de Android volverá a intentarse automáticamente.';

  @override
  String get weatherSuggestionTitle =>
      'Sugerencia de hidratación según el clima de hoy';

  @override
  String get humidityLabel => 'Humedad';

  @override
  String get standardGoalLabel => 'Objetivo estándar';

  @override
  String get todaySuggestedGoalLabel => 'Objetivo sugerido para hoy';

  @override
  String get updatedLabel => 'Actualizado';

  @override
  String get weatherSuggestionDisclosure =>
      'Esta sugerencia usa tu perfil guardado, el permiso de ubicación y el clima local. No constituye consejo médico.';

  @override
  String get keepStandardGoal => 'Mantener el objetivo estándar';

  @override
  String get useSuggestion => 'Usar sugerencia';

  @override
  String get pomodoroSessionNotificationTitle => 'Sesión Pomodoro';

  @override
  String get homeworkSessionNotificationTitle => 'Sesión de estudio';

  @override
  String get sessionPaused => 'En pausa';

  @override
  String get pauseAction => 'Pausar';

  @override
  String get resumeAction => 'Reanudar';

  @override
  String get stopAction => 'Detener';

  @override
  String get openAction => 'Abrir';

  @override
  String get waterNotLoggedRetry =>
      'No se registró el agua. Inténtalo de nuevo.';

  @override
  String loggedFormattedVolume({required String amount}) {
    return 'Se registró $amount';
  }

  @override
  String get dailyGoalReachedRecognition =>
      'Objetivo diario alcanzado. Bien hecho.';

  @override
  String get sevenDayStreakRecognition =>
      'Racha de hidratación de siete días. Una rutina constante está tomando forma.';

  @override
  String get profileMenu => 'Menú del perfil';

  @override
  String get viewProfile => 'Ver perfil';

  @override
  String get support => 'Asistencia';

  @override
  String get addChallengeDetails => 'Añadir detalles del reto';

  @override
  String get challengeDetailsAdded => 'Detalles del reto añadidos';

  @override
  String get challengeDetailsHelp =>
      'Toda el agua cuenta para tu objetivo diario. Los detalles del reto registran lo que necesita la tarea de hoy.';

  @override
  String get challengeDetailsTitle => 'Detalles del reto';

  @override
  String get temperatureStyle => 'Temperatura';

  @override
  String get temperatureCool => 'Fresca';

  @override
  String get temperatureRoom => 'Temperatura ambiente';

  @override
  String get temperatureWarm => 'Agradablemente tibia';

  @override
  String get infusionTheme => 'Tema de la infusión';

  @override
  String get noAddedSugar => 'Sin azúcar añadido';

  @override
  String get useDetails => 'Usar detalles';

  @override
  String get history => 'Historial';

  @override
  String get customAmount => 'Cantidad personalizada';

  @override
  String get momentum => 'Impulso';

  @override
  String get applySuggestedGoalQuestion => '¿Aplicar el objetivo sugerido?';

  @override
  String get applySuggestedGoalConfirmation =>
      '¿Aplicar este objetivo diario sugerido y continuar?';

  @override
  String get refineInputs => 'No, ajustar datos';

  @override
  String get confirmApply => 'Sí, aplicar';

  @override
  String get enterMeasurementsWithKeyboard =>
      'Introducir las medidas con el teclado';

  @override
  String recalculatedAt({required String date}) {
    return 'Recalculado el $date';
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
  String get routineFitsDay => 'Una rutina que se adapta a tu día';

  @override
  String get routineFitsDayBody =>
      'Sigue registrando el agua que realmente bebes. Los pequeños registros crean una imagen útil del día.';

  @override
  String amountLeft({required String amount}) {
    return 'Quedan $amount';
  }

  @override
  String get weatherAdjusted => 'Ajustado al clima';

  @override
  String get noReusableContainerSaved =>
      'No hay un recipiente reutilizable guardado. Añade uno en Ajustes para usarlo aquí y en Bottle Bingo.';

  @override
  String savedContainerHelp({required String amount}) {
    return 'Recipiente guardado: $amount. Selecciónalo aquí para usar la misma cantidad en Bottle Bingo.';
  }

  @override
  String get firstLogWaiting => 'Primer registro pendiente';

  @override
  String get momentumEmptyBody => 'Un pequeño registro da forma al día.';

  @override
  String get momentumDataBody =>
      'Tu tiburón tiene datos reales a los que responder.';

  @override
  String get challengePick => 'Elegir reto';

  @override
  String get activeChallenge => 'Reto activo';

  @override
  String get bottleBingoReady =>
      'Bottle Bingo está listo cuando quieras una rutina divertida.';

  @override
  String get activeChallengeGentle =>
      'Mantén un ritmo suave hoy; el progreso viene de los registros normales.';

  @override
  String get progress => 'Progreso';

  @override
  String get logHistory => 'Historial de registros';

  @override
  String greetingMorning({required String name}) {
    return 'Buenos días, $name';
  }

  @override
  String greetingAfternoon({required String name}) {
    return 'Buenas tardes, $name';
  }

  @override
  String greetingEvening({required String name}) {
    return 'Buenas noches, $name';
  }

  @override
  String get greetingFallbackName => 'tú';

  @override
  String recentLogCounted({required String amount}) {
    return 'Tu registro reciente de $amount está contabilizado. Dale tiempo a tu rutina antes de decidir qué hacer después.';
  }

  @override
  String get noWaterLoggedToday =>
      'Todavía no hay agua registrada hoy. Añade lo que realmente hayas bebido cuando estés listo.';

  @override
  String todayLogSummary({required int count, required String remaining}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
    );
    return 'Tienes $_temp0 hoy. Quedan unos $remaining.';
  }

  @override
  String todayLogSummaryWithContainer(
      {required int count,
      required String remaining,
      required String container}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
    );
    return 'Tienes $_temp0 hoy. Quedan unos $remaining; tu recipiente de $container está disponible como cantidad rápida.';
  }

  @override
  String get goalCompleted => 'Objetivo completado';

  @override
  String get noHydrationLoggedToday => 'No hay hidratación registrada hoy';

  @override
  String get todaysHydration => 'Hidratación de hoy';

  @override
  String get onboardingNicknameInvalid =>
      'Introduce un apodo de hasta 32 caracteres.';

  @override
  String get onboardingAgeInvalid =>
      'Los perfiles independientes de Hydrion requieren una edad de 13 a 120 años.';

  @override
  String get onboardingTermsRequired =>
      'Acepta los Términos y reconoce el aviso de salud para continuar.';

  @override
  String get onboardingGoalInvalid =>
      'Revisa tu objetivo y el tamaño del recipiente antes de continuar.';

  @override
  String get onboardingCompleteRecognition =>
      'La configuración de Hydrion está completa.';

  @override
  String get onboardingWelcome => 'Te damos la bienvenida a Hydrion';

  @override
  String get back => 'Atrás';

  @override
  String get start => 'Empezar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get onboardingLocalFirstTitle =>
      'Hydrion mantiene la hidratación de forma local';

  @override
  String get onboardingMascotSemantics => 'Mascota de Hydrion';

  @override
  String get onboardingLocalFirstBody =>
      'Registra agua, objetivos, recordatorios y retos individuales en este dispositivo. Las funciones opcionales de proveedores permanecen desactivadas hasta que las elijas.';

  @override
  String get onboardingBasicProfile => 'Perfil básico';

  @override
  String get nickname => 'Apodo';

  @override
  String get requiredSavedLocally => 'Obligatorio, guardado localmente.';

  @override
  String get age => 'Edad';

  @override
  String get ageOptionalHelp =>
      'Opcional. Se usa solo para orientación personalizada.';

  @override
  String get sexGuidanceLabel =>
      'Sexo usado para la orientación de hidratación';

  @override
  String get sexOptionalHelp =>
      'Opcional. Puedes elegir no responder en cualquier momento.';

  @override
  String get onboardingProfileNeededForMetrics =>
      'Guarda un apodo y una edad válida antes de añadir medidas corporales.';

  @override
  String get chooseDefaultAvatar => 'Elige tu avatar predeterminado';

  @override
  String get goalMode => 'Modo de objetivo';

  @override
  String get standardOrManual => 'Estándar o manual';

  @override
  String get personalizedEstimate => 'Estimación personalizada';

  @override
  String get standardGoalModeHelp =>
      'Usa el objetivo estándar o introduce tu propio objetivo.';

  @override
  String get personalizedGoalModeHelp =>
      'Usa las medidas corporales guardadas localmente para calcular una estimación general de bienestar.';

  @override
  String get weatherBaselineHelp =>
      'La asistencia meteorológica opcional se elige por separado y nunca reemplaza tu referencia.';

  @override
  String get hydrationSetup => 'Configuración de hidratación';

  @override
  String get dailyGoalMlLabel => 'Objetivo diario en ml';

  @override
  String get dailyGoalSupportedRange => 'Rango admitido: 500-5000 ml.';

  @override
  String get displayUnit => 'Unidad de visualización';

  @override
  String get milliliters => 'Mililitros';

  @override
  String get ounces => 'Onzas';

  @override
  String get containerSizeMlLabel => 'Tamaño habitual del recipiente en ml';

  @override
  String get containerSupportedRange => 'Rango admitido: 100-2000 ml.';

  @override
  String get usuallyReusable => 'Normalmente reutilizable';

  @override
  String get reusableHelp =>
      'Activa esto solo si la mayoría de las bebidas registradas usan una botella o taza reutilizable.';

  @override
  String get optionalDeviceFeatures => 'Funciones opcionales del dispositivo';

  @override
  String get reviewBeforeStart => 'Revisar antes de empezar';

  @override
  String get ready => 'Listo';

  @override
  String get onboardingReadySemantics => 'Configuración lista';

  @override
  String onboardingSummary(
      {required String name, required String avatar, required String goal}) {
    return 'Hydrion empezará con $name, $avatar, $goal ml/día y seguimiento local.';
  }

  @override
  String get yourProfile => 'tu perfil';

  @override
  String get sexFemale => 'Mujer';

  @override
  String get sexMale => 'Hombre';

  @override
  String get sexIntersex => 'Intersexual';

  @override
  String get preferNotToSay => 'Prefiero no responder';

  @override
  String get hydrationReminders => 'Recordatorios de hidratación';

  @override
  String get remindersCapabilityHelp =>
      'Hydrion puede enviar recordatorios locales en este dispositivo. Puedes activarlos ahora o más tarde.';

  @override
  String get remindersNotNowHelp =>
      'Ahora no - los recordatorios se pueden activar en Ajustes.';

  @override
  String get enableReminders => 'Activar recordatorios';

  @override
  String get weatherAssistance => 'Asistencia meteorológica';

  @override
  String get weatherCapabilityHelp =>
      'Hydrion puede usar una ubicación aproximada para obtener el tiempo local y ofrecer una sugerencia temporal de hidratación. Tu objetivo estándar sigue funcionando sin ella.';

  @override
  String get weatherNotNowHelp =>
      'Ahora no - tu objetivo de hidratación estándar sigue activo.';

  @override
  String get enableWeatherAssistance => 'Activar asistencia meteorológica';

  @override
  String get waitingForDevice => 'Esperando el resultado del dispositivo...';

  @override
  String get enabled => 'Activado';

  @override
  String capabilityEnabled({required String title}) {
    return '$title: activado';
  }

  @override
  String capabilityStatus({required String title, required String status}) {
    return '$title: $status';
  }

  @override
  String avatarSelectedSemantics({required String avatar}) {
    return 'Avatar $avatar seleccionado';
  }

  @override
  String selectAvatarSemantics({required String avatar}) {
    return 'Seleccionar avatar $avatar';
  }

  @override
  String get skip => 'Omitir';

  @override
  String get next => 'Siguiente';

  @override
  String get pullToRefresh => 'Desliza para actualizar';

  @override
  String tourStepSemantics(
      {required String tour, required int current, required int total}) {
    return '$tour, paso $current de $total';
  }

  @override
  String get achievementSemantics => 'Logro';

  @override
  String get noCheckInsYet => 'Aún no hay registros.';

  @override
  String get coachPreviewTitle => 'Coach';

  @override
  String get coachPreviewComingSoon =>
      'El Coach de Hydrion se está preparando para una actualización futura.';

  @override
  String get coachPreviewGuidance =>
      'Por ahora, sigue registrando agua y controlando tu progreso diario.';

  @override
  String get reminderNotificationTitle => 'Recordatorio de Hydrion';

  @override
  String get reminderChannelName => 'Recordatorios de hidratación';

  @override
  String get reminderChannelDescription =>
      'Recordatorios locales para los controles de hidratación de Hydrion creados por el usuario.';

  @override
  String get challengeAroundWorldTitle => 'Semana de infusiones por el mundo';

  @override
  String get challengeAroundWorldDescription =>
      'Prueba siete temas de infusión sin azúcar añadido mientras mantienes tu objetivo habitual de hidratación.';

  @override
  String get challengeTemperatureTitle => 'Ruleta de temperaturas';

  @override
  String get challengeTemperatureDescription =>
      'Compara temperaturas agradables del agua como experimento de preferencia.';

  @override
  String get challengeEatWaterTitle => 'Come tu agua';

  @override
  String get challengeEatWaterDescription =>
      'Incluye un alimento rico en agua elegido en una comida sin inventar volumen de hidratación.';

  @override
  String get challengePomodoroTitle => 'Sorbo Pomodoro';

  @override
  String get challengePomodoroDescription =>
      'Combina controles moderados de hidratación con descansos de concentración confirmados manualmente.';

  @override
  String get challengePlantTwinTitle => 'Reto de la planta gemela';

  @override
  String get challengePlantTwinDescription =>
      'Usa una señal de cuidado de plantas para revisar tu rutina de hidratación.';

  @override
  String get challengeBottleBingoTitle => 'Bingo de la botella';

  @override
  String get challengeBottleBingoDescription =>
      'Completa una combinación semanal de acciones explícitas de hidratación y controles sin hidratación.';

  @override
  String get challengeLunchRefillTitle => 'Recarga del almuerzo';

  @override
  String get challengeLunchRefillDescription =>
      'Aprovecha el almuerzo para revisar y llenar tu botella si hace falta.';

  @override
  String get challengeHomeworkTitle => 'Hidratación y estudio';

  @override
  String get challengeHomeworkDescription =>
      'Asocia una revisión cómoda con una pausa de estudio.';

  @override
  String get challengeAfterSchoolTitle => 'Recarga de la tarde';

  @override
  String get challengeAfterSchoolDescription =>
      'Haz una pausa tras tu rutina y revisa tu hidratación.';

  @override
  String get challengeBackpackTitle => 'Revisión de la botella';

  @override
  String get challengeBackpackDescription =>
      'Usa la preparación de la mochila para dejar lista tu botella.';

  @override
  String get challengeDeskResetTitle => 'Pausa sentado';

  @override
  String get challengeDeskResetDescription =>
      'Usa una pausa opcional para revisar tu hidratación.';

  @override
  String get challengeShiftCheckTitle => 'Revisión a mitad de jornada';

  @override
  String get challengeShiftCheckDescription =>
      'Añade una revisión opcional a mitad de un periodo de trabajo.';

  @override
  String get challengeCommuteCupTitle => 'Vaso de viaje';

  @override
  String get challengeCommuteCupDescription =>
      'Usa la salida o la llegada como recordatorio opcional.';

  @override
  String get challengeEveningReviewTitle => 'Revisión de la tarde';

  @override
  String get challengeEveningReviewDescription =>
      'Revisa tu día y decide si tu plan todavía te resulta adecuado.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get aboutAndLegal => 'Acerca de e información legal';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get openSourceLicensesSummary =>
      'Avisos de licencias de Flutter y paquetes.';

  @override
  String get openSourceLegalese =>
      'Hydrion utiliza componentes de código abierto conforme a sus licencias.';

  @override
  String get legalDocument => 'Documento legal';

  @override
  String get reviewHydrionTerms => 'Revisar los términos de Hydrion';

  @override
  String get continueToHydrion => 'Continuar a Hydrion';

  @override
  String get acceptHydrionTerms => 'Acepto los Términos de uso de Hydrion.';

  @override
  String get acknowledgeHealthDisclaimer =>
      'Reconozco el Aviso de salud y seguridad.';

  @override
  String get supportEmailCopied => 'Correo de asistencia copiado.';

  @override
  String documentVersion({required Object version}) {
    return 'Versión $version';
  }

  @override
  String documentEffective({required Object date}) {
    return 'Vigente desde $date';
  }

  @override
  String documentUpdated({required Object date}) {
    return 'Actualizado el $date';
  }

  @override
  String get homeTitle => 'Inicio';

  @override
  String get pausedChallengesTitle => 'En pausa';

  @override
  String get pausedChallengeSummary =>
      'Progreso guardado. Los registros nuevos no se evalúan.';

  @override
  String weatherConditionTemperature(
      {required Object condition, required Object temperature}) {
    return '$condition - $temperature °C';
  }

  @override
  String get weatherClear => 'Despejado';

  @override
  String get weatherCloudy => 'Nublado';

  @override
  String get weatherFog => 'Niebla';

  @override
  String get weatherRain => 'Lluvia';

  @override
  String get weatherSnow => 'Nieve';

  @override
  String get weatherStorm => 'Tormenta';

  @override
  String get weatherMixed => 'Variable';

  @override
  String get weatherUnknown => 'Desconocido';

  @override
  String get tourHydrationBody =>
      'Tu hidratación diaria y la cantidad restante aparecen aquí.';

  @override
  String get tourLogWater => 'Registrar agua';

  @override
  String get tourLogWaterBody =>
      'Registra la cantidad que realmente bebes. Usa un recipiente guardado o elige otra cantidad.';

  @override
  String get tourReviewCorrect => 'Revisar y corregir';

  @override
  String get tourReviewCorrectBody =>
      'Revisa, edita o elimina una entrada de hidratación si cometes un error.';

  @override
  String get tourChallengesBody =>
      'Los retos añaden hábitos y tareas opcionales. El agua de los retos sigue contando normalmente.';

  @override
  String get tourProgressRefresh => 'Progreso y actualización';

  @override
  String get tourProgressRefreshBody =>
      'Consulta aquí tus últimos totales. Desliza hacia abajo para actualizar la hidratación y el progreso de los retos.';

  @override
  String get seeWhatsNew => 'Ver novedades';

  @override
  String get seeWhatsNewBody =>
      'Haz un recorrido breve por la hidratación, los retos y el progreso.';

  @override
  String get showMe => 'Mostrar';

  @override
  String get challengeOptions => 'Opciones del reto';

  @override
  String get challengeSettings => 'Ajustes del reto';

  @override
  String get leaveAction => 'Salir';

  @override
  String challengeTutorialSemantics({required Object title}) {
    return 'Tutorial de $title';
  }

  @override
  String get tourOpenTile => 'Abrir una casilla';

  @override
  String get tourOpenTileBody =>
      'Abre una casilla para ver exactamente qué requiere.';

  @override
  String get tourAutomaticTiles => 'Casillas automáticas';

  @override
  String get tourAutomaticTilesBody =>
      'Algunas casillas se actualizan automáticamente con tus registros habituales de hidratación.';

  @override
  String get tourActionsCheckIns => 'Acciones y confirmaciones';

  @override
  String get tourActionsCheckInsBody =>
      'Otras casillas piden una bebida medida o una confirmación sencilla.';

  @override
  String get tourMakeBingo => 'Hacer Bingo';

  @override
  String get tourMakeBingoBody =>
      'Completa cinco casillas en una fila, columna o diagonal para hacer Bingo.';

  @override
  String get tourStartFocus => 'Iniciar una sesión de concentración';

  @override
  String get tourStartFocusBody =>
      'Inicia el temporizador al comenzar una sesión de concentración.';

  @override
  String get tourChooseAfterTimer => 'Elegir después del temporizador';

  @override
  String get tourChooseAfterTimerBody =>
      'Al terminar, confirma un sorbo o registra una bebida medida.';

  @override
  String get tourSipNoWater => 'Las confirmaciones de sorbo no añaden agua';

  @override
  String get tourSipNoWaterBody =>
      'Una confirmación de sorbo nunca añade una cantidad estimada de hidratación.';

  @override
  String get tourMeasuredDrinks => 'Las bebidas medidas cuentan normalmente';

  @override
  String get tourMeasuredDrinksBody =>
      'Una bebida medida actualiza la hidratación normal y puede contar para otro reto activo.';

  @override
  String get tourTodaysTemperature => 'Temperatura de hoy';

  @override
  String get tourTodaysTemperatureBody =>
      'Revisa el estilo de temperatura asignado para hoy.';

  @override
  String get tourWeatherBody =>
      'Cuando está activada, la meteorología local puede influir en la recomendación.';

  @override
  String get tourLogWithContext => 'Registrar con contexto';

  @override
  String get tourLogWithContextBody =>
      'Usa la acción del reto o añade detalles de temperatura al registrar desde Inicio.';

  @override
  String get tourTodaysInfusion => 'Infusión de hoy';

  @override
  String get tourTodaysInfusionBody => 'Revisa el tema de infusión de hoy.';

  @override
  String get tourPrepareNoSugar => 'Preparar sin azúcar añadido';

  @override
  String get tourPrepareNoSugarBody => 'Usa el tema sin añadir azúcar.';

  @override
  String get tourLogWhatYouDrink => 'Registrar lo que bebes';

  @override
  String get tourLogWhatYouDrinkBody =>
      'Registra la cantidad medida que realmente bebes.';

  @override
  String get whatChallengeIs => 'En qué consiste este reto';

  @override
  String get whatYouWillDo => 'Qué harás';

  @override
  String get whatCounts => 'Qué cuenta';

  @override
  String get whatDoesNotCount => 'Qué no cuenta';

  @override
  String get duration => 'Duración';

  @override
  String challengeDurationHelp({required Object days}) {
    return '$days días naturales locales. El reto comienza al unirte. Los requisitos diarios se reinician a medianoche local; los días perdidos no se recuperan automáticamente.';
  }

  @override
  String get completeSchedule => 'Programa completo';

  @override
  String challengeScheduleDay({required Object day, required Object item}) {
    return 'Día $day: $item';
  }

  @override
  String get howItWorks => 'Cómo funciona';

  @override
  String get hydrationProgressPrivacy => 'Hidratación, progreso y privacidad';

  @override
  String get hydrationProgressPrivacyBody =>
      'Tu objetivo de hidratación habitual permanece activo. Las bebidas medidas aparecen en Hydrion, mientras que las confirmaciones no añaden agua. Los ajustes y el progreso del reto permanecen en este dispositivo.';

  @override
  String get requiredSetup => 'Configuración obligatoria';

  @override
  String get requiredSetupHelp =>
      'Elige los detalles que se adapten a tu rutina.';

  @override
  String get amountInFluidOunces => 'Cantidad en onzas líquidas';

  @override
  String get dateAndTime => 'Fecha y hora';

  @override
  String get notSpecified => 'Sin especificar';

  @override
  String get addReminder => 'Añadir recordatorio';

  @override
  String get editReminder => 'Editar recordatorio';

  @override
  String get reminderDefaultMessage =>
      'Es hora de hacer una revisión tranquila de hidratación.';

  @override
  String get messageLabel => 'Mensaje';

  @override
  String get minutesFromNow => 'Minutos desde ahora';

  @override
  String get minutesRangeHelp => 'Usa entre 5 y 1440 minutos.';

  @override
  String get priorityLabel => 'Prioridad';

  @override
  String get reminderDetailsInvalid =>
      'Revisa los datos del recordatorio e inténtalo de nuevo.';

  @override
  String get ageRangeError => 'Introduce una edad de 13 a 120 años.';

  @override
  String get ageSaveFailed => 'No se pudo guardar la edad. Inténtalo de nuevo.';

  @override
  String get profileDeleteDeviceSummary =>
      'Esto elimina de este dispositivo el perfil local de Hydrion y los datos de hidratación, recordatorios y retos.';

  @override
  String get reviewProfileAge => 'Revisar la edad del perfil';

  @override
  String get independentProfileAgeHelp =>
      'Los perfiles independientes de Hydrion admiten edades de 13 años o más.';

  @override
  String get ageReviewExistingDataHelp =>
      'Tus datos locales siguen aquí. Si la edad guardada se introdujo incorrectamente, corrígela una vez a continuación. De lo contrario, elimina el perfil local y empieza de nuevo.';

  @override
  String get correctAge => 'Corregir edad';

  @override
  String get saveAgeCorrection => 'Guardar corrección de edad';

  @override
  String get optionalDeviceAccess => 'Acceso opcional al dispositivo';

  @override
  String get optionalDeviceAccessHelp =>
      'Hydrion funciona con un objetivo de hidratación estándar aunque omitas estas opciones.';

  @override
  String get preciseReminderTiming => 'Horario preciso de recordatorios';

  @override
  String get allowNotifications => 'Permitir notificaciones';

  @override
  String get continueWithoutReminders => 'Continuar sin recordatorios';

  @override
  String get allowLocation => 'Permitir ubicación';

  @override
  String get continueWithStandardGoal => 'Continuar con el objetivo estándar';

  @override
  String get openAlarmSettings => 'Abrir ajustes de Alarmas y recordatorios';

  @override
  String get continueApproximateScheduling =>
      'Continuar con programación aproximada';

  @override
  String get refreshStatus => 'Actualizar estado';

  @override
  String get requesting => 'Solicitando';

  @override
  String get waitingPermissionResult =>
      'Esperando el resultado del permiso del dispositivo...';

  @override
  String get openDeviceSettings => 'Abrir ajustes del dispositivo';

  @override
  String get permissionNotRequested => 'No solicitado';

  @override
  String get permissionApproximateEnabled => 'Ubicación aproximada activada';

  @override
  String get permissionPreciseEnabled => 'Ubicación precisa activada';

  @override
  String get permissionDenied => 'Denegado';

  @override
  String get permissionBlocked => 'Bloqueado';

  @override
  String get permissionRestricted => 'Restringido';

  @override
  String get permissionNotRequired => 'No requerido';

  @override
  String get permissionUnsupported => 'No compatible';

  @override
  String get permissionTemporarilyUnavailable => 'Temporalmente no disponible';

  @override
  String get permissionStatusUnavailable => 'Estado no disponible';

  @override
  String get permissionNotificationUnchecked =>
      'El estado de las notificaciones aún no se ha comprobado.';

  @override
  String get permissionLocationUnchecked =>
      'El estado de la ubicación aún no se ha comprobado.';

  @override
  String get permissionAlarmUnchecked =>
      'El estado de la programación de alarmas aún no se ha comprobado.';

  @override
  String get permissionNotificationsAllowed =>
      'Las notificaciones están permitidas para Hydrion.';

  @override
  String get permissionNotificationsOff =>
      'Las notificaciones están desactivadas. Puedes permitirlas aquí o en los ajustes del dispositivo.';

  @override
  String get permissionNotificationsNotAsked =>
      'Hydrion aún no ha pedido permiso para enviar notificaciones.';

  @override
  String get permissionNotificationsBlocked =>
      'Las notificaciones están bloqueadas. Abre los ajustes del dispositivo para permitirlas.';

  @override
  String get permissionNotificationStatusUnavailableAndroid =>
      'Hydrion no pudo leer el estado de las notificaciones de Android.';

  @override
  String get permissionNotificationsUnsupported =>
      'Las notificaciones de Hydrion no son compatibles con esta plataforma.';

  @override
  String get permissionNotificationStatusTemporary =>
      'El estado de las notificaciones no está disponible temporalmente. Actualiza para volver a intentarlo.';

  @override
  String get permissionPreciseLocationAllowed =>
      'La ubicación precisa en primer plano está permitida. La ubicación aproximada es suficiente para el tiempo de Hydrion.';

  @override
  String get permissionApproximateLocationAllowed =>
      'La ubicación aproximada en primer plano está permitida y es suficiente para la asistencia meteorológica.';

  @override
  String get permissionLocationOff =>
      'La ubicación está desactivada. Tu objetivo de hidratación estándar sigue funcionando.';

  @override
  String get permissionLocationNotAsked =>
      'Hydrion aún no ha solicitado la ubicación.';

  @override
  String get permissionLocationBlocked =>
      'La ubicación está bloqueada. Abre los ajustes del dispositivo para activar la asistencia meteorológica.';

  @override
  String get permissionLocationRestricted =>
      'El dispositivo restringe el acceso a la ubicación.';

  @override
  String get permissionLocationServicesOff =>
      'Los servicios de ubicación están desactivados. Tu objetivo estándar sigue disponible.';

  @override
  String get permissionLocationUnsupported =>
      'La asistencia meteorológica basada en la ubicación no es compatible con esta plataforma.';

  @override
  String get permissionLocationStatusTemporary =>
      'El estado de la ubicación no está disponible temporalmente. Actualiza para volver a intentarlo.';

  @override
  String get permissionExactAlarmNotRequired =>
      'El acceso especial a alarmas exactas no es necesario en este dispositivo.';

  @override
  String get permissionExactAlarmAndroidOnly =>
      'El acceso a alarmas exactas es específico de Android.';

  @override
  String get permissionExactSchedulingAvailable =>
      'La programación precisa de recordatorios está disponible.';

  @override
  String get permissionExactSchedulingApproximate =>
      'La programación exacta no está disponible. Hydrion continuará con recordatorios aproximados.';

  @override
  String historyFocusEndedEarly({required Object session}) {
    return 'Sesión de concentración $session terminada antes de tiempo';
  }

  @override
  String historyFocusCompleted({required Object session}) {
    return 'Sesión de concentración $session completada';
  }

  @override
  String historyBingoTileCompleted({required Object tile}) {
    return '$tile completado';
  }

  @override
  String historyBingoLineCompleted({required Object line}) {
    return 'Línea $line de Bingo de botella completada';
  }

  @override
  String historyTemperatureDrink(
      {required Object amount, required Object style}) {
    return 'Bebida $style registrada$amount';
  }

  @override
  String historyInfusionTried({required Object amount, required Object theme}) {
    return 'Infusión $theme probada$amount';
  }

  @override
  String historyPomodoroDrink({required Object amount}) {
    return 'Bebida Pomodoro registrada$amount';
  }

  @override
  String historyPomodoroSession({required Object amount}) {
    return 'Sesión de concentración Pomodoro completada$amount';
  }

  @override
  String historyPomodoroSessionNumber(
      {required Object amount, required Object session}) {
    return 'Sesión Pomodoro $session completada$amount';
  }

  @override
  String historyFoodAdded({required Object food, required Object meal}) {
    return 'Se añadió $food a $meal';
  }

  @override
  String historyCueCompleted({required Object cue}) {
    return '$cue completado';
  }

  @override
  String get historyChallengeTaskCompleted => 'Tarea del reto completada';

  @override
  String historyChallengeDrink({required Object amount}) {
    return 'Bebida del reto registrada$amount';
  }

  @override
  String historyBottleBingoDrink({required Object amount}) {
    return 'Bebida de Bingo de botella registrada$amount';
  }

  @override
  String historyMeasuredFocusDrink({required Object amount}) {
    return 'Bebida medida de la sesión registrada$amount';
  }

  @override
  String get assignedTemperature => 'temperatura asignada';

  @override
  String get scheduledTemperature => 'temperatura programada';

  @override
  String get dailyValue => 'diaria';

  @override
  String get mealValue => 'comida';

  @override
  String get waterRichFood => 'alimento rico en agua';

  @override
  String get plantCareCue => 'recordatorio de cuidado de la planta';

  @override
  String get bottleBingoTile => 'una casilla de Bingo de botella';

  @override
  String get bottleBingoDrink => 'una bebida de Bingo de botella';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get localProfilePhoto => 'Foto de perfil local';

  @override
  String get profilePhotoSaved => 'Foto de perfil guardada localmente.';

  @override
  String get profilePhotoTooLarge =>
      'Esa foto es demasiado grande para el almacenamiento local del perfil.';

  @override
  String get profileEditorSummary =>
      'Actualiza tu identidad y preferencias de Hydrion. Esto no reinicia la configuración inicial ni elimina el historial.';

  @override
  String get profilePhotoPrivacy =>
      'Las fotos seleccionadas solo se usan como imagen de perfil local. Puedes eliminar la foto y volver al avatar predeterminado en cualquier momento.';

  @override
  String get legal => 'Información legal';

  @override
  String get hydrationIdentity => 'Perfil de hidratación';

  @override
  String get dailyGoal => 'Objetivo diario';

  @override
  String get units => 'Unidades';

  @override
  String get preferredContainer => 'Recipiente preferido';

  @override
  String get notSet => 'Sin configurar';

  @override
  String get noRemindersYet => 'Aún no hay recordatorios';

  @override
  String savedCount({required int count}) {
    return '$count guardado(s)';
  }

  @override
  String contactEmail({required String email}) {
    return 'Contacto: $email';
  }

  @override
  String get editProfileInvalid =>
      'Revisa los campos del perfil e inténtalo de nuevo.';

  @override
  String get choosePhoto => 'Elegir foto';

  @override
  String get useDefaultAvatar => 'Usar avatar predeterminado';

  @override
  String get displayName => 'Nombre visible';

  @override
  String get defaultProfileAvatar => 'Avatar de perfil predeterminado';

  @override
  String get baselineDailyGoalMl => 'Objetivo diario base en mL';

  @override
  String get preferredContainerMl => 'Recipiente preferido en mL';

  @override
  String get personalized => 'Personalizado';

  @override
  String get saveProfile => 'Guardar perfil';

  @override
  String get whyHydrionExists => 'Por qué existe Hydrion';

  @override
  String get missionAndCommunity => 'Misión y comunidad';

  @override
  String get help => 'Ayuda';

  @override
  String get replayAppTour =>
      'Recorrido de la aplicación - Repetir la guía rápida';

  @override
  String get appearance => 'Apariencia';

  @override
  String get useDeviceSetting => 'Usar configuración del dispositivo';

  @override
  String get automaticDayNight => 'Día/noche automático';

  @override
  String get dayTheme => 'Día';

  @override
  String get nightTheme => 'Noche';

  @override
  String get deviceSetting => 'Configuración del dispositivo';

  @override
  String get autoDayNight => 'Día/noche auto';

  @override
  String dailyGoalPerDay({required int amount}) {
    return '$amount mL/día';
  }

  @override
  String get personalizedBaselineActive => 'Referencia personalizada';

  @override
  String get manualBaselineActive => 'Referencia estándar o manual';

  @override
  String get weatherAssistanceSelected =>
      'Asistencia meteorológica seleccionada';

  @override
  String get weatherAssistanceOff => 'Asistencia meteorológica desactivada';

  @override
  String get amountInOz => 'Cantidad en oz';

  @override
  String get containerSharedHelp =>
      'Una cantidad guardada se usa en Inicio y Bingo de botella.';

  @override
  String get containerAmountInvalid =>
      'Introduce una cantidad de 100 a 2000 mL.';

  @override
  String get permissionsSummary =>
      'Revisa los recordatorios, la ubicación meteorológica y el acceso a alarmas de Android.';

  @override
  String get legalPrivacySupport => 'Información legal, privacidad y ayuda';

  @override
  String get widgetNoActiveChallenge => 'No hay un reto activo';

  @override
  String get widgetChooseChallenge => 'Abre Hydrion para elegir un reto.';

  @override
  String get widgetOpenChallenges => 'Ver retos';

  @override
  String get widgetChallengePaused => 'Reto en pausa';

  @override
  String get widgetActivityActive => 'Actividad activa';

  @override
  String get widgetActivityPaused => 'Actividad en pausa';

  @override
  String get widgetActivityComplete => 'Actividad de hoy completada';

  @override
  String widgetCheckpointProgress(
      {required int completed, required int total}) {
    return '$completed de $total pasos hoy';
  }

  @override
  String get widgetOpenToContinue => 'Abre Hydrion para continuar';

  @override
  String get widgetOpenChallenge => 'Abrir reto';

  @override
  String get reportsTitle => 'Informes de hidratacion';

  @override
  String get reportsDescription =>
      'Crea un resumen privado con los registros guardados en este dispositivo.';

  @override
  String get reportsOpen => 'Crear informe';

  @override
  String get reportsFrequency => 'Frecuencia del informe';

  @override
  String get reportsWeekly => 'Semanal';

  @override
  String get reportsMonthly => 'Mensual';

  @override
  String get reportsQuarterly => 'Trimestral';

  @override
  String get reportsYearly => 'Anual';

  @override
  String get reportsChoosePeriod => 'Elegir periodo';

  @override
  String get reportsPeriod => 'Periodo';

  @override
  String get reportsGenerated => 'Generado';

  @override
  String get reportsPreview => 'Vista previa del informe';

  @override
  String get reportsTotal => 'Consumo total registrado';

  @override
  String get reportsAverage => 'Promedio en dias registrados';

  @override
  String get reportsTrackedDays => 'Dias registrados';

  @override
  String get reportsTargetsMet => 'Objetivos conocidos cumplidos';

  @override
  String get reportsTarget => 'Objetivo aplicable';

  @override
  String get reportsDate => 'Fecha';

  @override
  String get reportsIntake => 'Consumo registrado';

  @override
  String get reportsMissing => 'Sin registro';

  @override
  String get reportsUnavailable => 'No disponible';

  @override
  String get reportsPartial => 'Este periodo aun esta en curso.';

  @override
  String get reportsEmpty => 'No se registro consumo de agua en este periodo.';

  @override
  String get reportsLegacyTarget =>
      'Los objetivos historicos no guardados se muestran como no disponibles.';

  @override
  String get reportsDisclaimer =>
      'Este informe resume datos de hidratacion registrados por el usuario. No es un diagnostico medico ni sustituye el consejo medico profesional.';

  @override
  String get reportsExport => 'Exportar PDF';

  @override
  String get reportsExported => 'Informe compartido correctamente.';

  @override
  String get reportsDismissed => 'Se cancelo el uso compartido.';

  @override
  String get reportsExportFailed =>
      'No se pudo exportar el informe. Intentalo de nuevo.';

  @override
  String get reportsPage => 'Pagina';

  @override
  String get reportsVisualization => 'Hidratacion registrada';

  @override
  String get healthDataTitle => 'Conectar datos de salud';

  @override
  String get healthDataSettingsSummary =>
      'Importa actividad aprobada desde un proveedor disponible en este dispositivo.';

  @override
  String get healthDataProvider => 'Proveedor';

  @override
  String get healthDataHealthConnect => 'Health Connect';

  @override
  String get healthDataAppleHealth => 'Apple Health';

  @override
  String get healthDataAppleAccessRequested =>
      'Se solicito acceso a Apple Health. Apple protege tus elecciones, por lo que Hydrion no puede mostrar que categorias de lectura permitiste.';

  @override
  String get healthDataContributingSources => 'Fuentes contribuyentes:';

  @override
  String get healthDataAvailable =>
      'Este proveedor de datos de salud esta disponible en el dispositivo.';

  @override
  String get healthDataLoading =>
      'Comprobando proveedores de datos de salud disponibles...';

  @override
  String get healthDataInstallationRequired =>
      'Instala Health Connect para usar datos de salud de Android.';

  @override
  String get healthDataUpdateRequired =>
      'Actualiza Health Connect antes de conectarte.';

  @override
  String get healthDataUnsupported =>
      'Health Connect no es compatible con este perfil del dispositivo.';

  @override
  String get healthDataPermissionNotRequested =>
      'Aun no se ha solicitado acceso a los datos de salud.';

  @override
  String get healthDataPermissionPartial =>
      'Algunas categorias solicitadas no estan permitidas.';

  @override
  String get healthDataPermissionDenied =>
      'El acceso a los datos de salud no esta permitido. El registro manual sigue disponible.';

  @override
  String get healthDataConnected =>
      'Conectado a datos de salud en modo de solo lectura.';

  @override
  String get healthDataConnectedNoData =>
      'Conectado, pero no se encontraron registros legibles.';

  @override
  String get healthDataSynchronizing => 'Sincronizando datos de salud...';

  @override
  String get healthDataSyncPartial =>
      'La sincronizacion termino con algunas categorias no disponibles.';

  @override
  String healthDataSuccessfulCategories({required String categories}) {
    return 'Categorias sincronizadas: $categories';
  }

  @override
  String healthDataFailedCategories({required String categories}) {
    return 'Categorias que necesitan atencion: $categories';
  }

  @override
  String get healthDataRetryFailedCategories =>
      'Reintentar categorias fallidas';

  @override
  String get healthDataSyncFailed =>
      'No se pudieron sincronizar los datos de salud.';

  @override
  String get healthDataStorageUnavailable =>
      'El almacenamiento protegido de datos de salud no esta disponible. No se importo ningun registro.';

  @override
  String get healthDataProviderFailure =>
      'No se pudo actualizar el proveedor de datos de salud. Vuelve a intentarlo o gestiona el acceso al proveedor.';

  @override
  String get healthDataDisconnected =>
      'Desconectado dentro de Hydrion. Los permisos de origen siguen controlados por el proveedor de datos de salud.';

  @override
  String get healthDataConsentIntro =>
      'Hydrion solicita acceso de solo lectura al proveedor mostrado arriba solo despues de que elijas conectar.';

  @override
  String get healthDataCategories => 'Categorias solicitadas';

  @override
  String get healthDataWorkouts => 'Entrenamientos';

  @override
  String get healthDataActiveEnergy => 'Energia activa';

  @override
  String get healthDataSteps => 'Pasos';

  @override
  String get healthDataDistance => 'Distancia';

  @override
  String get healthDataCategoryExplanation =>
      'Los entrenamientos aportan duracion de actividad. La energia activa aporta contexto de esfuerzo. Los pasos y la distancia son contexto alternativo sin doble conteo.';

  @override
  String get healthDataPrivacyExplanation =>
      'Los registros importados permanecen cifrados en este dispositivo. No se requiere cuenta de Hydrion ni carga en la nube. Puedes rechazar, gestionar el acceso al proveedor, desconectar o borrar la copia importada sin borrar los registros de origen.';

  @override
  String get healthDataWellnessDisclaimer =>
      'Esta es informacion de bienestar, no un diagnostico medico. Los datos importados no cambian tu objetivo de hidratacion en esta version.';

  @override
  String get healthDataConnect => 'Conectar';

  @override
  String get healthDataRequestMissing => 'Solicitar acceso faltante';

  @override
  String get healthDataSynchronize => 'Sincronizar';

  @override
  String get healthDataOpenSettings => 'Abrir ajustes de Android';

  @override
  String get healthDataDisconnect => 'Desconectar';

  @override
  String get healthDataDeleteImported => 'Borrar datos importados';

  @override
  String get healthDataDeleteQuestion =>
      'Borrar los datos de salud importados por Hydrion?';

  @override
  String get healthDataDeleteExplanation =>
      'Esto elimina la copia importada y cifrada de Hydrion, sus puntos de control y el contexto derivado de los dispositivos. No elimina los registros del proveedor de origen ni el historial manual de hidratacion.';

  @override
  String healthDataImportedCount({required int count}) {
    return 'Registros importados: $count';
  }

  @override
  String healthDataGrantedCategories({required String categories}) {
    return 'Permitidas: $categories';
  }

  @override
  String get healthDataNoGrantedCategories => 'Permitidas: ninguna';

  @override
  String healthDataContributors({required String applications}) {
    return 'Aplicaciones contribuyentes: $applications';
  }

  @override
  String get healthDataNoContributors =>
      'Aplicaciones contribuyentes: ninguna encontrada';

  @override
  String healthDataLastSuccessful({required String time}) {
    return 'Ultima sincronizacion correcta: $time';
  }

  @override
  String get healthDataNeverSynchronized =>
      'Ultima sincronizacion correcta: nunca';

  @override
  String get healthDataDashboardTitle => 'Datos de salud';

  @override
  String get healthDataPermissionRequesting =>
      'Abriendo los permisos del proveedor...';

  @override
  String get healthDataConnectedNotSynchronized =>
      'Proveedor de datos de salud conectado';

  @override
  String get healthDataNoSyncYet =>
      'Aun no se ha completado ninguna sincronizacion.';

  @override
  String get healthDataSynchronizedWithRecords => 'Conectado y sincronizado';

  @override
  String get healthDataSynchronizedNoRecords =>
      'Conectado, pero no se encontraron datos de salud';

  @override
  String get healthDataNoDataExplanation =>
      'El proveedor no devolvio entrenamientos, energia activa, pasos ni distancia legibles. Puede que no haya datos coincidentes o que no se permitiera el acceso de lectura. Comprueba la aplicacion de origen e intentalo de nuevo.';

  @override
  String get healthDataPermissionRevoked =>
      'El acceso a los datos de salud requiere atencion';

  @override
  String healthDataMissingCategories({required String categories}) {
    return 'Acceso faltante: $categories';
  }

  @override
  String healthDataLastAttempt({required String time}) {
    return 'Ultimo intento: $time';
  }

  @override
  String get healthDataLatestAttemptFailed =>
      'La ultima sincronizacion fallo. Los registros importados anteriormente no se modificaron.';

  @override
  String healthDataSyncCounts(
      {required int read,
      required int inserted,
      required int updated,
      required int deleted,
      required int rejected}) {
    return 'Ultima sincronizacion: $read leidos, $inserted nuevos, $updated actualizados, $deleted eliminados, $rejected rechazados';
  }

  @override
  String healthDataRecordPeriod({required String start, required String end}) {
    return 'Periodo disponible: $start - $end';
  }

  @override
  String healthDataSourceCount({required String source, required int count}) {
    return '$source: $count registros';
  }

  @override
  String get healthDataDataAvailable => 'Datos disponibles';

  @override
  String get healthDataWhatReads => 'Lo que lee Hydrion';

  @override
  String get healthDataViewImportedData => 'Ver datos importados';

  @override
  String get healthDataImportedDataTitle => 'Datos wearable importados';

  @override
  String get healthDataWorkoutTimeline => 'Cronología de entrenamientos';

  @override
  String get healthDataWorkoutTimelineEmpty =>
      'Aún no se han importado entrenamientos.';

  @override
  String healthDataWorkoutRow({required int minutes}) {
    return 'Entrenamiento de $minutes min';
  }

  @override
  String get healthDataStepsTrend => 'Tendencia de pasos (últimos 14 días)';

  @override
  String get healthDataDistanceTrend =>
      'Tendencia de distancia (últimos 14 días)';

  @override
  String get healthDataActiveEnergyTrend =>
      'Tendencia de energía activa (últimos 14 días)';

  @override
  String get healthDataTrendEmpty => 'Sin datos en los últimos 14 días.';

  @override
  String healthDataTrendDayTotal(
      {required String date, required String value, required String unit}) {
    return '$date: $value $unit';
  }

  @override
  String healthDataRecordSource(
      {required String source, required String date}) {
    return '$source · $date';
  }

  @override
  String get healthDataSyncNow => 'Sincronizar ahora';

  @override
  String get healthDataTryAgain => 'Intentar de nuevo';

  @override
  String get healthDataManageAccess => 'Gestionar acceso';

  @override
  String get healthDataCheckHealthConnect => 'Abrir Health Connect';

  @override
  String get healthDataReadingSecurely =>
      'Leyendo de forma segura los registros autorizados. No cierres Hydrion.';

  @override
  String get healthDataReasonUnavailable =>
      'El proveedor de datos de salud no estaba disponible.';

  @override
  String get healthDataReasonPermission =>
      'El acceso a los datos de salud fue denegado o revocado.';

  @override
  String get healthDataReasonOperation =>
      'La operacion de sincronizacion segura no pudo completarse.';
}
