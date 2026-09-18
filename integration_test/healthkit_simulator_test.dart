import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/repositories/encrypted_health_data_repository.dart';
import 'package:hydrion/services/health_database_key_store.dart';
import 'package:hydrion/services/health_kit_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

// Run only in the fresh validation simulator. This entrypoint never writes to
// HealthKit and is not included by the production lib/main.dart entrypoint.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(defaultTargetPlatform, TargetPlatform.iOS);
    expect(
      const bool.fromEnvironment('HYDRION_SIMULATOR_VALIDATION'),
      isTrue,
      reason: 'Explicitly select the isolated simulator and opt in with '
          '--dart-define=HYDRION_SIMULATOR_VALIDATION=true.',
    );
    // On-device Dart processes do not inherit the host shell's environment;
    // only compile-time --dart-define values reach them, consistent with the
    // HYDRION_SIMULATOR_VALIDATION guard above.
    expect(const String.fromEnvironment('SIMULATOR_UDID'), isNotEmpty,
        reason: 'This synthetic validation must not run on a physical device.');
  });

  testWidgets(
      'registered native bridge reports availability and opaque consent',
      (tester) async {
    const provider = AppleHealthKitProvider();
    expect((await provider.availability()).status,
        HealthProviderAvailabilityStatus.available);
    final state = await provider.authorizationState(provider.connectionMetrics);
    expect(state.status, HealthPermissionStatus.notRequested);
    expect(state.grantedMetrics, isEmpty);
    // No permission prompt: requesting access remains an explicit UI action.
  });

  testWidgets(
      'simulator Keychain and SQLCipher preserve atomic encrypted state',
      (tester) async {
    final directory = await Directory.systemTemp.createTemp('hk-validation-');
    final path = '${directory.path}/health.db';
    EncryptedHealthDataRepository? repository;
    try {
      final firstKey = await PlatformHealthDatabaseKeyStore().obtain(
        databaseExists: false,
      );
      expect(firstKey.status, HealthDatabaseKeyStatus.available);
      final key = firstKey.key!;
      repository =
          await EncryptedHealthDataRepository.open(path: path, key: key);
      final now = DateTime.utc(2026, 9, 17, 12);
      final record = CanonicalHealthRecord(
        id: 'simulator-synthetic-record',
        providerId: AppleHealthKitProvider.id,
        externalRecordId: 'simulator-synthetic-source-uuid',
        synchronizationVersion: 'v1',
        metric: HealthMetric.steps,
        semanticId: 'activity.steps',
        value: 1234,
        originalUnit: HealthUnit.count,
        unit: HealthUnit.count,
        shape: HealthRecordShape.interval,
        valueOrigin: HealthValueOrigin.rawSensor,
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        ingestedAt: now,
        provenance: const HealthProvenance(
          sourcePlatform: 'ios',
          sourceApplicationId: 'synthetic.simulator.fixture',
          acquisitionRoute: HealthAcquisitionRoute.healthKit,
          entryMethod: HealthEntryMethod.manual,
        ),
      );
      final checkpoint = HealthSyncCheckpoint(
        providerId: AppleHealthKitProvider.id,
        metric: HealthMetric.steps,
        historyStart: now.subtract(const Duration(days: 30)),
        cursor: 'synthetic-checkpoint',
      );
      await repository.commitImport(records: [record], checkpoint: checkpoint);
      await repository.close();
      repository = null;

      final restoredKey = await PlatformHealthDatabaseKeyStore().obtain(
        databaseExists: true,
      );
      expect(restoredKey.status, HealthDatabaseKeyStatus.available);
      // Compare as a boolean so a failing assertion never prints key bytes.
      expect(listEquals(key, restoredKey.key), isTrue);
      repository = await EncryptedHealthDataRepository.open(
        path: path,
        key: restoredKey.key!,
      );
      expect((await repository.records()).single.value, 1234);
      expect(
        (await repository.checkpointFor(
                AppleHealthKitProvider.id, HealthMetric.steps))
            ?.cursor,
        'synthetic-checkpoint',
      );
      await repository.close();
      repository = null;

      final unkeyed = sqlite.sqlite3.open(path);
      try {
        expect(unkeyed.select('PRAGMA cipher_version'), isNotEmpty);
        expect(() => unkeyed.select('SELECT count(*) FROM sqlite_master'),
            throwsA(isA<sqlite.SqliteException>()));
      } finally {
        unkeyed.close();
      }
      final wrongKey = Uint8List.fromList(key)..[0] ^= 0xff;
      await expectLater(
        EncryptedHealthDataRepository.open(path: path, key: wrongKey),
        throwsA(isA<HealthRepositoryOpenException>()),
      );

      repository = await EncryptedHealthDataRepository.open(
        path: path,
        key: key,
        failureInjector: (stage) async {
          if (stage == HealthRepositoryWriteStage.beforeCheckpoint) {
            throw StateError('synthetic_transaction_failure');
          }
        },
      );
      await expectLater(
        repository.commitImport(
          records: [record.asDeleted(ingestedAt: now)],
          checkpoint: HealthSyncCheckpoint(
            providerId: checkpoint.providerId,
            metric: checkpoint.metric,
            historyStart: checkpoint.historyStart,
            cursor: 'must-not-advance',
          ),
        ),
        throwsStateError,
      );
      expect((await repository.records()).length, 1);
      expect(
        (await repository.checkpointFor(
                AppleHealthKitProvider.id, HealthMetric.steps))
            ?.cursor,
        'synthetic-checkpoint',
      );
      await repository.close();
      repository = null;

      final secretForms = [
        base64UrlEncode(key),
        base64Encode(key),
        key.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
      ];
      await for (final entity in directory.list(recursive: true)) {
        if (entity is! File) continue;
        final bytes = await entity.readAsBytes();
        final text = latin1.decode(bytes);
        expect(text.contains('SQLite format 3'), isFalse);
        expect(text.contains('synthetic.simulator.fixture'), isFalse);
        expect(text.contains('synthetic-checkpoint'), isFalse);
        expect(secretForms.any(text.contains), isFalse);
      }
    } finally {
      await repository?.close();
      await directory.delete(recursive: true);
    }
  });
}
