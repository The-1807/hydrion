import 'dart:typed_data';
import 'dart:convert';

import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sqlite_async/native.dart';
import 'package:sqlite_async/sqlite_async.dart';

import 'protected_app_store.dart';
import 'protected_settings_record.dart';
import 'protected_challenge_record.dart';
import 'protected_reminder_record.dart';
import '../services/validated_profile_photo.dart';

enum AppStoreStage { schemaCreated, recordWritten, beforeVerification }

final class AppStoreOpenFailure implements Exception {
  final ProtectedReadStatus status;
  const AppStoreOpenFailure(this.status);
  @override
  String toString() => 'AppStoreOpenFailure(${status.name})';
}

final class _AppDatabaseFactory extends NativeSqliteOpenFactory {
  final String _key;
  _AppDatabaseFactory({required super.path, required Uint8List key})
      : _key = key.map((e) => e.toRadixString(16).padLeft(2, '0')).join(),
        super(sqliteOptions: const SqliteOptions(maxReaders: 1));

  @override
  void configureConnection(sqlite.Database db, SqliteOpenOptions options) {
    db.execute('PRAGMA key = "x\'$_key\'"');
    db.execute('PRAGMA cipher_memory_security = ON');
    db.execute('PRAGMA temp_store = MEMORY');
    final cipher = db.select('PRAGMA cipher_version');
    if (cipher.isEmpty || cipher.first.values.first.toString().isEmpty) {
      throw const AppStoreOpenFailure(ProtectedReadStatus.unavailable);
    }
    db.select('SELECT count(*) FROM sqlite_master');
    super.configureConnection(db, options);
  }
}

