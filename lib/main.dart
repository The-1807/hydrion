import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'adapters/elka/elka_adapter.dart';
import 'adapters/gemini/gemini_adapter.dart';
import 'adapters/local/local_hydrion_adapters.dart';
import 'domain/hydration_contracts.dart';
import 'domain/legal_document_registry.dart';
import 'l10n/app_localizations.dart';
import 'repositories/challenge_repository.dart';
import 'repositories/hydration_repository.dart';
import 'repositories/reminder_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/core_bridge.dart';
import 'services/eco_tracker.dart';
import 'services/ai_provider_config.dart';
import 'services/coach_suggestion_service.dart';
import 'services/hydration_ai_action_executor.dart';
import 'services/hydration_ai_orchestrator.dart';
import 'services/hydration_context_builder.dart';
import 'services/location_service.dart';
import 'services/notifications.dart';
import 'services/policy_service.dart';
import 'services/provider_health.dart';
import 'services/profile_photo_service.dart';
import 'services/voice_client.dart';
import 'services/voice_llm_bridge.dart';
import 'services/wearable_service.dart';
import 'services/weather_goal_service.dart';
import 'ui/screens/analytics_screen.dart';
import 'ui/screens/chat_coach_screen.dart';
import 'ui/screens/hydrion_shell.dart';
import 'ui/screens/legal_about_screen.dart';
import 'ui/screens/log_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/reminders_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/social_challenges_screen.dart';
import 'ui/screens/startup_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/theme/hydrion_design.dart';
import 'storage/local_store.dart';
import 'utils/i18n_resolver.dart';
import 'utils/permissions.dart';
import 'utils/startup_trace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydrionStartupTrace.log('Dart main() reached');
  runApp(const HydrionBootstrapApp());
}

class HydrionBootstrapApp extends StatefulWidget {
  final Future<HydrionServices> Function()? servicesLoader;
  final Duration startupMinimumDuration;

  const HydrionBootstrapApp({
    super.key,
    this.servicesLoader,
    this.startupMinimumDuration = const Duration(seconds: 3),
  });

  @override
  State<HydrionBootstrapApp> createState() => _HydrionBootstrapAppState();
}

class _HydrionBootstrapAppState extends State<HydrionBootstrapApp> {
  late final Future<HydrionServices> _servicesFuture;
  HydrionServices? _loadedServices;
  HydrionServices? _services;
  String _initialRoute = '/home';

  @override
  void initState() {
    super.initState();
    HydrionStartupTrace.log('HydrionBootstrapApp.initState');
    _servicesFuture = (widget.servicesLoader ?? HydrionServices.local)();
  }

  Future<void> _loadServicesAndWarmUp() async {
    HydrionStartupTrace.log('HydrionBootstrapApp.warmup started');
    final services = await _servicesFuture;
    _loadedServices = services;
    await Future.wait([
      services.hydrationSummaryService.getHydrationSummary(),
      services.hydrationContextProvider.getHydrationContext(),
    ]);
    HydrionStartupTrace.log('HydrionBootstrapApp.warmup complete');
  }

  String _routeFor(HydrionServices services) {
    final settings = services.settingsRepository.settings;
    if (!settings.onboardingCompleted) {
      return '/onboarding';
    }
    if (HydrionLegalAcceptancePolicy.needsReview(
      onboardingCompleted: settings.onboardingCompleted,
      acceptedTermsVersion: settings.acceptedTermsVersion,
      acknowledgedHealthDisclaimerVersion:
          settings.acknowledgedHealthDisclaimerVersion,
    )) {
      return '/legal-review';
    }
    return '/home';
  }

