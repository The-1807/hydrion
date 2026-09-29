import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/storage/app_database_key_store.dart';

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('dedicated random key is reused across adapters and concurrent calls',
      () async {
    final storage = _Secure();
    final results = await Future.wait([
      AppDatabaseKeyStore(storage: storage).obtain(databaseExists: false),
      AppDatabaseKeyStore(storage: storage).obtain(databaseExists: false),
    ]);
    expect(results.every((e) => e.status == AppDatabaseKeyStatus.available),
        isTrue);
    expect(results.first.key, hasLength(32));
    expect(results.last.key, results.first.key);
    expect(storage.writes, 1);
    expect(storage.values.keys, [AppDatabaseKeyStore.storageKey]);
    expect(
        storage.android!.toMap()['storageNamespace'], 'hydrion_app_database');
    expect(storage.ios!.toMap()['accountName'],
        'com.the1807.hydrion.app-database');
  });

  test('existing encrypted data with missing key never creates a replacement',
      () async {
    final storage = _Secure();
    final result = await AppDatabaseKeyStore(storage: storage)
        .obtain(databaseExists: true);
    expect(result.status, AppDatabaseKeyStatus.missing);
    expect(storage.writes, 0);
  });

  test('read failure preserves secrets and recovers on retry', () async {
    final storage = _Secure()..failRead = true;
    final store = AppDatabaseKeyStore(storage: storage);
    expect((await store.obtain(databaseExists: false)).status,
        AppDatabaseKeyStatus.unavailable);
    expect(storage.writes, 0);
    storage.failRead = false;
    expect((await store.obtain(databaseExists: false)).status,
        AppDatabaseKeyStatus.available);
  });

  test('creation write failure never returns a usable key', () async {
    final storage = _Secure()..failWrite = true;
    final store = AppDatabaseKeyStore(storage: storage);
    expect((await store.obtain(databaseExists: false)).status,
        AppDatabaseKeyStatus.unavailable);
    expect(storage.values, isEmpty);
    storage.failWrite = false;
    expect((await store.obtain(databaseExists: false)).status,
        AppDatabaseKeyStatus.available);
  });

  test('creation readback mismatch is unavailable', () async {
    final storage = _Secure()..dropWrite = true;
    final result = await AppDatabaseKeyStore(storage: storage)
        .obtain(databaseExists: false);
    expect(result.status, AppDatabaseKeyStatus.unavailable);
    expect(result.key, isNull);
  });

  test('malformed existing key is preserved without regeneration', () async {
    final storage = _Secure()
      ..values[AppDatabaseKeyStore.storageKey] = 'malformed';
    final result = await AppDatabaseKeyStore(storage: storage)
        .obtain(databaseExists: true);
    expect(result.status, AppDatabaseKeyStatus.unavailable);
    expect(storage.values[AppDatabaseKeyStore.storageKey], 'malformed');
    expect(storage.writes, 0);
  });

  test('unsupported desktop never reads or writes a secret', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final storage = _Secure();
    final result = await AppDatabaseKeyStore(storage: storage)
        .obtain(databaseExists: false);
    expect(result.status, AppDatabaseKeyStatus.unsupported);
    expect(storage.reads, 0);
    expect(storage.writes, 0);
  });

  test('key result diagnostics do not expose key bytes', () async {
    final result = await AppDatabaseKeyStore(storage: _Secure())
        .obtain(databaseExists: false);
    expect(result.toString(), 'AppDatabaseKeyResult(available)');
  });
}

class _Secure extends FlutterSecureStorage {
  final values = <String, String>{};
  bool failRead = false, failWrite = false, dropWrite = false;
  int writes = 0, reads = 0;
  AndroidOptions? android;
  AppleOptions? ios;
  @override
  Future<String?> read(
      {required String key,
      AppleOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      AppleOptions? mOptions,
      WindowsOptions? wOptions}) async {
    reads++;
    android = aOptions;
    ios = iOptions;
    if (failRead) throw StateError('private native error');
    return values[key];
  }

  @override
  Future<void> write(
      {required String key,
      required String? value,
      AppleOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      AppleOptions? mOptions,
      WindowsOptions? wOptions}) async {
    writes++;
    if (failWrite) throw StateError('private native error');
    if (!dropWrite && value != null) values[key] = value;
  }
}