/// Separate app-data database. Health schemas, keys and deletion are not used.
/// Operations serialize per instance, with one repository writer per dataset
/// in an isolate. SQLite transactions coordinate connections to the same app
/// database. Native commit/readback is not physical-durability evidence.
final class EncryptedAppStore
    implements
        ProtectedAppStore,
        ProtectedSettingsStore,
        ProtectedChallengeStore,
        ProtectedReminderStore {
  static const schemaVersion = 4;
  final SqliteDatabase _db;
  final Future<void> Function(AppStoreStage)? _failureInjector;
  Future<void> _tail = Future.value();
  bool _closed = false;

  EncryptedAppStore._(this._db, this._failureInjector);

  static Future<EncryptedAppStore> open({
    required String path,
    required Uint8List key,
    Future<void> Function(AppStoreStage)? failureInjector,
  }) async {
    if (key.length != 32) {
      throw const AppStoreOpenFailure(ProtectedReadStatus.unavailable);
    }
    final db =
        SqliteDatabase.withFactory(_AppDatabaseFactory(path: path, key: key));
    final store = EncryptedAppStore._(db, failureInjector);
    try {
      await db.initialize();
      await db.writeTransaction((tx) async {
        final version = (await tx.get('PRAGMA user_version'))['user_version'];
        if (version is! int || version < 0 || version > schemaVersion) {
          throw const AppStoreOpenFailure(ProtectedReadStatus.unsupported);
        }
        if (version == 0) {
          // Version zero is accepted only for an empty database, never as a
          // license to overwrite an unknown or malformed existing schema.
          final tables = await tx.getAll(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'");
          if (tables.isNotEmpty) {
            throw const AppStoreOpenFailure(ProtectedReadStatus.corrupt);
          }
          await tx.execute('''CREATE TABLE daily_context (
            singleton INTEGER PRIMARY KEY CHECK(singleton = 1),
            revision INTEGER NOT NULL CHECK(revision > 0),
            phase TEXT NOT NULL CHECK(phase IN ('provisional', 'active', 'deleted')),
            payload TEXT NOT NULL
          ) STRICT''');
          await failureInjector?.call(AppStoreStage.schemaCreated);
          await tx.execute('PRAGMA user_version = 1');
        }
        await tx.getAll(
            'SELECT singleton, revision, phase, payload FROM daily_context');
        if (version == 0 || version == 1) {
          await tx.execute('''CREATE TABLE settings_profile (
            singleton INTEGER PRIMARY KEY CHECK(singleton = 1),
            schema_version INTEGER NOT NULL,
            revision INTEGER NOT NULL CHECK(revision > 0),
            phase TEXT NOT NULL CHECK(phase IN ('provisional', 'active', 'deleted')),
            profile TEXT NOT NULL,
            photo BLOB,
            width INTEGER,
            height INTEGER,
            CHECK((photo IS NULL AND width IS NULL AND height IS NULL) OR
              (photo IS NOT NULL AND length(photo) <= 1200000 AND
               width BETWEEN 1 AND 720 AND height BETWEEN 1 AND 720))
          ) STRICT''');
          await tx.execute('PRAGMA user_version = 2');
        }
        await tx.getAll(
            'SELECT singleton, schema_version, revision, phase, profile, photo, width, height FROM settings_profile');
        // Each table is created exactly once, by the upgrade step that
        // introduced it; later upgrades never recreate earlier tables.
        if (version <= 2) {
          await tx.execute('''CREATE TABLE challenge_state (
            singleton INTEGER PRIMARY KEY CHECK(singleton = 1),
            schema_version INTEGER NOT NULL,
            revision INTEGER NOT NULL CHECK(revision > 0),
            phase TEXT NOT NULL CHECK(phase IN ('provisional', 'active', 'deleted')),
            payload TEXT NOT NULL
          ) STRICT''');
          await tx.execute('PRAGMA user_version = 3');
        }
        await tx.getAll(
            'SELECT singleton, schema_version, revision, phase, payload FROM challenge_state');
        if (version <= 3) {
          await tx.execute('''CREATE TABLE reminder_state (
            singleton INTEGER PRIMARY KEY CHECK(singleton = 1),
            schema_version INTEGER NOT NULL,
            revision INTEGER NOT NULL CHECK(revision > 0),
            phase TEXT NOT NULL CHECK(phase IN ('provisional', 'active', 'deleted')),
            payload TEXT NOT NULL
          ) STRICT''');
          await tx.execute('PRAGMA user_version = 4');
        }
        await tx.getAll(
            'SELECT singleton, schema_version, revision, phase, payload FROM reminder_state');
      });
      return store;
    } catch (error) {
      try {
        await db.close();
      } catch (_) {
        // Preserve the classified open failure, not native SQL/key details.
      }
      if (error is AppStoreOpenFailure) rethrow;
      throw const AppStoreOpenFailure(ProtectedReadStatus.corrupt);
    }
  }

  Future<T> _run<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  ProtectedChallengeRecord _challengeFromRow(Map<String, dynamic> row) {
    if (row['schema_version'] != ProtectedChallengeRecord.schemaVersion) {
      throw const ProtectedContextSchemaUnsupported();
    }
    return ProtectedChallengeRecord(
      revision: row['revision'] as int,
      phase: ContextRecordPhase.values.byName(row['phase'] as String),
      state:
          (jsonDecode(row['payload'] as String) as Map).cast<String, Object?>(),
    );
  }

  Future<ProtectedChallengeRead> _readChallenges() async {
    if (_closed) {
      return const ProtectedChallengeRead(ProtectedReadStatus.unavailable);
    }
    try {
      final rows =
          await _db.getAll('SELECT * FROM challenge_state WHERE singleton = 1');
      if (rows.isEmpty) {
        return const ProtectedChallengeRead(ProtectedReadStatus.absent);
      }
      final record = _challengeFromRow(rows.single);
      return ProtectedChallengeRead(
          record.phase == ContextRecordPhase.deleted
              ? ProtectedReadStatus.absent
              : ProtectedReadStatus.found,
          record);
    } on ProtectedContextSchemaUnsupported {
      return const ProtectedChallengeRead(ProtectedReadStatus.unsupported);
    } on FormatException {
      return const ProtectedChallengeRead(ProtectedReadStatus.corrupt);
    } on ArgumentError {
      return const ProtectedChallengeRead(ProtectedReadStatus.corrupt);
    } on TypeError {
      return const ProtectedChallengeRead(ProtectedReadStatus.corrupt);
    } catch (_) {
      return const ProtectedChallengeRead(ProtectedReadStatus.unavailable);
    }
  }

  @override
  Future<ProtectedChallengeRead> readChallenges() => _run(_readChallenges);

  @override
  Future<ProtectedWriteStatus> writeChallenges(
          ProtectedChallengeRecord record) =>
      _run(() async {
        if (_closed) return ProtectedWriteStatus.unavailable;
        try {
          await _db.writeTransaction((tx) async {
            final rows = await tx
                .getAll('SELECT * FROM challenge_state WHERE singleton = 1');
            if (rows.isNotEmpty) {
              final old = _challengeFromRow(rows.single);
              final activation = old.phase == ContextRecordPhase.provisional &&
                  record.phase == ContextRecordPhase.active &&
                  old.encodePayload() == record.encodePayload();
              if (old.revision > record.revision ||
                  (old.revision == record.revision &&
                      !old.equivalentTo(record) &&
                      !activation)) {
                throw const FormatException('Conflicting challenge revision');
              }
            }
            await tx.execute(
                '''INSERT INTO challenge_state
          (singleton, schema_version, revision, phase, payload) VALUES(1, ?, ?, ?, ?)
          ON CONFLICT(singleton) DO UPDATE SET schema_version = excluded.schema_version,
          revision = excluded.revision, phase = excluded.phase, payload = excluded.payload''',
                [
                  ProtectedChallengeRecord.schemaVersion,
                  record.revision,
                  record.phase.name,
                  record.encodePayload()
                ]);
            await _failureInjector?.call(AppStoreStage.recordWritten);
          });
        } catch (_) {
          return ProtectedWriteStatus.failed;
        }
        try {
          await _failureInjector?.call(AppStoreStage.beforeVerification);
          return (await _readChallenges()).record?.equivalentTo(record) == true
              ? ProtectedWriteStatus.committed
              : ProtectedWriteStatus.verificationFailed;
        } catch (_) {
          return ProtectedWriteStatus.verificationFailed;
        }
      });

  ProtectedReminderRecord _reminderFromRow(Map<String, dynamic> row) {
    if (row['schema_version'] != ProtectedReminderRecord.schemaVersion) {
      throw const ProtectedContextSchemaUnsupported();
    }
    return ProtectedReminderRecord(
      revision: row['revision'] as int,
      phase: ContextRecordPhase.values.byName(row['phase'] as String),
      state:
          (jsonDecode(row['payload'] as String) as Map).cast<String, Object?>(),
    );
  }

  Future<ProtectedReminderRead> _readReminders() async {
    if (_closed) {
      return const ProtectedReminderRead(ProtectedReadStatus.unavailable);
    }
    try {
      final rows =
          await _db.getAll('SELECT * FROM reminder_state WHERE singleton = 1');
      if (rows.isEmpty) {
        return const ProtectedReminderRead(ProtectedReadStatus.absent);
      }
      final record = _reminderFromRow(rows.single);
      return ProtectedReminderRead(
          record.phase == ContextRecordPhase.deleted
              ? ProtectedReadStatus.absent
              : ProtectedReadStatus.found,
          record);
    } on ProtectedContextSchemaUnsupported {
      return const ProtectedReminderRead(ProtectedReadStatus.unsupported);
    } on FormatException {
      return const ProtectedReminderRead(ProtectedReadStatus.corrupt);
    } on ArgumentError {
      return const ProtectedReminderRead(ProtectedReadStatus.corrupt);
    } on TypeError {
      return const ProtectedReminderRead(ProtectedReadStatus.corrupt);
    } catch (_) {
      return const ProtectedReminderRead(ProtectedReadStatus.unavailable);
    }
  }

  @override
  Future<ProtectedReminderRead> readReminders() => _run(_readReminders);

  @override
  Future<ProtectedWriteStatus> writeReminders(ProtectedReminderRecord record) =>
      _run(() async {
        if (_closed) return ProtectedWriteStatus.unavailable;
        try {
          await _db.writeTransaction((tx) async {
            final rows = await tx
                .getAll('SELECT * FROM reminder_state WHERE singleton = 1');
            if (rows.isNotEmpty) {
              final old = _reminderFromRow(rows.single);
              final activation = old.phase == ContextRecordPhase.provisional &&
                  record.phase == ContextRecordPhase.active &&
                  old.encodePayload() == record.encodePayload();
              if (old.revision > record.revision ||
                  (old.revision == record.revision &&
                      !old.equivalentTo(record) &&
                      !activation)) {
                throw const FormatException('Conflicting reminder revision');
              }
            }
            await tx.execute(
                '''INSERT INTO reminder_state
          (singleton, schema_version, revision, phase, payload) VALUES(1, ?, ?, ?, ?)
          ON CONFLICT(singleton) DO UPDATE SET schema_version = excluded.schema_version,
          revision = excluded.revision, phase = excluded.phase, payload = excluded.payload''',
                [
                  ProtectedReminderRecord.schemaVersion,
                  record.revision,
                  record.phase.name,
                  record.encodePayload()
                ]);
            await _failureInjector?.call(AppStoreStage.recordWritten);
          });
        } catch (_) {
          return ProtectedWriteStatus.failed;
        }
        try {
          await _failureInjector?.call(AppStoreStage.beforeVerification);
          return (await _readReminders()).record?.equivalentTo(record) == true
              ? ProtectedWriteStatus.committed
              : ProtectedWriteStatus.verificationFailed;
        } catch (_) {
          return ProtectedWriteStatus.verificationFailed;
        }
      });

  Future<ProtectedContextRead> _read() async {
    if (_closed) {
      return const ProtectedContextRead(ProtectedReadStatus.unavailable);
    }
    try {
      final rows = await _db.getAll(
          'SELECT revision, phase, payload FROM daily_context WHERE singleton = 1');
      if (rows.isEmpty) {
        return const ProtectedContextRead(ProtectedReadStatus.absent);
      }
      final row = rows.single;
      final record = ProtectedContextRecord(
        revision: row['revision'] as int,
        phase: ContextRecordPhase.values.byName(row['phase'] as String),
        contexts:
            ProtectedContextRecord.decodePayload(row['payload'] as String),
      );
      return ProtectedContextRead(
        record.phase == ContextRecordPhase.deleted
            ? ProtectedReadStatus.absent
            : ProtectedReadStatus.found,
        record,
      );
    } on ProtectedContextSchemaUnsupported {
      return const ProtectedContextRead(ProtectedReadStatus.unsupported);
    } on FormatException {
      return const ProtectedContextRead(ProtectedReadStatus.corrupt);
    } on ArgumentError {
      return const ProtectedContextRead(ProtectedReadStatus.corrupt);
    } on TypeError {
      return const ProtectedContextRead(ProtectedReadStatus.corrupt);
    } catch (_) {
      return const ProtectedContextRead(ProtectedReadStatus.unavailable);
    }
  }

  @override
  Future<ProtectedContextRead> readDailyContext() => _run(_read);

  Future<ProtectedWriteStatus> _write(ProtectedContextRecord record) async {
    if (_closed) return ProtectedWriteStatus.unavailable;
    try {
      await _db.writeTransaction((tx) async {
        final previous = await tx.getAll(
            'SELECT revision, phase, payload FROM daily_context WHERE singleton = 1');
        if (previous.isNotEmpty &&
            (previous.single['revision'] as int) > record.revision) {
          throw const FormatException('Stale protected revision');
        }
        if (previous.isNotEmpty) {
          final row = previous.single;
          final old = ProtectedContextRecord(
            revision: row['revision'] as int,
            phase: ContextRecordPhase.values.byName(row['phase'] as String),
            contexts:
                ProtectedContextRecord.decodePayload(row['payload'] as String),
          );
          if (old.revision == record.revision &&
              !old.equivalentTo(record) &&
              !(old.phase == ContextRecordPhase.provisional &&
                  record.phase == ContextRecordPhase.active &&
                  old.encodePayload() == record.encodePayload())) {
            throw const FormatException('Conflicting protected revision');
          }
        }
        await tx.execute(
            '''INSERT INTO daily_context(singleton, revision, phase, payload)
          VALUES(1, ?, ?, ?) ON CONFLICT(singleton) DO UPDATE SET
          revision = excluded.revision, phase = excluded.phase, payload = excluded.payload''',
            [record.revision, record.phase.name, record.encodePayload()]);
        await _failureInjector?.call(AppStoreStage.recordWritten);
      });
    } catch (_) {
      return ProtectedWriteStatus.failed;
    }
    try {
      await _failureInjector?.call(AppStoreStage.beforeVerification);
      final verified = await _read();
      return verified.record?.equivalentTo(record) == true
          ? ProtectedWriteStatus.committed
          : ProtectedWriteStatus.verificationFailed;
    } catch (_) {
      return ProtectedWriteStatus.verificationFailed;
    }
  }

  @override
  Future<ProtectedWriteStatus> writeDailyContext(
          ProtectedContextRecord record) =>
      _run(() => _write(record));

  @override
  Future<ProtectedDeleteStatus> deleteDailyContext(int revision) =>
      _run(() async {
        final result = await _write(ProtectedContextRecord(
          revision: revision,
          phase: ContextRecordPhase.deleted,
          contexts: const [],
        ));
        return switch (result) {
          ProtectedWriteStatus.committed =>
            ProtectedDeleteStatus.verifiedAbsent,
          ProtectedWriteStatus.unavailable => ProtectedDeleteStatus.unavailable,
          ProtectedWriteStatus.failed => ProtectedDeleteStatus.failed,
          ProtectedWriteStatus.verificationFailed =>
            ProtectedDeleteStatus.verificationFailed,
          ProtectedWriteStatus.unsupported => ProtectedDeleteStatus.unsupported,
        };
      });

  @override
  Future<void> close() => _run(() async {
        if (_closed) return;
        _closed = true;
        await _db.close();
      });

  Future<ProtectedSettingsRecord> _settingsFromRow(
      Map<String, dynamic> row) async {
    if (row['schema_version'] != ProtectedSettingsRecord.schemaVersion) {
      throw const ProtectedContextSchemaUnsupported();
    }
    final data = jsonDecode(row['profile'] as String);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid protected profile');
    }
    final photo = row['photo'] == null
        ? null
        : await ValidatedProfilePhoto.fromBytes(
            Uint8List.fromList((row['photo'] as List).cast<int>()));
    if (photo?.width != row['width'] || photo?.height != row['height']) {
      throw const FormatException('Invalid protected photo dimensions');
    }
    return ProtectedSettingsRecord(
        revision: row['revision'] as int,
        phase: ContextRecordPhase.values.byName(row['phase'] as String),
        profile: ProtectedProfileFields.fromJson(data),
        photo: photo);
  }

  Future<ProtectedSettingsRead> _readSettings() async {
    if (_closed) {
      return const ProtectedSettingsRead(ProtectedReadStatus.unavailable);
    }
    try {
      final rows = await _db
          .getAll('SELECT * FROM settings_profile WHERE singleton = 1');
      if (rows.isEmpty) {
        return const ProtectedSettingsRead(ProtectedReadStatus.absent);
      }
      return ProtectedSettingsRead(
          ProtectedReadStatus.found, await _settingsFromRow(rows.single));
    } on ProtectedContextSchemaUnsupported {
      return const ProtectedSettingsRead(ProtectedReadStatus.unsupported);
    } on FormatException {
      return const ProtectedSettingsRead(ProtectedReadStatus.corrupt);
    } on InvalidProfilePhoto {
      return const ProtectedSettingsRead(ProtectedReadStatus.corrupt);
    } on ArgumentError {
      return const ProtectedSettingsRead(ProtectedReadStatus.corrupt);
    } on TypeError {
      return const ProtectedSettingsRead(ProtectedReadStatus.corrupt);
    } catch (_) {
      return const ProtectedSettingsRead(ProtectedReadStatus.unavailable);
    }
  }

  @override
  Future<ProtectedSettingsRead> readSettings() => _run(_readSettings);

  @override
  Future<ProtectedWriteStatus> writeSettings(ProtectedSettingsRecord record) =>
      _run(() async {
        if (_closed) return ProtectedWriteStatus.unavailable;
        try {
          await _db.writeTransaction((tx) async {
            final rows = await tx
                .getAll('SELECT * FROM settings_profile WHERE singleton = 1');
            if (rows.isNotEmpty) {
              final old = await _settingsFromRow(rows.single);
              final activation = old.phase == ContextRecordPhase.provisional &&
                  record.phase == ContextRecordPhase.active &&
                  ProtectedSettingsRecord(
                          revision: old.revision,
                          phase: record.phase,
                          profile: old.profile,
                          photo: old.photo)
                      .equivalentTo(record);
              if (old.revision > record.revision ||
                  (old.revision == record.revision &&
                      !old.equivalentTo(record) &&
                      !activation)) {
                throw const FormatException('Conflicting settings revision');
              }
            }
            await tx.execute('''INSERT INTO settings_profile
          (singleton, schema_version, revision, phase, profile, photo, width, height)
          VALUES(1, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(singleton) DO UPDATE SET
          schema_version=excluded.schema_version, revision=excluded.revision,
          phase=excluded.phase, profile=excluded.profile, photo=excluded.photo,
          width=excluded.width, height=excluded.height''', [
              ProtectedSettingsRecord.schemaVersion,
              record.revision,
              record.phase.name,
              record.profile.encode(),
              record.photo?.bytes,
              record.photo?.width,
              record.photo?.height
            ]);
            await _failureInjector?.call(AppStoreStage.recordWritten);
          });
        } catch (_) {
          return ProtectedWriteStatus.failed;
        }
        try {
          await _failureInjector?.call(AppStoreStage.beforeVerification);
          final read = await _readSettings();
          return read.record?.equivalentTo(record) == true
              ? ProtectedWriteStatus.committed
              : ProtectedWriteStatus.verificationFailed;
        } catch (_) {
          return ProtectedWriteStatus.verificationFailed;
        }
      });
}
