import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AppDatabaseKeyStatus { available, missing, unavailable, unsupported }

final class AppDatabaseKeyResult {
  final AppDatabaseKeyStatus status;
  final Uint8List? key;
  const AppDatabaseKeyResult(this.status, [this.key]);
  @override
  String toString() => 'AppDatabaseKeyResult(${status.name})';
}

final class AppDatabaseKeyStore {
  static const storageKey = 'hydrion.app.database.key.v1';
  static const androidOptions = AndroidOptions(
    resetOnError: false,
    migrateWithBackup: true,
    storageNamespace: 'hydrion_app_database',
  );
  static const iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
    accountName: 'com.the1807.hydrion.app-database',
  );
  // Creation is serialized across adapters in this isolate. No cached secret:
  // every attempt reads the native store, including retries after failures.
  static Future<void> _tail = Future.value();
  final FlutterSecureStorage _storage;
  AppDatabaseKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<AppDatabaseKeyResult> obtain({required bool databaseExists}) {
    final result = _tail.then((_) => _obtain(databaseExists));
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<AppDatabaseKeyResult> _obtain(bool databaseExists) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const AppDatabaseKeyResult(AppDatabaseKeyStatus.unsupported);
    }
    try {
      final encoded = await _storage.read(
          key: storageKey, aOptions: androidOptions, iOptions: iosOptions);
      if (encoded != null) {
        final decoded = base64Url.decode(encoded);
        return decoded.length == 32
            ? AppDatabaseKeyResult(AppDatabaseKeyStatus.available, decoded)
            : const AppDatabaseKeyResult(AppDatabaseKeyStatus.unavailable);
      }
      if (databaseExists) {
        return const AppDatabaseKeyResult(AppDatabaseKeyStatus.missing);
      }
      final random = Random.secure();
      final key =
          Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
      final value = base64UrlEncode(key);
      await _storage.write(
          key: storageKey,
          value: value,
          aOptions: androidOptions,
          iOptions: iosOptions);
      final verified = await _storage.read(
          key: storageKey, aOptions: androidOptions, iOptions: iosOptions);
      return verified == value
          ? AppDatabaseKeyResult(AppDatabaseKeyStatus.available, key)
          : const AppDatabaseKeyResult(AppDatabaseKeyStatus.unavailable);
    } catch (_) {
      return const AppDatabaseKeyResult(AppDatabaseKeyStatus.unavailable);
    }
  }
}
