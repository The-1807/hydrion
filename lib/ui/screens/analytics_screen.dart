import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../domain/ui_asset_manifest.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/eco_tracker.dart';
import '../components/hydration_score_card.dart';
import '../theme/hydrion_design.dart';

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
    final weeklyTotals = List.generate(7, (index) {
      final day = DateTime(today.year, today.month, today.day - (6 - index));
      return hydrationRepository.totalForDay(day);
    });
    final hydrationPercent = (todayMl / targetMl * 100).clamp(0.0, 100.0);
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
          _WeeklyHydrationStrip(
            totals: weeklyTotals,
            targetMl: targetMl,
            sex: settings.sex,
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

class _WeeklyHydrationStrip extends StatelessWidget {
  final List<int> totals;
  final int targetMl;
  final HydrionSex? sex;

  const _WeeklyHydrationStrip({
    required this.totals,
    required this.targetMl,
    required this.sex,
  });

  @override
  Widget build(BuildContext context) {
    final scene = HydrionLifestyleArtResolver.sceneFor(
      surface: HydrionLifestyleSurface.progress,
      sex: sex,
    );
    final maxValue = [
      targetMl,
      ...totals,
    ].reduce((a, b) => a > b ? a : b);
    final average = totals.isEmpty
        ? 0
        : (totals.reduce((a, b) => a + b) / totals.length).round();
    final loggedDays = totals.where((value) => value > 0).length;
    final rhythmSummary = loggedDays == 0
        ? 'Log a drink to start the rhythm.'
        : loggedDays < 2
            ? 'Building rhythm from today\'s logs.'
            : 'Average: $average ml/day. Target: $targetMl ml.';
    return HydrionSurface(
      key: const Key('weekly-hydration-strip'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7-day rhythm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(rhythmSummary),
                const SizedBox(height: 16),
                Semantics(
                  label:
                      'Seven day hydration chart. Daily totals: ${totals.join(', ')} milliliters.',
                  child: SizedBox(
                    height: 112,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var index = 0; index < totals.length; index += 1)
                          Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(right: index == 6 ? 0 : 8),
                              child: _DayBar(
                                valueMl: totals[index],
                                maxMl: maxValue,
                                targetMl: targetMl,
                                isToday: index == totals.length - 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(HydrionRadii.sm),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                scene.assetPath,
                width: 76,
                height: 120,
                fit: BoxFit.contain,
                semanticLabel: scene.description,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final int valueMl;
  final int maxMl;
  final int targetMl;
  final bool isToday;

  const _DayBar({
    required this.valueMl,
    required this.maxMl,
    required this.targetMl,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final percent = maxMl <= 0 ? 0.0 : (valueMl / maxMl).clamp(0.0, 1.0);
    final goalMet = valueMl >= targetMl;
    final label = isToday ? 'Today' : _compactLiters(valueMl);
    final subLabel = isToday ? _compactLiters(valueMl) : '';
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: HydrionColors.current.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(HydrionRadii.pill),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: percent,
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: goalMet
                        ? HydrionColors.kelp
                        : isToday
                            ? HydrionColors.deep
                            : HydrionColors.current.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(HydrionRadii.pill),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        SizedBox(
          height: 14,
          child: Text(
            subLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

String _compactLiters(int valueMl) {
  if (valueMl <= 0) {
    return '0';
  }
  final liters = valueMl / 1000;
  return '${liters.toStringAsFixed(1)}L';
}
