import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/hydration_report.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  test('records synthetic long-term storage and operation costs', () async {
    final results = <Map<String, Object?>>[];
    for (final yearsAndDays in const <(String, int)>[
      ('30-days', 30),
      ('1-year', 365),
      ('5-years', 1826),
      ('10-years', 3653),
    ]) {
      for (final workload in const <(String, int, bool)>[
        ('typical', 8, false),
        ('heavy', 48, true),
      ]) {
        results.add(await _benchmark(
          label: yearsAndDays.$1,
          days: yearsAndDays.$2,
          recordsPerDay: workload.$2,
          richMetadata: workload.$3,
          workload: workload.$1,
        ));
      }
    }

    final challengeResults = <Map<String, Object?>>[];
    for (final years in const [1, 5, 10]) {
      for (final attemptsPerMonth in const [1, 4]) {
        challengeResults.add(await _challengeBenchmark(
          years: years,
          attempts: years * 12 * attemptsPerMonth,
          workload: attemptsPerMonth == 1 ? 'typical' : 'heavy',
        ));
      }
    }

    final failure = await _thresholdFailureBenchmark();
    final output = File(
      'audit-output/release-size-runtime/analysis/storage-benchmark.json',
    );
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
            'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
            'dataClass': 'synthetic-only',
            'hydration': results,
            'challengeHistory': challengeResults,
            'syntheticThresholdFailure': failure,
          })}\n',
    );
    expect(results, hasLength(8));
    expect(challengeResults, hasLength(6));
    expect(failure['rollbackPreserved'], isTrue);
  }, timeout: const Timeout(Duration(minutes: 20)));
}

Future<Map<String, Object?>> _benchmark({
  required String label,
  required int days,
  required int recordsPerDay,
  required bool richMetadata,
  required String workload,
}) async {
  final start = DateTime(2016, 1, 1, 8);
  final rawWatch = Stopwatch()..start();
  final buffer = StringBuffer('[');
  var recordCount = 0;
  for (var day = 0; day < days; day++) {
    for (var index = 0; index < recordsPerDay; index++) {
      final timestamp = start.add(Duration(
        days: day,
        minutes: (index * 23) % (12 * 60),
      ));
      if (recordCount > 0) buffer.write(',');
      buffer.write(jsonEncode({
        'id': 'synthetic-$day-$index',
        'volumeMl': 250,
        'timestamp': timestamp.toIso8601String(),
        'source': richMetadata ? 'synthetic-heavy' : 'synthetic',
        if (richMetadata) 'actionId': 'synthetic-action-$day-$index',
        if (richMetadata)
          'metadata': {
            'temperatureStyle': 'Room temperature',
            'infusionTheme': 'Synthetic citrus',
            'noAddedSugar': true,
            'savedContainerUsed': true,
            'mealContext': 'synthetic meal',
            'timeWindow': 'synthetic window',
            'challengeActionSource': 'synthetic-challenge',
            'bingoTileSource': 'synthetic-tile',
          },
      }));
      recordCount += 1;
    }
  }
  buffer.write(']');
  final raw = buffer.toString();
  rawWatch.stop();
  final serializedBytes = utf8.encode(raw).length;

  final store = _RecordingStore({HydrationRepository.storageKey: raw});
  final rssBefore = ProcessInfo.currentRss;
  final loadWatch = Stopwatch()..start();
  final repository = await HydrationRepository.load(store);
  loadWatch.stop();
  final rssAfterLoad = ProcessInfo.currentRss;

  final appendWatch = Stopwatch()..start();
  final appended = await repository.addLog(
    volumeMl: 300,
    timestamp: start.add(Duration(days: days, hours: 1)),
    source: 'synthetic-benchmark',
  );
  appendWatch.stop();

  final updateWatch = Stopwatch()..start();
  await repository.updateLog(id: appended!.id, volumeMl: 350);
  updateWatch.stop();

  final deleteWatch = Stopwatch()..start();
  await repository.deleteLog(appended.id);
  deleteWatch.stop();

  final aggregation = <String, int>{};
  final ending = start.add(Duration(days: days - 1));
  for (final frequency in HydrationReportFrequency.values) {
    final watch = Stopwatch()..start();
    const HydrationReportCalculator().calculate(
      period: HydrationReportPeriod.endingOn(frequency, ending),
      logs: repository.logs,
      generatedAt: ending.add(const Duration(hours: 12)),
      displayLabel: 'Synthetic Hydrion user',
      targetChanges: [
        HydrationReportTargetChange(effectiveDate: start, targetMl: 2200),
      ],
    );
    watch.stop();
    aggregation[frequency.name] = watch.elapsedMicroseconds;
  }

  return {
    'horizon': label,
    'workload': workload,
    'days': days,
    'recordsPerDay': recordsPerDay,
    'recordCount': recordCount,
    'serializedBytes': serializedBytes,
    'bytesPerRecord': serializedBytes / recordCount,
    'datasetGenerationUs': rawWatch.elapsedMicroseconds,
    'loadUs': loadWatch.elapsedMicroseconds,
    'rssBefore': rssBefore,
    'rssAfterLoad': rssAfterLoad,
    'rssLoadDelta': rssAfterLoad - rssBefore,
    'appendAndPersistUs': appendWatch.elapsedMicroseconds,
    'updateAndPersistUs': updateWatch.elapsedMicroseconds,
    'deleteAndPersistUs': deleteWatch.elapsedMicroseconds,
    'lastPersistedBytes': store.lastWriteBytes,
    'reportAggregationUs': aggregation,
  };
}

