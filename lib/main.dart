// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';

// Notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// SQLite for EcoTracker
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// Services
import 'sevices/llm_service.dart';
import '/services/voice_service.dart';
import '/services/voice_llm_bridge.dart';
import '/services/wearable_service.dart';
import '/services/notifications.dart';
import '/services/ai_bridge.dart';
import '/services/eco_tracker.dart';

// Utils
import 'utils/permissions.dart';
import 'utils/i18n_resolver.dart';

// Screens
import 'ui/screens/HomeScreen.dart';
import '../hydrion/app/lib/ui/screens/AnalyticsScreen.dart';
import 'ui/screens/ChatCoachScreen.dart';
import 'ui/screens/LogScreen.dart';
import 'ui/screens/SettingsScreen.dart';
import '../hydrion/app/lib/ui/screens/SocialChallengesScreen.dart';
import 'ui/screens/ArVisualizationScreen.dart';

// Optional (if your ReminderPolicy KMP binding is available on Dart side)
// If not available yet, comment the import + construction below and
// use a lightweight stub in NotificationService instead.
import 'package:hydrion/policy/policy.dart'; // KMP export expected

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late Future<_AppBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _initAll();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppBundle>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return MaterialApp(
            theme: _theme,
            debugShowCheckedModeBanner: false,
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final bundle = snap.data ?? _AppBundle.fallback();

        return MultiProvider(
          providers: [
            Provider.value(value: bundle.permissions),
            Provider.value(value: bundle.i18n),
            Provider.value(value: bundle.notifications),
            Provider.value(value: bundle.notificationService),
            Provider.value(value: bundle.llm),
            Provider.value(value: bundle.voice),
            Provider.value(value: bundle.voiceBridge),
            Provider.value(value: bundle.wearables),
            Provider.value(value: bundle.aiBridge),
            Provider.value(value: bundle.ecoTracker),
          ],
          child: MaterialApp(
            title: 'Hydrion',
            theme: _theme,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: I18nResolver.localizationsDelegates,
            supportedLocales: I18nResolver.supportedLocales,
            initialRoute: '/',
            routes: {
              '/': (_) => Stack(
                    children: [
                      const HomeScreen(),
                      if (snap.hasError)
                        _BootstrapErrorBanner(message: snap.error.toString()),
                    ],
                  ),
              '/analytics': (_) => const AnalyticsScreen(),
              '/chat': (_) => const ChatCoachScreen(),
              '/log': (_) => const LogScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/challenges': (_) => const SocialChallengesScreen(),
              '/ar': (_) => const ArVisualizationScreen(),
            },
          ),
        );
      },
    );
  }
}

final ThemeData _theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
  fontFamily: 'Roboto',
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

class _BootstrapErrorBanner extends StatelessWidget {
  final String message;
  const _BootstrapErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Startup issue: $message',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
          ),
        ),
      ),
    );
  }
}

class _AppBundle {
  final Permissions permissions;
  final I18nResolver i18n;
  final FlutterLocalNotificationsPlugin notifications;
  final NotificationService notificationService;
  final LLMService llm;
  final VoiceService voice;
  final VoiceLLMBridge voiceBridge;
  final WearableService wearables;
  final AIBridge aiBridge;
  final EcoTracker ecoTracker;

  _AppBundle({
    required this.permissions,
    required this.i18n,
    required this.notifications,
    required this.notificationService,
    required this.llm,
    required this.voice,
    required this.voiceBridge,
    required this.wearables,
    required this.aiBridge,
    required this.ecoTracker,
  });

