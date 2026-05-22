import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../hydrion/app/lib/services/ai_bridge.dart';
import '../../utils/i18n_resolver.dart';
import '../../../hydrion/app/lib/ai/ai.dart' show Challenge; // KMP model

/// SocialChallengesScreen — personalized challenge from AI.
class SocialChallengesScreen extends StatefulWidget {
  const SocialChallengesScreen({super.key});

  @override
  State<SocialChallengesScreen> createState() => _SocialChallengesScreenState();
}

class _SocialChallengesScreenState extends State<SocialChallengesScreen> {
  late Future<Challenge> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Challenge> _load() {
    final ai = context.read<AIBridge>();
    // Replace 'beginner' with real profile level from DB/profile store.
    return ai.createChallenge(userLevel: 'beginner');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();
    final dir = Directionality.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('challenges_title', 'Challenges'), textDirection: dir),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<Challenge>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Text(
                      i18n.getText('no_challenges', 'No challenges available'),
                      textDirection: dir,
                    ),
                  ),
                ],
              );
            }

            final c = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, textDirection: dir, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          '${c.description} (${c.targetMl} ml, ${c.durationDays} days)',
                          textDirection: dir,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Chip(
                              label: Text('${c.targetMl} ml/day'),
                              avatar: const Icon(Icons.water_drop, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text('${c.durationDays} days'),
                              avatar: const Icon(Icons.calendar_today, size: 18),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(i18n.getText('challenge_joined', 'Challenge joined'))),
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