  void _showLoadedApp(String route) {
    final services = _loadedServices;
    if (services == null || !mounted) {
      return;
    }
    HydrionStartupTrace.log(
      'HydrionBootstrapApp.route handoff accepted',
      data: {'route': route},
    );
    setState(() {
      _services = services;
      _initialRoute = route;
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (services != null) {
      return HydrionApp(
        services: services,
        initialRoute: _initialRoute,
      );
    }

    return MaterialApp(
      title: 'Hydrion',
      theme: buildHydrionTheme(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: StartupScreen(
        warmUp: _loadServicesAndWarmUp,
        isOnboardingCompleted: () =>
            _loadedServices?.settingsRepository.settings.onboardingCompleted ??
            false,
        nextRoute: () {
          final services = _loadedServices;
          return services == null ? '/onboarding' : _routeFor(services);
        },
        onRouteSelected: _showLoadedApp,
        minimumDuration: widget.startupMinimumDuration,
      ),
    );
  }
}

class HydrionApp extends StatelessWidget {
  final HydrionServices services;
  final String initialRoute;
  final Duration startupMinimumDuration;

  HydrionApp({
    super.key,
    HydrionServices? services,
    this.initialRoute = '/',
    this.startupMinimumDuration = Duration.zero,
  }) : services = services ?? HydrionServices.memory();

  @override
  Widget build(BuildContext context) {
    final routes = <String, WidgetBuilder>{
      '/': (_) => StartupScreen(
            warmUp: () async {
              await Future.wait([
                services.hydrationSummaryService.getHydrationSummary(),
                services.hydrationContextProvider.getHydrationContext(),
              ]);
            },
            isOnboardingCompleted: () =>
                services.settingsRepository.settings.onboardingCompleted,
            nextRoute: () {
              final settings = services.settingsRepository.settings;
              if (!settings.onboardingCompleted) {
                return '/onboarding';
              }
              if (HydrionLegalAcceptancePolicy.needsReview(
                onboardingCompleted: settings.onboardingCompleted,
                acceptedTermsVersion: settings.acceptedTermsVersion,
                acknowledgedHealthDisclaimerVersion:
                    settings.acknowledgedHealthDisclaimerVersion,
              )) {
                return '/legal-review';
              }
              return '/home';
            },
            minimumDuration: startupMinimumDuration,
          ),
      '/home': (_) => const HydrionShell(),
      '/onboarding': (_) => const OnboardingScreen(),
      '/analytics': (_) => const AnalyticsScreen(),
      '/chat': (_) => const ChatCoachScreen(),
      '/log': (_) => const LogScreen(),
      if (services.capabilityReporter.capabilities.osNotifications)
        '/reminders': (_) => const RemindersScreen(),
      '/settings': (_) => const SettingsScreen(),
      '/profile': (_) => const ProfileScreen(),
      '/legal-about': (_) => const LegalAboutScreen(),
      '/legal-review': (_) => const LegalReviewScreen(),
      for (final document in HydrionLegalDocumentRegistry.userFacingDocuments)
        document.routeName: (_) => LegalDocumentScreen(documentId: document.id),
      '/challenges': (_) => const SocialChallengesScreen(),
    };

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: services.hydrationRepository),
        ChangeNotifierProvider.value(value: services.settingsRepository),
        ChangeNotifierProvider.value(value: services.reminderRepository),
        ChangeNotifierProvider.value(value: services.challengeRepository),
        Provider.value(value: services.coreBridge),
        Provider.value(value: services.permissions),
        ChangeNotifierProvider.value(value: services.i18n),
        Provider.value(value: services.notificationService),
        Provider.value(value: services.locationService),
        Provider.value(value: services.weatherForecastService),
        Provider.value(value: services.dailyWeatherGoalCoordinator),
        Provider.value(value: services.profilePhotoPicker),
        Provider<HydrationSummaryService>.value(
          value: services.hydrationSummaryService,
        ),
        Provider<HydrationCoach>.value(value: services.hydrationCoach),
        Provider<CoachSuggestionService>.value(
          value: services.coachSuggestionService,
        ),
        Provider<HydrationContextProvider>.value(
          value: services.hydrationContextProvider,
        ),
        Provider<HydrationAiActionValidator>.value(
          value: services.aiActionValidator,
        ),
        Provider<ChallengeGenerator>.value(value: services.challengeGenerator),
        Provider<HydrationCommandParser>.value(value: services.commandParser),
        Provider<AppCapabilityReporter>.value(
          value: services.capabilityReporter,
        ),
        ChangeNotifierProvider<ProviderHealthReporter>.value(
          value: services.providerHealthReporter,
        ),
        Provider<HydrationAiActionExecutionService>.value(
          value: services.aiActionExecutor,
        ),
        Provider.value(value: services.elkaAdapter),
        Provider.value(value: services.voice),
        Provider.value(value: services.voiceBridge),
        Provider.value(value: services.wearables),
        Provider.value(value: services.ecoTracker),
      ],
      child: Consumer<I18nResolver>(
        builder: (context, i18n, _) {
          return MaterialApp(
            title: 'Hydrion',
            theme: buildHydrionTheme(),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: i18n.locale,
            initialRoute: initialRoute,
            routes: routes,
            onGenerateInitialRoutes: (initialRouteName) {
              final builder = routes[initialRouteName] ?? routes['/']!;
              return [
                MaterialPageRoute<void>(
                  builder: builder,
                  settings: RouteSettings(name: initialRouteName),
                ),
              ];
            },
          );
        },
      ),
    );
  }
}

