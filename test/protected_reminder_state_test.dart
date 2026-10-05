import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/reminder_protection.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/repositories/settings_protection.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/validated_profile_photo.dart';
import 'package:hydrion/storage/encrypted_app_store.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/storage/protected_challenge_record.dart';
import 'package:hydrion/storage/protected_reminder_record.dart';
import 'package:hydrion/storage/protected_settings_record.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'support/memory_protected_app_store.dart';
import 'support/profile_photo_fixture.dart';

const syntheticMessage = 'synthetic-private-reminder-6182';

Map<String, Object?> legacyEntry({
  String id = 'reminder-1',
  String message = syntheticMessage,
  DateTime? at,
  Map<String, Object?> extra = const {},
}) =>
    {
      'id': id,
      'triggerTime': (at ?? DateTime(2030, 7, 1, 9)).toIso8601String(),
      'message': message,
      'priority': 2,
      'enabled': true,
      'scheduleState': 'scheduledExactly',
      'scheduleError': null,
      'lastScheduledAt': DateTime(2030, 6, 30, 9).toIso8601String(),
      'challengeId': null,
      ...extra,
    };

String legacyList(List<Map<String, Object?>> entries) => jsonEncode(entries);

class CleanupStore extends MemoryHydrionStore {
  bool rejectCleanup = false;
  bool rejectWrites = false;
  CleanupStore([super.initialValues]);
  @override
  Future<bool> removeAcknowledged(String key) async =>
      rejectCleanup ? false : super.removeAcknowledged(key);
  @override
  Future<bool> writeString(String key, String value) async =>
      rejectWrites ? false : super.writeString(key, value);
}

class HoldingReminderStore extends MemoryProtectedAppStore {
  Completer<void>? hold;
  @override
  Future<ProtectedWriteStatus> writeReminders(
      ProtectedReminderRecord value) async {
    final gate = hold;
    if (gate != null) await gate.future;
    return super.writeReminders(value);
  }
}

class VerificationLossStore extends MemoryProtectedAppStore {
  bool loseNextRead = false;
  @override
  Future<ProtectedReminderRead> readReminders() async {
    if (loseNextRead) {
      loseNextRead = false;
      return const ProtectedReminderRead(ProtectedReadStatus.unavailable);
    }
    return super.readReminders();
  }
}

Future<ReminderRepository> load(
        HydrionLocalStore prefs, ProtectedAppStore protected) =>
    ReminderRepository.load(prefs, protectedStore: protected);

