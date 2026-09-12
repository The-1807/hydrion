import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/services/health_database_key_store.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('generates and then reuses one 256-bit platform-protected key',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final storage = _MemorySecureStorage();
    final keyStore = PlatformHealthDatabaseKeyStore(storage: storage);

    final first = await keyStore.obtain(databaseExists: false);
    final second = await keyStore.obtain(databaseExists: true);

    expect(first.status, HealthDatabaseKeyStatus.available);
    expect(first.key, hasLength(32));
    expect(second.key, first.key);
    expect(storage.lastAndroidOptions, isNotNull);
  });

  test('never generates a replacement when an existing database lost its key',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final storage = _MemorySecureStorage();
    final result = await PlatformHealthDatabaseKeyStore(storage: storage)
        .obtain(databaseExists: true);

    expect(result.status, HealthDatabaseKeyStatus.missingForExistingDatabase);
    expect(storage.values, isEmpty);
  });

  test('maps secure-storage failures to an inaccessible state', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final result = await PlatformHealthDatabaseKeyStore(
      storage: _MemorySecureStorage(throwOnRead: true),
    ).obtain(databaseExists: false);

    expect(result.status, HealthDatabaseKeyStatus.inaccessible);
  });

  test('injected test keys require exactly 256 bits', () {
    expect(
      () => InjectedHealthDatabaseKeyStore(List<int>.filled(31, 1)),
      throwsArgumentError,
    );
    expect(
      InjectedHealthDatabaseKeyStore(List<int>.filled(32, 1)).key,
      hasLength(32),
    );
  });
}

class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};
  final bool throwOnRead;
  AndroidOptions? lastAndroidOptions;

  _MemorySecureStorage({this.throwOnRead = false});

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwOnRead) throw StateError('secure storage unavailable');
    lastAndroidOptions = aOptions;
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    lastAndroidOptions = aOptions;
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