class HydrionServices {
  final HydrionAiRuntimeConfig aiRuntimeConfig;
  final HydrionLocalStore localStore;
  final HydrationRepository hydrationRepository;
  final UserSettingsRepository settingsRepository;
  final ReminderRepository reminderRepository;
  final ChallengeRepository challengeRepository;
  final CoreBridge coreBridge;
  final Permissions permissions;
  final I18nResolver i18n;
  final NotificationService notificationService;
  final HydrionLocationService locationService;
  final WeatherForecastService weatherForecastService;
  final DailyWeatherGoalCoordinator dailyWeatherGoalCoordinator;
  final HydrionProfilePhotoPicker profilePhotoPicker;
  final HydrationSummaryService hydrationSummaryService;
  final HydrationContextProvider hydrationContextProvider;
  final HydrationAiActionValidator aiActionValidator;
  final HydrationCoach hydrationCoach;
  final CoachSuggestionService coachSuggestionService;
  final HydrationAiActionExecutionService aiActionExecutor;
  final ChallengeGenerator challengeGenerator;
  final HydrationCommandParser commandParser;
  final AppCapabilityReporter capabilityReporter;
  final ProviderHealthReporter providerHealthReporter;
  final ElkaAdapterShell elkaAdapter;
  final VoiceService voice;
  final VoiceLLMBridge voiceBridge;
  final WearableService wearables;
  final EcoTracker ecoTracker;

  HydrionServices({
    this.aiRuntimeConfig = const HydrionAiRuntimeConfig(),
    required this.localStore,
    required this.hydrationRepository,
    required this.settingsRepository,
    required this.reminderRepository,
    required this.challengeRepository,
    required this.coreBridge,
    required this.permissions,
    required this.i18n,
    required this.notificationService,
    required this.locationService,
    required this.weatherForecastService,
    required this.dailyWeatherGoalCoordinator,
    required this.profilePhotoPicker,
    required this.hydrationSummaryService,
    required this.hydrationContextProvider,
    required this.aiActionValidator,
    required this.hydrationCoach,
    required this.coachSuggestionService,
    required this.aiActionExecutor,
    required this.challengeGenerator,
    required this.commandParser,
    required this.capabilityReporter,
    required this.providerHealthReporter,
    required this.elkaAdapter,
    required this.voice,
    required this.voiceBridge,
    required this.wearables,
    required this.ecoTracker,
  });

  static Future<HydrionServices> local() async {
    final store = await SharedPreferencesHydrionStore.create();
    final services = await fromStore(
      store,
      aiRuntimeConfig: HydrionAiRuntimeConfig.fromEnvironment(),
    );
    await services.notificationService.initialize();
    await services.notificationService.reconcileSchedules();
    return services;
  }

  static Future<HydrionServices> fromStore(
    HydrionLocalStore store, {
    HydrionAiRuntimeConfig aiRuntimeConfig = const HydrionAiRuntimeConfig(),
    HydrionLocationService? locationService,
    HydrionNotificationAdapter? notificationAdapter,
    DailyWeatherProvider? weatherProvider,
    HydrionProfilePhotoPicker? profilePhotoPicker,
  }) async {
    final hydrationRepository = await HydrationRepository.load(store);
    final settingsRepository = await UserSettingsRepository.load(store);
    final reminderRepository = await ReminderRepository.load(store);
    final challengeRepository = await ChallengeRepository.load(store);
    return _build(
      store: store,
      hydrationRepository: hydrationRepository,
      settingsRepository: settingsRepository,
      reminderRepository: reminderRepository,
      challengeRepository: challengeRepository,
      aiRuntimeConfig: aiRuntimeConfig,
      locationService: locationService,
      notificationAdapter: notificationAdapter,
      weatherProvider: weatherProvider,
      profilePhotoPicker: profilePhotoPicker,
    );
  }

