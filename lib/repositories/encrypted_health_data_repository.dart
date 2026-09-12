import 'dart:convert';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sqlite_async/native.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../domain/health_data.dart';
import 'health_data_repository.dart';

enum HealthRepositoryOpenStatus {
  ready,
  unsupportedSchema,
  unreadableOrCorrupt,
}

enum HealthRepositoryWriteStage { recordsWritten, beforeCheckpoint }

class HealthRepositoryOpenException implements Exception {
  final HealthRepositoryOpenStatus status;

  const HealthRepositoryOpenException(this.status);

  @override
  String toString() => 'HealthRepositoryOpenException(${status.name})';
}

final class _EncryptedSqliteOpenFactory extends NativeSqliteOpenFactory {
  final String _hexKey;

  _EncryptedSqliteOpenFactory({
    required super.path,
    required Uint8List key,
  })  : _hexKey =
            key.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
        super(
          sqliteOptions: const SqliteOptions(
            maxReaders: 2,
            preparedStatementCacheSize: 20,
          ),
        );

  @override
  void configureConnection(
    sqlite.Database database,
    SqliteOpenOptions options,
  ) {
    database.execute('PRAGMA key = "x\'$_hexKey\'"');
    database.execute('PRAGMA cipher_memory_security = ON');
    final cipher = database.select('PRAGMA cipher_version');
    if (cipher.isEmpty || cipher.first.values.first.toString().isEmpty) {
      throw const HealthRepositoryOpenException(
        HealthRepositoryOpenStatus.unreadableOrCorrupt,
      );
    }
    database.select('SELECT count(*) FROM sqlite_master');
    super.configureConnection(database, options);
  }
}

class EncryptedHealthDataRepository implements HealthDataRepository {
  static const schemaVersion = 1;

  final SqliteDatabase _database;
  final Future<void> Function(HealthRepositoryWriteStage stage)?
      _failureInjector;
  bool _closed = false;

  EncryptedHealthDataRepository._(
    this._database,
    this._failureInjector,
  );

