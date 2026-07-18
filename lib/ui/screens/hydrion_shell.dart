import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../repositories/settings_repository.dart';
import '../../services/notifications.dart';
import '../../services/weather_goal_service.dart';
import '../components/guided_tour_overlay.dart';
import '../theme/hydrion_design.dart';
import '../components/intake_ring.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'social_challenges_screen.dart';

class HydrionShell extends StatefulWidget {
  const HydrionShell({super.key});

  @override
  State<HydrionShell> createState() => _HydrionShellState();
}

class _HydrionShellState extends State<HydrionShell>
    with WidgetsBindingObserver {
  static final _homeTargetKey = GlobalKey();
  static final _logTargetKey = GlobalKey();
  static final _historyTargetKey = GlobalKey();
  static final _challengesTargetKey = GlobalKey();
  static final _progressTargetKey = GlobalKey();

  int _selectedIndex = 0;
  Timer? _dayRolloverTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDayRollover();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateWeatherAssistance();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayRolloverTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocalLifecycleState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applySystemBars();
  }

  Future<void> _refreshLocalLifecycleState() async {
    if (!mounted) {
      return;
    }
    setState(() {});
    _scheduleDayRollover();
    final notificationService = context.read<NotificationService>();
    final settings = context.read<UserSettingsRepository>().settings;
    await notificationService.reconcileSchedules();
    if (!mounted) {
      return;
    }
    if (settings.goalMode == HydrionGoalMode.weatherInformed) {
      await _evaluateWeatherAssistance();
      if (!mounted) {
        return;
      }
      setState(() {});
    }
  }

  void _scheduleDayRollover() {
    _dayRolloverTimer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _dayRolloverTimer = Timer(nextDay.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleDayRollover();
      _evaluateWeatherAssistance();
    });
  }

  Future<void> _evaluateWeatherAssistance() async {
    if (!mounted) return;
    final settings = context.read<UserSettingsRepository>().settings;
    if (settings.goalMode != HydrionGoalMode.weatherInformed) return;

    final coordinator = context.read<DailyWeatherGoalCoordinator>();
    final result = await coordinator.evaluate();
    if (!mounted ||
        result.status != DailyWeatherGoalStatus.promptReady ||
        result.decision == null ||
        result.forecast == null) {
      return;
    }

    final decision = result.decision!;
    final forecast = result.forecast!;
    final unit = settings.volumeUnit;
    final weatherAdjustment = HydrationVolumeFormatter.format(
      decision.weatherAdjustmentMl.abs(),
      unit,
    );
    final useSuggestion = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Today's weather hydration suggestion"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${forecast.condition} · '
                  '${forecast.temperatureC.toStringAsFixed(1)}°C'),
              if (forecast.humidityPercent != null)
                Text(
                  'Humidity: ${forecast.humidityPercent!.round()}%',
                ),
              const SizedBox(height: 12),
              Text(
                'Standard goal: '
                '${HydrationVolumeFormatter.format(decision.baselineGoalMl, unit)}',
              ),
              Text(
                'Weather adjustment: '
                '${decision.weatherAdjustmentMl >= 0 ? '+' : ''}'
                '$weatherAdjustment',
              ),
              Text(
                "Today's suggested goal: "
                '${HydrationVolumeFormatter.format(decision.recommendedGoalMl, unit)}',
              ),
              const SizedBox(height: 8),
              Text(decision.explanation),
              Text(
                'Updated: ${TimeOfDay.fromDateTime(forecast.retrievedAt).format(dialogContext)}',
              ),
              const SizedBox(height: 8),
              const Text(
                'This suggestion uses your saved profile, location permission, and local weather. It is not medical advice.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep standard goal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Use suggestion'),
          ),
        ],
      ),
    );
    if (!mounted || useSuggestion == null) return;
    if (useSuggestion) {
      await coordinator.acceptRecommendation(decision: decision);
    } else {
      await coordinator.keepPreviousGoal(
        explanation: 'Standard goal kept after reviewing local weather.',
      );
    }
  }

  void _applySystemBars() {
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GuidedTourOverlay(
      steps: [
        GuidedTourStep(
          targetKey: _homeTargetKey,
          title: "Today's hydration",
          body: 'Your daily hydration and remaining amount appear here.',
        ),
        GuidedTourStep(
          targetKey: _logTargetKey,
          title: 'Log water',
          body:
              'Log the amount you actually drink. Use a saved container or choose another amount.',
        ),
        GuidedTourStep(
          targetKey: _historyTargetKey,
          title: 'Review and correct',
          body:
              'Review, edit, or remove a hydration entry if you make a mistake.',
        ),
        GuidedTourStep(
          targetKey: _challengesTargetKey,
          title: 'Challenges',
          body:
              'Challenges add optional habits and tasks. Challenge water still counts normally.',
        ),
        GuidedTourStep(
          targetKey: _progressTargetKey,
          title: 'Progress and refresh',
          body:
              'Review daily progress here. Pull down on supported screens to refresh.',
        ),
      ],
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF041621), Color(0xFF0A3040)],
                  )
                : HydrionGradients.lagoon,
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: IndexedStack(
              key: const Key('hydrion-tab-safe-stack'),
              index: _selectedIndex,
              children: [
                HomeScreen(
                  showRouteShortcuts: false,
                  hydrationTargetKey: _homeTargetKey,
                  logTargetKey: _logTargetKey,
                  historyTargetKey: _historyTargetKey,
                ),
                const SocialChallengesScreen(embedded: true),
                const AnalyticsScreen(embedded: true),
                const ProfileScreen(embedded: true),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: NavigationBar(
            key: const Key('hydrion-bottom-nav'),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: [
              const NavigationDestination(
                key: Key('nav-home'),
                icon: Icon(Icons.water_drop_outlined),
                selectedIcon: Icon(Icons.water_drop),
                label: 'Home',
              ),
              NavigationDestination(
                key: const Key('nav-challenges'),
                icon: Icon(Icons.emoji_events_outlined,
                    key: _challengesTargetKey),
                selectedIcon: const Icon(Icons.emoji_events),
                label: 'Challenges',
              ),
              NavigationDestination(
                key: const Key('nav-progress'),
                icon: Icon(Icons.insights_outlined, key: _progressTargetKey),
                selectedIcon: const Icon(Icons.insights),
                label: 'Progress',
              ),
              const NavigationDestination(
                key: Key('nav-profile'),
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