  factory HydrionServices.memory({
    HydrionAiRuntimeConfig aiRuntimeConfig = const HydrionAiRuntimeConfig(),
    HydrionLocationService? locationService,
    HydrionNotificationAdapter? notificationAdapter,
    DailyWeatherProvider? weatherProvider,
    HydrionProfilePhotoPicker? profilePhotoPicker,
  }) {
    final store = MemoryHydrionStore();
    return _build(
      store: store,
      hydrationRepository: HydrationRepository.memory(),
      settingsRepository: UserSettingsRepository.memory(),
      reminderRepository: ReminderRepository.memory(),
      challengeRepository: ChallengeRepository.memory(),
      aiRuntimeConfig: aiRuntimeConfig,
      locationService: locationService ?? FakeHydrionLocationService(),
      notificationAdapter: notificationAdapter ??
          FakeHydrionNotificationAdapter(
            permission: HydrionNotificationPermissionState.granted,
          ),
      weatherProvider: weatherProvider ?? _FakeDailyWeatherProvider(),
      profilePhotoPicker: profilePhotoPicker ?? FakeHydrionProfilePhotoPicker(),
    );
  }

  static HydrionServices _build({
    required HydrionLocalStore store,
    required HydrationRepository hydrationRepository,
    required UserSettingsRepository settingsRepository,
    required ReminderRepository reminderRepository,
    required ChallengeRepository challengeRepository,
    required HydrionAiRuntimeConfig aiRuntimeConfig,
    HydrionLocationService? locationService,
    HydrionNotificationAdapter? notificationAdapter,
    DailyWeatherProvider? weatherProvider,
    HydrionProfilePhotoPicker? profilePhotoPicker,
  }) {
    final coreBridge = CoreBridge(hydrationRepository: hydrationRepository);
    final permissions = Permissions();
    final location =
        locationService ?? const GeolocatorHydrionLocationService();
    final i18n = I18nResolver(settingsRepository: settingsRepository);
    final policy = ReminderPolicy();
    final notificationService = NotificationService(
      reminderPolicy: policy,
      reminderRepository: reminderRepository,
      adapter: notificationAdapter,
    );
    final weatherForecastService = WeatherForecastService(
      provider: weatherProvider ?? OpenMeteoWeatherProvider(),
      cache: WeatherForecastCacheRepository(store),
    );
    final dailyWeatherGoalCoordinator = DailyWeatherGoalCoordinator(
      settingsRepository: settingsRepository,
      locationService: location,
      weatherService: weatherForecastService,
      notificationService: notificationService,
    );
    final photoPicker =
        profilePhotoPicker ?? ImagePickerHydrionProfilePhotoPicker();
    final providerHealthReporter = LocalProviderHealthReporter.fromConfig(
      aiRuntimeConfig,
      privacyConsentGranted:
          settingsRepository.settings.nonLocalProviderConsentGranted,
    );
    const challengeGenerator = LocalChallengeGenerator();
    const commandParser = LocalHydrationCommandParser();
    final capabilityReporter = LocalAppCapabilityReporter(
      capabilities: const AppCapabilities.standalone().copyWith(
        geminiConfigured: aiRuntimeConfig.shouldUseGemini,
        osNotifications: notificationService.supportsOsNotifications,
        cloudAi: _geminiActivation(
          config: aiRuntimeConfig,
          settingsRepository: settingsRepository,
        ).canReportActive,
      ),
    );
    final hydrationSummaryService = LocalHydrationSummaryService(
      hydrationRepository: hydrationRepository,
      settingsRepository: settingsRepository,
    );
    final hydrationContextProvider = LocalHydrationContextProvider(
      hydrationRepository: hydrationRepository,
      reminderRepository: reminderRepository,
      challengeRepository: challengeRepository,
      capabilityReporter: capabilityReporter,
      settingsRepository: settingsRepository,
    );
    const aiActionValidator = HydrationAiActionValidator();
    final localHydrationCoach = LocalHydrationCoach(
      contextProvider: hydrationContextProvider,
      actionValidator: aiActionValidator,
      adviceBuilder: ({
        required double hydrationPercent,
        required int entryCount,
        required double temperatureC,
      }) =>
          _localizedHomeAdvice(
        l10n: lookupAppLocalizations(i18n.locale),
        hydrationPercent: hydrationPercent,
        entryCount: entryCount,
        temperatureC: temperatureC,
      ),
    );
    final geminiProvider = GeminiHydrationAiProvider(
      config: aiRuntimeConfig.gemini,
    );
    final hydrationCoach = ProviderBackedHydrationCoach(
      selectedProvider: aiRuntimeConfig.provider,
      primaryProvider: geminiProvider,
      localRulesProvider: localHydrationCoach,
      contextProvider: hydrationContextProvider,
      actionValidator: aiActionValidator,
      providerHealth: providerHealthReporter,
      nonLocalProviderEnabled: () => _geminiActivation(
        config: aiRuntimeConfig,
        settingsRepository: settingsRepository,
      ).canTransmit,
    );
    final aiActionExecutor = LocalHydrationAiActionExecutor(
      hydrationRepository: hydrationRepository,
      reminderRepository: reminderRepository,
      challengeRepository: challengeRepository,
      capabilityReporter: capabilityReporter,
      validator: aiActionValidator,
    );
    final coachSuggestionService = LocalCoachSuggestionService(
      provider: hydrationCoach,
      contextProvider: hydrationContextProvider,
      validator: aiActionValidator,
      executor: aiActionExecutor,
      providerHealth: providerHealthReporter,
    );
    const elkaAdapter = ElkaAdapterShell.unconfigured();
    final voiceBridge = VoiceLLMBridge(commandParser: commandParser);
    final voice = VoiceService(voiceLLMBridge: voiceBridge);
    final wearables = WearableService(hydrationRepository: hydrationRepository);
    final ecoTracker = EcoTracker(
      coreBridge: coreBridge,
      hydrationRepository: hydrationRepository,
      settingsRepository: settingsRepository,
    );

    return HydrionServices(
      aiRuntimeConfig: aiRuntimeConfig,
      localStore: store,
      hydrationRepository: hydrationRepository,
      settingsRepository: settingsRepository,
      reminderRepository: reminderRepository,
      challengeRepository: challengeRepository,
      coreBridge: coreBridge,
      permissions: permissions,
      i18n: i18n,
      notificationService: notificationService,
      locationService: location,
      weatherForecastService: weatherForecastService,
      dailyWeatherGoalCoordinator: dailyWeatherGoalCoordinator,
      profilePhotoPicker: photoPicker,
      hydrationSummaryService: hydrationSummaryService,
      hydrationContextProvider: hydrationContextProvider,
      aiActionValidator: aiActionValidator,
      hydrationCoach: hydrationCoach,
      coachSuggestionService: coachSuggestionService,
      aiActionExecutor: aiActionExecutor,
      challengeGenerator: challengeGenerator,
      commandParser: commandParser,
      capabilityReporter: capabilityReporter,
      providerHealthReporter: providerHealthReporter,
      elkaAdapter: elkaAdapter,
      voice: voice,
      voiceBridge: voiceBridge,
      wearables: wearables,
      ecoTracker: ecoTracker,
    );
  }

