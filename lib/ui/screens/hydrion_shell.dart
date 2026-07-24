import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/settings_repository.dart';
import '../../repositories/guided_tour_repository.dart';
import '../../repositories/challenge_repository.dart';
import '../../services/notifications.dart';
import '../../services/weather_goal_service.dart';
import '../components/guided_tour_overlay.dart';
import '../components/hydrion_viewport.dart';
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
  static final _bottomNavigationKey = GlobalKey();

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

  Future<void> _refreshLocalLifecycleState() async {
    if (!mounted) {
      return;
    }
    setState(() {});
    _scheduleDayRollover();
    final notificationService = context.read<NotificationService>();
    final settings = context.read<UserSettingsRepository>().settings;
    await context.read<ChallengeRepository>().reconcileLocalDay();
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
      context.read<ChallengeRepository>().reconcileLocalDay();
      _evaluateWeatherAssistance();
    });
  }

  Future<void> _evaluateWeatherAssistance() async {
    if (!mounted) return;
    final settings = context.read<UserSettingsRepository>().settings;
    if (settings.goalMode != HydrionGoalMode.weatherInformed) return;

    final coordinator = context.read<DailyWeatherGoalCoordinator>();
    final result = await coordinator.evaluate(
      requestLocationPermission: true,
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tourRepository = context.watch<GuidedTourRepository>();
    final navigationColor =
        Theme.of(context).navigationBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface;
    final scaffold = Scaffold(
      extendBody: false,
      body: DecoratedBox(
        key: const Key('hydrion-edge-background'),
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
          child: MediaQuery.removeViewPadding(
            context: context,
            removeBottom: true,
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
                const SocialChallengesScreen(
                  embedded: true,
                ),
                const AnalyticsScreen(
                  embedded: true,
                ),
                const ProfileScreen(embedded: true),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: KeyedSubtree(
        key: _bottomNavigationKey,
        child: ColoredBox(
          key: const Key('hydrion-bottom-nav-background'),
          color: navigationColor,
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: NavigationBar(
              key: const Key('hydrion-bottom-nav'),
              height: HydrionViewport.navigationBarHeight(context),
              backgroundColor: navigationColor,
              labelBehavior: MediaQuery.sizeOf(context).width < 320
                  ? NavigationDestinationLabelBehavior.alwaysHide
                  : NavigationDestinationLabelBehavior.alwaysShow,
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
                  key: _challengesTargetKey,
                  icon: const Icon(Icons.emoji_events_outlined),
                  selectedIcon: const Icon(Icons.emoji_events),
                  label: 'Challenges',
                ),
                NavigationDestination(
                  key: _progressTargetKey,
                  icon: const Icon(Icons.insights_outlined),
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
      ),
    );
    return GuidedTourOverlay(
      obstructionKey: _bottomNavigationKey,
      onDestinationRequested: (index) {
        if (mounted && _selectedIndex != index) {
          setState(() => _selectedIndex = index);
        }
      },
      onFinished: () {
        if (mounted && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      steps: [
        GuidedTourStep(
          targetKey: _homeTargetKey,
          destinationIndex: 0,
          title: "Today's hydration",
          body: 'Your daily hydration and remaining amount appear here.',
        ),
        GuidedTourStep(
          targetKey: _logTargetKey,
          destinationIndex: 0,
          title: 'Log water',
          body:
              'Log the amount you actually drink. Use a saved container or choose another amount.',
        ),
        GuidedTourStep(
          targetKey: _historyTargetKey,
          destinationIndex: 0,
          title: 'Review and correct',
          body:
              'Review, edit, or remove a hydration entry if you make a mistake.',
        ),
        GuidedTourStep(
          targetKey: _challengesTargetKey,
          destinationIndex: 1,
          title: 'Challenges',
          body:
              'Challenges add optional habits and tasks. Challenge water still counts normally.',
        ),
        GuidedTourStep(
          targetKey: _progressTargetKey,
          destinationIndex: 2,
          demonstratesPullToRefresh: true,
          title: 'Progress and refresh',
          body:
              'Review your latest totals here. Pull down to refresh hydration and challenge progress.',
        ),
      ],
      child: Stack(
        children: [
          scaffold,
          if (tourRepository.shouldOfferWhatsNew)
            Positioned(
              key: const Key('whats-new-tour-prompt'),
              top: 12,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'See what\u2019s new',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Take a short tour of hydration, challenges, and progress.',
                        ),
                        const SizedBox(height: 8),
                        OverflowBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              key: const Key('whats-new-not-now'),
                              onPressed: tourRepository.dismissWhatsNew,
                              child: const Text('Not now'),
                            ),
                            FilledButton(
                              key: const Key('whats-new-show-me'),
                              onPressed: () async {
                                await tourRepository.showWhatsNewTour();
                                if (mounted && _selectedIndex != 0) {
                                  setState(() => _selectedIndex = 0);
                                }
                              },
                              child: const Text('Show me'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
