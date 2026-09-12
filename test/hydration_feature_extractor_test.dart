import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/services/hydration_feature_extractor.dart';

void main() {
  const extractor = HydrationFeatureExtractor();
  final day = DateTime(2026, 9, 11);

  test('merges overlapping workouts instead of double-counting minutes', () {
    final features = extractor.extract([
      _record(
        id: 'workout-a',
        metric: HealthMetric.workout,
        value: 40,
        unit: HealthUnit.minute,
        start: DateTime(2026, 9, 11, 10),
        end: DateTime(2026, 9, 11, 10, 40),
      ),
      _record(
        id: 'workout-b',
        metric: HealthMetric.workout,
        value: 30,
        unit: HealthUnit.minute,
        start: DateTime(2026, 9, 11, 10, 30),
        end: DateTime(2026, 9, 11, 11),
      ),
    ], day: day);

    expect(features.workoutMinutes, 60);
    expect(features.contributingRecordIds, ['workout-a', 'workout-b']);
  });

  test('uses steps and distance only as fallback without a workout', () {
    final features = extractor.extract([
      _record(
        id: 'steps',
        metric: HealthMetric.steps,
        value: 6400,
        unit: HealthUnit.count,
      ),
      _record(
        id: 'distance',
        metric: HealthMetric.distance,
        value: 5100,
        unit: HealthUnit.meter,
      ),
    ], day: day);

    expect(features.workoutMinutes, 0);
    expect(features.fallbackSteps, 6400);
    expect(features.fallbackDistanceMeters, 5100);
  });

  test('retains active-energy evidence without converting it to fluid', () {
    final features = extractor.extract([
      _record(
        id: 'energy',
        metric: HealthMetric.activeEnergy,
        value: 325,
        unit: HealthUnit.kilocalorie,
      ),
    ], day: day);

    expect(features.activeEnergyKcal, 325);
    expect(features.contributingRecordIds, ['energy']);
    expect(features.productionTargetIntegrationEnabled, isFalse);
  });

  test('selects one source per aggregate metric and honors source priority',
      () {
    final features = extractor.extract(
        [
          _record(
            id: 'energy-a',
            metric: HealthMetric.activeEnergy,
            value: 300,
            unit: HealthUnit.kilocalorie,
            sourceApp: 'source-a',
          ),
          _record(
            id: 'energy-b',
            metric: HealthMetric.activeEnergy,
            value: 450,
            unit: HealthUnit.kilocalorie,
            sourceApp: 'source-b',
          ),
        ],
        day: day,
        sourcePriority: const [
          'test-provider|test|source-b|',
        ]);

    expect(features.activeEnergyKcal, 450);
    expect(features.contributingRecordIds, ['energy-b']);
  });

  test('excludes duplicates, deleted records and unrelated sensitive metrics',
      () {
    final features = extractor.extract([
      _record(
        id: 'primary',
        metric: HealthMetric.workout,
        value: 30,
        unit: HealthUnit.minute,
        start: DateTime(2026, 9, 11, 10),
        end: DateTime(2026, 9, 11, 10, 30),
      ),
      _record(
        id: 'duplicate',
        metric: HealthMetric.workout,
        value: 30,
        unit: HealthUnit.minute,
        duplicateOf: 'primary',
        start: DateTime(2026, 9, 11, 10),
        end: DateTime(2026, 9, 11, 10, 30),
      ),
      _record(
        id: 'deleted',
        metric: HealthMetric.workout,
        value: 60,
        unit: HealthUnit.minute,
        deleted: true,
      ),
      _record(
        id: 'hrv',
        metric: HealthMetric.hrvSdnn,
        value: 48,
        unit: HealthUnit.millisecond,
      ),
    ], day: day);

    expect(features.workoutMinutes, 30);
    expect(features.contributingRecordIds, ['primary']);
    expect(features.productionTargetIntegrationEnabled, isFalse);
    expect(features.algorithmVersion, 'wearable-activity-context-v1');
  });

  test('clips workouts to local calendar-day boundaries', () {
    final features = extractor.extract([
      _record(
        id: 'boundary',
        metric: HealthMetric.workout,
        value: 60,
        unit: HealthUnit.minute,
        start: DateTime(2026, 9, 10, 23, 30),
        end: DateTime(2026, 9, 11, 0, 30),
      ),
    ], day: day);

    expect(features.workoutMinutes, 30);
  });
}

CanonicalHealthRecord _record({
  required String id,
  required HealthMetric metric,
  required double value,
  required HealthUnit unit,
  DateTime? start,
  DateTime? end,
  String? duplicateOf,
  bool deleted = false,
  String sourceApp = 'test-app',
}) {
  return CanonicalHealthRecord(
    id: id,
    providerId: 'test-provider',
    externalRecordId: id,
    synchronizationVersion: '1',
    metric: metric,
    semanticId: metric.name,
    value: value,
    unit: unit,
    startTime: start ?? DateTime(2026, 9, 11, 9),
    endTime: end ?? DateTime(2026, 9, 11, 10),
    ingestedAt: DateTime(2026, 9, 11, 12),
    shape: HealthRecordShape.aggregate,
    valueOrigin: HealthValueOrigin.rawSensor,
    provenance: HealthProvenance(
      sourcePlatform: 'test',
      sourceApplicationId: sourceApp,
      acquisitionRoute: HealthAcquisitionRoute.test,
      entryMethod: HealthEntryMethod.sensor,
    ),
    duplicateOfRecordId: duplicateOf,
    isDeleted: deleted,
  );
}
