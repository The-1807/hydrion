import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/challenge_catalog.dart';
import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../components/intake_ring.dart';
import '../components/voice_input_widget.dart';
import '../theme/hydrion_design.dart';

class HomeScreen extends StatefulWidget {
  final bool showRouteShortcuts;

  const HomeScreen({super.key, this.showRouteShortcuts = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedVolumeMl = 250;
  bool _isLogging = false;
  Future<void> _logWater(int volumeMl) async {
    if (_isLogging) {
      return;
    }
    setState(() => _isLogging = true);
    final repository = context.read<HydrationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final volumeUnit =
        context.read<UserSettingsRepository>().settings.volumeUnit;
    var succeeded = false;
    try {
      await repository.addLog(
        volumeMl: volumeMl,
        timestamp: DateTime.now(),
        source: 'quick-add',
      );
      succeeded = true;
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Water was not logged. Please retry.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLogging = false);
      }
    }
    if (!mounted || !succeeded) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          volumeUnit == HydrionVolumeUnit.milliliters
              ? l10n.loggedVolume(volumeMl: volumeMl)
              : 'Logged ${HydrationVolumeFormatter.format(volumeMl, volumeUnit)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final settings = context.watch<UserSettingsRepository>().settings;
    final hydrationRepository = context.watch<HydrationRepository>();
    final challengeRepository = context.watch<ChallengeRepository>();
    final now = DateTime.now();
    final todayMl = hydrationRepository.totalForDay(now);
    final targetMl = settings.dailyGoalMl;
    final percent = targetMl <= 0 ? 0.0 : (todayMl / targetMl * 100);
    final remainingMl = math.max(0, targetMl - todayMl);
    final todayLogs = hydrationRepository.fetch(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day + 1),
    );
    final hydrationStatus = _hydrationStatus(
      l10n,
      hydrationPercent: percent,
      entryCount: todayLogs.length,
      now: now,
      mostRecentLog: todayLogs.isEmpty ? null : todayLogs.first,
      remainingMl: remainingMl,
      containerSizeMl: settings.usableContainerSizeMl,
      volumeUnit: settings.volumeUnit,
    );
    final profileAvatar = HydrionAvatarManifest.byId(settings.avatarId);
    final progress = (percent / 100).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        key: const Key('home-appbar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hydrion',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              _greeting(settings, now),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('home-settings-action'),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings),
          ),
          PopupMenuButton<String>(
            key: const Key('home-avatar-menu'),
            tooltip: 'Profile menu',
            icon: CircleAvatar(
              backgroundImage: AssetImage(profileAvatar.assetPath),
              radius: 18,
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.of(context).pushNamed('/profile');
                  break;
                case 'settings':
                  Navigator.of(context).pushNamed('/settings');
                  break;
                case 'support':
                  Navigator.of(context).pushNamed('/legal-about');
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('View Profile')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'support', child: Text('Support')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _HeroHydrationScene(
            avatar: profileAvatar,
            statusText: hydrationStatus,
            consumedMl: todayMl,
            targetMl: targetMl,
            remainingMl: remainingMl,
            progress: progress,
            settings: settings,
          ),
          const SizedBox(height: 16),
          _QuickLogPanel(
            title: l10n.logHydration,
            logLabel: settings.volumeUnit == HydrionVolumeUnit.milliliters
                ? l10n.logVolume(volumeMl: _selectedVolumeMl)
                : '${l10n.logHydration} ${HydrationVolumeFormatter.format(_selectedVolumeMl, settings.volumeUnit)}',
            selectedVolumeMl: _selectedVolumeMl,
            defaultContainerSizeMl: settings.usableContainerSizeMl,
            volumeUnit: settings.volumeUnit,
            onVolumeChanged: (value) =>
                setState(() => _selectedVolumeMl = value),
            onLog: () => _logWater(_selectedVolumeMl),
            onHistory: () => Navigator.of(context).pushNamed('/log'),
          ),
          const SizedBox(height: 16),
          _TodayMomentumGrid(
            entryCount: todayLogs.length,
            challengeRepository: challengeRepository,
            targetMl: targetMl,
          ),
          if (widget.showRouteShortcuts) ...[
            const SizedBox(height: 16),
            _LegacyRouteShortcuts(capabilities: capabilities),
          ],
        ],
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

class _HeroHydrationScene extends StatelessWidget {
  final HydrionAvatar avatar;
  final String statusText;
  final int consumedMl;
  final int targetMl;
  final int remainingMl;
  final double progress;
  final UserSettings settings;

  const _HeroHydrationScene({
    required this.avatar,
    required this.statusText,
    required this.consumedMl,
    required this.targetMl,
    required this.remainingMl,
    required this.progress,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final remainingLabel = HydrationVolumeFormatter.format(
      remainingMl,
      settings.volumeUnit,
    );
    return HydrionSurface(
      gradient: HydrionGradients.ocean,
      radius: HydrionRadii.lg,
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hydrationStatusTitle(consumedMl, targetMl),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroPill('$percent%'),
                          _HeroPill('$remainingLabel left'),
                          _HeroPill(
                            settings.weatherAdjustedGoalActive
                                ? 'Weather-adjusted'
                                : 'Standard goal',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipOval(
                  child: SizedBox.square(
                    dimension: 116,
                    child: Image.asset(
                      avatar.assetPath,
                      key: const Key('home-logo'),
                      fit: BoxFit.cover,
                      semanticLabel: avatar.displayName,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(320.0, constraints.maxWidth);
                  return HydrationProgressGauge(
                    consumedMl: consumedMl.toDouble(),
                    targetMl: targetMl.toDouble(),
                    volumeUnit: settings.volumeUnit,
                    width: width,
                    height: 178,
                    onDarkBackground: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogPanel extends StatelessWidget {
  final String title;
  final String logLabel;
  final int selectedVolumeMl;
  final int? defaultContainerSizeMl;
  final HydrionVolumeUnit volumeUnit;
  final ValueChanged<int> onVolumeChanged;
  final VoidCallback onLog;
  final VoidCallback onHistory;

  const _QuickLogPanel({
    required this.title,
    required this.logLabel,
    required this.selectedVolumeMl,
    required this.defaultContainerSizeMl,
    required this.volumeUnit,
    required this.onVolumeChanged,
    required this.onLog,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final favorites = <int>{
      150,
      250,
      350,
      500,
      750,
      1000,
      if (defaultContainerSizeMl case final amount?) amount,
    }.toList()
      ..sort();
    return HydrionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton.icon(
                key: const Key('home-log-history'),
                onPressed: onHistory,
                icon: const Icon(Icons.history),
                label: const Text('History'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final amount in favorites)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('quick-volume-$amount'),
                      selected: selectedVolumeMl == amount,
                      label: Text(
                        HydrationVolumeFormatter.format(amount, volumeUnit),
                      ),
                      onSelected: (_) => onVolumeChanged(amount),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            defaultContainerSizeMl == null
                ? 'No reusable container saved. Add one in Settings to use it here and in Bottle Bingo.'
                : 'Saved container: ${HydrationVolumeFormatter.format(defaultContainerSizeMl!, volumeUnit)}. Select it here to use the same amount as Bottle Bingo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const Key('volume-picker'),
            initialValue: selectedVolumeMl,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Custom amount',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: favorites
                .map(
                  (amount) => DropdownMenuItem<int>(
                    value: amount,
                    child: Text(
                      HydrationVolumeFormatter.format(amount, volumeUnit),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onVolumeChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('log-water-button'),
              onPressed: onLog,
              icon: const Icon(Icons.water_drop),
              label: Text(logLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMomentumGrid extends StatelessWidget {
  final int entryCount;
  final ChallengeRepository challengeRepository;
  final int targetMl;

  const _TodayMomentumGrid({
    required this.entryCount,
    required this.challengeRepository,
    required this.targetMl,
  });

  @override
  Widget build(BuildContext context) {
    final challenge = challengeRepository.activeChallenge;
    final catalogChallenge = challenge == null
        ? HydrionChallengeCatalog.byId('bottle-bingo')
        : HydrionChallengeCatalog.byId(challenge.id);
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 430;
        final children = [
          _MiniModule(
            icon: Icons.bolt,
            title: 'Momentum',
            value: entryCount == 0 ? 'First log waiting' : '$entryCount logs',
            body: entryCount == 0
                ? 'One small entry gives the day a shape.'
                : 'Your shark has real data to react to.',
          ),
          _MiniModule(
            icon: Icons.emoji_events_outlined,
            title: challenge == null ? 'Challenge pick' : 'Active challenge',
            value: catalogChallenge.name,
            body: challenge == null
                ? 'Bottle Bingo is ready when you want a playful routine.'
                : 'Keep today gentle; progress comes from normal logs.',
          ),
        ];
        if (!twoColumns) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children) ...[
              Expanded(child: child),
              if (child != children.last) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MiniModule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String body;

  const _MiniModule({
    required this.icon,
    required this.title,
    required this.value,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return HydrionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill(this.label);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(HydrionRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label),
      ),
    );
  }
}

class _LegacyRouteShortcuts extends StatelessWidget {
  final AppCapabilities capabilities;

  const _LegacyRouteShortcuts({required this.capabilities});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const _RouteButton(
            label: 'Progress', icon: Icons.insights, route: '/analytics'),
        const _RouteButton(
            label: 'Log history', icon: Icons.list_alt, route: '/log'),
        const _RouteButton(
            label: 'Challenges',
            icon: Icons.emoji_events,
            route: '/challenges'),
        if (capabilities.osNotifications)
          const _RouteButton(
            label: 'Reminders',
            icon: Icons.notifications_none,
            route: '/reminders',
          ),
      ],
    );
  }
}

class _RouteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _RouteButton({
    required this.label,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key: Key('route-$route'),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => Navigator.of(context).pushNamed(route),
    );
  }
}

String _greeting(UserSettings settings, DateTime now) {
  final name = settings.nickname?.trim();
  final displayName = name == null || name.isEmpty ? 'there' : name;
  final dayPart = now.hour < 12
      ? 'Good morning'
      : now.hour < 18
          ? 'Good afternoon'
          : 'Good evening';
  return '$dayPart, $displayName';
}

String _hydrationStatus(
  AppLocalizations l10n, {
  required double hydrationPercent,
  required int entryCount,
  required DateTime now,
  required HydrationLog? mostRecentLog,
  required int remainingMl,
  required int? containerSizeMl,
  required HydrionVolumeUnit volumeUnit,
}) {
  final hydration = hydrationPercent.clamp(0.0, 100.0);
  if (hydration >= 100) return l10n.homeAdviceGoalReached;

  if (mostRecentLog != null &&
      now.difference(mostRecentLog.timestamp).abs() <=
          const Duration(minutes: 30)) {
    return 'Your recent ${HydrationVolumeFormatter.format(mostRecentLog.volumeMl, volumeUnit)} log is counted. Give your routine time before deciding what comes next.';
  }
  if (hydration >= 85) return l10n.homeAdviceStrong;
  if (hydration >= 65) return l10n.homeAdviceClose;

  if (entryCount == 0) {
    return now.hour < 12
        ? l10n.homeAdviceStart
        : 'No water is logged yet today. Add what you have actually consumed when you are ready.';
  }

  final remaining = HydrationVolumeFormatter.format(remainingMl, volumeUnit);
  final container = containerSizeMl == null
      ? ''
      : '; your ${HydrationVolumeFormatter.format(containerSizeMl, volumeUnit)} container is available as a quick-log amount';
  return 'You have $entryCount ${entryCount == 1 ? 'log' : 'logs'} today. About $remaining remains$container.';
}

String _hydrationStatusTitle(int consumedMl, int targetMl) {
  if (targetMl > 0 && consumedMl >= targetMl) return 'Goal completed';
  if (consumedMl == 0) return 'No hydration logged today';
  return 'Today’s hydration';
}
