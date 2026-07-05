import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/challenge_catalog.dart';
import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';

class SocialChallengesScreen extends StatelessWidget {
  const SocialChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final challengeRepository = context.watch<ChallengeRepository>();
    final hydrationRepository = context.watch<HydrationRepository>();
    final settings = context.watch<UserSettingsRepository>().settings;
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.challengesTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                capabilities.socialSync
                    ? l10n.socialChallengeCapabilityReported
                    : l10n.localChallengeMode,
              ),
              subtitle: Text(
                capabilities.socialSync
                    ? l10n.socialCapabilityNoAdapter
                    : l10n.socialSyncNotConnected,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.health_and_safety_outlined),
              title: Text('Challenge safety'),
              subtitle: Text(HydrionChallengeCatalog.safetyNote),
            ),
          ),
          const SizedBox(height: 12),
          if (challengeRepository.activeChallenge == null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(l10n.noActiveChallengeYet),
                subtitle: Text(l10n.joinLocalChallengeDescription),
              ),
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

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(challenge.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              challenge.category,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.challengeDetails(
                description: challenge.description,
                targetMl: targetMl,
                durationDays: challenge.durationDays,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(challenge.dailyTask),
            const SizedBox(height: 12),
            if (joined) ...[
              LinearProgressIndicator(value: progress.percent),
              const SizedBox(height: 8),
              Text(
                l10n.challengeProgress(
                  completedDays: progress.completedDays,
                  durationDays: progress.durationDays,
                  todayMl: progress.todayMl,
                  targetMl: progress.targetMl,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(l10n.challengeTargetPerDay(targetMl: targetMl)),
                  avatar: const Icon(Icons.water_drop, size: 18),
                ),
                Chip(
                  label: Text(
                    l10n.challengeDurationDays(
                      durationDays: challenge.durationDays,
                    ),
                  ),
                  avatar: const Icon(Icons.calendar_today, size: 18),
                ),
                if (joined)
                  Chip(
                    label: Text(l10n.joined),
                    avatar: const Icon(Icons.check, size: 18),
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
      ),
    );
  }
}
