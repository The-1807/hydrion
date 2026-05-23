import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_bridge.dart';
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
    return context.read<AIBridge>().createChallenge(userLevel: 'beginner');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();

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
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(i18n.getText(
                                          'challenge_joined',
                                          'Challenge joined'))),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: Text(i18n.getText('join', 'Join')),
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
