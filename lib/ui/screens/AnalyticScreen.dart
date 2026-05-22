import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../hydrion/app/lib/services/ai_bridge.dart';
import '../../../hydrion/app/lib/services/eco_tracker.dart';
import '../../utils/i18n_resolver.dart';
import '../components/AchievementBadge.dart';
import '../components/HydrationScoreCard.dart';

/// AnalyticsScreen — hydration score, achievements, and eco impact.
/// - Fixes method name for EcoTracker (getTotalPlasticSavedKg)
/// - Uses consistent typography and spacing
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Replace these with real sources (DB/bridge)
  double _hydrationPercent = 75.0;
  int _activityMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();
    final dir = Directionality.of(context);

    // Ensure services are available
    context.read<AIBridge>();
    final eco = context.read<EcoTracker>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.getText('analytics_title', 'Analytics'),
          textDirection: dir,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HydrationScoreCard(
              hydrationPercent: _hydrationPercent,
              activityMinutes: _activityMinutes,
            ),
            const SizedBox(height: 20),
            Text(
              i18n.getText('achievements', 'Achievements'),
              textDirection: dir,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                AchievementBadge(badgeName: '7_day_streak', isUnlocked: true),
                AchievementBadge(badgeName: '2l_goal', isUnlocked: false),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              i18n.getText('eco_impact', 'Environmental Impact'),
              textDirection: dir,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            FutureBuilder<double>(
              future: eco.getTotalPlasticSavedKg(),
              builder: (context, snap) {
                final val = (snap.data ?? 0.0).toStringAsFixed(2);
                return Text(
                  i18n.getText('plastic_saved', 'Plastic Saved: $val kg'),
                  textDirection: dir,
                  style: Theme.of(context).textTheme.bodyLarge,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
