import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/health_data.dart';
import '../../l10n/app_localizations.dart';
import '../../services/health_connection_controller.dart';
import '../components/hydrion_viewport.dart';

/// Read-only presentation of records already imported by the connected
/// wearable-data provider: a workout timeline and short trends for steps,
/// distance and active energy. This screen never talks to HealthKit or
/// Health Connect directly — it only reads what `HealthConnectionController`
/// has already synchronized into the encrypted local repository.
class WearableDataDashboardScreen extends StatefulWidget {
  const WearableDataDashboardScreen({super.key});

  @override
  State<WearableDataDashboardScreen> createState() =>
      _WearableDataDashboardScreenState();
}

class _WearableDataDashboardScreenState
    extends State<WearableDataDashboardScreen> {
  late Future<List<CanonicalHealthRecord>> _records;

  @override
  void initState() {
    super.initState();
    _records = context.read<HealthConnectionController>().importedRecords();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.healthDataImportedDataTitle)),
      body: FutureBuilder<List<CanonicalHealthRecord>>(
        future: _records,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final records = snapshot.data!;
          return ListView(
            padding: HydrionViewport.scrollPadding(context),
            children: [
              _WorkoutTimeline(
                workouts: records
                    .where((r) => r.metric == HealthMetric.workout)
                    .toList(growable: false),
              ),
              const SizedBox(height: 20),
              _TrendSection(
                title: l10n.healthDataStepsTrend,
                unit: l10n.healthDataSteps,
                records: records
                    .where((r) => r.metric == HealthMetric.steps)
                    .toList(growable: false),
              ),
              const SizedBox(height: 20),
              _TrendSection(
                title: l10n.healthDataDistanceTrend,
                unit: l10n.healthDataDistance,
                records: records
                    .where((r) => r.metric == HealthMetric.distance)
                    .toList(growable: false),
              ),
              const SizedBox(height: 20),
              _TrendSection(
                title: l10n.healthDataActiveEnergyTrend,
                unit: l10n.healthDataActiveEnergy,
                records: records
                    .where((r) => r.metric == HealthMetric.activeEnergy)
                    .toList(growable: false),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.healthDataWellnessDisclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _WorkoutTimeline extends StatelessWidget {
  final List<CanonicalHealthRecord> workouts;

  const _WorkoutTimeline({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.healthDataWorkoutTimeline,
      child: workouts.isEmpty
          ? Text(l10n.healthDataWorkoutTimelineEmpty)
          : Column(
              children: [
                for (final workout in workouts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.healthDataWorkoutRow(
                                minutes: workout.endTime
                                    .difference(workout.startTime)
                                    .inMinutes,
                              )),
                              Text(
                                l10n.healthDataRecordSource(
                                  source: _sourceLabel(workout),
                                  date: _dateTime(context, workout.startTime),
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  final String title;
  final String unit;
  final List<CanonicalHealthRecord> records;
  static const _days = 14;

  const _TrendSection({
    required this.title,
    required this.unit,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buckets = _dailyTotals(records);
    final maxValue =
        buckets.isEmpty ? 0.0 : buckets.map((b) => b.total).reduce(math.max);
    return _SectionCard(
      title: title,
      child: buckets.isEmpty
          ? Text(l10n.healthDataTrendEmpty)
          : SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bucket in buckets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Semantics(
                          label: l10n.healthDataTrendDayTotal(
                            date: _date(context, bucket.day),
                            value: bucket.total.toStringAsFixed(1),
                            unit: unit,
                          ),
                          child: FractionallySizedBox(
                            heightFactor: maxValue == 0
                                ? 0.02
                                : (0.06 + 0.94 * (bucket.total / maxValue)),
                            alignment: Alignment.bottomCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  List<_DayTotal> _dailyTotals(List<CanonicalHealthRecord> records) {
    final today = DateTime.now().toUtc();
    final start = DateTime.utc(today.year, today.month, today.day)
        .subtract(const Duration(days: _days - 1));
    final totals = <DateTime, double>{};
    final days = List<DateTime>.generate(
      _days,
      (i) => start.add(Duration(days: i)),
    );
    for (final day in days) {
      totals[day] = 0.0;
    }
    for (final record in records) {
      final day = DateTime.utc(
        record.startTime.year,
        record.startTime.month,
        record.startTime.day,
      );
      if (totals.containsKey(day)) {
        totals[day] = totals[day]! + record.value;
      }
    }
    if (totals.values.every((value) => value == 0)) return const [];
    return [for (final day in days) _DayTotal(day, totals[day]!)];
  }
}

class _DayTotal {
  final DateTime day;
  final double total;

  const _DayTotal(this.day, this.total);
}

String _sourceLabel(CanonicalHealthRecord record) {
  final name = record.provenance.sourceApplicationName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return record.provenance.sourceApplicationId;
}

String _dateTime(BuildContext context, DateTime value) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_jm()
        .format(value.toLocal());

String _date(BuildContext context, DateTime value) =>
    DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
        .format(value.toLocal());
