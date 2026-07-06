import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/challenge_catalog.dart';
import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../theme/hydrion_design.dart';

class SocialChallengesScreen extends StatefulWidget {
  final bool embedded;

  const SocialChallengesScreen({super.key, this.embedded = false});

  @override
  State<SocialChallengesScreen> createState() => _SocialChallengesScreenState();
}

class _SocialChallengesScreenState extends State<SocialChallengesScreen> {
  final Set<int> _bingoPreviewedTiles = <int>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final challengeRepository = context.watch<ChallengeRepository>();
    final hydrationRepository = context.watch<HydrationRepository>();
    final settings = context.watch<UserSettingsRepository>().settings;
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final activeChallenge = challengeRepository.activeChallenge;
    final progress = challengeRepository.progressFor(
      hydrationRepository,
      targetMlOverride: settings.dailyGoalMl,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(l10n.challengesTitle),
              centerTitle: true,
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          _ChallengeHero(
            localModeLabel: capabilities.socialSync
                ? l10n.socialChallengeCapabilityReported
                : l10n.localChallengeMode,
            localModeBody: capabilities.socialSync
                ? l10n.socialCapabilityNoAdapter
                : l10n.socialSyncNotConnected,
            activeChallenge: activeChallenge,
            progress: progress,
          ),
          const SizedBox(height: 16),
          _BottleBingoBoard(
            activeChallenge: activeChallenge,
            progress: progress,
            previewedTiles: _bingoPreviewedTiles,
            onTileToggled: (index) {
              setState(() {
                if (!_bingoPreviewedTiles.add(index)) {
                  _bingoPreviewedTiles.remove(index);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          const HydrionSurface(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.health_and_safety_outlined),
                SizedBox(width: 12),
                Expanded(
                  child: Text(HydrionChallengeCatalog.safetyNote),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (activeChallenge == null) ...[
            _NoChallengeCard(
              title: l10n.noActiveChallengeYet,
              body: l10n.joinLocalChallengeDescription,
            ),
            const SizedBox(height: 12),
          ],
          for (final challenge in HydrionChallengeCatalog.challenges) ...[
            _ChallengeCard(
              challenge: challenge,
              challengeRepository: challengeRepository,
              hydrationRepository: hydrationRepository,
              targetMl: settings.dailyGoalMl,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ChallengeHero extends StatelessWidget {
  final String localModeLabel;
  final String localModeBody;
  final JoinedChallenge? activeChallenge;
  final ChallengeProgress progress;

  const _ChallengeHero({
    required this.localModeLabel,
    required this.localModeBody,
    required this.activeChallenge,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = activeChallenge != null;
    return HydrionSurface(
      gradient: HydrionGradients.ocean,
      radius: HydrionRadii.lg,
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(HydrionRadii.pill),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.emoji_events, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasActive ? activeChallenge!.name : 'Challenge dock',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(hasActive
                ? activeChallenge!.description
                : 'Pick a local challenge that adds texture to the routine without turning hydration into pressure.'),
            const SizedBox(height: 14),
            if (hasActive) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(HydrionRadii.pill),
                child: LinearProgressIndicator(
                  value: progress.percent,
                  minHeight: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    HydrionColors.sunrise,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.completedDays}/${progress.durationDays} days complete. Today: ${progress.todayMl}/${progress.targetMl} ml.',
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChallengePill(localModeLabel),
                  const _ChallengePill('No account required'),
                  const _ChallengePill('Local progress'),
                ],
              ),
              const SizedBox(height: 8),
              Text(localModeBody),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottleBingoBoard extends StatelessWidget {
  static const _tiles = [
    _BingoTileData(
      title: 'Before lunch',
      body: 'Log water before noon.',
      icon: Icons.wb_twilight_outlined,
      progressBacked: true,
    ),
    _BingoTileData(
      title: 'Refill ritual',
      body: 'Refill your usual bottle once.',
      icon: Icons.local_drink_outlined,
    ),
    _BingoTileData(
      title: 'Flavor swap',
      body: 'Try citrus, mint, cucumber, or plain.',
      icon: Icons.spa_outlined,
    ),
    _BingoTileData(
      title: 'Desk reset',
      body: 'Place water where your hand lands.',
      icon: Icons.table_restaurant_outlined,
    ),
    _BingoTileData(
      title: 'Tiny sip',
      body: 'Take a small comfortable sip.',
      icon: Icons.water_drop_outlined,
    ),
    _BingoTileData(
      title: 'Evening ease',
      body: 'Slow down before bed; no forcing.',
      icon: Icons.nightlight_round,
    ),
  ];

  final JoinedChallenge? activeChallenge;
  final ChallengeProgress progress;
  final Set<int> previewedTiles;
  final ValueChanged<int> onTileToggled;

  const _BottleBingoBoard({
    required this.activeChallenge,
    required this.progress,
    required this.previewedTiles,
    required this.onTileToggled,
  });

  @override
  Widget build(BuildContext context) {
    final bottleBingoJoined = activeChallenge?.id == 'bottle-bingo';
    return HydrionSurface(
      key: const Key('bottle-bingo-board'),
      gradient: LinearGradient(
        colors: [
          HydrionColors.foam,
          HydrionColors.glow.withValues(alpha: 0.16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bottle Bingo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              _StatusChip(
                label: bottleBingoJoined ? 'Active' : 'Preview',
                active: bottleBingoJoined,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bottleBingoJoined
                ? 'Tiles react to your local progress. Tap the other prompts to sketch today\'s plan.'
                : 'Preview the prompts before joining. The first tile completes from real water logged before lunch.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 540 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: columns == 3 ? 1.35 : 1.05,
                ),
                itemBuilder: (context, index) {
                  final tile = _tiles[index];
                  final completed = tile.progressBacked &&
                      bottleBingoJoined &&
                      progress.todayMl > 0;
                  final previewed = previewedTiles.contains(index);
                  return _BottleBingoTile(
                    key: Key('bottle-bingo-tile-$index'),
                    tile: tile,
                    selected: completed || previewed,
                    lockedToProgress: tile.progressBacked,
                    onTap:
                        tile.progressBacked ? null : () => onTileToggled(index),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BottleBingoTile extends StatelessWidget {
  final _BingoTileData tile;
  final bool selected;
  final bool lockedToProgress;
  final VoidCallback? onTap;

  const _BottleBingoTile({
    super.key,
    required this.tile,
    required this.selected,
    required this.lockedToProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        selected ? HydrionColors.deep : Colors.white.withValues(alpha: 0.86);
    final foreground = selected ? Colors.white : HydrionColors.abyss;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(HydrionRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HydrionRadii.sm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: DefaultTextStyle(
            style: TextStyle(color: foreground),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(tile.icon, color: foreground),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : lockedToProgress
                              ? Icons.lock_clock
                              : Icons.add_circle_outline,
                      color: foreground.withValues(alpha: 0.9),
                      size: 20,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  tile.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  tile.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: foreground.withValues(alpha: 0.86)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final HydrationChallenge challenge;
  final ChallengeRepository challengeRepository;
  final HydrationRepository hydrationRepository;
  final int targetMl;

  const _ChallengeCard({
    required this.challenge,
    required this.challengeRepository,
    required this.hydrationRepository,
    required this.targetMl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final joined = challengeRepository.isJoined(challenge.id);
    final hasOtherActive =
        challengeRepository.activeChallenge != null && !joined;
    final progress = challengeRepository.progressFor(
      hydrationRepository,
      targetMlOverride: targetMl,
    );

    return HydrionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: HydrionColors.glow.withValues(alpha: 0.16),
                foregroundColor: HydrionColors.deep,
                child: Icon(_challengeIcon(challenge)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.category,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.challengeDetails(
              description: challenge.description,
              targetMl: targetMl,
              durationDays: challenge.durationDays,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.dailyTask,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (joined) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(HydrionRadii.pill),
              child: LinearProgressIndicator(value: progress.percent),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.challengeProgress(
                completedDays: progress.completedDays,
                durationDays: progress.durationDays,
                todayMl: progress.todayMl,
                targetMl: progress.targetMl,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusChip(
                label: l10n.challengeTargetPerDay(targetMl: targetMl),
                active: false,
              ),
              _StatusChip(
                label: l10n.challengeDurationDays(
                  durationDays: challenge.durationDays,
                ),
                active: false,
              ),
              if (joined)
                _StatusChip(
                  label: l10n.joined,
                  active: true,
                ),
              if (joined)
                OutlinedButton.icon(
                  key: Key('leave-${challenge.id}'),
                  onPressed: () async {
                    await challengeRepository.leave();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Leave'),
                )
              else
                FilledButton.icon(
                  key: Key('join-${challenge.id}'),
                  onPressed: hasOtherActive
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await challengeRepository.join(
                            id: challenge.id,
                            name: challenge.name,
                            description: challenge.description,
                            targetMl: targetMl,
                            durationDays: challenge.durationDays,
                          );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.challengeJoinedLocally(
                                  message: l10n.challengeJoined,
                                ),
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(hasOtherActive ? 'One active' : l10n.join),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoChallengeCard extends StatelessWidget {
  final String title;
  final String body;

  const _NoChallengeCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return HydrionSurface(
      child: Row(
        children: [
          const Icon(Icons.flag_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengePill extends StatelessWidget {
  final String label;

  const _ChallengePill(this.label);

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

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: Icon(active ? Icons.check : Icons.water_drop, size: 18),
      backgroundColor:
          active ? HydrionColors.kelp.withValues(alpha: 0.16) : null,
    );
  }
}

class _BingoTileData {
  final String title;
  final String body;
  final IconData icon;
  final bool progressBacked;

  const _BingoTileData({
    required this.title,
    required this.body,
    required this.icon,
    this.progressBacked = false,
  });
}

IconData _challengeIcon(HydrationChallenge challenge) {
  return switch (challenge.id) {
    'around-the-world-infusion-week' => Icons.public,
    'temperature-roulette' => Icons.device_thermostat,
    'eat-your-water-day' => Icons.restaurant,
    'front-loader-challenge' => Icons.wb_twilight_outlined,
    'pomodoro-sip' => Icons.timer_outlined,
    'plant-twin-challenge' => Icons.local_florist_outlined,
    'bottle-bingo' => Icons.grid_view_rounded,
    _ => Icons.emoji_events_outlined,
  };
}
