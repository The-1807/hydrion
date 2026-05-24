import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/hydration_repository.dart';
import '../../utils/i18n_resolver.dart';

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
    final i18n = context.watch<I18nResolver>();
    final challengeRepository = context.watch<ChallengeRepository>();
    final hydrationRepository = context.watch<HydrationRepository>();
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('challenges_title', 'Challenges')),
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
                    child: Text(i18n.getText(
                        'no_challenges', 'No challenges available')),
                  ),
                ],
              );
            }

            final challenge = snapshot.data!;
            final joined = challengeRepository.isJoined(challenge.id);
            final progress =
                challengeRepository.progressFor(hydrationRepository);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(
                      capabilities.socialSync
                          ? 'Social challenge capability reported'
                          : 'Local challenge mode',
                    ),
                    subtitle: Text(
                      capabilities.socialSync
                          ? 'No social adapter is wired yet. Progress is still saved on this device.'
                          : 'Social sync is not connected yet. Challenge progress is saved on this device.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (challengeRepository.activeChallenge == null) ...[
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.emoji_events_outlined),
                      title: Text('No active challenge yet'),
                      subtitle: Text(
                        'Join the local challenge below to start tracking progress from saved hydration logs.',
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
                        Text(challenge.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          '${challenge.description} (${challenge.targetMl} ml, ${challenge.durationDays} days)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        if (joined) ...[
                          LinearProgressIndicator(value: progress.percent),
                          const SizedBox(height: 8),
                          Text(
                            '${progress.completedDays}/${progress.durationDays} days complete. Today: ${progress.todayMl}/${progress.targetMl} ml.',
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
                              label: Text('${challenge.targetMl} ml/day'),
                              avatar: const Icon(Icons.water_drop, size: 18),
                            ),
                            Chip(
                              label: Text('${challenge.durationDays} days'),
                              avatar:
                                  const Icon(Icons.calendar_today, size: 18),
                            ),
                            FilledButton.icon(
                              onPressed: joined
                                  ? null
                                  : () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      final message = i18n.getText(
                                          'challenge_joined',
                                          'Challenge joined');
                                      await challengeRepository.join(
                                        id: challenge.id,
                                        name: challenge.name,
                                        description: challenge.description,
                                        targetMl: challenge.targetMl,
                                        durationDays: challenge.durationDays,
                                      );
                                      if (!mounted) {
                                        return;
                                      }
                                      messenger.showSnackBar(
                                        SnackBar(
                                            content: Text('$message locally')),
                                      );
                                    },
                              icon:
                                  Icon(joined ? Icons.check : Icons.play_arrow),
                              label: Text(joined
                                  ? 'Joined'
                                  : i18n.getText('join', 'Join')),
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
}
