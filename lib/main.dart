import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'adapters/elka/elka_adapter.dart';
import 'adapters/gemini/gemini_adapter.dart';
import 'adapters/local/local_hydrion_adapters.dart';
import 'domain/hydration_contracts.dart';
import 'domain/challenge_catalog.dart';
import 'domain/body_metrics.dart';
import 'domain/legal_document_registry.dart';
import 'domain/life_stage_policy.dart';
import 'l10n/app_localizations.dart';
import 'l10n/coach_localizations.dart';
import 'repositories/challenge_repository.dart';
import 'repositories/app_locale_repository.dart';
import 'repositories/body_metrics_repository.dart';
import 'repositories/daily_hydration_context_repository.dart';
import 'repositories/guided_tour_repository.dart';
import 'repositories/hydration_repository.dart';
import 'repositories/personalization_state_repository.dart';
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
import 'services/local_profile_reset_service.dart';
import 'services/notifications.dart';
import 'services/policy_service.dart';
import 'services/pomodoro_session_service.dart';
import 'services/timed_session_notification_service.dart';
import 'services/provider_health.dart';
import 'services/profile_photo_service.dart';
import 'services/voice_client.dart';
import 'services/voice_llm_bridge.dart';
import 'services/wearable_service.dart';
import 'services/weather_goal_service.dart';
import 'services/app_refresh_controller.dart';
import 'services/android_widget_service.dart';
import 'services/dynamic_theme_clock.dart';
import 'services/daily_hydration_recommendation_coordinator.dart';
import 'services/challenge_recommendation_service.dart';
import 'services/current_weather_context.dart';
import 'ui/screens/analytics_screen.dart';
import 'ui/screens/hydrion_shell.dart';
import 'ui/screens/legal_about_screen.dart';
import 'ui/screens/log_screen.dart';
import 'ui/screens/language_selection_screen.dart';
import 'ui/screens/mission_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/permission_center_screen.dart';
import 'ui/screens/reminders_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/social_challenges_screen.dart';
import 'ui/screens/startup_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/profile_age_review_screen.dart';
import 'ui/screens/body_metrics_screen.dart';
import 'ui/screens/challenge_experience_screen.dart';
import 'ui/components/hydrion_system_ui.dart';
import 'ui/theme/hydrion_design.dart';
import 'storage/local_store.dart';
import 'utils/i18n_resolver.dart';
import 'utils/permissions.dart';
import 'utils/startup_trace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    HydrionStartupTrace.log(
      'HydrionBootstrapApp.warmup gate=services_future status=start',
    );
    final services = await _servicesFuture;
    HydrionStartupTrace.log(
      'HydrionBootstrapApp.warmup gate=services_future status=done',
    );
    _loadedServices = services;
    if (mounted) {
      setState(() {});
    }
    HydrionStartupTrace.log(
      'HydrionBootstrapApp.warmup gate=network_dependent_init status=start',
    );
    await Future.wait([
      services.hydrationSummaryService.getHydrationSummary(),
      services.hydrationContextProvider.getHydrationContext(),
    ]);
    HydrionStartupTrace.log(
      'HydrionBootstrapApp.warmup gate=network_dependent_init status=done',
    );
    HydrionStartupTrace.log('HydrionBootstrapApp.warmup complete');
  }

  String _routeFor(HydrionServices services) {
    if (!services.appLocaleRepository.selectionCompleted) {
      HydrionStartupTrace.log(
        'HydrionBootstrapApp.routing gate=locale_selection result=blocked',
      );
      return '/language';
    }
    final settings = services.settingsRepository.settings;
    if (!settings.onboardingCompleted) {
      HydrionStartupTrace.log(
        'HydrionBootstrapApp.routing gate=onboarding result=blocked',
      );
      return '/onboarding';
    }
    final accessStage = HydrionLifeStagePolicy.productAccessStage(settings.age);
    if (accessStage == HydrionProductAccessStage.unsupportedIndependentChild ||
        accessStage == HydrionProductAccessStage.invalid) {
      HydrionStartupTrace.log(
        'HydrionBootstrapApp.routing gate=life_stage result=blocked',
        data: {'accessStage': accessStage.name},
      );
      return '/profile-age-review';
    }
    if (HydrionLegalAcceptancePolicy.needsReview(
      onboardingCompleted: settings.onboardingCompleted,
      acceptedTermsVersion: settings.acceptedTermsVersion,
      acknowledgedHealthDisclaimerVersion:
          settings.acknowledgedHealthDisclaimerVersion,
    )) {
      HydrionStartupTrace.log(
        'HydrionBootstrapApp.routing gate=legal_acceptance result=blocked',
      );
      return '/legal-review';
    }
    HydrionStartupTrace.log(
      'HydrionBootstrapApp.routing gate=all result=passed route=/home',
    );
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

    final startupThemeMode = switch (
        _loadedServices?.settingsRepository.settings.themePreference ??
            HydrionThemePreference.system) {
      final preference =>
        DynamicThemeClock.themeModeFor(preference, DateTime.now()),
    };
    return MaterialApp(
      title: 'Hydrion',
      theme: buildHydrionTheme(),
      darkTheme: buildHydrionTheme(brightness: Brightness.dark),
      themeMode: startupThemeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => HydrionSystemUi(child: child!),
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  HydrionApp({
    super.key,
    HydrionServices? services,
    this.initialRoute = '/',
    this.startupMinimumDuration = Duration.zero,
  }) : services = services ?? HydrionServices.memory();

  @override
  Widget build(BuildContext context) {
    services.androidWidgetService.attachTimedSessionActionHandler(
      (challengeId, action) async {
        if (challengeId == PomodoroSessionService.challengeId) {
          switch (action) {
            case 'pause':
              await services.pomodoroSessionService.pause();
            case 'resume':
              await services.pomodoroSessionService.resume();
            case 'stop':
              await services.pomodoroSessionService.stop();
          }
          return;
        }
        if (challengeId != 'homework-hydration') return;
        switch (action) {
          case 'pause':
            await services.challengeRepository
                .pauseActivitySession(challengeId);
          case 'resume':
            await services.challengeRepository
                .startActivitySession(challengeId);
          case 'stop':
            await services.challengeRepository
                .resetActivitySession(challengeId);
        }
        await _syncHomeworkTimedNotification(services);
      },
    );
    services.androidWidgetService.attachChallengeOpener((challengeId) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      if (challengeId == null) {
        navigator.pushNamed('/challenges');
        return;
      }
      if (challengeId == '__log__') {
        navigator.pushNamed('/log');
        return;
      }
      if (challengeId == '__home__') {
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        return;
      }
      HydrationChallenge? selected;
      for (final challenge in HydrionChallengeCatalog.challenges) {
        if (challenge.id == challengeId) {
          selected = challenge;
          break;
        }
      }
      if (selected == null) {
        navigator.pushNamed('/challenges');
        return;
      }
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ChallengeExperienceScreen(challenge: selected!),
        ),
      );
    });
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
              if (!services.appLocaleRepository.selectionCompleted) {
                return '/language';
              }
              final settings = services.settingsRepository.settings;
              if (!settings.onboardingCompleted) {
                return '/onboarding';
              }
              if (!settings.missionIntroductionHandled) {
                return '/mission';
              }
              final accessStage =
                  HydrionLifeStagePolicy.productAccessStage(settings.age);
              if (accessStage ==
                      HydrionProductAccessStage.unsupportedIndependentChild ||
                  accessStage == HydrionProductAccessStage.invalid) {
                return '/profile-age-review';
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
      '/language': (_) => const LanguageSelectionScreen(),
      '/onboarding': (_) => const OnboardingScreen(),
      '/mission': (_) => const MissionScreen(fromOnboarding: true),
      '/analytics': (_) => const AnalyticsScreen(),
      '/log': (_) => const LogScreen(),
      if (services.capabilityReporter.capabilities.osNotifications)
        '/reminders': (_) => const RemindersScreen(),
      '/settings': (_) => const SettingsScreen(),
      '/permissions': (_) => const PermissionCenterScreen(),
      '/profile': (_) => const ProfileScreen(),
      '/profile-age-review': (_) => const ProfileAgeReviewScreen(),
      '/body-metrics': (_) => const BodyMetricsScreen(),
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
        ChangeNotifierProvider.value(value: services.appLocaleRepository),
        ChangeNotifierProvider.value(value: services.reminderRepository),
        ChangeNotifierProvider.value(value: services.challengeRepository),
        ChangeNotifierProvider.value(value: services.bodyMetricsRepository),
        ChangeNotifierProvider.value(
          value: services.dailyHydrationContextRepository,
        ),
        ChangeNotifierProvider.value(
          value: services.personalizationStateRepository,
        ),
        ChangeNotifierProvider.value(value: services.guidedTourRepository),
        Provider(
          create: (_) => AppRefreshController(
            hydrationRepository: services.hydrationRepository,
            challengeRepository: services.challengeRepository,
            settingsRepository: services.settingsRepository,
          ),
        ),
        ChangeNotifierProvider(create: (_) => DynamicThemeClock()),
        Provider.value(value: services.coreBridge),
        ChangeNotifierProvider.value(value: services.permissions),
        ChangeNotifierProvider.value(value: services.currentWeatherContext),
        ChangeNotifierProvider.value(value: services.i18n),
        Provider.value(value: services.notificationService),
        Provider.value(value: services.pomodoroSessionService),
        Provider.value(value: services.timedSessionNotificationService),
        Provider.value(value: services.locationService),
        Provider.value(value: services.weatherForecastService),
        Provider.value(value: services.dailyWeatherGoalCoordinator),
        Provider.value(
          value: services.dailyHydrationRecommendationCoordinator,
        ),
        Provider.value(value: services.challengeRecommendationService),
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
        Provider.value(value: services.localProfileResetService),
      ],
      child: Consumer3<I18nResolver, UserSettingsRepository, DynamicThemeClock>(
        builder: (context, i18n, settingsRepository, themeClock, _) {
          final themeMode = themeClock.resolve(
            settingsRepository.settings.themePreference,
          );
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Hydrion',
            theme: buildHydrionTheme(),
            darkTheme: buildHydrionTheme(brightness: Brightness.dark),
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: i18n.locale,
            builder: (context, child) => HydrionSystemUi(child: child!),
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

Future<void> _syncHomeworkTimedNotification(HydrionServices services) async {
  const challengeId = 'homework-hydration';
  final challenge =
      services.challengeRepository.activeChallengeFor(challengeId);
  if (challenge == null) {
    await services.timedSessionNotificationService
        .cancel(HydrionTimedSessionKind.homework);
    return;
  }
  final status = challenge.parameters['activitySessionStatus']?.toString();
  final totalMinutes = ((challenge.parameters['sessionMinutes'] as num?) ?? 25)
      .round()
      .clamp(1, 1440);
  final remaining = Duration(minutes: totalMinutes) -
      services.challengeRepository.activitySessionElapsed(challengeId);
  final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
  final lifecycle = switch (status) {
    'running' => HydrionTimedSessionLifecycle.running,
    'paused' => HydrionTimedSessionLifecycle.paused,
    _ => HydrionTimedSessionLifecycle.stopped,
  };
  await services.timedSessionNotificationService.sync(
    HydrionTimedSessionNotification(
      kind: HydrionTimedSessionKind.homework,
      lifecycle: lifecycle,
      remaining: safeRemaining,
      completionAt: lifecycle == HydrionTimedSessionLifecycle.running
          ? DateTime.now().add(safeRemaining)
          : null,
    ),
  );
}

class HydrionServices {
  final HydrionAiRuntimeConfig aiRuntimeConfig;
  final HydrionLocalStore localStore;
  final HydrationRepository hydrationRepository;
  final UserSettingsRepository settingsRepository;
  final AppLocaleRepository appLocaleRepository;
  final ReminderRepository reminderRepository;
  final ChallengeRepository challengeRepository;
  final BodyMetricsRepository bodyMetricsRepository;
  final DailyHydrationContextRepository dailyHydrationContextRepository;
  final PersonalizationStateRepository personalizationStateRepository;
  final GuidedTourRepository guidedTourRepository;
  final CoreBridge coreBridge;
  final Permissions permissions;
  final I18nResolver i18n;
  final NotificationService notificationService;
  final PomodoroSessionService pomodoroSessionService;
  final TimedSessionNotificationService timedSessionNotificationService;
  final HydrionLocationService locationService;
  final WeatherForecastService weatherForecastService;
  final DailyWeatherGoalCoordinator dailyWeatherGoalCoordinator;
  final DailyHydrationRecommendationCoordinator
      dailyHydrationRecommendationCoordinator;
  final ChallengeRecommendationService challengeRecommendationService;
  final CurrentWeatherContext currentWeatherContext;
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
  final LocalProfileResetService localProfileResetService;
  final AndroidWidgetService androidWidgetService;

  HydrionServices({
    this.aiRuntimeConfig = const HydrionAiRuntimeConfig(),
    required this.localStore,
    required this.hydrationRepository,
    required this.settingsRepository,
    required this.appLocaleRepository,
    required this.reminderRepository,
    required this.challengeRepository,
    required this.bodyMetricsRepository,
    required this.dailyHydrationContextRepository,
    required this.personalizationStateRepository,
    required this.guidedTourRepository,
    required this.coreBridge,
    required this.permissions,
    required this.i18n,
    required this.notificationService,
    required this.pomodoroSessionService,
    required this.timedSessionNotificationService,
    required this.locationService,
    required this.weatherForecastService,
    required this.dailyWeatherGoalCoordinator,
    required this.dailyHydrationRecommendationCoordinator,
    required this.challengeRecommendationService,
    CurrentWeatherContext? currentWeatherContext,
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
    required this.localProfileResetService,
    AndroidWidgetService? androidWidgetService,
  })  : currentWeatherContext =
            currentWeatherContext ?? CurrentWeatherContext(),
        androidWidgetService = androidWidgetService ??
            AndroidWidgetService(
              hydrationRepository: hydrationRepository,
              settingsRepository: settingsRepository,
              challengeRepository: challengeRepository,
              appLocaleRepository: appLocaleRepository,
            );

  static Future<HydrionServices> local() async {
    HydrionStartupTrace.log('HydrionServices.local gate=storage status=start');
    final store = await SharedPreferencesHydrionStore.create();
    HydrionStartupTrace.log('HydrionServices.local gate=storage status=done');

    HydrionStartupTrace.log(
      'HydrionServices.local gate=dependency_init status=start',
    );
    final services = await fromStore(
      store,
      aiRuntimeConfig: HydrionAiRuntimeConfig.fromEnvironment(),
    );
    HydrionStartupTrace.log(
      'HydrionServices.local gate=dependency_init status=done',
    );

    HydrionStartupTrace.log(
      'HydrionServices.local gate=notification_init status=start',
    );
    await services.notificationService.initialize();
    HydrionStartupTrace.log(
      'HydrionServices.local gate=notification_init status=done',
    );

    HydrionStartupTrace.log(
      'HydrionServices.local gate=permissions_refresh status=start',
    );
    await services.permissions.refresh();
    HydrionStartupTrace.log(
      'HydrionServices.local gate=permissions_refresh status=done',
    );

    HydrionStartupTrace.log(
      'HydrionServices.local gate=pomodoro_reconcile status=start',
    );
    await services.pomodoroSessionService.reconcile();
    HydrionStartupTrace.log(
      'HydrionServices.local gate=pomodoro_reconcile status=done',
    );

    HydrionStartupTrace.log(
      'HydrionServices.local gate=homework_timed_notification status=start',
    );
    await _syncHomeworkTimedNotification(services);
    HydrionStartupTrace.log(
      'HydrionServices.local gate=homework_timed_notification status=done',
    );

    HydrionStartupTrace.log(
      'HydrionServices.local gate=notification_reconcile_schedules '
      'status=start',
    );
    await services.notificationService.reconcileSchedules();
    HydrionStartupTrace.log(
      'HydrionServices.local gate=notification_reconcile_schedules '
      'status=done',
    );

    HydrionStartupTrace.log(
      'HydrionServices.local gate=android_widget_init status=start',
    );
    await services.androidWidgetService.initialize();
    HydrionStartupTrace.log(
      'HydrionServices.local gate=android_widget_init status=done',
    );
    return services;
  }

  static Future<HydrionServices> fromStore(
    HydrionLocalStore store, {
    HydrionAiRuntimeConfig aiRuntimeConfig = const HydrionAiRuntimeConfig(),
    HydrionLocationService? locationService,
    HydrionNotificationAdapter? notificationAdapter,
    HydrionTimedSessionNotificationAdapter? timedSessionNotificationAdapter,
    DailyWeatherProvider? weatherProvider,
    HydrionProfilePhotoPicker? profilePhotoPicker,
  }) async {
    final hydrationRepository = await HydrationRepository.load(store);
    final settingsRepository = await UserSettingsRepository.load(store);
    final appLocaleRepository = await AppLocaleRepository.load(
      store,
      legacyLocale: settingsRepository.settings.locale,
      establishedUser: settingsRepository.settings.onboardingCompleted ||
          hydrationRepository.eventCount > 0,
    );
    final reminderRepository = await ReminderRepository.load(store);
    final challengeRepository = await ChallengeRepository.load(store);
    final bodyMetricsRepository = await BodyMetricsRepository.load(store);
    final dailyHydrationContextRepository =
        await DailyHydrationContextRepository.load(store);
    final personalizationStateRepository =
        await PersonalizationStateRepository.load(store);
    if (settingsRepository.settings.sex != HydrionSex.female &&
        bodyMetricsRepository.metrics.reproductiveState !=
            HydrionReproductiveHydrationState.none) {
      await bodyMetricsRepository.update(
        reproductiveState: HydrionReproductiveHydrationState.none,
        femaleProfile: false,
      );
    }
    final guidedTourRepository = await GuidedTourRepository.load(
      store,
      establishedUser: settingsRepository.settings.onboardingCompleted ||
          hydrationRepository.eventCount > 0,
    );
    return _build(
      store: store,
      hydrationRepository: hydrationRepository,
      settingsRepository: settingsRepository,
      appLocaleRepository: appLocaleRepository,
      reminderRepository: reminderRepository,
      challengeRepository: challengeRepository,
      bodyMetricsRepository: bodyMetricsRepository,
      dailyHydrationContextRepository: dailyHydrationContextRepository,
      personalizationStateRepository: personalizationStateRepository,
      guidedTourRepository: guidedTourRepository,
      aiRuntimeConfig: aiRuntimeConfig,
      locationService: locationService,
      notificationAdapter: notificationAdapter,
      timedSessionNotificationAdapter: timedSessionNotificationAdapter,
      weatherProvider: weatherProvider,
      profilePhotoPicker: profilePhotoPicker,
    );
  }

  factory HydrionServices.memory({
    HydrionAiRuntimeConfig aiRuntimeConfig = const HydrionAiRuntimeConfig(),
    HydrionLocationService? locationService,
    HydrionNotificationAdapter? notificationAdapter,
    HydrionTimedSessionNotificationAdapter? timedSessionNotificationAdapter,
    DailyWeatherProvider? weatherProvider,
    HydrionProfilePhotoPicker? profilePhotoPicker,
    GuidedTourRepository? guidedTourRepository,
    ChallengeRepository? challengeRepository,
  }) {
    final store = MemoryHydrionStore();
    return _build(
      store: store,
      hydrationRepository: HydrationRepository.memory(),
      settingsRepository: UserSettingsRepository.memory(),
      appLocaleRepository: AppLocaleRepository.memory(),
      reminderRepository: ReminderRepository.memory(),
      challengeRepository: challengeRepository ?? ChallengeRepository.memory(),
      bodyMetricsRepository: BodyMetricsRepository.memory(),
      dailyHydrationContextRepository: DailyHydrationContextRepository.memory(),
      personalizationStateRepository: PersonalizationStateRepository.memory(),
      guidedTourRepository:
          guidedTourRepository ?? GuidedTourRepository.memory(),
      aiRuntimeConfig: aiRuntimeConfig,
      locationService: locationService ?? FakeHydrionLocationService(),
      notificationAdapter: notificationAdapter ??
          FakeHydrionNotificationAdapter(
            permission: HydrionNotificationPermissionState.granted,
          ),
      timedSessionNotificationAdapter: timedSessionNotificationAdapter ??
          FakeTimedSessionNotificationAdapter(),
      weatherProvider: weatherProvider ?? _FakeDailyWeatherProvider(),
      profilePhotoPicker: profilePhotoPicker ?? FakeHydrionProfilePhotoPicker(),
    );
  }

  static HydrionServices _build({
    required HydrionLocalStore store,
    required HydrationRepository hydrationRepository,
    required UserSettingsRepository settingsRepository,
    required AppLocaleRepository appLocaleRepository,
    required ReminderRepository reminderRepository,
    required ChallengeRepository challengeRepository,
    required BodyMetricsRepository bodyMetricsRepository,
    required DailyHydrationContextRepository dailyHydrationContextRepository,
    required PersonalizationStateRepository personalizationStateRepository,
    required GuidedTourRepository guidedTourRepository,
    required HydrionAiRuntimeConfig aiRuntimeConfig,
    HydrionLocationService? locationService,
    HydrionNotificationAdapter? notificationAdapter,
    HydrionTimedSessionNotificationAdapter? timedSessionNotificationAdapter,
    DailyWeatherProvider? weatherProvider,
    HydrionProfilePhotoPicker? profilePhotoPicker,
  }) {
    challengeRepository.bindHydrationRepository(hydrationRepository);
    final coreBridge = CoreBridge(hydrationRepository: hydrationRepository);
    final location =
        locationService ?? const GeolocatorHydrionLocationService();
    final i18n = I18nResolver(localeRepository: appLocaleRepository);
    final policy = ReminderPolicy();
    final notificationService = NotificationService(
      reminderPolicy: policy,
      reminderRepository: reminderRepository,
      adapter: notificationAdapter,
      localeRepository: appLocaleRepository,
    );
    final permissions = Permissions(
      notifications: notificationService,
      location: location,
      settings: settingsRepository,
    );
    final timedSessionNotificationService = TimedSessionNotificationService(
      localeRepository: appLocaleRepository,
      adapter: timedSessionNotificationAdapter ??
          const AndroidTimedSessionNotificationAdapter(),
    );
    final pomodoroSessionService = PomodoroSessionService(
      challengeRepository: challengeRepository,
      notificationService: notificationService,
      timedSessionNotificationService: timedSessionNotificationService,
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
    final dailyHydrationRecommendationCoordinator =
        DailyHydrationRecommendationCoordinator(
      settingsRepository: settingsRepository,
      bodyMetricsRepository: bodyMetricsRepository,
      dailyContextRepository: dailyHydrationContextRepository,
      stateRepository: personalizationStateRepository,
    );
    const challengeRecommendationService = ChallengeRecommendationService();
    final currentWeatherContext = CurrentWeatherContext();
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
      fallbackBuilder: ({required context, required userQuery}) =>
          lookupAppLocalizations(i18n.locale).localCoachFallback(
        context: context,
        userQuery: userQuery,
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
    final localProfileResetService = LocalProfileResetService(
      settingsRepository: settingsRepository,
      hydrationRepository: hydrationRepository,
      challengeRepository: challengeRepository,
      reminderRepository: reminderRepository,
      notificationService: notificationService,
      weatherForecastService: weatherForecastService,
      bodyMetricsRepository: bodyMetricsRepository,
      dailyHydrationContextRepository: dailyHydrationContextRepository,
      personalizationStateRepository: personalizationStateRepository,
      timedSessionNotificationService: timedSessionNotificationService,
    );
    final androidWidgetService = AndroidWidgetService(
      hydrationRepository: hydrationRepository,
      settingsRepository: settingsRepository,
      challengeRepository: challengeRepository,
      appLocaleRepository: appLocaleRepository,
    );

    return HydrionServices(
      aiRuntimeConfig: aiRuntimeConfig,
      localStore: store,
      hydrationRepository: hydrationRepository,
      settingsRepository: settingsRepository,
      appLocaleRepository: appLocaleRepository,
      reminderRepository: reminderRepository,
      challengeRepository: challengeRepository,
      bodyMetricsRepository: bodyMetricsRepository,
      dailyHydrationContextRepository: dailyHydrationContextRepository,
      personalizationStateRepository: personalizationStateRepository,
      guidedTourRepository: guidedTourRepository,
      coreBridge: coreBridge,
      permissions: permissions,
      i18n: i18n,
      notificationService: notificationService,
      pomodoroSessionService: pomodoroSessionService,
      timedSessionNotificationService: timedSessionNotificationService,
      locationService: location,
      weatherForecastService: weatherForecastService,
      dailyWeatherGoalCoordinator: dailyWeatherGoalCoordinator,
      dailyHydrationRecommendationCoordinator:
          dailyHydrationRecommendationCoordinator,
      challengeRecommendationService: challengeRecommendationService,
      currentWeatherContext: currentWeatherContext,
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
      localProfileResetService: localProfileResetService,
      androidWidgetService: androidWidgetService,
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
