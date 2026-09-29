import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/storage/encrypted_app_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late Directory directory;
  late String path;
  final key = Uint8List.fromList(List.generate(32, (i) => i + 1));
  final opened = <EncryptedAppStore>[];
  AppStoreStage? failure;
  Future<EncryptedAppStore> open() async {
    final store = await EncryptedAppStore.open(
        path: path,
        key: key,
        failureInjector: (stage) async {
          if (stage == failure) throw StateError('synthetic private details');
        });
    opened.add(store);
    return store;
  }

  sqlite.Database native() {
    final db = sqlite.sqlite3.open(path);
    final hex = key.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    db.execute('PRAGMA key = "x\'$hex\'"');
    return db;
  }

  setUp(() async {
    failure = null;
    directory = await Directory.systemTemp.createTemp('hydrion-app-pilot-');
    path = '${directory.path}/app.db';
  });
  tearDown(() async {
    for (final store in opened) {
      await store.close();
    }
    opened.clear();
    await directory.delete(recursive: true);
  });

  test('first creation migrates empty schema and reports genuine absence',
      () async {
    final store = await open();
    expect((await store.readDailyContext()).status, ProtectedReadStatus.absent);
    await store.close();
    final db = native();
    expect(db.select('PRAGMA user_version').single['user_version'], 2);
    db.close();
  });

  test('protected fields survive close/reopen with same key', () async {
    var store = await open();
    final record = _record(1);
    expect(
        await store.writeDailyContext(record), ProtectedWriteStatus.committed);
    await store.close();
    store = await open();
    expect(
        (await store.readDailyContext()).record!.equivalentTo(record), isTrue);
    expect(String.fromCharCodes(await File(path).readAsBytes()),
        isNot(contains('vomitingOrDiarrhea')));
    expect(
        String.fromCharCodes(
            await File(path).openRead(0, 16).expand((e) => e).toList()),
        isNot('SQLite format 3\u0000'));
  });

  test('wrong key fails without replacement or plaintext recovery', () async {
    final store = await open();
    await store.writeDailyContext(_record(1));
    await store.close();
    final before = await File(path).readAsBytes();
    await expectLater(
        EncryptedAppStore.open(
            path: path, key: Uint8List.fromList(List.filled(32, 200))),
        throwsA(isA<AppStoreOpenFailure>()));
    expect(await File(path).readAsBytes(), before);
    expect((await (await open()).readDailyContext()).record!.revision, 1);
  });

  test('multi-day records use one canonical order for verified readback',
      () async {
    final store = await open();
    final record = ProtectedContextRecord(
        revision: 1,
        phase: ContextRecordPhase.active,
        contexts: [
          DailyHydrationContext(
              localDateKey: '2026-09-28', updatedAt: DateTime.utc(2026, 9, 28)),
          ..._record(1).contexts,
        ]);
    expect(
        await store.writeDailyContext(record), ProtectedWriteStatus.committed);
    expect(
        (await store.readDailyContext()).record!.equivalentTo(record), isTrue);
  });

  test('failed multi-field replacement rolls back whole logical record',
      () async {
    final store = await open();
    await store.writeDailyContext(_record(1));
    failure = AppStoreStage.recordWritten;
    expect(await store.writeDailyContext(_record(2, minutes: 80)),
        ProtectedWriteStatus.failed);
    expect((await store.readDailyContext()).record!.equivalentTo(_record(1)),
        isTrue);
    failure = null;
    expect(await store.writeDailyContext(_record(2, minutes: 80)),
        ProtectedWriteStatus.committed);
    expect(
        (await store.readDailyContext())
            .record!
            .contexts
            .single
            .activityMinutes,
        80);
  });

  test('post-commit verification failure is not reported as success', () async {
    final store = await open();
    failure = AppStoreStage.beforeVerification;
    expect(await store.writeDailyContext(_record(1)),
        ProtectedWriteStatus.verificationFailed);
    failure = null;
    expect((await store.readDailyContext()).record!.revision, 1);
  });

  test('deletion replaces payload with verified restart-stable tombstone',
      () async {
    var store = await open();
    await store.writeDailyContext(_record(1));
    expect(await store.deleteDailyContext(2),
        ProtectedDeleteStatus.verifiedAbsent);
    await store.close();
    store = await open();
    final read = await store.readDailyContext();
    expect(read.status, ProtectedReadStatus.absent);
    expect(read.record!.contexts, isEmpty);
    expect(read.record!.phase, ContextRecordPhase.deleted);
    expect(read.record!.revision, 2);
  });

  test('failed deletion preserves record and retries', () async {
    final store = await open();
    await store.writeDailyContext(_record(1));
    failure = AppStoreStage.recordWritten;
    expect(await store.deleteDailyContext(2), ProtectedDeleteStatus.failed);
    expect((await store.readDailyContext()).status, ProtectedReadStatus.found);
    failure = null;
    expect(await store.deleteDailyContext(2),
        ProtectedDeleteStatus.verifiedAbsent);
  });

  test('delete verification failure remains explicit', () async {
    final store = await open();
    await store.writeDailyContext(_record(1));
    failure = AppStoreStage.beforeVerification;
    expect(await store.deleteDailyContext(2),
        ProtectedDeleteStatus.verificationFailed);
    failure = null;
    expect(await store.deleteDailyContext(2),
        ProtectedDeleteStatus.verifiedAbsent);
  });

  test('corrupt record is never defaulted or overwritten', () async {
    final store = await open();
    await store.writeDailyContext(_record(1));
    await store.close();
    final db = native();
    db.execute("UPDATE daily_context SET payload = '{}' ");
    db.close();
    final reopened = await open();
    expect((await reopened.readDailyContext()).status,
        ProtectedReadStatus.corrupt);
    expect(await reopened.writeDailyContext(_record(2)),
        ProtectedWriteStatus.failed);
  });

  test('corrupt database remains intact after rejected open', () async {
    final bytes = List<int>.filled(8192, 55);
    await File(path).writeAsBytes(bytes);
    await expectLater(open(), throwsA(isA<AppStoreOpenFailure>()));
    expect(await File(path).readAsBytes(), bytes);
  });

  test('future record schema is unsupported and cannot be overwritten',
      () async {
    final store = await open();
    await store.writeDailyContext(_record(1));
    await store.close();
    final db = native();
    db.execute('UPDATE daily_context SET payload = ?',
        ['{"schemaVersion":99,"contexts":[]}']);
    db.close();
    final reopened = await open();
    expect((await reopened.readDailyContext()).status,
        ProtectedReadStatus.unsupported);
    expect(await reopened.writeDailyContext(_record(2)),
        ProtectedWriteStatus.failed);
  });

  test('live database and sidecars contain no recognizable pilot payload',
      () async {
    final store = await open();
    await store.writeDailyContext(_record(1));
    failure = AppStoreStage.recordWritten;
    await store.writeDailyContext(_record(2, minutes: 80));
    final files =
        await directory.list().where((e) => e is File).cast<File>().toList();
    expect(files, isNotEmpty);
    for (final file in files) {
      final bytes = String.fromCharCodes(await file.readAsBytes());
      for (final marker in [
        'vomitingOrDiarrhea',
        '2026-09-29',
        'mostlyOutdoors',
        'activityMinutes'
      ]) {
        expect(bytes, isNot(contains(marker)),
            reason: 'protected app artifact');
      }
    }
  });

  test('future schema is unsupported and preserved', () async {
    final store = await open();
    await store.close();
    final db = native();
    db.execute('PRAGMA user_version = 99');
    db.close();
    await expectLater(
        open(),
        throwsA(isA<AppStoreOpenFailure>().having(
            (e) => e.status, 'status', ProtectedReadStatus.unsupported)));
    final check = native();
    expect(check.select('PRAGMA user_version').single['user_version'], 99);
    check.close();
  });

  test('initial schema migration failure rolls back and can recover', () async {
    failure = AppStoreStage.schemaCreated;
    await expectLater(open(), throwsA(isA<AppStoreOpenFailure>()));
    final db = native();
    expect(db.select('PRAGMA user_version').single['user_version'], 0);
    expect(
        db.select(
            "SELECT name FROM sqlite_master WHERE name = 'daily_context'"),
        isEmpty);
    db.close();
    failure = null;
    expect((await (await open()).readDailyContext()).status,
        ProtectedReadStatus.absent);
  });

  test('unknown unversioned schema is not repurposed', () async {
    final db = native();
    db.execute('CREATE TABLE unknown_data(value TEXT)');
    db.close();
    await expectLater(open(), throwsA(isA<AppStoreOpenFailure>()));
    final check = native();
    expect(
        check.select(
            "SELECT name FROM sqlite_master WHERE name = 'unknown_data'"),
        hasLength(1));
    check.close();
  });

  test('close is idempotent and closed operations remain unavailable',
      () async {
    final store = await open();
    await store.close();
    await store.close();
    expect((await store.readDailyContext()).status,
        ProtectedReadStatus.unavailable);
    expect(await store.writeDailyContext(_record(1)),
        ProtectedWriteStatus.unavailable);
    expect(
        await store.deleteDailyContext(1), ProtectedDeleteStatus.unavailable);
  });

  test('concurrent opens retain the same versioned record', () async {
    final stores = await Future.wait([open(), open()]);
    expect(await stores.first.writeDailyContext(_record(1)),
        ProtectedWriteStatus.committed);
    expect((await stores.last.readDailyContext()).record!.revision, 1);
  });

  test('stale and conflicting revisions cannot overwrite newer state',
      () async {
    final store = await open();
    await store.writeDailyContext(_record(2));
    expect(
        await store.writeDailyContext(_record(1)), ProtectedWriteStatus.failed);
    expect(await store.writeDailyContext(_record(2, minutes: 80)),
        ProtectedWriteStatus.failed);
    expect((await store.readDailyContext()).record!.equivalentTo(_record(2)),
        isTrue);
  });

  test('unsupported store rejects every mutation without a fallback', () async {
    const store = UnavailableProtectedAppStore();
    expect((await store.readDailyContext()).status,
        ProtectedReadStatus.unsupported);
    expect(await store.writeDailyContext(_record(1)),
        ProtectedWriteStatus.unsupported);
    expect(
        await store.deleteDailyContext(1), ProtectedDeleteStatus.unsupported);
  });

  test('diagnostic strings contain only controlled status names', () {
    expect(_record(1).toString(), 'ProtectedContextRecord(active)');
    expect(const AppStoreOpenFailure(ProtectedReadStatus.corrupt).toString(),
        'AppStoreOpenFailure(corrupt)');
    expect(
        ProtectedContextRead(ProtectedReadStatus.found, _record(1)).toString(),
        'ProtectedContextRead(found)');
  });
}

ProtectedContextRecord _record(int revision, {int minutes = 30}) =>
    ProtectedContextRecord(
        revision: revision,
        phase: ContextRecordPhase.active,
        contexts: [
          DailyHydrationContext(
              localDateKey: '2026-09-29',
              activityIntensity: minutes == 30
                  ? HydrionActivityIntensity.light
                  : HydrionActivityIntensity.vigorous,
              activityMinutes: minutes,
              environment: HydrionEnvironmentExposure.mostlyOutdoors,
              temporaryCondition: HydrionTemporaryCondition.vomitingOrDiarrhea,
              userAdjustmentMl: minutes,
              updatedAt: DateTime.utc(2026, 9, 29))
        ]);
