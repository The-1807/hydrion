import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../hydrion/app/lib/services/ai_bridge.dart';
import '../../../hydrion/app/lib/services/eco_tracker.dart';
import '../../utils/i18n_resolver.dart';
import '../components/AchievementBadge.dart';
import '../components/HydrationScoreCard.dart';

// AnalyticsScreen.dart - Displays insights and charts for Hydrion.ai
// Includes LLM explanations and eco-tracking
// Version: 1.0
// Author: Hydrion.ai Team

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aiBridge = Provider.of<AIBridge>(context, listen: false);
    final ecoTracker = Provider.of<EcoTracker>(context, listen: false);
    final i18n = Provider.of<I18nResolver>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.getText('analytics_title', 'Analytics'),
          textDirection: i18n.getTextDirection(context.locale),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HydrationScoreCard(
              hydrationPercent: 75.0, // Placeholder: Fetch from ai_bridge.dart
              activityMinutes: 30,
            ),
            const SizedBox(height: 16),
            Text(
              i18n.getText('achievements', 'Achievements'),
              style: Theme.of(context).textTheme.headlineSmall,
              textDirection: i18n.getTextDirection(context.locale),
            ),
            Wrap(
              spacing: 8,
              children: [
                AchievementBadge(badgeName: '7_day_streak', isUnlocked: true),
                AchievementBadge(badgeName: '2l_goal', isUnlocked: false),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              i18n.getText('eco_impact', 'Environmental Impact'),
              style: Theme.of(context).textTheme.headlineSmall,
              textDirection: i18n.getTextDirection(context.locale),
            ),
            FutureBuilder<double>(
              future: ecoTracker.getTotalPlasticSaved(),
              builder: (context, snapshot) {
                return Text(
                  i18n.getText(
                    'plastic_saved',
                    'Plastic Saved: ${snapshot.data?.toStringAsFixed(2) ?? 0.0} kg',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textDirection: i18n.getTextDirection(context.locale),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}