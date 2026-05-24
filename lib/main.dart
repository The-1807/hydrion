import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adapters/elka/elka_adapter.dart';
import 'adapters/local/local_hydrion_adapters.dart';
import 'domain/hydration_contracts.dart';
import 'repositories/challenge_repository.dart';
import 'repositories/hydration_repository.dart';
import 'repositories/reminder_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/core_bridge.dart';
import 'services/eco_tracker.dart';
import 'services/notifications.dart';
import 'services/policy_service.dart';
import 'services/voice_client.dart';
import 'services/voice_llm_bridge.dart';
import 'services/wearable_service.dart';
import 'ui/screens/analytics_screen.dart';
import 'ui/screens/ar_visualization_screen.dart';
import 'ui/screens/chat_coach_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/log_screen.dart';
import 'ui/screens/reminders_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/social_challenges_screen.dart';
import 'storage/local_store.dart';
import 'utils/i18n_resolver.dart';
import 'utils/permissions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await HydrionServices.local();
  runApp(HydrionApp(services: services));
}

class HydrionApp extends StatelessWidget {
  final HydrionServices services;

  HydrionApp({super.key, HydrionServices? services})
      : services = services ?? HydrionServices.memory();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: services.hydrationRepository),
        Provider.value(value: services.settingsRepository),
        ChangeNotifierProvider.value(value: services.reminderRepository),
        ChangeNotifierProvider.value(value: services.challengeRepository),
        Provider.value(value: services.coreBridge),
        Provider.value(value: services.permissions),
        ChangeNotifierProvider.value(value: services.i18n),
        Provider.value(value: services.notificationService),
        Provider<HydrationSummaryService>.value(
          value: services.hydrationSummaryService,
        ),
        Provider<HydrationCoach>.value(value: services.hydrationCoach),
        Provider<ChallengeGenerator>.value(value: services.challengeGenerator),
        Provider<HydrationCommandParser>.value(value: services.commandParser),
        Provider<AppCapabilityReporter>.value(
          value: services.capabilityReporter,
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
            theme: _theme,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: I18nResolver.localizationsDelegates,
            supportedLocales: I18nResolver.supportedLocales,
            locale: i18n.locale,
            initialRoute: '/',
            routes: {
              '/': (_) => const HomeScreen(),
              '/analytics': (_) => const AnalyticsScreen(),
              '/chat': (_) => const ChatCoachScreen(),
              '/log': (_) => const LogScreen(),
              '/reminders': (_) => const RemindersScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/challenges': (_) => const SocialChallengesScreen(),
              '/ar': (_) => const ArVisualizationScreen(),
            },
          );
        },
      ),
    );
  }
}

class HydrionServices {
  final HydrionLocalStore localStore;
  final HydrationRepository hydrationRepository;
  final UserSettingsRepository settingsRepository;
  final ReminderRepository reminderRepository;
  final ChallengeRepository challengeRepository;
  final CoreBridge coreBridge;
  final Permissions permissions;
  final I18nResolver i18n;
  final NotificationService notificationService;
  final HydrationSummaryService hydrationSummaryService;
  final HydrationCoach hydrationCoach;
  final ChallengeGenerator challengeGenerator;
  final HydrationCommandParser commandParser;
  final AppCapabilityReporter capabilityReporter;
  final ElkaAdapterShell elkaAdapter;
  final VoiceService voice;
  final VoiceLLMBridge voiceBridge;
  final WearableService wearables;
  final EcoTracker ecoTracker;

  HydrionServices({
    required this.localStore,
    required this.hydrationRepository,
    required this.settingsRepository,
    required this.reminderRepository,
    required this.challengeRepository,
    required this.coreBridge,
    required this.permissions,
    required this.i18n,
    required this.notificationService,
    required this.hydrationSummaryService,
    required this.hydrationCoach,
    required this.challengeGenerator,
    required this.commandParser,
    required this.capabilityReporter,
    required this.elkaAdapter,
    required this.voice,
    required this.voiceBridge,
    required this.wearables,
    required this.ecoTracker,
  });

  static Future<HydrionServices> local() async {
    final store = await SharedPreferencesHydrionStore.create();
    return fromStore(store);
  }

  static Future<HydrionServices> fromStore(HydrionLocalStore store) async {
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
    );
  }

  factory HydrionServices.memory() {
    return _build(
      store: MemoryHydrionStore(),
      hydrationRepository: HydrationRepository.memory(),
      settingsRepository: UserSettingsRepository.memory(),
      reminderRepository: ReminderRepository.memory(),
      challengeRepository: ChallengeRepository.memory(),
    );
  }

  static HydrionServices _build({
    required HydrionLocalStore store,
    required HydrationRepository hydrationRepository,
    required UserSettingsRepository settingsRepository,
    required ReminderRepository reminderRepository,
    required ChallengeRepository challengeRepository,
  }) {
    final coreBridge = CoreBridge(hydrationRepository: hydrationRepository);
    final permissions = Permissions();
    final i18n = I18nResolver(settingsRepository: settingsRepository);
    final policy = ReminderPolicy();
    final notificationService = NotificationService(
      reminderPolicy: policy,
      reminderRepository: reminderRepository,
    );
    final hydrationSummaryService = LocalHydrationSummaryService(
      hydrationRepository: hydrationRepository,
    );
    final hydrationCoach = LocalHydrationCoach(coreBridge: coreBridge);
    const challengeGenerator = LocalChallengeGenerator();
    const commandParser = LocalHydrationCommandParser();
    const capabilityReporter = LocalAppCapabilityReporter();
    const elkaAdapter = ElkaAdapterShell.unconfigured();
    final voiceBridge = VoiceLLMBridge(commandParser: commandParser);
    final voice = VoiceService(voiceLLMBridge: voiceBridge);
    final wearables = WearableService(hydrationRepository: hydrationRepository);
    final ecoTracker = EcoTracker(coreBridge: coreBridge);

    return HydrionServices(
      localStore: store,
      hydrationRepository: hydrationRepository,
      settingsRepository: settingsRepository,
      reminderRepository: reminderRepository,
      challengeRepository: challengeRepository,
      coreBridge: coreBridge,
      permissions: permissions,
      i18n: i18n,
      notificationService: notificationService,
      hydrationSummaryService: hydrationSummaryService,
      hydrationCoach: hydrationCoach,
      challengeGenerator: challengeGenerator,
      commandParser: commandParser,
      capabilityReporter: capabilityReporter,
      elkaAdapter: elkaAdapter,
      voice: voice,
      voiceBridge: voiceBridge,
      wearables: wearables,
      ecoTracker: ecoTracker,
    );
  }
}

final ThemeData _theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