  static Future<EncryptedHealthDataRepository> open({
    required String path,
    required Uint8List key,
    Future<void> Function(HealthRepositoryWriteStage stage)? failureInjector,
  }) async {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key', 'must contain 32 bytes');
    }
    final database = SqliteDatabase.withFactory(
      _EncryptedSqliteOpenFactory(path: path, key: key),
    );
    final repository = EncryptedHealthDataRepository._(
      database,
      failureInjector,
    );
    try {
      await database.initialize();
      await repository._migrate();
      return repository;
    } on HealthRepositoryOpenException {
      await _closeAfterFailedOpen(database);
      rethrow;
    } catch (_) {
      await _closeAfterFailedOpen(database);
      throw const HealthRepositoryOpenException(
        HealthRepositoryOpenStatus.unreadableOrCorrupt,
      );
    }
  }

  static Future<void> _closeAfterFailedOpen(SqliteDatabase database) async {
    try {
      await database.close();
    } catch (_) {
      // The initialization error is reported as the authoritative open state.
    }
  }

  Future<void> _migrate() async {
    await _database.writeTransaction((tx) async {
      final row = await tx.get('PRAGMA user_version');
      final version = row['user_version'] as int;
      if (version > schemaVersion) {
        throw const HealthRepositoryOpenException(
          HealthRepositoryOpenStatus.unsupportedSchema,
        );
      }
      if (version == 0) {
        await tx.execute('''
CREATE TABLE health_records (
  provider_record_key TEXT PRIMARY KEY,
  id TEXT NOT NULL UNIQUE,
  schema_version INTEGER NOT NULL,
  provider_id TEXT NOT NULL,
  external_record_id TEXT NOT NULL,
  synchronization_version TEXT NOT NULL,
  metric TEXT NOT NULL,
  semantic_id TEXT NOT NULL,
  semantic_version INTEGER NOT NULL,
  value REAL NOT NULL,
  original_unit TEXT NOT NULL,
  canonical_unit TEXT NOT NULL,
  category TEXT,
  start_us INTEGER NOT NULL,
  end_us INTEGER NOT NULL,
  source_time_zone TEXT,
  source_utc_offset_minutes INTEGER,
  temporal_precision TEXT NOT NULL,
  recorded_at_us INTEGER,
  created_at_us INTEGER,
  modified_at_us INTEGER,
  ingested_at_us INTEGER NOT NULL,
  shape TEXT NOT NULL,
  aggregation_method TEXT,
  value_origin TEXT NOT NULL,
  record_kind TEXT NOT NULL CHECK (record_kind IN ('imported', 'derived')),
  source_platform TEXT NOT NULL,
  source_application_id TEXT NOT NULL,
  source_application_name TEXT,
  physical_device_id TEXT,
  manufacturer TEXT,
  device_model TEXT,
  device_hardware_version TEXT,
  device_software_version TEXT,
  acquisition_route TEXT NOT NULL,
  entry_method TEXT NOT NULL,
  quality TEXT NOT NULL,
  is_deleted INTEGER NOT NULL CHECK (is_deleted IN (0, 1)),
  supersedes_external_record_id TEXT,
  duplicate_of_record_id TEXT,
  algorithm_version TEXT,
  contributing_record_ids_json TEXT NOT NULL,
  provider_metadata_version INTEGER NOT NULL,
  provider_metadata_json TEXT NOT NULL
) STRICT
''');
        await tx.execute('''
CREATE TABLE health_sync_checkpoints (
  provider_id TEXT NOT NULL,
  metric TEXT NOT NULL,
  cursor TEXT,
  history_start_us INTEGER NOT NULL,
  last_successful_sync_us INTEGER,
  PRIMARY KEY (provider_id, metric)
) STRICT
''');
        await tx.execute(
          'CREATE INDEX health_records_provider_metric_time '
          'ON health_records(provider_id, metric, start_us, id)',
        );
        await tx.execute(
          'CREATE INDEX health_records_metric_time '
          'ON health_records(metric, start_us, id)',
        );
        await tx.execute(
          'CREATE INDEX health_records_kind_time '
          'ON health_records(record_kind, end_us, id)',
        );
        await tx.execute('PRAGMA user_version = $schemaVersion');
      }
    });
  }

  @override
  Future<List<CanonicalHealthRecord>> records({
    Set<HealthMetric>? metrics,
    DateTime? start,
    DateTime? end,
    bool includeDeleted = false,
    bool includeDuplicates = false,
    int limit = HealthDataRepository.defaultPageSize,
    int offset = 0,
  }) async {
    _checkOpen();
    _validatePage(limit, offset);
    final conditions = <String>[];
    final parameters = <Object?>[];
    if (!includeDeleted) conditions.add('is_deleted = 0');
    if (!includeDuplicates) conditions.add('duplicate_of_record_id IS NULL');
    if (metrics != null && metrics.isNotEmpty) {
      conditions
          .add('metric IN (${List.filled(metrics.length, '?').join(',')})');
      parameters.addAll(metrics.map((metric) => metric.name));
    }
    if (start != null) {
      conditions.add('end_us >= ?');
      parameters.add(start.toUtc().microsecondsSinceEpoch);
    }
    if (end != null) {
      conditions.add('start_us < ?');
      parameters.add(end.toUtc().microsecondsSinceEpoch);
    }
    parameters
      ..add(limit)
      ..add(offset);
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await _database.getAll(
      'SELECT * FROM health_records $where '
      'ORDER BY start_us, id LIMIT ? OFFSET ?',
      parameters,
    );
    return List.unmodifiable(rows.map(_recordFromRow));
  }

  @override
  Future<HealthSyncCheckpoint?> checkpointFor(
    String providerId,
    HealthMetric metric,
  ) async {
    _checkOpen();
    final row = await _database.getOptional(
      'SELECT * FROM health_sync_checkpoints '
      'WHERE provider_id = ? AND metric = ?',
      [providerId, metric.name],
    );
    if (row == null) return null;
    return HealthSyncCheckpoint(
      providerId: row['provider_id'] as String,
      metric: _enumByName(HealthMetric.values, row['metric'] as String),
      cursor: row['cursor'] as String?,
      historyStart: _date(row['history_start_us'] as int),
      lastSuccessfulSync: _nullableDate(row['last_successful_sync_us'] as int?),
    );
  }

  @override
  Future<void> commitImport({
    required List<CanonicalHealthRecord> records,
    required HealthSyncCheckpoint checkpoint,
  }) async {
    _checkOpen();
    if (checkpoint.providerId.trim().isEmpty) {
      throw const FormatException('Checkpoint provider is required.');
    }
    for (final record in records) {
      record.validate();
      if (record.providerId != checkpoint.providerId ||
          record.metric != checkpoint.metric) {
        throw const FormatException(
          'Record and checkpoint provider/metric must match.',
        );
      }
    }

    await _database.writeTransaction((tx) async {
      for (final record in records) {
        await tx.execute(_upsertRecordSql, _recordArguments(record));
      }
      await _failureInjector?.call(HealthRepositoryWriteStage.recordsWritten);
      await _failureInjector?.call(HealthRepositoryWriteStage.beforeCheckpoint);
      await tx.execute('''
INSERT INTO health_sync_checkpoints (
  provider_id, metric, cursor, history_start_us, last_successful_sync_us
) VALUES (?, ?, ?, ?, ?)
ON CONFLICT(provider_id, metric) DO UPDATE SET
  cursor = excluded.cursor,
  history_start_us = excluded.history_start_us,
  last_successful_sync_us = excluded.last_successful_sync_us
''', [
        checkpoint.providerId,
        checkpoint.metric.name,
        checkpoint.cursor,
        checkpoint.historyStart.toUtc().microsecondsSinceEpoch,
        checkpoint.lastSuccessfulSync?.toUtc().microsecondsSinceEpoch,
      ]);
    });
  }

  @override
  Future<int> deleteImportedProvider(String providerId) async {
    _checkOpen();
    return _database.writeTransaction((tx) async {
      await tx.execute(
        "DELETE FROM health_records WHERE provider_id = ? AND record_kind = 'imported'",
        [providerId],
      );
      final changes =
          (await tx.get('SELECT changes() AS count'))['count'] as int;
      await tx.execute(
        'DELETE FROM health_sync_checkpoints WHERE provider_id = ?',
        [providerId],
      );
      return changes;
    });
  }

  @override
  Future<int> purgeBefore(DateTime cutoff) async {
    _checkOpen();
    return _database.writeTransaction((tx) async {
      await tx.execute(
        'DELETE FROM health_records WHERE end_us < ?',
        [cutoff.toUtc().microsecondsSinceEpoch],
      );
      return (await tx.get('SELECT changes() AS count'))['count'] as int;
    });
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _database.close();
  }

  void _checkOpen() {
    if (_closed) throw StateError('Health repository is closed.');
  }

  static void _validatePage(int limit, int offset) {
    if (limit < 1 ||
        limit > HealthDataRepository.maximumPageSize ||
        offset < 0) {
      throw RangeError('Health record page is outside allowed bounds.');
    }
  }

  static final _upsertRecordSql = '''
INSERT INTO health_records (
  provider_record_key, id, schema_version, provider_id, external_record_id,
  synchronization_version, metric, semantic_id, semantic_version, value,
  original_unit, canonical_unit, category, start_us, end_us,
  source_time_zone, source_utc_offset_minutes, temporal_precision, recorded_at_us, created_at_us,
  modified_at_us, ingested_at_us, shape, aggregation_method, value_origin,
  record_kind, source_platform, source_application_id, source_application_name,
  physical_device_id, manufacturer, device_model, device_hardware_version,
  device_software_version, acquisition_route, entry_method, quality, is_deleted,
  supersedes_external_record_id, duplicate_of_record_id, algorithm_version,
  contributing_record_ids_json, provider_metadata_version, provider_metadata_json
) VALUES (${_placeholders(44)})
ON CONFLICT(provider_record_key) DO UPDATE SET
  id = excluded.id,
  schema_version = excluded.schema_version,
  synchronization_version = excluded.synchronization_version,
  metric = excluded.metric,
  semantic_id = excluded.semantic_id,
  semantic_version = excluded.semantic_version,
  value = excluded.value,
  original_unit = excluded.original_unit,
  canonical_unit = excluded.canonical_unit,
  category = excluded.category,
  start_us = excluded.start_us,
  end_us = excluded.end_us,
  source_time_zone = excluded.source_time_zone,
  source_utc_offset_minutes = excluded.source_utc_offset_minutes,
  temporal_precision = excluded.temporal_precision,
  recorded_at_us = excluded.recorded_at_us,
  created_at_us = excluded.created_at_us,
  modified_at_us = excluded.modified_at_us,
  ingested_at_us = excluded.ingested_at_us,
  shape = excluded.shape,
  aggregation_method = excluded.aggregation_method,
  value_origin = excluded.value_origin,
  record_kind = excluded.record_kind,
  source_application_name = excluded.source_application_name,
  physical_device_id = excluded.physical_device_id,
  manufacturer = excluded.manufacturer,
  device_model = excluded.device_model,
  device_hardware_version = excluded.device_hardware_version,
  device_software_version = excluded.device_software_version,
  acquisition_route = excluded.acquisition_route,
  entry_method = excluded.entry_method,
  quality = excluded.quality,
  is_deleted = excluded.is_deleted,
  supersedes_external_record_id = excluded.supersedes_external_record_id,
  duplicate_of_record_id = excluded.duplicate_of_record_id,
  algorithm_version = excluded.algorithm_version,
  contributing_record_ids_json = excluded.contributing_record_ids_json,
  provider_metadata_version = excluded.provider_metadata_version,
  provider_metadata_json = excluded.provider_metadata_json
''';

  static String _placeholders(int count) => List.filled(count, '?').join(', ');

  static List<Object?> _recordArguments(CanonicalHealthRecord record) => [
        record.providerRecordKey,
        record.id,
        record.schemaVersion,
        record.providerId,
        record.externalRecordId,
        record.synchronizationVersion,
        record.metric.name,
        record.semanticId,
        record.semanticVersion,
        record.value,
        record.originalUnit.name,
        record.unit.name,
        record.category,
        record.startTime.toUtc().microsecondsSinceEpoch,
        record.endTime.toUtc().microsecondsSinceEpoch,
        record.sourceTimeZone,
        record.sourceUtcOffset?.inMinutes,
        record.temporalPrecision.name,
        record.recordedAt?.toUtc().microsecondsSinceEpoch,
        record.createdAt?.toUtc().microsecondsSinceEpoch,
        record.modifiedAt?.toUtc().microsecondsSinceEpoch,
        record.ingestedAt.toUtc().microsecondsSinceEpoch,
        record.shape.name,
        record.aggregationMethod,
        record.valueOrigin.name,
        record.isDerived ? 'derived' : 'imported',
        record.provenance.sourcePlatform,
        record.provenance.sourceApplicationId,
        record.provenance.sourceApplicationName,
        record.provenance.physicalDeviceId,
        record.provenance.manufacturer,
        record.provenance.deviceModel,
        record.provenance.deviceHardwareVersion,
        record.provenance.deviceSoftwareVersion,
        record.provenance.acquisitionRoute.name,
        record.provenance.entryMethod.name,
        record.quality,
        record.isDeleted ? 1 : 0,
        record.supersedesExternalRecordId,
        record.duplicateOfRecordId,
        record.algorithmVersion,
        jsonEncode(record.contributingRecordIds),
        record.providerMetadataVersion,
        jsonEncode(record.providerMetadata),
      ];

  static CanonicalHealthRecord _recordFromRow(Map<String, Object?> row) {
    final metadata = (jsonDecode(row['provider_metadata_json'] as String)
            as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as String));
    return CanonicalHealthRecord(
      schemaVersion: row['schema_version'] as int,
      id: row['id'] as String,
      providerId: row['provider_id'] as String,
      externalRecordId: row['external_record_id'] as String,
      synchronizationVersion: row['synchronization_version'] as String,
      metric: _enumByName(HealthMetric.values, row['metric'] as String),
      semanticId: row['semantic_id'] as String,
      semanticVersion: row['semantic_version'] as int,
      value: row['value'] as double,
      originalUnit:
          _enumByName(HealthUnit.values, row['original_unit'] as String),
      unit: _enumByName(HealthUnit.values, row['canonical_unit'] as String),
      category: row['category'] as String?,
      startTime: _date(row['start_us'] as int),
      endTime: _date(row['end_us'] as int),
      sourceTimeZone: row['source_time_zone'] as String?,
      sourceUtcOffset: row['source_utc_offset_minutes'] == null
          ? null
          : Duration(minutes: row['source_utc_offset_minutes'] as int),
      temporalPrecision: _enumByName(
        HealthTemporalPrecision.values,
        row['temporal_precision'] as String,
      ),
      recordedAt: _nullableDate(row['recorded_at_us'] as int?),
      createdAt: _nullableDate(row['created_at_us'] as int?),
      modifiedAt: _nullableDate(row['modified_at_us'] as int?),
      ingestedAt: _date(row['ingested_at_us'] as int),
      shape: _enumByName(HealthRecordShape.values, row['shape'] as String),
      aggregationMethod: row['aggregation_method'] as String?,
      valueOrigin:
          _enumByName(HealthValueOrigin.values, row['value_origin'] as String),
      provenance: HealthProvenance(
        sourcePlatform: row['source_platform'] as String,
        sourceApplicationId: row['source_application_id'] as String,
        sourceApplicationName: row['source_application_name'] as String?,
        physicalDeviceId: row['physical_device_id'] as String?,
        manufacturer: row['manufacturer'] as String?,
        deviceModel: row['device_model'] as String?,
        deviceHardwareVersion: row['device_hardware_version'] as String?,
        deviceSoftwareVersion: row['device_software_version'] as String?,
        acquisitionRoute: _enumByName(
          HealthAcquisitionRoute.values,
          row['acquisition_route'] as String,
        ),
        entryMethod: _enumByName(
            HealthEntryMethod.values, row['entry_method'] as String),
      ),
      quality: row['quality'] as String,
      isDeleted: row['is_deleted'] == 1,
      supersedesExternalRecordId:
          row['supersedes_external_record_id'] as String?,
      duplicateOfRecordId: row['duplicate_of_record_id'] as String?,
      algorithmVersion: row['algorithm_version'] as String?,
      contributingRecordIds:
          (jsonDecode(row['contributing_record_ids_json'] as String) as List)
              .cast<String>(),
      providerMetadataVersion: row['provider_metadata_version'] as int,
      providerMetadata: metadata,
    );
  }

  static DateTime _date(int microseconds) =>
      DateTime.fromMicrosecondsSinceEpoch(microseconds, isUtc: true);

  static DateTime? _nullableDate(int? microseconds) =>
      microseconds == null ? null : _date(microseconds);

  static T _enumByName<T extends Enum>(List<T> values, String name) =>
      values.byName(name);
}
