import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/ai_bridge.dart';
import 'services/core_bridge.dart';
import 'services/eco_tracker.dart';
import 'services/llm_service.dart';
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
import 'ui/screens/settings_screen.dart';
import 'ui/screens/social_challenges_screen.dart';
import 'utils/i18n_resolver.dart';
import 'utils/permissions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HydrionApp());
}

class HydrionApp extends StatelessWidget {
  final HydrionServices services;

  HydrionApp({super.key, HydrionServices? services})
      : services = services ?? HydrionServices.local();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: services.coreBridge),
        Provider.value(value: services.permissions),
        Provider.value(value: services.i18n),
        Provider.value(value: services.notificationService),
        Provider.value(value: services.llm),
        Provider.value(value: services.voice),
        Provider.value(value: services.voiceBridge),
        Provider.value(value: services.wearables),
        Provider.value(value: services.aiBridge),
        Provider.value(value: services.ecoTracker),
      ],
      child: MaterialApp(
        title: 'Hydrion',
        theme: _theme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: I18nResolver.localizationsDelegates,
        supportedLocales: I18nResolver.supportedLocales,
        locale: services.i18n.locale,
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/analytics': (_) => const AnalyticsScreen(),
          '/chat': (_) => const ChatCoachScreen(),
          '/log': (_) => const LogScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/challenges': (_) => const SocialChallengesScreen(),
          '/ar': (_) => const ArVisualizationScreen(),
        },
      ),
    );
  }
}

class HydrionServices {
  final CoreBridge coreBridge;
  final Permissions permissions;
  final I18nResolver i18n;
  final NotificationService notificationService;
  final LLMService llm;
  final VoiceService voice;
  final VoiceLLMBridge voiceBridge;
  final WearableService wearables;
  final AIBridge aiBridge;
  final EcoTracker ecoTracker;

  HydrionServices({
    required this.coreBridge,
    required this.permissions,
    required this.i18n,
    required this.notificationService,
    required this.llm,
    required this.voice,
    required this.voiceBridge,
    required this.wearables,
    required this.aiBridge,
    required this.ecoTracker,
  });

  factory HydrionServices.local() {
    final coreBridge = CoreBridge();
    final permissions = Permissions();
    final i18n = I18nResolver();
    final policy = ReminderPolicy();
    final notificationService = NotificationService(reminderPolicy: policy);
    final llm = LLMService(coreBridge: coreBridge);
    final voiceBridge = VoiceLLMBridge(llmService: llm);
    final voice = VoiceService(voiceLLMBridge: voiceBridge);
    final wearables = WearableService();
    final aiBridge = AIBridge();
    final ecoTracker = EcoTracker(coreBridge: coreBridge);

    return HydrionServices(
      coreBridge: coreBridge,
      permissions: permissions,
      i18n: i18n,
      notificationService: notificationService,
      llm: llm,
      voice: voice,
      voiceBridge: voiceBridge,
      wearables: wearables,
      aiBridge: aiBridge,
      ecoTracker: ecoTracker,
    );
  }
}

final ThemeData _theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
