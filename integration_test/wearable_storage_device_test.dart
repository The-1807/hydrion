import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/repositories/encrypted_health_data_repository.dart';
import 'package:hydrion/services/android_health_provider_discovery.dart';
import 'package:hydrion/services/health_database_key_store.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('certifies encrypted wearable storage on Android',
      (tester) async {
    expect(Platform.isAndroid, isTrue);

    final supportDirectory = await getApplicationSupportDirectory();
    final testDirectory = Directory(
      '${supportDirectory.path}/wearable_health_certification',
    );
    await testDirectory.create(recursive: true);
    final databaseFile = File('${testDirectory.path}/synthetic-health.db');

    final keyResult = await PlatformHealthDatabaseKeyStore().obtain(
      databaseExists: await databaseFile.exists(),
    );
    expect(keyResult.status, HealthDatabaseKeyStatus.available);
    final key = keyResult.key!;
    expect(key, hasLength(32));

    const canary = 'HYDRION_SYNTHETIC_CANARY_20260912';
    final firstOpen = Stopwatch()..start();
    var repository = await EncryptedHealthDataRepository.open(
      path: databaseFile.path,
      key: key,
    );
    firstOpen.stop();

    final insertion = Stopwatch()..start();
    await repository.commitImport(
      records: List<CanonicalHealthRecord>.generate(
        1000,
        (index) => _record(index, canary),
      ),
      checkpoint: _checkpoint('batch-1000'),
    );
    insertion.stop();

    final query = Stopwatch()..start();
    final page = await repository.records(
      metrics: const {HealthMetric.workout},
      start: DateTime.utc(2026, 9, 1),
      end: DateTime.utc(2026, 10),
      limit: 250,
    );
    query.stop();
    expect(page, hasLength(250));
    expect(page.first.category, canary);
    expect(
      (await repository.checkpointFor(
        'device-certification',
        HealthMetric.workout,
      ))
          ?.cursor,
      'batch-1000',
    );

    final rollbackRepository = await EncryptedHealthDataRepository.open(
      path: databaseFile.path,
      key: key,
      failureInjector: (stage) async {
        if (stage == HealthRepositoryWriteStage.beforeCheckpoint) {
          throw StateError('synthetic storage failure');
        }
      },
    );
    await expectLater(
      rollbackRepository.commitImport(
        records: [_record(1001, canary)],
        checkpoint: _checkpoint('must-not-commit'),
      ),
      throwsStateError,
    );
    expect(
      await rollbackRepository.checkpointFor(
        'device-certification',
        HealthMetric.workout,
      ),
      isA<HealthSyncCheckpoint>().having(
        (checkpoint) => checkpoint.cursor,
        'cursor',
        'batch-1000',
      ),
    );
    await rollbackRepository.close();

    await repository.close();
    repository = await EncryptedHealthDataRepository.open(
      path: databaseFile.path,
      key: key,
    );
    expect(await repository.records(limit: 1), hasLength(1));

    final cipher = sqlite.sqlite3.open(databaseFile.path);
    cipher.execute('PRAGMA key = "x\'${_hex(key)}\'"');
    final cipherVersion = cipher.select('PRAGMA cipher_version').single.values;
    expect(cipherVersion.single.toString(), isNotEmpty);
    cipher.close();

    final unkeyed = sqlite.sqlite3.open(databaseFile.path);
    expect(
      () => unkeyed.select('SELECT count(*) FROM sqlite_master'),
      throwsA(isA<sqlite.SqliteException>()),
    );
    unkeyed.close();

    await repository.close();
    final beforeWrongKey = await databaseFile.readAsBytes();
    await expectLater(
      EncryptedHealthDataRepository.open(
        path: databaseFile.path,
        key: Uint8List.fromList(List<int>.filled(32, 0xA5)),
      ),
      throwsA(isA<HealthRepositoryOpenException>()),
    );
    expect(await databaseFile.readAsBytes(), beforeWrongKey);

    final sandboxRoot = supportDirectory.parent;
    final forbidden = <String>{base64UrlEncode(key), _hex(key)};
    final plaintextFiles = <String>[];
    final rawKeyFiles = <String>[];
    await for (final entity in sandboxRoot.list(recursive: true)) {
      if (entity is! File) continue;
      final bytes = await entity.readAsBytes();
      final text = latin1.decode(bytes, allowInvalid: true);
      if (entity.path.startsWith(testDirectory.path) && text.contains(canary)) {
        plaintextFiles.add(entity.path);
      }
      if (forbidden.any(text.contains)) rawKeyFiles.add(entity.path);
    }
    expect(plaintextFiles, isEmpty);
    expect(rawKeyFiles, isEmpty);

    final providerEnvironment =
        await const AndroidHealthProviderDiscovery().discover();
    expect(providerEnvironment.phoneManufacturer.toUpperCase(), 'INFINIX');
    expect(providerEnvironment.sdkLevel, 33);
    expect(providerEnvironment.workProfile, isFalse);
    expect(providerEnvironment.manualHydrationAvailable, isTrue);
    final installedCompanions = providerEnvironment.companionServices
        .where((service) => service.installed)
        .map((service) => <String, Object>{
              'packageName': service.packageName,
              'serviceName': service.serviceName,
              'enabled': service.enabled,
              'exportStatus': service.exportStatus.name,
              'route': service.route.name,
            })
        .toList(growable: false);

    final report = <String, Object>{
      'databaseBytes': await databaseFile.length(),
      'firstOpenMs': firstOpen.elapsedMilliseconds,
      'insert1000Ms': insertion.elapsedMilliseconds,
      'indexedPage250Ms': query.elapsedMilliseconds,
      'recordCount': 1000,
      'cipherVersionPresent': true,
      'unkeyedReadRejected': true,
      'wrongKeyRejected': true,
      'plaintextCanaryFiles': 0,
      'rawKeyEncodingFiles': 0,
      'phoneManufacturer': providerEnvironment.phoneManufacturer,
      'phoneModel': providerEnvironment.phoneModel,
      'sdkLevel': providerEnvironment.sdkLevel,
      'googleMobileServicesAvailable':
          providerEnvironment.googleMobileServicesAvailable,
      'googlePlayStoreAvailable': providerEnvironment.googlePlayStoreAvailable,
      'workProfile': providerEnvironment.workProfile,
      'healthConnectBuiltIn': providerEnvironment.healthConnectBuiltIn,
      'healthConnectPackageInstalled':
          providerEnvironment.healthConnectPackageInstalled,
      'healthConnectStatus': providerEnvironment.healthConnectStatus.name,
      'healthPermissionState': providerEnvironment.permissionState.name,
      'healthConnectionState': providerEnvironment.connectionState.name,
      'installedCompanions': installedCompanions,
    };
    await File('${supportDirectory.path}/hwi-certification-report.json')
        .writeAsString(jsonEncode(report), flush: true);
  });
}

