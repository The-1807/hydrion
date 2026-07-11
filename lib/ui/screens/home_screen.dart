import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/avatar_manifest.dart';
import '../../domain/companion_state.dart';
import '../../domain/challenge_catalog.dart';
import '../../domain/hydration_contracts.dart';
import '../../domain/ui_asset_manifest.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/reminder_repository.dart';
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
  Future<void> _logWater(int volumeMl) async {
    final repository = context.read<HydrationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await repository.addLog(
      volumeMl: volumeMl,
      timestamp: DateTime.now(),
      source: 'local',
    );
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.loggedVolume(volumeMl: volumeMl))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final settings = context.watch<UserSettingsRepository>().settings;
    final hydrationRepository = context.watch<HydrationRepository>();
    final challengeRepository = context.watch<ChallengeRepository>();
    final reminderRepository = context.watch<ReminderRepository>();
    final now = DateTime.now();
    final todayMl = hydrationRepository.totalForDay(now);
    final targetMl = settings.dailyGoalMl;
    final percent = targetMl <= 0 ? 0.0 : (todayMl / targetMl * 100);
    final remainingMl = math.max(0, targetMl - todayMl);
    final todayLogs = hydrationRepository.fetch(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day + 1),
    );
    final companion = const HydrionCompanionDirector().select(
      hydrationPercent: percent,
      entryCount: todayLogs.length,
      settings: settings,
      now: now,
      hasActiveChallenge: challengeRepository.activeChallenge != null,
      reminderDue: reminderRepository.reminders.isNotEmpty,
    );
    final localizedAdvice = _homeAdvice(
      l10n,
      hydrationPercent: percent,
      entryCount: todayLogs.length,
    );
    final profileAvatar = HydrionAvatarManifest.byId(settings.avatarId);
    final companionAvatar =
        HydrionAvatarManifest.companionByProfileAvatarId(settings.avatarId);
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
            avatar: companionAvatar,
            companion: companion,
            localizedAdvice: localizedAdvice,
            consumedMl: todayMl,
            targetMl: targetMl,
            remainingMl: remainingMl,
            progress: progress,
            settings: settings,
          ),
          const SizedBox(height: 16),
          _QuickLogPanel(
            title: l10n.logHydration,
            logLabel: l10n.logVolume(volumeMl: _selectedVolumeMl),
            selectedVolumeMl: _selectedVolumeMl,
            onVolumeChanged: (value) =>
                setState(() => _selectedVolumeMl = value),
            onLog: () => _logWater(_selectedVolumeMl),
            onHistory: () => Navigator.of(context).pushNamed('/log'),
          ),
          const SizedBox(height: 16),
          _HydrionLifestyleRail(
            sex: settings.sex,
            consumedMl: todayMl,
            targetMl: targetMl,
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

class _HydrionLifestyleRail extends StatelessWidget {
  final HydrionSex? sex;
  final int consumedMl;
  final int targetMl;

  const _HydrionLifestyleRail({
    required this.sex,
    required this.consumedMl,
    required this.targetMl,
  });

  @override
  Widget build(BuildContext context) {
    final scenes = HydrionLifestyleArtResolver.homeRailScenes(sex);
    final progress =
        targetMl <= 0 ? 0.0 : (consumedMl / targetMl).clamp(0, 1).toDouble();

    return HydrionSurface(
      key: const Key('home-lifestyle-rail'),
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.98),
          HydrionColors.foam,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Today\'s hydration rhythm',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Updates as you log water.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 178,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: scenes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final scene = scenes[index];
                return _LifestyleSceneCard(
                  scene: scene,
                  status: _rhythmStatusFor(index, scenes.length, progress),
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

_RhythmStatus _rhythmStatusFor(int index, int count, double progress) {
  if (count <= 0) {
    return _RhythmStatus.upNext;
  }
  final segmentStart = index / count;
  final segmentEnd = (index + 1) / count;
  if (progress >= segmentEnd) {
    return _RhythmStatus.completed;
  }
  if (progress >= segmentStart) {
    return _RhythmStatus.current;
  }
  return _RhythmStatus.upNext;
}

enum _RhythmStatus {
  completed('Completed'),
  current('Current'),
  upNext('Up next');

  final String label;

  const _RhythmStatus(this.label);
}

class _LifestyleSceneCard extends StatelessWidget {
  final HydrionUiScene scene;
  final _RhythmStatus status;
  final int index;

  const _LifestyleSceneCard({
    required this.scene,
    required this.status,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('hydration-rhythm-card-$index'),
      width: 132,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: HydrionColors.foam.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(HydrionRadii.sm),
          border: Border.all(
            color: HydrionColors.current.withValues(alpha: 0.08),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HydrionRadii.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    scene.assetPath,
                    fit: BoxFit.contain,
                    semanticLabel: scene.description,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: HydrionColors.abyss.withValues(
                              alpha: 0.72,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHydrationScene extends StatelessWidget {
  final HydrionAvatar avatar;
  final HydrionCompanionState companion;
  final String localizedAdvice;
  final int consumedMl;
  final int targetMl;
  final int remainingMl;
  final double progress;
  final UserSettings settings;

  const _HeroHydrationScene({
    required this.avatar,
    required this.companion,
    required this.localizedAdvice,
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
                        companion.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(companion.message),
                      const SizedBox(height: 6),
                      Text(
                        localizedAdvice,
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
                Transform.rotate(
                  angle: _companionTilt(companion.mood),
                  child: ClipOval(
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
  final ValueChanged<int> onVolumeChanged;
  final VoidCallback onLog;
  final VoidCallback onHistory;

  const _QuickLogPanel({
    required this.title,
    required this.logLabel,
    required this.selectedVolumeMl,
    required this.onVolumeChanged,
    required this.onLog,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    const favorites = [150, 250, 350, 500, 750, 1000];
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
                      label: Text('$amount ml'),
                      onSelected: (_) => onVolumeChanged(amount),
                    ),
                  ),
              ],
            ),
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
                    child: Text('$amount ml'),
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
            label: 'Coach', icon: Icons.chat_bubble_outline, route: '/chat'),
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

String _homeAdvice(
  AppLocalizations l10n, {
  required double hydrationPercent,
  required int entryCount,
}) {
  final hydration = hydrationPercent.clamp(0.0, 100.0);
  final advice = switch (hydration) {
    >= 100.0 => l10n.homeAdviceGoalReached,
    >= 85.0 => l10n.homeAdviceStrong,
    >= 65.0 => l10n.homeAdviceClose,
    _ => l10n.homeAdviceStart,
  };
  final entryNote = entryCount >= 3
      ? ' ${l10n.homeAdviceReliableEntries(count: entryCount)}'
      : ' ${l10n.homeAdviceAddEntries}';
  return '$advice$entryNote';
}

double _companionTilt(HydrionCompanionMood mood) {
  return switch (mood) {
    HydrionCompanionMood.goalComplete => -0.08,
    HydrionCompanionMood.nearlyComplete => 0.06,
    HydrionCompanionMood.hotWeather => -0.04,
    HydrionCompanionMood.recovery => 0.02,
    _ => 0,
  };
}
