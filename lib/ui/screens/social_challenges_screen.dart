import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/challenge_catalog.dart';
import '../../domain/challenge_visual_registry.dart';
import '../../domain/hydration_contracts.dart';
import '../../domain/ui_asset_manifest.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/app_refresh_controller.dart';
import '../theme/hydrion_design.dart';
import '../components/intake_ring.dart';
import 'challenge_experience_screen.dart';

class SocialChallengesScreen extends StatefulWidget {
  final bool embedded;

  const SocialChallengesScreen({super.key, this.embedded = false});

  @override
  State<SocialChallengesScreen> createState() => _SocialChallengesScreenState();
}

class _SocialChallengesScreenState extends State<SocialChallengesScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final challengeRepository = context.watch<ChallengeRepository>();
    final hydrationRepository = context.watch<HydrationRepository>();
    final settings = context.watch<UserSettingsRepository>().settings;
    final activeChallenges = challengeRepository.activeChallenges;
    final todayTotalMl = hydrationRepository.totalForDay(DateTime.now());
    final activeIds = activeChallenges.map((challenge) => challenge.id).toSet();
    final activeCatalogChallenges = HydrionChallengeCatalog.challenges
        .where((challenge) => activeIds.contains(challenge.id))
        .toList(growable: false);
    final availableChallenges = HydrionChallengeCatalog.challenges
        .where((challenge) => !activeIds.contains(challenge.id))
        .toList(growable: false);

    final mediaPadding = MediaQuery.paddingOf(context);
    final bottomPadding = widget.embedded ? 96.0 + mediaPadding.bottom : 28.0;
    final listView = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding),
      children: [
        _ChallengeHero(
          activeChallengeCount: activeChallenges.length,
          todayTotalMl: todayTotalMl,
          volumeUnit: settings.volumeUnit,
          sex: settings.sex,
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
        if (activeChallenges.isEmpty) ...[
          _NoChallengeCard(
            title: l10n.noActiveChallengeYet,
            body: l10n.joinLocalChallengeDescription,
          ),
          const SizedBox(height: 12),
        ] else ...[
          Text(
            'Active challenges',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          for (final challenge in activeCatalogChallenges) ...[
            _ChallengeCard(
              challenge: challenge,
              challengeRepository: challengeRepository,
              hydrationRepository: hydrationRepository,
              targetMl: settings.dailyGoalMl,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Other challenges',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
        ],
        for (final challenge in availableChallenges) ...[
          _ChallengeCard(
            challenge: challenge,
            challengeRepository: challengeRepository,
            hydrationRepository: hydrationRepository,
            targetMl: settings.dailyGoalMl,
          ),
          const SizedBox(height: 12),
        ],
        if (challengeRepository.pausedChallenges.isNotEmpty) ...[
          Text(
            'Paused',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          for (final paused in challengeRepository.pausedChallenges)
            Card(
              child: ListTile(
                key: Key('paused-challenge-${paused.id}'),
                leading: const Icon(Icons.pause_circle_outline),
                title: Text(paused.name),
                subtitle:
                    const Text('Progress saved. New logs are not evaluated.'),
                trailing: TextButton(
                  onPressed: challengeRepository.hasRoomForAnotherChallenge
                      ? () =>
                          challengeRepository.resumeChallenge(paused.instanceId)
                      : null,
                  child: const Text('Resume'),
                ),
                onTap: () => _openChallenge(context, paused.id),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (challengeRepository.challengeHistory.any((challenge) =>
            challenge.lifecycleStatus != ChallengeLifecycleStatus.paused)) ...[
          Text(
            'Challenge history',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          for (final past in challengeRepository.challengeHistory.where(
            (challenge) =>
                challenge.lifecycleStatus != ChallengeLifecycleStatus.paused,
          ))
            Card(
              child: ListTile(
                key: Key('challenge-history-${past.instanceId}'),
                leading: Icon(
                  past.lifecycleStatus == ChallengeLifecycleStatus.completed ||
                          past.lifecycleStatus ==
                              ChallengeLifecycleStatus.archived
                      ? Icons.emoji_events_outlined
                      : Icons.history,
                ),
                title: Text(past.name),
                subtitle: Text(_friendlyHistoryStatus(context, past)),
                onTap: () => _openChallenge(context, past.id),
              ),
            ),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(l10n.challengesTitle),
              centerTitle: true,
            ),
      body: RefreshIndicator(
        key: const Key('challenges-refresh-indicator'),
        onRefresh: () => refreshHydrionData(context),
        child: listView,
      ),
    );
  }

  void _openChallenge(BuildContext context, String challengeId) {
    final challenge = HydrionChallengeCatalog.byId(challengeId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeExperienceScreen(challenge: challenge),
      ),
    );
  }

  String _friendlyHistoryStatus(
    BuildContext context,
    JoinedChallenge challenge,
  ) {
    final date = challenge.endedAt ?? challenge.joinedAt;
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(date);
    final status = switch (challenge.lifecycleStatus) {
      ChallengeLifecycleStatus.completed => 'Completed',
      ChallengeLifecycleStatus.left => 'Left',
      ChallengeLifecycleStatus.archived => 'Completed',
      ChallengeLifecycleStatus.paused => 'Paused',
      ChallengeLifecycleStatus.active => 'Active',
    };
    return '$status \u00b7 $dateLabel';
  }
}

class _ChallengeHero extends StatelessWidget {
  final int activeChallengeCount;
  final int todayTotalMl;
  final HydrionVolumeUnit volumeUnit;
  final HydrionSex? sex;

  const _ChallengeHero({
    required this.activeChallengeCount,
    required this.todayTotalMl,
    required this.volumeUnit,
    required this.sex,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = activeChallengeCount > 0;
    final scene = HydrionLifestyleArtResolver.sceneFor(
      surface: HydrionLifestyleSurface.challenges,
      sex: sex,
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
                    hasActive
                        ? '$activeChallengeCount active '
                            '${activeChallengeCount == 1 ? 'challenge' : 'challenges'}'
                        : 'Challenge dock',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(HydrionRadii.md),
                  child: SizedBox.square(
                    dimension: 88,
                    child: Image.asset(
                      scene.assetPath,
                      fit: BoxFit.contain,
                      semanticLabel: scene.description,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(hasActive
                ? 'Your active challenges are listed once below with their own progress and actions.'
                : 'Pick a local challenge that adds texture to the routine without turning hydration into pressure.'),
            if (hasActive) ...[
              const SizedBox(height: 8),
              Text(
                "Today's total hydration: "
                '${HydrationVolumeFormatter.format(todayTotalMl, volumeUnit)}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Kept only to decode and present pre-redesign Bingo state during migration.
// ignore: unused_element
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
      hydrationAction: _BingoHydrationAction.bottle,
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
      hydrationAction: _BingoHydrationAction.sip,
    ),
    _BingoTileData(
      title: 'Evening ease',
      body: 'Slow down before bed; no forcing.',
      icon: Icons.nightlight_round,
    ),
  ];

  final JoinedChallenge? activeChallenge;
  final ChallengeProgress progress;
  final ChallengeRepository challengeRepository;
  final HydrationRepository hydrationRepository;
  final int? containerSizeMl;
  final HydrionVolumeUnit volumeUnit;
  final Future<bool> Function(int index) onTileToggled;
  final VoidCallback onReset;

  const _BottleBingoBoard({
    required this.activeChallenge,
    required this.progress,
    required this.challengeRepository,
    required this.hydrationRepository,
    required this.containerSizeMl,
    required this.volumeUnit,
    required this.onTileToggled,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final bottleBingoJoined = activeChallenge?.id == 'bottle-bingo';
    final manuallyCompleted =
        activeChallenge?.bottleBingoCompletedTiles ?? const <int>{};
    final resettableCompleted = manuallyCompleted
        .difference(ChallengeRepository.bottleBingoHydrationTileIndexes);
    final progressBackedComplete = bottleBingoJoined && progress.todayMl > 0;
    final today = DateTime.now();
    final completedHydrationTiles =
        ChallengeRepository.bottleBingoHydrationTileIndexes.where(
      (index) => challengeRepository.isBottleBingoHydrationTileCompleteForDay(
        index,
        hydrationRepository,
        today,
      ),
    );
    final completedCount = manuallyCompleted
            .difference(ChallengeRepository.bottleBingoHydrationTileIndexes)
            .length +
        completedHydrationTiles.length +
        (progressBackedComplete ? 1 : 0);
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
                label: bottleBingoJoined
                    ? '$completedCount/${_tiles.length}'
                    : 'Preview',
                active: bottleBingoJoined,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bottleBingoJoined
                ? 'The first tile reacts to real logs before lunch. Tap other prompts when you complete them.'
                : 'Preview the prompts before joining. The first tile completes from real water logged before lunch.',
          ),
          if (bottleBingoJoined) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusChip(
                  label: '$completedCount complete',
                  active: completedCount > 0,
                ),
                OutlinedButton.icon(
                  key: const Key('bottle-bingo-reset'),
                  onPressed: resettableCompleted.isEmpty ? null : onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset board'),
                ),
              ],
            ),
          ],
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
                  final hydrationVolumeMl = _hydrationVolumeMlFor(
                    tile,
                    containerSizeMl,
                  );
                  final completed = tile.progressBacked
                      ? progressBackedComplete
                      : ChallengeRepository.bottleBingoHydrationTileIndexes
                              .contains(index)
                          ? challengeRepository
                              .isBottleBingoHydrationTileCompleteForDay(
                              index,
                              hydrationRepository,
                              today,
                            )
                          : challengeRepository
                              .isBottleBingoTileManuallyComplete(index);
                  return _BottleBingoTile(
                    key: Key('bottle-bingo-tile-$index'),
                    tile: tile,
                    selected: completed,
                    lockedToProgress: tile.progressBacked,
                    hydrationVolumeMl: hydrationVolumeMl,
                    onTap: tile.progressBacked || !bottleBingoJoined
                        ? null
                        : tile.hydrationAction != null &&
                                hydrationVolumeMl == null
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Set a reusable container amount in Settings before logging this Bottle Bingo action.',
                                    ),
                                  ),
                                );
                              }
                            : hydrationVolumeMl != null
                                ? completed
                                    ? null
                                    : () async {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        HydrationLog? log;
                                        try {
                                          log = await challengeRepository
                                              .completeBottleBingoHydrationTile(
                                            index: index,
                                            hydrationRepository:
                                                hydrationRepository,
                                            volumeMl: hydrationVolumeMl,
                                          );
                                        } catch (_) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Water was not logged. Please retry.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (log != null) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Logged ${HydrationVolumeFormatter.format(log.volumeMl, volumeUnit)}',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                : () {
                                    onTileToggled(index);
                                  },
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
  final int? hydrationVolumeMl;
  final VoidCallback? onTap;

  const _BottleBingoTile({
    super.key,
    required this.tile,
    required this.selected,
    required this.lockedToProgress,
    required this.hydrationVolumeMl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        selected ? HydrionColors.deep : Colors.white.withValues(alpha: 0.86);
    final foreground = selected ? Colors.white : HydrionColors.abyss;
    final state = selected
        ? hydrationVolumeMl == null
            ? 'Complete'
            : 'Logged to hydration history'
        : lockedToProgress
            ? 'Completes from water logged before lunch'
            : hydrationVolumeMl != null
                ? 'Double tap to log ${HydrationVolumeFormatter.format(hydrationVolumeMl!, context.read<UserSettingsRepository>().settings.volumeUnit)}'
                : tile.hydrationAction != null
                    ? 'Set a reusable container amount in Settings'
                    : onTap == null
                        ? 'Join Bottle Bingo to mark this tile'
                        : 'Double tap to toggle completion';
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${tile.title}. ${tile.body}. $state.',
      child: Material(
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
    final volumeUnit =
        context.watch<UserSettingsRepository>().settings.volumeUnit;
    final joined = challengeRepository.isJoined(challenge.id);
    final active = challengeRepository.activeChallengeFor(challenge.id);
    final hydrationMetric =
        challenge.objectiveType != ChallengeObjectiveType.manualCheckIn ||
            challenge.id == 'pomodoro-sip';
    final joinBlocked =
        !joined && !challengeRepository.hasRoomForAnotherChallenge;
    final progress = challengeRepository.progressFor(
      hydrationRepository,
      targetMlOverride: targetMl,
      challengeId: challenge.id,
    );
    final visual = ChallengeVisualRegistry.forId(challenge.id);

    void openDetails() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChallengeExperienceScreen(challenge: challenge),
        ),
      );
    }

    return Semantics(
      button: true,
      label: '${challenge.name}. Open challenge details.',
      child: InkWell(
        key: Key('challenge-card-${challenge.id}'),
        onTap: openDetails,
        borderRadius: BorderRadius.circular(HydrionRadii.lg),
        child: HydrionSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          visual.primary.withValues(alpha: 0.20),
                          visual.secondary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(HydrionRadii.md),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: visual.cardAsset == null
                        ? Icon(visual.icon, color: visual.primary, size: 40)
                        : Image.asset(
                            visual.cardAsset!,
                            fit: BoxFit.contain,
                            alignment: visual.imageAlignment,
                            excludeFromSemantics: true,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
              Text(challenge.description),
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
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      end: hydrationMetric
                          ? progress.dailyHydrationPercent
                          : progress.percent,
                    ),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 320),
                    builder: (context, value, _) => LinearProgressIndicator(
                      key: const Key('challenge-daily-progress'),
                      value: value,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hydrationMetric
                      ? challenge.id == 'pomodoro-sip'
                          ? '${progress.completedDays}/${progress.durationDays} days \u00b7 ${active?.completedActionIds.length ?? 0} sip check-ins \u00b7 ${HydrationVolumeFormatter.format(progress.todayMl, volumeUnit)} measured'
                          : "Today's challenge hydration: ${HydrationVolumeFormatter.format(progress.todayMl, volumeUnit)}"
                      : '${progress.completedDays}/${progress.durationDays} days checked in',
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusChip(
                    label:
                        '${HydrationVolumeFormatter.format(targetMl, volumeUnit)}/day',
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
                  FilledButton.icon(
                    key: Key(joined
                        ? 'continue-${challenge.id}'
                        : 'join-${challenge.id}'),
                    onPressed: openDetails,
                    icon: Icon(
                        joined ? Icons.dashboard_outlined : Icons.info_outline),
                    label: Text(joined ? 'Continue' : 'View setup'),
                  ),
                ],
              ),
              if (joinBlocked) ...[
                const SizedBox(height: 8),
                Text(
                  'You already have two active challenges. Pause or leave one before starting another.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
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
  final _BingoHydrationAction? hydrationAction;

  const _BingoTileData({
    required this.title,
    required this.body,
    required this.icon,
    this.progressBacked = false,
    this.hydrationAction,
  });
}

enum _BingoHydrationAction {
  bottle,
  sip,
}

int? _hydrationVolumeMlFor(_BingoTileData tile, int? containerSizeMl) {
  return switch (tile.hydrationAction) {
    _BingoHydrationAction.bottle => containerSizeMl,
    _BingoHydrationAction.sip => 150,
    null => null,
  };
}