void main() {
  group('real SQLCipher app store', () {
    late Directory directory;
    late String path;
    final key = Uint8List.fromList(List.generate(32, (i) => 255 - i));
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

    List<Map<String, Object?>> rows(sqlite.Database db, String table) => db
        .select('SELECT * FROM $table')
        .map((row) => {for (final c in row.keys) c: row[c]})
        .toList();

    setUp(() async {
      failure = null;
      directory = await Directory.systemTemp.createTemp('hydrion-i09-');
      path = '${directory.path}/app.db';
    });
    tearDown(() async {
      for (final store in opened) {
        await store.close();
      }
      opened.clear();
      await directory.delete(recursive: true);
    });

    test(
        'schema-3 database upgrades to 4 with context, settings/photo and '
        'challenge rows unchanged', () async {
      // Build every schema-3 table through the accepted record APIs, then
      // return the file to the exact schema-3 shape released at fe4d7ac:
      // schema 4 only adds `reminder_state`.
      final png = await syntheticPng(64, 48);
      final photo = await ValidatedProfilePhoto.fromBytes(png);
      var store = await open();
      expect(
          await store.writeDailyContext(ProtectedContextRecord(
              revision: 3,
              phase: ContextRecordPhase.active,
              contexts: [
                DailyHydrationContext(
                    localDateKey: '2026-10-04',
                    activityIntensity: HydrionActivityIntensity.moderate,
                    activityMinutes: 45,
                    environment: HydrionEnvironmentExposure.mostlyOutdoors,
                    temporaryCondition: HydrionTemporaryCondition.none,
                    userAdjustmentMl: 120,
                    updatedAt: DateTime.utc(2026, 10, 4))
              ])),
          ProtectedWriteStatus.committed);
      final profile = SettingsProtection.profileFrom(const UserSettings(
              locale: ui.Locale('fr'),
              nickname: 'SYNTHETIC-UPGRADE',
              age: 41,
              dailyGoalMl: 2400,
              baselineDailyGoalMl: 2400)
          .toJson());
      expect(
          await store.writeSettings(ProtectedSettingsRecord(
              revision: 2,
              phase: ContextRecordPhase.active,
              profile: profile,
              photo: photo)),
          ProtectedWriteStatus.committed);
      expect(
          await store.writeChallenges(ProtectedChallengeRecord(
              revision: 5,
              phase: ContextRecordPhase.active,
              state: {
                'schemaVersion': 6,
                'activeChallenges': [
                  JoinedChallenge(
                          id: 'plant-twin-challenge',
                          name: 'Plant',
                          description: '',
                          targetMl: 2000,
                          durationDays: 7,
                          joinedAt: DateTime(2026, 9, 30),
                          parameters: const {'cue': 'synthetic-upgrade-cue'})
                      .toJson()
                ],
                'challengeHistory': [],
              })),
          ProtectedWriteStatus.committed);
      await store.close();

      var db = native();
      db.execute('DROP TABLE reminder_state');
      db.execute('PRAGMA user_version = 3');
      final before = {
        for (final table in [
          'daily_context',
          'settings_profile',
          'challenge_state'
        ])
          table: rows(db, table),
      };
      final tables = db
          .select("SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name NOT LIKE 'sqlite_%' ORDER BY name")
          .map((r) => r['name'])
          .toList();
      expect(tables, ['challenge_state', 'daily_context', 'settings_profile']);
      db.close();

      store = await open();
      expect((await store.readReminders()).status, ProtectedReadStatus.absent);
      expect((await store.readDailyContext()).record!.revision, 3);
      final settings = (await store.readSettings()).record!;
      expect(settings.revision, 2);
      expect(settings.photo!.bytes, photo.bytes);
      expect((await store.readChallenges()).record!.revision, 5);
      await store.close();

      db = native();
      expect(db.select('PRAGMA user_version').single['user_version'], 4);
      for (final entry in before.entries) {
        expect(rows(db, entry.key), entry.value, reason: entry.key);
      }
      db.close();

      // Reopening the upgraded schema is a no-op, not a second migration.
      store = await open();
      expect((await store.readChallenges()).record!.revision, 5);
    });

    test('legacy reminders and orphans migrate into one encrypted record',
        () async {
      final store = await open();
      final prefs = MemoryHydrionStore({
        ReminderRepository.storageKey: legacyList([legacyEntry()]),
        ReminderRepository.orphanCleanupStorageKey: jsonEncode([11, 3]),
      });
      final repo = await load(prefs, store);
      expect(repo.storageStatus, ReminderStorageStatus.ready);
      expect(repo.reminders.single.message, syntheticMessage);
      expect(repo.orphanNotificationIds, {3, 11});
      expect(prefs.snapshot, {ReminderProtection.authorityKey: '1'},
          reason: 'only payload-free control metadata remains');
      await repo.close();
      expect(String.fromCharCodes(await File(path).readAsBytes()),
          isNot(contains(syntheticMessage)));
      final reopened = await load(prefs, await open());
      expect(reopened.reminders.single.id, 'reminder-1');
      expect(reopened.orphanNotificationIds, {3, 11});
    });

    for (final stage in [
      AppStoreStage.recordWritten,
      AppStoreStage.beforeVerification,
    ]) {
      test(
          'migration interrupted at ${stage.name} preserves source and retries',
          () async {
        final raw = legacyList([legacyEntry()]);
        final prefs = MemoryHydrionStore({ReminderRepository.storageKey: raw});
        failure = stage;
        final store = await open();
        final repo = await load(prefs, store);
        expect(repo.isKnown, isFalse);
        expect(prefs.snapshot[ReminderRepository.storageKey], raw);
        failure = null;
        await repo.refreshFromStore();
        expect(repo.isKnown, isTrue);
        expect(repo.reminders.single.message, syntheticMessage);
        expect(
            prefs.snapshot.containsKey(ReminderRepository.storageKey), isFalse);
      });
    }

    test('future protected reminder schema is unsupported, never overwritten',
        () async {
      var store = await open();
      final prefs = MemoryHydrionStore();
      final repo = await load(prefs, store);
      await repo.save(
          triggerTime: DateTime(2030, 7, 1), message: 'Water', priority: 1);
      await repo.close();
      final db = native();
      db.execute('UPDATE reminder_state SET schema_version = 99');
      db.close();
      store = await open();
      final reloaded = await load(prefs, store);
      expect(reloaded.storageStatus, ReminderStorageStatus.unsupported);
      await expectLater(
          reloaded.save(
              triggerTime: DateTime(2030, 7, 2), message: 'X', priority: 1),
          throwsA(isA<ReminderStorageUnavailable>()));
      final check = native();
      expect(
          check
              .select('SELECT schema_version FROM reminder_state')
              .single['schema_version'],
          99);
      check.close();
    });

    test('post-commit verification failure is ambiguous, not rolled back',
        () async {
      final store = await open();
      final repo = await load(MemoryHydrionStore(), store);
      failure = AppStoreStage.beforeVerification;
      try {
        await repo.save(
            triggerTime: DateTime(2030, 7, 1), message: 'Water', priority: 1);
        fail('expected typed failure');
      } on ReminderStorageUnavailable catch (error) {
        expect(error.writeStatus, ProtectedWriteStatus.verificationFailed);
        expect(error.definitelyNotCommitted, isFalse);
      }
      failure = null;
      await repo.refreshFromStore();
      expect(repo.reminders.single.message, 'Water');
    });
  });

  group('migration authority', () {
    final quarantined = <String, Map<String, String>>{
      'malformed reminders': {ReminderRepository.storageKey: '[{"id":'},
      'wrong top-level shape': {ReminderRepository.storageKey: '{"a":1}'},
      'future schema': {
        ReminderRepository.storageKey: '{"schemaVersion":2,"reminders":[]}'
      },
      'partially invalid records': {
        ReminderRepository.storageKey: jsonEncode([legacyEntry(), null]),
      },
      'unknown field': {
        ReminderRepository.storageKey: legacyList([
          legacyEntry(extra: {'unclassified': syntheticMessage})
        ]),
      },
      'non-boolean enabled': {
        ReminderRepository.storageKey: legacyList([
          legacyEntry(extra: {'enabled': 'false'})
        ]),
      },
      'invalid challenge link': {
        ReminderRepository.storageKey: legacyList([
          legacyEntry(extra: {'challengeId': 7})
        ]),
      },
      'duplicate identity': {
        ReminderRepository.storageKey:
            legacyList([legacyEntry(), legacyEntry(at: DateTime(2030, 8))]),
      },
      'malformed orphans': {ReminderRepository.orphanCleanupStorageKey: '[1,'},
      'non-list orphans': {ReminderRepository.orphanCleanupStorageKey: '{}'},
      'non-integer orphan': {
        ReminderRepository.orphanCleanupStorageKey: '[1, 2.5]'
      },
      'negative orphan': {ReminderRepository.orphanCleanupStorageKey: '[-4]'},
    };
    for (final entry in quarantined.entries) {
      test('${entry.key} is quarantined with every source byte preserved',
          () async {
        final source = {
          ReminderRepository.storageKey: legacyList([legacyEntry()]),
          ReminderRepository.orphanCleanupStorageKey: '[9]',
          ...entry.value,
        };
        final prefs = MemoryHydrionStore(source);
        final protected = MemoryProtectedAppStore();
        final repo = await load(prefs, protected);
        expect(repo.isKnown, isFalse);
        expect(
            repo.storageStatus,
            entry.key == 'future schema'
                ? ReminderStorageStatus.unsupported
                : ReminderStorageStatus.corrupt);
        expect(repo.reminders, isEmpty);
        expect(repo.orphanNotificationIds, isEmpty);
        expect(protected.reminderWrites, 0);
        // Negative control: the former loader returned an empty writable list
        // and the next save overwrote the preserved source.
        await expectLater(
            repo.save(
                triggerTime: DateTime(2030, 9), message: 'New', priority: 1),
            throwsA(isA<ReminderStorageUnavailable>()));
        await expectLater(repo.recordOrphanNotificationIds([5]),
            throwsA(isA<ReminderStorageUnavailable>()));
        expect(prefs.snapshot, source);
      });
    }

    test('legacy operational fields normalize; identity is preserved',
        () async {
      final legacyAt = DateTime(2030, 7, 3, 8);
      final prefs = MemoryHydrionStore({
        ReminderRepository.storageKey: jsonEncode([
          {
            'triggerTime': legacyAt.toIso8601String(),
            'message': '  Drink   water ',
            'priority': 1,
            'scheduleState': 'scheduled',
            'scheduleError':
                'OS notification scheduling is unsupported on this platform.',
          },
          legacyEntry(
              id: 'reminder-2',
              at: DateTime(2030, 7, 4),
              extra: {'scheduleError': 'time_passed'}),
        ]),
      });
      final repo = await load(prefs, MemoryProtectedAppStore());
      expect(repo.isKnown, isTrue);
      final first = repo.reminders.first;
      final fallbackId = legacyAt.millisecondsSinceEpoch.toString();
      expect(first.id, fallbackId);
      expect(first.platformNotificationId, fallbackId.hashCode & 0x7fffffff,
          reason: 'existing OS notification IDs are not re-derived');
      expect(first.message, 'Drink water');
      expect(first.scheduleState, ReminderScheduleState.scheduledApproximately);
      expect(
          first.scheduleError, ProtectedReminderRecord.legacyUnclassifiedError);
      expect(repo.reminders.last.scheduleError, 'time_passed');
    });

    test('an empty reminder collection keeps a non-empty orphan set', () async {
      final protected = MemoryProtectedAppStore();
      final prefs = MemoryHydrionStore({
        ReminderRepository.orphanCleanupStorageKey: jsonEncode([42, 7])
      });
      final repo = await load(prefs, protected);
      expect(repo.reminders, isEmpty);
      expect(repo.orphanNotificationIds, {7, 42});
      expect(protected.reminderRecord!.orphanNotificationIds, {7, 42});
    });

    test('cleanup failure stays known and pending until retried', () async {
      final prefs = CleanupStore({
        ReminderRepository.storageKey: legacyList([legacyEntry()]),
        ReminderRepository.orphanCleanupStorageKey: '[1]',
      })
        ..rejectCleanup = true;
      final repo = await load(prefs, MemoryProtectedAppStore());
      expect(repo.storageStatus, ReminderStorageStatus.cleanupPending);
      expect(repo.isKnown, isTrue);
      expect(repo.reminders.single.message, syntheticMessage);
      prefs.rejectCleanup = false;
      await repo.refreshFromStore();
      expect(repo.storageStatus, ReminderStorageStatus.ready);
      expect(prefs.snapshot, {ReminderProtection.authorityKey: '1'});
    });

    test('authority reference without protected state never boots empty',
        () async {
      final prefs = MemoryHydrionStore({ReminderProtection.authorityKey: '4'});
      final repo = await load(prefs, MemoryProtectedAppStore());
      expect(repo.storageStatus, ReminderStorageStatus.corrupt);
      expect(repo.isKnown, isFalse);
    });

    test('older protected revision than the reference is corrupt', () async {
      final protected = MemoryProtectedAppStore();
      final prefs = MemoryHydrionStore();
      final repo = await load(prefs, protected);
      await repo.save(
          triggerTime: DateTime(2030, 7, 1), message: 'Water', priority: 1);
      await prefs.writeString(ReminderProtection.authorityKey, '9');
      expect((await load(prefs, protected)).storageStatus,
          ReminderStorageStatus.corrupt);
    });

    for (final conflict in [false, true]) {
      test('provisional restart verifies matching source: conflict=$conflict',
          () async {
        final raw = legacyList([legacyEntry()]);
        final protected = MemoryProtectedAppStore()
          ..reminderRecord = ProtectedReminderRecord(
              revision: 1,
              phase: ContextRecordPhase.provisional,
              state: ReminderRepository.decodeLegacyForMigration(
                  conflict ? legacyList([legacyEntry(message: 'Other')]) : raw,
                  null));
        final prefs = MemoryHydrionStore({ReminderRepository.storageKey: raw});
        final repo = await load(prefs, protected);
        expect(repo.isKnown, !conflict);
        if (conflict) {
          expect(repo.storageStatus, ReminderStorageStatus.corrupt);
          expect(prefs.snapshot[ReminderRepository.storageKey], raw);
          expect(
              protected.reminderRecord!.phase, ContextRecordPhase.provisional);
        }
      });
    }

    test('unsupported platform store has no plaintext or memory fallback',
        () async {
      final prefs = MemoryHydrionStore();
      final repo = await load(prefs, const UnavailableProtectedAppStore());
      expect(repo.storageStatus, ReminderStorageStatus.unsupported);
      await expectLater(
          repo.save(
              triggerTime: DateTime(2030, 7, 1),
              message: syntheticMessage,
              priority: 1),
          throwsA(isA<ReminderStorageUnavailable>()));
      expect(prefs.snapshot, isEmpty);
    });
  });

  group('write authority', () {
    test('rejected protected write publishes nothing and notifies status',
        () async {
      final protected = MemoryProtectedAppStore();
      final prefs = MemoryHydrionStore();
      final repo = await load(prefs, protected);
      final first = await repo.save(
          triggerTime: DateTime(2030, 7, 1), message: 'Water', priority: 1);
      var notifications = 0;
      repo.addListener(() => notifications++);
      protected.reminderWriteFailure = ProtectedWriteStatus.failed;
      try {
        await repo.update(id: first.id, message: syntheticMessage);
        fail('expected typed failure');
      } on ReminderStorageUnavailable catch (error) {
        expect(error.definitelyNotCommitted, isTrue);
      }
      expect(notifications, 1);
      expect(repo.isKnown, isFalse);
      expect(jsonEncode(prefs.snapshot), isNot(contains(syntheticMessage)));
      protected.reminderWriteFailure = null;
      await repo.refreshFromStore();
      expect(repo.reminders.single.message, 'Water');
    });

    test('schema-invalid input is rejected without degrading the store',
        () async {
      final protected = MemoryProtectedAppStore();
      final repo = await load(MemoryHydrionStore(), protected);
      final writes = protected.reminderWrites;
      await expectLater(
          repo.save(
              triggerTime: DateTime(2030, 7, 1),
              message: 'Water',
              priority: 1,
              challengeId: 'not a valid id'),
          throwsArgumentError);
      expect(repo.isKnown, isTrue);
      expect(repo.storageStatus, ReminderStorageStatus.ready);
      expect(protected.reminderWrites, writes);
    });

    test('verification loss after commit is reported as ambiguous', () async {
      final protected = VerificationLossStore();
      final repo = await load(MemoryHydrionStore(), protected);
      protected.loseNextRead = true;
      try {
        await repo.save(
            triggerTime: DateTime(2030, 7, 1), message: 'Water', priority: 1);
        fail('expected typed failure');
      } on ReminderStorageUnavailable catch (error) {
        expect(error.writeStatus, ProtectedWriteStatus.verificationFailed);
      }
      await repo.refreshFromStore();
      expect(repo.reminders.single.message, 'Water');
    });

    test('concurrent mutations serialize without lost updates', () async {
      final protected = HoldingReminderStore();
      final repo = await load(MemoryHydrionStore(), protected);
      protected.hold = Completer<void>();
      final a = repo.save(
          triggerTime: DateTime(2030, 7, 1), message: 'A', priority: 1);
      final b = repo.save(
          triggerTime: DateTime(2030, 7, 1), message: 'B', priority: 1);
      final c = repo.recordOrphanNotificationIds([77]);
      expect(repo.reminders, isEmpty, reason: 'nothing published pre-commit');
      protected.hold!.complete();
      await Future.wait([a, b, c]);
      expect(repo.reminders.map((e) => e.message).toSet(), {'A', 'B'});
      expect(repo.reminders.map((e) => e.id).toSet(), hasLength(2),
          reason: 'colliding trigger times still yield unique identities');
      expect(repo.orphanNotificationIds, {77});
      expect(protected.reminderRecord!.revision, 4);
    });
  });

  group('deletion', () {
    test('deletion retains outstanding and newly orphaned OS IDs', () async {
      final protected = MemoryProtectedAppStore();
      final prefs = MemoryHydrionStore();
      final repo = await load(prefs, protected);
      final saved = await repo.save(
          triggerTime: DateTime(2030, 7, 1), message: 'Water', priority: 1);
      await repo.recordOrphanNotificationIds([5]);
      await repo.clear();
      expect(repo.storageStatus, ReminderStorageStatus.ready);
      expect(repo.reminders, isEmpty);
      expect(repo.orphanNotificationIds, {5, saved.platformNotificationId});
      expect(protected.reminderRecord!.phase, ContextRecordPhase.deleted);
      expect(prefs.snapshot, {
        ReminderProtection.authorityKey:
            protected.reminderRecord!.revision.toString()
      });
      await repo.resolveOrphanNotificationId(5);
      expect(repo.orphanNotificationIds, {saved.platformNotificationId});
      expect(protected.reminderRecord!.phase, ContextRecordPhase.active);
      final reloaded = await load(prefs, protected);
      expect(reloaded.orphanNotificationIds, {saved.platformNotificationId});
      expect(reloaded.reminders, isEmpty);
    });

    test('deletion intent survives restart and finishes before migration',
        () async {
      final protected = MemoryProtectedAppStore();
      final prefs = MemoryHydrionStore();
      final repo = await load(prefs, protected);
      await repo.save(
          triggerTime: DateTime(2030, 7, 1), message: 'Water', priority: 1);
      protected.reminderReadFailure = ProtectedReadStatus.unavailable;
      await expectLater(
          repo.clear(), throwsA(isA<ReminderStorageUnavailable>()));
      expect(repo.storageStatus, ReminderStorageStatus.deletionPending);
      expect(repo.isKnown, isFalse);
      expect(prefs.snapshot[ReminderProtection.deletionKey], isNotNull);
      final pending = await load(prefs, protected);
      expect(pending.storageStatus, ReminderStorageStatus.deletionPending);
      protected.reminderReadFailure = null;
      final finished = await load(prefs, protected);
      expect(finished.storageStatus, ReminderStorageStatus.ready);
      expect(finished.reminders, isEmpty);
      expect(finished.orphanNotificationIds, hasLength(1));
      expect(
          prefs.snapshot.containsKey(ReminderProtection.deletionKey), isFalse);
    });

    test('rejected deletion intent is reported, not silent success', () async {
      final prefs = CleanupStore();
      final repo = await load(prefs, MemoryProtectedAppStore());
      prefs.rejectWrites = true;
      await expectLater(
          repo.clear(), throwsA(isA<ReminderStorageUnavailable>()));
      expect(repo.isKnown, isFalse);
    });

    test('never-migrated legacy cleanup work survives deletion', () async {
      final legacy = legacyList([legacyEntry()]);
      final protected = MemoryProtectedAppStore()
        ..reminderReadFailure = ProtectedReadStatus.unavailable;
      final prefs = MemoryHydrionStore({
        ReminderRepository.storageKey: legacy,
        ReminderRepository.orphanCleanupStorageKey: '[13]',
      });
      final repo = await load(prefs, protected);
      expect(repo.isKnown, isFalse);
      await expectLater(
          repo.clear(), throwsA(isA<ReminderStorageUnavailable>()));
      protected.reminderReadFailure = null;
      final finished = await load(prefs, protected);
      expect(finished.storageStatus, ReminderStorageStatus.ready);
      expect(finished.orphanNotificationIds,
          {13, ScheduledReminder.platformIdFor('reminder-1')});
      expect(prefs.snapshot.keys, [ReminderProtection.authorityKey]);
    });

    test('uninterpretable legacy orphan source is preserved by deletion',
        () async {
      final prefs = MemoryHydrionStore({
        ReminderRepository.storageKey: legacyList([legacyEntry()]),
        ReminderRepository.orphanCleanupStorageKey: '[13,',
      });
      final protected = MemoryProtectedAppStore();
      final repo = await load(prefs, protected);
      expect(repo.storageStatus, ReminderStorageStatus.corrupt);
      await repo.clear();
      expect(repo.storageStatus, ReminderStorageStatus.cleanupPending);
      expect(repo.reminders, isEmpty);
      expect(
          prefs.snapshot[ReminderRepository.orphanCleanupStorageKey], '[13,');
      expect(
          prefs.snapshot.containsKey(ReminderRepository.storageKey), isFalse);
    });
  });

  test('diagnostics never stringify reminder payloads', () {
    final record = ProtectedReminderRecord(
        revision: 1,
        phase: ContextRecordPhase.active,
        state: ReminderRepository.decodeLegacyForMigration(
            legacyList([legacyEntry()]), '[1]'));
    expect(
        '$record ${ProtectedReminderRead(ProtectedReadStatus.found, record)} '
        '${const ReminderStorageUnavailable()}',
        isNot(contains(syntheticMessage)));
  });

  test('closed record schema rejects unclassified diagnostics and fields', () {
    Map<String, Object?> with_(Map<String, Object?> extra) =>
        ProtectedReminderRecord.canonicalState(reminders: [
          {
            ...ScheduledReminder(
                    id: 'reminder-1',
                    triggerTime: DateTime(2030, 7, 1),
                    message: 'Water',
                    priority: 1)
                .toProtectedJson(),
            ...extra,
          }
        ], orphanNotificationIds: const []);
    for (final extra in <Map<String, Object?>>[
      {'scheduleError': 'Free-form private text'},
      {'note': 'x'},
      {'message': ' padded'},
      {'priority': 9},
      {'scheduleState': 'scheduled'},
    ]) {
      expect(
          () => ProtectedReminderRecord(
              revision: 1,
              phase: ContextRecordPhase.active,
              state: with_(extra)),
          throwsFormatException,
          reason: '$extra');
    }
    expect(
        () => ProtectedReminderRecord(
            revision: 1,
            phase: ContextRecordPhase.deleted,
            state: with_(const {})),
        throwsFormatException,
        reason: 'a tombstone holds no reminder definitions');
  });
}