CanonicalHealthRecord _record(int index, String canary) {
  final start = DateTime.utc(2026, 9, 1).add(Duration(minutes: index));
  return CanonicalHealthRecord(
    id: 'device-$index',
    providerId: 'device-certification',
    externalRecordId: 'external-$index',
    synchronizationVersion: '1',
    metric: HealthMetric.workout,
    semanticId: 'exercise-session',
    value: 30,
    originalUnit: HealthUnit.minute,
    unit: HealthUnit.minute,
    category: canary,
    startTime: start,
    endTime: start.add(const Duration(minutes: 30)),
    sourceTimeZone: 'UTC',
    sourceUtcOffset: Duration.zero,
    recordedAt: start,
    createdAt: start,
    modifiedAt: start,
    ingestedAt: DateTime.utc(2026, 9, 12),
    temporalPrecision: HealthTemporalPrecision.minute,
    shape: HealthRecordShape.interval,
    valueOrigin: HealthValueOrigin.rawSensor,
    provenance: const HealthProvenance(
      sourcePlatform: 'android',
      sourceApplicationId: 'synthetic.device.certification',
      sourceApplicationName: 'Synthetic Device Certification',
      manufacturer: 'Synthetic',
      deviceModel: 'Synthetic Workout Source',
      acquisitionRoute: HealthAcquisitionRoute.test,
      entryMethod: HealthEntryMethod.sensor,
    ),
    quality: 'synthetic',
  );
}

HealthSyncCheckpoint _checkpoint(String cursor) => HealthSyncCheckpoint(
      providerId: 'device-certification',
      metric: HealthMetric.workout,
      cursor: cursor,
      historyStart: DateTime.utc(2026, 9, 1),
      lastSuccessfulSync: DateTime.utc(2026, 9, 12),
    );

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
