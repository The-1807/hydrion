import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_bridge.dart';
import '../../services/eco_tracker.dart';
import '../../utils/i18n_resolver.dart';
import '../components/achievement_badge.dart';
import '../components/hydration_score_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();
    final aiBridge = context.read<AIBridge>();
    final ecoTracker = context.read<EcoTracker>();

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('analytics_title', 'Analytics')),
        centerTitle: true,
      ),
      body: FutureBuilder<HydrationSummary>(
        future: aiBridge.getHydrationSummary(),
        builder: (context, snapshot) {
          final summary = snapshot.data ??
              const HydrationSummary(
                hydrationPercent: 0,
                activityMinutes: 0,
                consumedMl: 0,
                targetMl: 2200,
              );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              HydrationScoreCard(
                hydrationPercent: summary.hydrationPercent,
                activityMinutes: summary.activityMinutes,
              ),
              const SizedBox(height: 20),
              Text(
                i18n.getText('achievements', 'Achievements'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AchievementBadge(badgeName: '7 day streak', isUnlocked: true),
                  AchievementBadge(badgeName: '2L goal', isUnlocked: false),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                i18n.getText('eco_impact', 'Environmental Impact'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              FutureBuilder<double>(
                future: ecoTracker.getTotalPlasticSavedKg(),
                builder: (context, ecoSnapshot) {
                  final value = (ecoSnapshot.data ?? 0.0).toStringAsFixed(2);
                  return Text(
                    'Plastic Saved: $value kg',
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
