import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sqlite_async/native.dart';
import 'package:sqlite_async/sqlite_async.dart';

import 'protected_app_store.dart';

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
/// Operations serialize per instance; application ownership is one writer per
/// path/isolate. Native commit/readback is not physical-durability evidence.
final class EncryptedAppStore implements ProtectedAppStore {
  static const schemaVersion = 1;
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
        if (version != 0 && version != schemaVersion) {
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
}
