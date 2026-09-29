import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/storage/app_database_key_store.dart';
import 'package:hydrion/storage/app_persistence_io.dart';
import 'package:hydrion/storage/protected_app_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory support;
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterSecureStorage.setMockInitialValues({});
    support = await Directory.systemTemp.createTemp('hydrion-app-initialize-');
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await support.delete(recursive: true);
  });

  test('composition uses isolated directory and reopened key', () async {
    var store = await openProtectedAppStore(supportDirectory: support);
    expect((await store.readDailyContext()).status, ProtectedReadStatus.absent);
    await store.close();
    expect(await File('${support.path}/protected_app/app.db').exists(), isTrue);
    expect(
        await Directory('${support.path}/wearable_health').exists(), isFalse);
    final key = await const FlutterSecureStorage()
        .read(key: AppDatabaseKeyStore.storageKey);
    expect(key, isNotNull);
    store = await openProtectedAppStore(supportDirectory: support);
    expect((await store.readDailyContext()).status, ProtectedReadStatus.absent);
    await store.close();
    expect(
        await const FlutterSecureStorage()
            .read(key: AppDatabaseKeyStore.storageKey),
        key);
  });

  test(
      'lost key with real encrypted file preserves bytes and never regenerates',
      () async {
    final store = await openProtectedAppStore(supportDirectory: support);
    await store.close();
    final file = File('${support.path}/protected_app/app.db');
    final bytes = await file.readAsBytes();
    FlutterSecureStorage.setMockInitialValues({});
    final unavailable = await openProtectedAppStore(supportDirectory: support);
    expect((await unavailable.readDailyContext()).status,
        ProtectedReadStatus.unavailable);
    expect(await file.readAsBytes(), bytes);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  test('orphan encrypted sidecar blocks replacement key and new database',
      () async {
    final directory = await Directory('${support.path}/protected_app').create();
    final wal = File('${directory.path}/app.db-wal');
    await wal.writeAsBytes([1, 2, 3, 4]);
    final store = await openProtectedAppStore(supportDirectory: support);
    expect((await store.readDailyContext()).status,
        ProtectedReadStatus.unavailable);
    expect(await File('${directory.path}/app.db').exists(), isFalse);
    expect(await wal.readAsBytes(), [1, 2, 3, 4]);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  test('unsupported platform creates neither files nor key', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final store = await openProtectedAppStore(supportDirectory: support);
    expect((await store.readDailyContext()).status,
        ProtectedReadStatus.unsupported);
    expect(await support.list().toList(), isEmpty);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });
}
