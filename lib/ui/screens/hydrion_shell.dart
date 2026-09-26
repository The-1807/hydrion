import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/settings_repository.dart';
import '../../repositories/app_locale_repository.dart';
import '../../domain/daily_hydration_context.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/weather_localizations.dart';
import '../../repositories/guided_tour_repository.dart';
import '../../repositories/challenge_repository.dart';
import '../../services/notifications.dart';
import '../../services/pomodoro_session_service.dart';
import '../../services/weather_goal_service.dart';
import '../../services/daily_hydration_recommendation_coordinator.dart';
import '../../services/current_weather_context.dart';
import '../../utils/permissions.dart';
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
      unawaited(context.read<AppLocaleRepository>().refreshFromAndroid());
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
    await context.read<AppLocaleRepository>().refreshFromAndroid();
    if (!mounted) return;
    setState(() {});
    _scheduleDayRollover();
    final notificationService = context.read<NotificationService>();
    final pomodoroSessionService = context.read<PomodoroSessionService>();
    final permissions = context.read<Permissions>();
    final weatherService = context.read<WeatherForecastService>();
    final currentWeatherContext = context.read<CurrentWeatherContext>();
    final challengeRepository = context.read<ChallengeRepository>();
    final settingsRepository = context.read<UserSettingsRepository>();
    await permissions.refresh();
    if (!permissions.snapshot.location.isGranted) {
      await weatherService.clearCache();
      currentWeatherContext.clear();
    }
    await challengeRepository.reconcileLocalDay();
    await pomodoroSessionService.reconcile();
    await notificationService.reconcileSchedules();
    if (!mounted) {
      return;
    }
    final refreshedSettings = settingsRepository.settings;
    if (refreshedSettings.weatherModifierEnabled) {
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
    final weatherContext = context.read<CurrentWeatherContext>();
    if (!settings.weatherModifierEnabled) {
      weatherContext.clear();
      return;
    }

    final coordinator = context.read<DailyWeatherGoalCoordinator>();
    final result = await coordinator.evaluate(
      requestLocationPermission: false,
    );
    if (!mounted) return;
    if (result.status != DailyWeatherGoalStatus.promptReady ||
        result.decision == null ||
        result.forecast == null) {
      final permissions = context.read<Permissions>();
      final cached = permissions.snapshot.location.isGranted
          ? await context.read<WeatherForecastService>().currentCachedForecast()
          : null;
      if (!mounted) return;
      if (cached != null) {
        weatherContext.publish(
          snapshot: cached,
          localDateKey: hydrionLocalDateKey(DateTime.now()),
          fromCache: true,
        );
        setState(() {});
        return;
      }
      weatherContext.clear();
      return;
    }

    final forecast = result.forecast!;
    weatherContext.publish(
      snapshot: forecast,
      localDateKey: hydrionLocalDateKey(DateTime.now()),
      fromCache: false,
    );
    final personalizedCoordinator =
        context.read<DailyHydrationRecommendationCoordinator>();
    final personalized = await personalizedCoordinator.calculate(
      now: DateTime.now(),
      weather: forecast,
      locationPermissionGranted: true,
    );
    if (!mounted) return;

    // Auto-apply is only allowed when BOTH the user's own preference and
    // Hydrion's domain safety policy (mayAutoApply) allow it. Domain
    // safety wins: a clinician-governed, fluid-restricted, or
    // temporary-condition target is never silently applied, regardless of
    // the user's "don't ask each day" setting. The value committed here
    // always comes from the full PersonalizedHydrationEngine recommendation
    // computed above, never from an independent weather-only calculator.
    if (settings.weatherGoalAutoApplyEnabled &&
        !settings.weatherGoalDailyConfirmationEnabled &&
        personalized.mayAutoApply) {
      await context.read<UserSettingsRepository>().applyWeatherGoal(
            goalMl: personalized.roundedRecommendedGoalMl,
            decidedAt: DateTime.now(),
            explanation:
                WeatherGoalExplanationCode.personalizedSuggestionAccepted.name,
            localDateKey: hydrionLocalDateKey(DateTime.now()),
            autoApplyEnabled: true,
          );
      return;
    }

    final unit = settings.volumeUnit;
    final l10n = AppLocalizations.of(context);
    final weatherAdjustment = HydrationVolumeFormatter.format(
      personalized.weatherAdjustmentMl.abs(),
      unit,
    );
    final suggestionChangesGoal =
        personalized.roundedRecommendedGoalMl != settings.dailyGoalMl;
    final useSuggestion = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.weatherSuggestionTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.weatherConditionTemperature(
                condition: l10n.weatherCondition(forecast.condition),
                temperature: forecast.temperatureC.toStringAsFixed(1),
              )),
              if (forecast.humidityPercent != null)
                Text(
                  '${l10n.humidityLabel}: ${forecast.humidityPercent!.round()}%',
                ),
              const SizedBox(height: 12),
              Text(
                '${l10n.standardGoalLabel}: '
                '${HydrationVolumeFormatter.format(personalized.baselineGoalMl, unit)}',
              ),
              Text(
                '${l10n.weatherAdjustmentLabel}: '
                '${personalized.weatherAdjustmentMl >= 0 ? '+' : ''}'
                '$weatherAdjustment',
              ),
              Text(
                '${l10n.todaySuggestedGoalLabel}: '
                '${HydrationVolumeFormatter.format(personalized.roundedRecommendedGoalMl, unit)}',
              ),
              const SizedBox(height: 8),
              if (personalized.activityAdjustmentMl != 0)
                Text(
                  '${l10n.activityAdjustmentLabel}: '
                  '${HydrationVolumeFormatter.format(personalized.activityAdjustmentMl, unit)}',
                ),
              if (personalized.reproductiveAdjustmentMl != 0)
                Text(
                  '${l10n.reproductiveAdjustmentLabel}: '
                  '${HydrationVolumeFormatter.format(personalized.reproductiveAdjustmentMl, unit)}',
                ),
              Text(
                '${l10n.updatedLabel}: ${TimeOfDay.fromDateTime(forecast.retrievedAt).format(dialogContext)}',
              ),
              const SizedBox(height: 8),
              Text(l10n.weatherSuggestionDisclosure),
            ],
          ),
        ),
        actions: [
          if (suggestionChangesGoal) ...[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.keepStandardGoal),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.useSuggestion),
            ),
          ] else
            FilledButton(
              key: const Key('weather-no-change-done'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.done),
            ),
        ],
      ),
    );
    if (!mounted || useSuggestion == null) return;
    if (useSuggestion) {
      await context.read<UserSettingsRepository>().applyWeatherGoal(
            goalMl: personalized.roundedRecommendedGoalMl,
            decidedAt: DateTime.now(),
            explanation:
                WeatherGoalExplanationCode.personalizedSuggestionAccepted.name,
            localDateKey: hydrionLocalDateKey(DateTime.now()),
          );
    } else {
      await coordinator.keepPreviousGoal(
        explanationCode: WeatherGoalExplanationCode.standardGoalKept,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                NavigationDestination(
                  key: const Key('nav-home'),
                  icon: const Icon(Icons.water_drop_outlined),
                  selectedIcon: const Icon(Icons.water_drop),
                  label: l10n.homeTitle,
                ),
                NavigationDestination(
                  key: _challengesTargetKey,
                  icon: const Icon(Icons.emoji_events_outlined),
                  selectedIcon: const Icon(Icons.emoji_events),
                  label: l10n.challengesTitle,
                ),
                NavigationDestination(
                  key: _progressTargetKey,
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: const Icon(Icons.insights),
                  label: l10n.progress,
                ),
                NavigationDestination(
                  key: const Key('nav-profile'),
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: l10n.profileTitle,
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
          title: l10n.todaysHydration,
          body: l10n.tourHydrationBody,
        ),
        GuidedTourStep(
          targetKey: _logTargetKey,
          destinationIndex: 0,
          title: l10n.tourLogWater,
          body: l10n.tourLogWaterBody,
        ),
        GuidedTourStep(
          targetKey: _historyTargetKey,
          destinationIndex: 0,
          title: l10n.tourReviewCorrect,
          body: l10n.tourReviewCorrectBody,
        ),
        GuidedTourStep(
          targetKey: _challengesTargetKey,
          destinationIndex: 1,
          title: l10n.challengesTitle,
          body: l10n.tourChallengesBody,
        ),
        GuidedTourStep(
          targetKey: _progressTargetKey,
          destinationIndex: 2,
          demonstratesPullToRefresh: true,
          title: l10n.tourProgressRefresh,
          body: l10n.tourProgressRefreshBody,
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
                          l10n.seeWhatsNew,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.seeWhatsNewBody),
                        const SizedBox(height: 8),
                        OverflowBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              key: const Key('whats-new-not-now'),
                              onPressed: tourRepository.dismissWhatsNew,
                              child: Text(l10n.notNow),
                            ),
                            FilledButton(
                              key: const Key('whats-new-show-me'),
                              onPressed: () async {
                                await tourRepository.showWhatsNewTour();
                                if (mounted && _selectedIndex != 0) {
                                  setState(() => _selectedIndex = 0);
                                }
                              },
                              child: Text(l10n.showMe),
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