  static ExternalIntegrationActivation _geminiActivation({
    required HydrionAiRuntimeConfig config,
    required UserSettingsRepository settingsRepository,
  }) {
    final selected = config.provider == HydrionAiProviderSelection.gemini;
    final configured = selected && config.gemini.isConfigured;
    return ExternalIntegrationActivation(
      configured: configured,
      enabledByUser: selected,
      disclosureVisible: configured,
      consentGranted:
          settingsRepository.settings.nonLocalProviderConsentGranted,
    );
  }
}

String _localizedHomeAdvice({
  required AppLocalizations l10n,
  required double hydrationPercent,
  required int entryCount,
  required double temperatureC,
}) {
  final hydration = hydrationPercent.clamp(0.0, 100.0);
  final advice = switch (hydration) {
    >= 100.0 => l10n.homeAdviceGoalReached,
    >= 85.0 => l10n.homeAdviceStrong,
    >= 65.0 => l10n.homeAdviceClose,
    _ => l10n.homeAdviceStart,
  };
  final heat = temperatureC >= 28 ? ' ${l10n.homeAdviceHeat}' : '';
  final entryNote = entryCount >= 3
      ? ' ${l10n.homeAdviceReliableEntries(count: entryCount)}'
      : ' ${l10n.homeAdviceAddEntries}';
  return '$advice$heat$entryNote';
}

class _FakeDailyWeatherProvider implements DailyWeatherProvider {
  @override
  String get providerId => 'fake-test-weather';

  @override
  bool get isConfigured => true;

  @override
  Future<WeatherSnapshot> fetchDailyForecast(
    HydrionCoordinates coordinates, {
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    return WeatherSnapshot(
      temperatureC: 24,
      humidityPercent: 45,
      uvIndex: 0,
      observedAt: currentTime,
      retrievedAt: currentTime,
      condition: 'Test clear',
      providerId: providerId,
    );
  }
}
