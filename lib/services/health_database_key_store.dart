import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum HealthDatabaseKeyStatus {
  available,
  unsupportedPlatform,
  missingForExistingDatabase,
  inaccessible,
}

class HealthDatabaseKeyResult {
  final HealthDatabaseKeyStatus status;
  final Uint8List? key;

  const HealthDatabaseKeyResult._(this.status, [this.key]);

  const HealthDatabaseKeyResult.unsupported()
      : this._(HealthDatabaseKeyStatus.unsupportedPlatform);

  const HealthDatabaseKeyResult.missing()
      : this._(HealthDatabaseKeyStatus.missingForExistingDatabase);

  const HealthDatabaseKeyResult.inaccessible()
      : this._(HealthDatabaseKeyStatus.inaccessible);

  HealthDatabaseKeyResult.available(Uint8List value)
      : this._(HealthDatabaseKeyStatus.available, value);
}

abstract interface class HealthDatabaseKeyStore {
  Future<HealthDatabaseKeyResult> obtain({required bool databaseExists});
}

class PlatformHealthDatabaseKeyStore implements HealthDatabaseKeyStore {
  static const _storageKey = 'hydrion.health.database.key.v1';
  static const _androidOptions = AndroidOptions(
    resetOnError: false,
    migrateWithBackup: true,
    storageNamespace: 'hydrion_health_database',
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
    accountName: 'com.the1807.hydrion.health-database',
  );

  final FlutterSecureStorage _storage;
  final Random _random;

  PlatformHealthDatabaseKeyStore({
    FlutterSecureStorage? storage,
    Random? random,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _random = random ?? Random.secure();

  @override
  Future<HealthDatabaseKeyResult> obtain({
    required bool databaseExists,
  }) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const HealthDatabaseKeyResult.unsupported();
    }

    try {
      final encoded = await _storage.read(
        key: _storageKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      if (encoded != null) {
        final decoded = base64Url.decode(encoded);
        if (decoded.length != 32) {
          return const HealthDatabaseKeyResult.inaccessible();
        }
        return HealthDatabaseKeyResult.available(Uint8List.fromList(decoded));
      }
      if (databaseExists) {
        return const HealthDatabaseKeyResult.missing();
      }

      final key = Uint8List.fromList(
        List<int>.generate(32, (_) => _random.nextInt(256)),
      );
      final value = base64UrlEncode(key);
      await _storage.write(
        key: _storageKey,
        value: value,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      final verified = await _storage.read(
        key: _storageKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      if (verified != value) {
        return const HealthDatabaseKeyResult.inaccessible();
      }
      return HealthDatabaseKeyResult.available(key);
    } catch (_) {
      return const HealthDatabaseKeyResult.inaccessible();
    }
  }
}

class InjectedHealthDatabaseKeyStore implements HealthDatabaseKeyStore {
  final Uint8List key;

  InjectedHealthDatabaseKeyStore(List<int> key)
      : key = Uint8List.fromList(key) {
    if (this.key.length != 32) {
      throw ArgumentError.value(key.length, 'key', 'must contain 32 bytes');
    }
  }

  @override
  Future<HealthDatabaseKeyResult> obtain({required bool databaseExists}) async {
    return HealthDatabaseKeyResult.available(Uint8List.fromList(key));
  }
}
