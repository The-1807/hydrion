import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/weather_goal_service.dart';
import '../components/hydrion_logo.dart';
import '../components/intake_ring.dart';
import '../components/llm_advice_card.dart';
import '../components/reminder_tile.dart';
import '../components/voice_input_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedVolumeMl = 250;
  bool _weatherGoalChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_weatherGoalChecked) {
      return;
    }
    _weatherGoalChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _maybeShowWeatherGoalPrompt();
      }
    });
  }

  Future<void> _logWater(int volumeMl) async {
    final repository = context.read<HydrationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    await repository.addLog(
      volumeMl: volumeMl,
      timestamp: now,
      source: 'local',
    );
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.loggedVolume(volumeMl: volumeMl))),
    );
  }

  Future<void> _maybeShowWeatherGoalPrompt() async {
    final coordinator = context.read<DailyWeatherGoalCoordinator>();
    final result = await coordinator.evaluate();
    if (!mounted) {
      return;
    }
    if (result.status == DailyWeatherGoalStatus.autoApplied &&
        result.decision != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weather-adjusted goal applied: '
            '${result.decision!.recommendedGoalMl} ml.',
          ),
        ),
      );
      return;
    }
    if (result.status != DailyWeatherGoalStatus.promptReady ||
        result.decision == null ||
        result.forecast == null) {
      return;
    }

    var doNotAskEachDay = false;
    final decision = result.decision!;
    final forecast = result.forecast!;
    final action = await showDialog<_WeatherGoalAction>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Today\'s weather goal'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Recommended goal: '
                        '${decision.recommendedGoalMl} ml'),
                    const SizedBox(height: 8),
                    Text('Baseline: ${decision.baselineGoalMl} ml'),
                    Text('Weather adjustment: '
                        '${decision.weatherAdjustmentMl >= 0 ? '+' : ''}'
                        '${decision.weatherAdjustmentMl} ml'),
                    Text('Weather: ${forecast.condition}, '
                        '${forecast.temperatureC.round()} C'
                        '${forecast.humidityPercent == null ? '' : ', ${forecast.humidityPercent!.round()}% humidity'}'),
                    const SizedBox(height: 8),
                    Text(decision.explanation),
                    const SizedBox(height: 8),
                    const Text(
                      'Hydrion is not medical advice. Drink comfortably, stop if you feel unwell, and adjust the goal any time.',
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: doNotAskEachDay,
                      onChanged: (value) {
                        setDialogState(
                          () => doNotAskEachDay = value == true,
                        );
                      },
                      title: const Text('Do not ask me each day'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(_WeatherGoalAction.keep),
                  child: const Text('Keep previous goal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext)
                      .pop(_WeatherGoalAction.adjust),
                  child: const Text('Adjust'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext)
                      .pop(_WeatherGoalAction.useRecommendation),
                  child: const Text('Use recommendation'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case _WeatherGoalAction.useRecommendation:
        await coordinator.acceptRecommendation(
          decision: decision,
          doNotAskEachDay: doNotAskEachDay,
        );
        break;
      case _WeatherGoalAction.adjust:
        await Navigator.of(context).pushNamed('/settings');
        break;
      case _WeatherGoalAction.keep:
        await coordinator.keepPreviousGoal(
          explanation: 'User kept the previous goal for today.',
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final settings = context.watch<UserSettingsRepository>().settings;
    context.watch<HydrationRepository>();
    final syncStatus = [
      if (!capabilities.bleSync) 'BLE',
      if (!capabilities.healthSync) 'Health',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HydrionLogo(
              size: 32,
              imageKey: const Key('home-logo'),
              semanticLabel: l10n.hydrionLogoSemantics,
            ),
            const SizedBox(width: 8),
            Text(l10n.appTitle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: l10n.settingsTooltip,
          ),
        ],
      ),
      body: FutureBuilder<HydrationSummary>(
        future: context.read<HydrationSummaryService>().getHydrationSummary(),
        builder: (context, snapshot) {
          final summary = snapshot.data ??
              const HydrationSummary(
                hydrationPercent: 0,
                entryCount: 0,
                consumedMl: 0,
                targetMl: 2200,
              );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: IntakeRing(
                  consumedMl: summary.consumedMl.toDouble(),
                  targetMl: summary.targetMl.toDouble(),
                ),
              ),
              const SizedBox(height: 16),
              LLMAdviceCard(
                hydrationPercent: summary.hydrationPercent,
                entryCount: summary.entryCount,
                temperatureC: 24,
              ),
              if (settings.weatherAdjustedGoalActive &&
                  settings.lastWeatherGoalExplanation != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: const Text('Weather-adjusted'),
                    subtitle: Text(settings.lastWeatherGoalExplanation!),
                    trailing: Text('${settings.dailyGoalMl} ml'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.logHydration,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stackControls = constraints.maxWidth < 380;
                          final picker = DropdownButtonFormField<int>(
                            key: const Key('volume-picker'),
                            initialValue: _selectedVolumeMl,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.amountLabel,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [150, 250, 350, 500, 750, 1000]
                                .map(
                                  (amount) => DropdownMenuItem<int>(
                                    value: amount,
                                    child: Text('$amount ml'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedVolumeMl = value);
                              }
                            },
                          );
                          final button = FilledButton.icon(
                            key: const Key('log-water-button'),
                            onPressed: () => _logWater(_selectedVolumeMl),
                            icon: const Icon(Icons.local_drink),
                            label: Text(
                              l10n.logVolume(volumeMl: _selectedVolumeMl),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );

                          if (stackControls) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                picker,
                                const SizedBox(height: 8),
                                button,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: picker),
                              const SizedBox(width: 8),
                              button,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        syncStatus.isEmpty
                            ? l10n.savedLocally
                            : l10n.savedLocallySyncDisabled(
                                syncNames: syncStatus.join(' and '),
                                verb: syncStatus.length == 1 ? 'is' : 'are',
                              ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (capabilities.osNotifications) ...[
                const SizedBox(height: 12),
                Card(
                  child: ReminderTile(
                    shortfallMl: (summary.targetMl - summary.consumedMl)
                        .clamp(0, summary.targetMl),
                    lastDrinkHoursAgo: 1.5,
                    hydrationPercent: summary.hydrationPercent,
                    isActiveTime: true,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _RouteButton(
                      labelKey: _RouteLabel.analytics,
                      icon: Icons.insights,
                      route: '/analytics'),
                  const _RouteButton(
                      labelKey: _RouteLabel.log,
                      icon: Icons.list_alt,
                      route: '/log'),
                  const _RouteButton(
                      labelKey: _RouteLabel.coach,
                      icon: Icons.chat_bubble_outline,
                      route: '/chat'),
                  const _RouteButton(
                      labelKey: _RouteLabel.challenges,
                      icon: Icons.emoji_events,
                      route: '/challenges'),
                  if (capabilities.osNotifications)
                    const _RouteButton(
                        labelKey: _RouteLabel.reminders,
                        icon: Icons.notifications_none,
                        route: '/reminders'),
                  if (capabilities.arVisualization)
                    const _RouteButton(
                        labelKey: _RouteLabel.arUnavailable,
                        icon: Icons.view_in_ar,
                        route: '/ar'),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: capabilities.voiceInput
          ? VoiceInputWidget(
              onCommandParsed: (command) {
                final intent = command['intent'] ?? 'unknown_command';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.voiceIntent(intent: intent))),
                );
              },
            )
          : null,
    );
  }
}

enum _WeatherGoalAction {
  useRecommendation,
  adjust,
  keep,
}

enum _RouteLabel {
  analytics,
  log,
  coach,
  challenges,
  reminders,
  arUnavailable,
}

class _RouteButton extends StatelessWidget {
  final _RouteLabel labelKey;
  final IconData icon;
  final String route;

  const _RouteButton({
    required this.labelKey,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (labelKey) {
      _RouteLabel.analytics => l10n.analyticsRoute,
      _RouteLabel.log => l10n.logRoute,
      _RouteLabel.coach => l10n.coachRoute,
      _RouteLabel.challenges => l10n.challengesRoute,
      _RouteLabel.reminders => l10n.remindersRoute,
      _RouteLabel.arUnavailable => l10n.arUnavailableRoute,
    };

    return ActionChip(
      key: Key('route-$route'),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => Navigator.of(context).pushNamed(route),
    );
  }
}
