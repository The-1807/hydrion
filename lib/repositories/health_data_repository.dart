import '../domain/health_data.dart';

abstract interface class HealthDataRepository {
  static const defaultPageSize = 250;
  static const maximumPageSize = 1000;

  Future<List<CanonicalHealthRecord>> records({
    Set<HealthMetric>? metrics,
    DateTime? start,
    DateTime? end,
    bool includeDeleted = false,
    bool includeDuplicates = false,
    int limit = defaultPageSize,
    int offset = 0,
  });

  Future<HealthSyncCheckpoint?> checkpointFor(
    String providerId,
    HealthMetric metric,
  );

  Future<void> commitImport({
    required List<CanonicalHealthRecord> records,
    required HealthSyncCheckpoint checkpoint,
  });

  Future<int> deleteImportedProvider(String providerId);

  Future<int> purgeBefore(DateTime cutoff);

  Future<void> close();
}

class MemoryHealthDataRepository implements HealthDataRepository {
  Map<String, CanonicalHealthRecord> _records = {};
  Map<String, HealthSyncCheckpoint> _checkpoints = {};

  static String _checkpointKey(String providerId, HealthMetric metric) =>
      '$providerId|${metric.name}';

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
    _validatePage(limit, offset);
    final matches = _records.values.where((record) {
      if (!includeDeleted && record.isDeleted) {
        return false;
      }
      if (!includeDuplicates && record.duplicateOfRecordId != null) {
        return false;
      }
      if (metrics != null && !metrics.contains(record.metric)) {
        return false;
      }
      if (start != null && record.endTime.isBefore(start)) {
        return false;
      }
      if (end != null && !record.startTime.isBefore(end)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final byTime = a.startTime.compareTo(b.startTime);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return List<CanonicalHealthRecord>.unmodifiable(
      matches.skip(offset).take(limit),
    );
  }

  @override
  Future<HealthSyncCheckpoint?> checkpointFor(
    String providerId,
    HealthMetric metric,
  ) async {
    return _checkpoints[_checkpointKey(providerId, metric)];
  }

  @override
  Future<void> commitImport({
    required List<CanonicalHealthRecord> records,
    required HealthSyncCheckpoint checkpoint,
  }) async {
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

    final nextRecords = Map<String, CanonicalHealthRecord>.from(_records);
    for (final record in records) {
      nextRecords[record.providerRecordKey] = record;
    }
    final nextCheckpoints =
        Map<String, HealthSyncCheckpoint>.from(_checkpoints);
    nextCheckpoints[_checkpointKey(checkpoint.providerId, checkpoint.metric)] =
        checkpoint;

    _records = nextRecords;
    _checkpoints = nextCheckpoints;
  }

  @override
  Future<int> deleteImportedProvider(String providerId) async {
    final before = _records.length;
    _records.removeWhere((_, record) => record.providerId == providerId);
    _checkpoints.removeWhere((key, _) => key.startsWith('$providerId|'));
    return before - _records.length;
  }

  @override
  Future<int> purgeBefore(DateTime cutoff) async {
    final before = _records.length;
    _records.removeWhere((_, record) => record.endTime.isBefore(cutoff));
    return before - _records.length;
  }

  @override
  Future<void> close() async {}

  static void _validatePage(int limit, int offset) {
    if (limit < 1 ||
        limit > HealthDataRepository.maximumPageSize ||
        offset < 0) {
      throw RangeError('Health record page is outside allowed bounds.');
    }
  }
}