  factory _AppBundle.fallback() {
    final permissions = Permissions();
    final i18n = I18nResolver();
    final notifications = FlutterLocalNotificationsPlugin();

    // Minimal stub policy if KMP binding not ready
    final reminderPolicy = _StubReminderPolicy();

    final notificationService = NotificationService(
      notifications: notifications,
      reminderPolicy: reminderPolicy,
    );

    final llm = LLMService();
    final voiceBridge = VoiceLLMBridge(llmService: llm, voiceService: _DummyVoice()); // temporary chain
    final voice = VoiceService(voiceLLMBridge: voiceBridge);
    final wearables = WearableService(permissions: permissions);
    final aiBridge = AIBridge();
    final ecoTracker = EcoTracker(db: _MemoryDb());

    return _AppBundle(
      permissions: permissions,
      i18n: i18n,
      notifications: notifications,
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

Future<_AppBundle> _initAll() async {
  final permissions = Permissions();
  final i18n = I18nResolver();

  // Firebase (optional)
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // degrade gracefully
  }

  // Notifications
  final notifications = FlutterLocalNotificationsPlugin();
  await _initNotifications(notifications);
  await _ensureNotificationPermissions(notifications);
  await _createAndroidChannel(notifications);

  // LLM
  final llm = LLMService();
  await llm.initialize();

  // Voice
  final voiceBridge = VoiceLLMBridge(
    llmService: llm,
    voiceService: _DummyVoice(), // will still route through bridge
  );
  final voice = VoiceService(voiceLLMBridge: voiceBridge);

  // Wearables
  final wearables = WearableService(permissions: permissions);

  // AIBridge (KMP) — assume cheap constructor
  final aiBridge = AIBridge();

  // EcoTracker DB
  final ecoDb = await _openEcoDb();
  final ecoTracker = EcoTracker(db: ecoDb);

  // Reminder Policy (from KMP binding if available)
  dynamic reminderPolicy;
  try {
    reminderPolicy = ReminderPolicy(); // requires KMP export
  } catch (_) {
    reminderPolicy = _StubReminderPolicy();
  }

  final notificationService = NotificationService(
    notifications: notifications,
    reminderPolicy: reminderPolicy,
  );

  // Kick off permissions (non-blocking)
  unawaited(permissions.requestPermissions());

  return _AppBundle(
    permissions: permissions,
    i18n: i18n,
    notifications: notifications,
    notificationService: notificationService,
    llm: llm,
    voice: voice,
    voiceBridge: voiceBridge,
    wearables: wearables,
    aiBridge: aiBridge,
    ecoTracker: ecoTracker,
  );
}

Future<void> _initNotifications(FlutterLocalNotificationsPlugin plugin) async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const settings = InitializationSettings(android: androidInit, iOS: iosInit);
  await plugin.initialize(settings);
}

Future<void> _ensureNotificationPermissions(FlutterLocalNotificationsPlugin plugin) async {
  final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  final ios = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  if (android != null) {
    await android.requestPermission();
  }
  if (ios != null) {
    await ios.requestPermissions(alert: true, badge: true, sound: true);
  }
}

Future<void> _createAndroidChannel(FlutterLocalNotificationsPlugin plugin) async {
  const channel = AndroidNotificationChannel(
    'hydration_channel',
    'Hydration Reminders',
    description: 'Smart reminders to keep you hydrated',
    importance: Importance.defaultImportance,
  );
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<Database> _openEcoDb() async {
  final dir = await getDatabasesPath();
  final path = p.join(dir, 'hydrion_eco.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS eco_log(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp INTEGER NOT NULL,
          volume_ml INTEGER NOT NULL,
          plastic_saved_kg REAL NOT NULL
        )
      ''');
    },
  );
}

/// Simple stub to satisfy NotificationService if KMP ReminderPolicy is unavailable.
class _StubReminderPolicy {
  bool shouldSendReminder(int _) => true;

  Future<dynamic> scheduleReminder({
    required int shortfallMl,
    required double lastDrinkHoursAgo,
    required double hydrationPercent,
    required bool isActiveTime,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch + 30 * 60 * 1000;
    return ({
      'message': 'Time to drink $shortfallMl ml!',
      'triggerTime': ts,
      'priority': 2,
    });
  }
}

/// Minimal voice stub; your real VoiceService uses speech_to_text internally.
class _DummyVoice extends VoiceService {
  _DummyVoice() : super(voiceLLMBridge: _DummyBridge());
}

class _DummyBridge extends VoiceLLMBridge {
  _DummyBridge() : super(llmService: LLMService(), voiceService: _NoopVoice());
  @override
  Future<Map<String, dynamic>> parseVoiceCommand(String speech) async => {'intent': 'noop'};
}

class _NoopVoice extends VoiceService {
  _NoopVoice() : super(voiceLLMBridge: _DummyBridge());
}

/// In-memory DB fallback if sqflite open fails (used only in fallback bundle).
class _MemoryDb implements Database {
  final List<Map<String, Object?>> _rows = [];
  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    _rows.add(values);
    return _rows.length;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final total = _rows.fold<double>(0.0, (sum, r) => sum + ((r['plastic_saved_kg'] as double?) ?? 0.0));
    return [
      {'total': total}
    ];
  }

  // The rest of Database methods are not used by EcoTracker; throw if called.
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