Future<Map<String, Object?>> _challengeBenchmark({
  required int years,
  required int attempts,
  required String workload,
}) async {
  final history = <Map<String, Object?>>[];
  for (var index = 0; index < attempts; index++) {
    final joined = DateTime(2016, 1 + index, 1, 8);
    history.add({
      'schemaVersion': 6,
      'id': 'desk-day-reset',
      'targetMl': 2200,
      'durationDays': 7,
      'joinedAt': joined.toIso8601String(),
      'bottleBingoCompletedTiles': <int>[],
      'parameters': {
        'optionalNote': 'synthetic',
        'sessionMinutes': 25,
      },
      'completedActionIds': [
        for (var action = 0; action < 10; action++)
          'synthetic-$index-action-$action',
      ],
      'instanceId': 'synthetic-instance-$index',
      'lifecycleStatus': 'completed',
      'endedAt': joined.add(const Duration(days: 7)).toIso8601String(),
    });
  }
  final raw = jsonEncode({
    'schemaVersion': 6,
    'activeChallenges': <Object?>[],
    'challengeHistory': history,
  });
  final store = _RecordingStore({ChallengeRepository.storageKey: raw});
  final rssBefore = ProcessInfo.currentRss;
  final watch = Stopwatch()..start();
  final repository = await ChallengeRepository.load(store);
  watch.stop();
  return {
    'years': years,
    'workload': workload,
    'attempts': attempts,
    'serializedBytes': utf8.encode(raw).length,
    'bytesPerAttempt': utf8.encode(raw).length / attempts,
    'loadUs': watch.elapsedMicroseconds,
    'rssBefore': rssBefore,
    'rssAfterLoad': ProcessInfo.currentRss,
    'loadedHistoryCount': repository.challengeHistory.length,
  };
}

Future<Map<String, Object?>> _thresholdFailureBenchmark() async {
  final initial = jsonEncode([
    for (var index = 0; index < 1000; index++)
      {
        'id': 'synthetic-threshold-$index',
        'volumeMl': 250,
        'timestamp': DateTime(2026, 1, 1)
            .add(Duration(minutes: index))
            .toIso8601String(),
        'source': 'synthetic-threshold',
      },
  ]);
  final store = _RecordingStore(
    {HydrationRepository.storageKey: initial},
    maxWriteBytes: utf8.encode(initial).length,
  );
  final repository = await HydrationRepository.load(store);
  final before = repository.eventCount;
  Object? error;
  try {
    await repository.addLog(
      volumeMl: 250,
      timestamp: DateTime(2027, 1, 1),
      source: 'synthetic-over-threshold',
    );
  } catch (caught) {
    error = caught;
  }
  return {
    'thresholdBytes': store.maxWriteBytes,
    'attemptFailed': error != null,
    'rollbackPreserved': repository.eventCount == before,
    'errorType': error.runtimeType.toString(),
    'note': 'Synthetic threshold; not an Android SharedPreferences limit.',
  };
}

class _RecordingStore implements HydrionLocalStore {
  final Map<String, String> values;
  final int? maxWriteBytes;
  int? lastWriteBytes;

  _RecordingStore(this.values, {this.maxWriteBytes});

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final bytes = utf8.encode(value).length;
    if (maxWriteBytes != null && bytes > maxWriteBytes!) {
      throw const FileSystemException('Synthetic storage threshold exceeded');
    }
    lastWriteBytes = bytes;
    values[key] = value;
  }
}
