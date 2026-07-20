import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../domain/ui_asset_manifest.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/eco_tracker.dart';
import '../../services/app_refresh_controller.dart';
import '../components/intake_ring.dart';
import '../components/hydration_score_card.dart';
import '../theme/hydrion_design.dart';

class AnalyticsScreen extends StatelessWidget {
  final bool embedded;
  final Key? tourTargetKey;

  const AnalyticsScreen({
    super.key,
    this.embedded = false,
    this.tourTargetKey,
  });

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
      body: RefreshIndicator(
        key: const Key('progress-refresh-indicator'),
        onRefresh: () => refreshHydrionData(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            KeyedSubtree(
              key: tourTargetKey,
              child: HydrationScoreCard(
                hydrationPercent: hydrationPercent,
                entryCount: todayLogs.length,
                todayMl: todayMl,
                targetMl: targetMl,
                volumeUnit: settings.volumeUnit,
              ),
            ),
            const SizedBox(height: 12),
            _WeeklyHydrationStrip(
              totals: weeklyTotals,
              endDate: today,
              targetMl: targetMl,
              sex: settings.sex,
              volumeUnit: settings.volumeUnit,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.water_drop),
                title: Text(
                  "Today's hydration: "
                  '${HydrationVolumeFormatter.format(todayMl, settings.volumeUnit)} / '
                  '${HydrationVolumeFormatter.format(targetMl, settings.volumeUnit)}',
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
      ),
    );
  }
}

class _WeeklyHydrationStrip extends StatelessWidget {
  final List<int> totals;
  final DateTime endDate;
  final int targetMl;
  final HydrionSex? sex;
  final HydrionVolumeUnit volumeUnit;

  const _WeeklyHydrationStrip({
    required this.totals,
    required this.endDate,
    required this.targetMl,
    required this.sex,
    required this.volumeUnit,
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
        ? 'No hydration recorded in the last 7 days.'
        : '${HydrationVolumeFormatter.format(average, volumeUnit)} daily average. '
            'Target: ${HydrationVolumeFormatter.format(targetMl, volumeUnit)}.';
    return HydrionSurface(
      key: const Key('weekly-hydration-strip'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last 7 days',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(rhythmSummary),
            ],
          );
          final chart = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 64,
                      height: 78,
                      child: Image.asset(
                        scene.assetPath,
                        key: const Key('progress-profile-art'),
                        fit: BoxFit.contain,
                        cacheWidth: 192,
                        semanticLabel: scene.description,
                      ),
                    ),
                  ],
                )
              else
                heading,
              const SizedBox(height: 16),
              Semantics(
                label: 'Seven day hydration chart. '
                    '${List.generate(totals.length, (index) {
                  final day = endDate.subtract(
                    Duration(days: totals.length - index - 1),
                  );
                  return '${MaterialLocalizations.of(context).formatFullDate(day)}: '
                      '${HydrationVolumeFormatter.format(totals[index], volumeUnit)}';
                }).join('. ')}.',
                child: SizedBox(
                  height: 128,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < totals.length; index += 1)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index == 6 ? 0 : 8),
                            child: _DayBar(
                              key: ValueKey('weekly-day-$index'),
                              date: endDate.subtract(
                                Duration(days: totals.length - index - 1),
                              ),
                              valueMl: totals[index],
                              maxMl: maxValue,
                              targetMl: targetMl,
                              isToday: index == totals.length - 1,
                              showLabel: !compact ||
                                  index.isEven ||
                                  index == totals.length - 1,
                              volumeUnit: volumeUnit,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
          if (compact) return chart;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: chart),
              const SizedBox(width: 14),
              SizedBox(
                width: 88,
                height: 132,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(HydrionRadii.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      scene.assetPath,
                      key: const Key('progress-profile-art'),
                      width: 76,
                      height: 120,
                      fit: BoxFit.contain,
                      cacheWidth: 192,
                      semanticLabel: scene.description,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final DateTime date;
  final int valueMl;
  final int maxMl;
  final int targetMl;
  final bool isToday;
  final bool showLabel;
  final HydrionVolumeUnit volumeUnit;

  const _DayBar({
    super.key,
    required this.date,
    required this.valueMl,
    required this.maxMl,
    required this.targetMl,
    required this.isToday,
    required this.showLabel,
    required this.volumeUnit,
  });

  @override
  Widget build(BuildContext context) {
    final percent = maxMl <= 0 ? 0.0 : (valueMl / maxMl).clamp(0.0, 1.0);
    final goalMet = valueMl >= targetMl;
    final formatted = HydrationVolumeFormatter.format(valueMl, volumeUnit);
    final localizations = MaterialLocalizations.of(context);
    final label = isToday
        ? 'Today'
        : DateFormat.E(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(date);
    final fullDate = localizations.formatFullDate(date);
    return Semantics(
      label: '$fullDate, $formatted${isToday ? ', today' : ''}',
      child: Tooltip(
        message: '$fullDate \u00b7 $formatted',
        child: Column(
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
            SizedBox(
              height: 18,
              child: showLabel
                  ? Text(
                      label,
                      key: Key(
                        'weekly-day-label-'
                        '${date.toIso8601String().substring(0, 10)}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight:
                                isToday ? FontWeight.w900 : FontWeight.w600,
                          ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
