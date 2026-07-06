import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/achievement_service.dart';
import '../../services/eco_tracker.dart';
import '../components/achievement_badge.dart';
import '../components/hydration_score_card.dart';

class AnalyticsScreen extends StatelessWidget {
  final bool embedded;

  const AnalyticsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hydrationRepository = context.watch<HydrationRepository>();
    final settings = context.watch<UserSettingsRepository>().settings;
    final ecoTracker = context.read<EcoTracker>();
    final today = DateTime.now();
    final targetMl = settings.dailyGoalMl;
    final todayMl = hydrationRepository.totalForDay(today);
    final lifetimeMl = hydrationRepository.totalMl;
    final eventCount = hydrationRepository.eventCount;
    final todayLogs = hydrationRepository.fetch(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day + 1),
    );
    final hydrationPercent = (todayMl / targetMl * 100).clamp(0.0, 100.0);
    final achievements = const AchievementService().evaluate(
      hydrationRepository: hydrationRepository,
      now: today,
      activeGoalMl: targetMl,
    );

    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: Text(l10n.analyticsTitle),
              centerTitle: true,
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hydrationRepository.logs.isEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.insights,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noAnalyticsYet,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.analyticsEmptyDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          HydrationScoreCard(
            hydrationPercent: hydrationPercent,
            entryCount: todayLogs.length,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.water_drop),
              title: Text(
                l10n.todayHydrationTitle(
                  todayMl: todayMl,
                  targetMl: targetMl,
                ),
              ),
              subtitle: Text(l10n.localEntriesToday(count: todayLogs.length)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.achievementsTitle,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AchievementBadge(
                badgeName: l10n.badgeDailyGoal,
                isUnlocked: achievements.dailyGoal.unlocked,
              ),
              AchievementBadge(
                badgeName: l10n.badgeThreeLogsToday,
                isUnlocked: achievements.threeLogsToday.unlocked,
              ),
              AchievementBadge(
                badgeName: l10n.badgeSevenDayStreak,
                isUnlocked: achievements.sevenDayStreak.unlocked,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.ecoImpactTitle,
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
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.eco),
                  title: Text(l10n.plasticEstimateTitle(value: value)),
                  subtitle: Text(
                    settings.reusableContainerEnabled
                        ? l10n.reusableContainerEstimateFromLogs(
                            lifetimeMl: lifetimeMl,
                            eventCount: eventCount,
                          )
                        : l10n.reusableContainerEstimateDisabled,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
