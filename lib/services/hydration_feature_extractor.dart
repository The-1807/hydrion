import '../domain/health_data.dart';

class HydrationActivityFeatures {
  final String algorithmVersion;
  final int workoutMinutes;
  final double activeEnergyKcal;
  final int? fallbackSteps;
  final double? fallbackDistanceMeters;
  final List<String> contributingRecordIds;
  final bool productionTargetIntegrationEnabled;

  const HydrationActivityFeatures({
    required this.algorithmVersion,
    required this.workoutMinutes,
    required this.activeEnergyKcal,
    required this.fallbackSteps,
    required this.fallbackDistanceMeters,
    required this.contributingRecordIds,
    this.productionTargetIntegrationEnabled = false,
  });
}

class HydrationFeatureExtractor {
  static const algorithmVersion = 'wearable-activity-context-v1';

  const HydrationFeatureExtractor();

  HydrationActivityFeatures extract(
    Iterable<CanonicalHealthRecord> records, {
    required DateTime day,
    List<String> sourcePriority = const <String>[],
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final eligible = records
        .where((record) =>
            !record.isDeleted &&
            record.duplicateOfRecordId == null &&
            record.startTime.isBefore(end) &&
            record.endTime.isAfter(start))
        .toList();

    final workouts = eligible
        .where((record) => record.metric == HealthMetric.workout)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final mergedIntervals = <({DateTime start, DateTime end})>[];
    for (final workout in workouts) {
      final clippedStart =
          workout.startTime.isBefore(start) ? start : workout.startTime;
      final clippedEnd = workout.endTime.isAfter(end) ? end : workout.endTime;
      if (!clippedEnd.isAfter(clippedStart)) continue;
      if (mergedIntervals.isEmpty ||
          clippedStart.isAfter(mergedIntervals.last.end)) {
        mergedIntervals.add((start: clippedStart, end: clippedEnd));
      } else if (clippedEnd.isAfter(mergedIntervals.last.end)) {
        mergedIntervals[mergedIntervals.length - 1] = (
          start: mergedIntervals.last.start,
          end: clippedEnd,
        );
      }
    }
    final workoutMinutes = mergedIntervals.fold<int>(
      0,
      (total, interval) =>
          total + interval.end.difference(interval.start).inMinutes,
    );

    final selectedEnergy = _selectMetricSource(
      eligible.where((record) =>
          record.metric == HealthMetric.activeEnergy &&
          record.unit == HealthUnit.kilocalorie),
      sourcePriority,
    );
    final activeEnergy = selectedEnergy.fold<double>(
      0,
      (sum, record) => sum + record.value,
    );

    int? fallbackSteps;
    double? fallbackDistance;
    var selectedSteps = <CanonicalHealthRecord>[];
    var selectedDistance = <CanonicalHealthRecord>[];
    if (workoutMinutes == 0) {
      selectedSteps = _selectMetricSource(
        eligible.where((r) =>
            r.metric == HealthMetric.steps && r.unit == HealthUnit.count),
        sourcePriority,
      );
      selectedDistance = _selectMetricSource(
        eligible.where((r) =>
            r.metric == HealthMetric.distance && r.unit == HealthUnit.meter),
        sourcePriority,
      );
      if (selectedSteps.isNotEmpty) {
        fallbackSteps = selectedSteps
            .fold<double>(
              0,
              (sum, record) => sum + record.value,
            )
            .round();
      }
      if (selectedDistance.isNotEmpty) {
        fallbackDistance = selectedDistance.fold<double>(
          0,
          (sum, record) => sum + record.value,
        );
      }
    }

    final contributors = <String>{
      ...workouts.map((record) => record.id),
      ...selectedEnergy.map((record) => record.id),
      ...selectedSteps.map((record) => record.id),
      ...selectedDistance.map((record) => record.id),
    }.toList()
      ..sort();

    return HydrationActivityFeatures(
      algorithmVersion: algorithmVersion,
      workoutMinutes: workoutMinutes,
      activeEnergyKcal: activeEnergy,
      fallbackSteps: fallbackSteps,
      fallbackDistanceMeters: fallbackDistance,
      contributingRecordIds: List<String>.unmodifiable(contributors),
    );
  }

  List<CanonicalHealthRecord> _selectMetricSource(
    Iterable<CanonicalHealthRecord> records,
    List<String> sourcePriority,
  ) {
    final bySource = <String, List<CanonicalHealthRecord>>{};
    for (final record in records) {
      final key = _sourceKey(record);
      bySource.putIfAbsent(key, () => []).add(record);
    }
    if (bySource.isEmpty) return const <CanonicalHealthRecord>[];

    for (final preferred in sourcePriority) {
      final selected = bySource[preferred];
      if (selected != null) return selected;
    }
    final keys = bySource.keys.toList()..sort();
    return bySource[keys.first]!;
  }

  String _sourceKey(CanonicalHealthRecord record) =>
      '${record.providerId}|${record.provenance.sourceKey}|'
      '${record.provenance.physicalDeviceId ?? ''}';
}
