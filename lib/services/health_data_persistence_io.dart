import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../repositories/encrypted_health_data_repository.dart';
import 'health_data_persistence_types.dart';
import 'health_database_key_store.dart';

Future<HealthPersistenceResult> initializeHealthDataPersistence() async {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return const HealthPersistenceResult(
      HealthPersistenceStatus.unsupportedPlatform,
    );
  }

  try {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory('${supportDirectory.path}/wearable_health');
    final database = File('${directory.path}/health.db');
    final keyResult = await PlatformHealthDatabaseKeyStore().obtain(
      databaseExists: await database.exists(),
    );
    switch (keyResult.status) {
      case HealthDatabaseKeyStatus.unsupportedPlatform:
        return const HealthPersistenceResult(
          HealthPersistenceStatus.unsupportedPlatform,
        );
      case HealthDatabaseKeyStatus.missingForExistingDatabase:
        return const HealthPersistenceResult(
          HealthPersistenceStatus.missingKey,
        );
      case HealthDatabaseKeyStatus.inaccessible:
        return const HealthPersistenceResult(
          HealthPersistenceStatus.inaccessibleKey,
        );
      case HealthDatabaseKeyStatus.available:
        break;
    }

    await directory.create(recursive: true);
    final repository = await EncryptedHealthDataRepository.open(
      path: database.path,
      key: keyResult.key!,
    );
    return HealthPersistenceResult(
      HealthPersistenceStatus.ready,
      repository: repository,
    );
  } on HealthRepositoryOpenException {
    return const HealthPersistenceResult(
      HealthPersistenceStatus.unreadableOrCorrupt,
    );
  } catch (_) {
    return const HealthPersistenceResult(
      HealthPersistenceStatus.unreadableOrCorrupt,
    );
  }
}
