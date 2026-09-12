import 'dart:io';
import 'dart:typed_data';

import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/repositories/encrypted_health_data_repository.dart';

Future<void> main() async {
  final directory =
      await Directory.systemTemp.createTemp('hydrion-health-bench-');
  final path = '${directory.path}/health.db';
  final key = Uint8List.fromList(List<int>.generate(32, (i) => i + 20));
  final rssBefore = ProcessInfo.currentRss;
  final openWatch = Stopwatch()..start();
  var repository =
      await EncryptedHealthDataRepository.open(path: path, key: key);
  openWatch.stop();

  final typical = _records(1000, dayOffset: 0);
  final typicalWatch = Stopwatch()..start();
  await repository.commitImport(
    records: typical,
    checkpoint: _checkpoint('typical'),
  );
  typicalWatch.stop();

  final heavy = _records(10000, dayOffset: 1, idPrefix: 'heavy');
  final heavyWatch = Stopwatch()..start();
  await repository.commitImport(
    records: heavy,
    checkpoint: _checkpoint('heavy'),
  );
  heavyWatch.stop();

  final queryWatch = Stopwatch()..start();
  final page = await repository.records(
    metrics: {HealthMetric.workout},
    start: DateTime.utc(2026, 9, 12),
    limit: 250,
  );
  queryWatch.stop();

  final updates = heavy.take(100).map((record) {
    return _record(
      id: record.id,
      start: record.startTime,
      value: 45,
      syncVersion: '2',
    );
  }).toList();
  final updateWatch = Stopwatch()..start();
  await repository.commitImport(
    records: updates,
    checkpoint: _checkpoint('updated'),
  );
  updateWatch.stop();

  final rssAfterWrites = ProcessInfo.currentRss;
  await repository.close();
  final sizes = await _databaseBytes(path);

  final reopenWatch = Stopwatch()..start();
  for (var i = 0; i < 10; i++) {
    repository = await EncryptedHealthDataRepository.open(path: path, key: key);
    await repository.close();
  }
  reopenWatch.stop();

  repository = await EncryptedHealthDataRepository.open(path: path, key: key);
  final purgeWatch = Stopwatch()..start();
  final purged = await repository.purgeBefore(DateTime.utc(2026, 9, 13));
  purgeWatch.stop();
  await repository.close();

  stdout.writeln('first_open_ms=${openWatch.elapsedMilliseconds}');
  stdout.writeln('typical_1000_append_ms=${typicalWatch.elapsedMilliseconds}');
  stdout.writeln('heavy_10000_append_ms=${heavyWatch.elapsedMilliseconds}');
  stdout.writeln('indexed_page_250_ms=${queryWatch.elapsedMilliseconds}');
  stdout.writeln('indexed_page_count=${page.length}');
  stdout.writeln('update_100_ms=${updateWatch.elapsedMilliseconds}');
  stdout.writeln('encrypted_files_bytes=$sizes');
  stdout.writeln('rss_delta_bytes=${rssAfterWrites - rssBefore}');
  stdout.writeln('reopen_10_total_ms=${reopenWatch.elapsedMilliseconds}');
  stdout.writeln('purge_${purged}_ms=${purgeWatch.elapsedMilliseconds}');

  await directory.delete(recursive: true);
  stdout.writeln('close_released_files=true');
}

List<CanonicalHealthRecord> _records(
  int count, {
  required int dayOffset,
  String idPrefix = 'typical',
}) {
  final base = DateTime.utc(2026, 9, 11 + dayOffset);
  return List.generate(count, (index) {
    return _record(
      id: '$idPrefix-$index',
      start: base.add(Duration(minutes: index)),
    );
  });
}

CanonicalHealthRecord _record({
  required String id,
  required DateTime start,
  double value = 30,
  String syncVersion = '1',
}) {
  return CanonicalHealthRecord(
    id: id,
    providerId: 'benchmark-provider',
    externalRecordId: id,
    synchronizationVersion: syncVersion,
    metric: HealthMetric.workout,
    semanticId: 'exercise.session.duration',
    value: value,
    unit: HealthUnit.minute,
    startTime: start,
    endTime: start.add(const Duration(minutes: 30)),
    ingestedAt: DateTime.utc(2026, 9, 20),
    shape: HealthRecordShape.interval,
    valueOrigin: HealthValueOrigin.rawSensor,
    provenance: const HealthProvenance(
      sourcePlatform: 'benchmark',
      sourceApplicationId: 'synthetic',
      acquisitionRoute: HealthAcquisitionRoute.test,
      entryMethod: HealthEntryMethod.sensor,
    ),
  );
}

HealthSyncCheckpoint _checkpoint(String cursor) => HealthSyncCheckpoint(
      providerId: 'benchmark-provider',
      metric: HealthMetric.workout,
      cursor: cursor,
      historyStart: DateTime.utc(2026, 9, 1),
      lastSuccessfulSync: DateTime.utc(2026, 9, 20),
    );

Future<int> _databaseBytes(String path) async {
  var total = 0;
  for (final suffix in ['', '-wal', '-shm']) {
    final file = File('$path$suffix');
    if (await file.exists()) total += await file.length();
  }
  return total;
}
