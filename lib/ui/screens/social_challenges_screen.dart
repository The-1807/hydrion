import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';

class SocialChallengesScreen extends StatefulWidget {
  const SocialChallengesScreen({super.key});

  @override
  State<SocialChallengesScreen> createState() => _SocialChallengesScreenState();
}

class _SocialChallengesScreenState extends State<SocialChallengesScreen> {
  late Future<HydrationChallenge> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<HydrationChallenge> _load() {
    return context
        .read<ChallengeGenerator>()
        .createChallenge(userLevel: 'beginner');
  }

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
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = _load();
          });
        },
        child: FutureBuilder<HydrationChallenge>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Text(l10n.noChallengesAvailable),
                  ),
                ],
              );
            }

            final challenge = snapshot.data!;
            final challengeName = _challengeName(challenge, l10n);
            final challengeDescription = _challengeDescription(
              challenge,
              l10n,
            );
            final targetMl = settings.dailyGoalMl;
            final joined = challengeRepository.isJoined(challenge.id);
            final progress = challengeRepository.progressFor(
              hydrationRepository,
              targetMlOverride: targetMl,
            );
            return ListView(
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
                if (challengeRepository.activeChallenge == null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.emoji_events_outlined),
                      title: Text(l10n.noActiveChallengeYet),
                      subtitle: Text(
                        l10n.joinLocalChallengeDescription,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(challengeName,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          l10n.challengeDetails(
                            description: challengeDescription,
                            targetMl: targetMl,
                            durationDays: challenge.durationDays,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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
                              label: Text(l10n.challengeTargetPerDay(
                                targetMl: targetMl,
                              )),
                              avatar: const Icon(Icons.water_drop, size: 18),
                            ),
                            Chip(
                              label: Text(l10n.challengeDurationDays(
                                durationDays: challenge.durationDays,
                              )),
                              avatar:
                                  const Icon(Icons.calendar_today, size: 18),
                            ),
                            FilledButton.icon(
                              onPressed: joined
                                  ? null
                                  : () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      await challengeRepository.join(
                                        id: challenge.id,
                                        name: challengeName,
                                        description: challengeDescription,
                                        targetMl: targetMl,
                                        durationDays: challenge.durationDays,
                                      );
                                      if (!mounted) {
                                        return;
                                      }
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
                              icon:
                                  Icon(joined ? Icons.check : Icons.play_arrow),
                              label: Text(joined ? l10n.joined : l10n.join),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _challengeName(HydrationChallenge challenge, AppLocalizations l10n) {
    return challenge.id.startsWith('steady-sip-7-day')
        ? l10n.challengeNameSevenDaySteadySip
        : challenge.name;
  }

  String _challengeDescription(
    HydrationChallenge challenge,
    AppLocalizations l10n,
  ) {
    return challenge.id.startsWith('steady-sip-7-day')
        ? l10n.challengeDescriptionSevenDaySteadySip
        : challenge.description;
  }
}
