import '../domain/health_data.dart';
import '../repositories/health_data_repository.dart';

class HealthDataSyncCoordinator {
  final Map<String, HealthDataProvider> _providers;
  final HealthDataRepository _repository;
  final DateTime Function() _clock;
  final Duration initialHistory;

  HealthDataSyncCoordinator({
    required Iterable<HealthDataProvider> providers,
    required HealthDataRepository repository,
    DateTime Function()? clock,
    this.initialHistory = const Duration(days: 30),
  })  : _providers = {
          for (final provider in providers) provider.providerId: provider
        },
        _repository = repository,
        _clock = clock ?? DateTime.now;

  Future<HealthProviderAvailability> availability(String providerId) async {
    final provider = _providers[providerId];
    if (provider == null) {
      return const HealthProviderAvailability(
        HealthProviderAvailabilityStatus.unsupported,
        reasonCode: 'provider_not_registered',
      );
    }
    return provider.availability();
  }

  Future<HealthSynchronizationResult> synchronize({
    required String providerId,
    required Set<HealthMetric> metrics,
    bool requestPermission = false,
    bool userInitiated = false,
    bool Function()? isCancelled,
  }) async {
    final provider = _providers[providerId];
    if (provider == null) {
      return const HealthSynchronizationResult(
        status: HealthSyncStatus.unsupported,
        reasonCode: 'provider_not_registered',
      );
    }

    final available = await provider.availability();
    if (!available.canConnect) {
      return HealthSynchronizationResult(
        status: available.status == HealthProviderAvailabilityStatus.unsupported
            ? HealthSyncStatus.unsupported
            : HealthSyncStatus.unavailable,
        reasonCode: available.reasonCode ?? available.status.name,
      );
    }

    final capabilities = await provider.capabilities();
    final requested = metrics.intersection(capabilities.readableMetrics);
    if (requested.isEmpty) {
      return const HealthSynchronizationResult(
        status: HealthSyncStatus.unsupported,
        reasonCode: 'requested_metrics_unsupported',
      );
    }

    var authorization = await provider.authorizationState(requested);
    if (requestPermission) {
      if (!userInitiated) {
        return const HealthSynchronizationResult(
          status: HealthSyncStatus.permissionRequired,
          reasonCode: 'permission_requires_user_action',
        );
      }
      authorization = await provider.requestReadAccess(requested);
    }
    final permitted = requested.intersection(authorization.grantedMetrics);
    if (permitted.isEmpty) {
      return HealthSynchronizationResult(
        status: authorization.status == HealthPermissionStatus.notRequested
            ? HealthSyncStatus.permissionRequired
            : HealthSyncStatus.permissionDenied,
        reasonCode: authorization.status.name,
      );
    }

    final metricResults = <HealthMetric, HealthMetricSynchronizationResult>{};
    for (final metric in permitted) {
      if (isCancelled?.call() ?? false) {
        return _combinedResult(
          metricResults,
          status: HealthSyncStatus.cancelled,
          reasonCode: 'synchronization_cancelled',
        );
      }
      metricResults[metric] = await _synchronizeMetric(
        provider: provider,
        providerId: providerId,
        metric: metric,
        isCancelled: isCancelled,
      );
      if (metricResults[metric]!.status == HealthSyncStatus.cancelled) {
        return _combinedResult(
          metricResults,
          status: HealthSyncStatus.cancelled,
          reasonCode: 'synchronization_cancelled',
        );
      }
    }

    final failures = metricResults.values
        .where((result) => result.status == HealthSyncStatus.failed)
        .toList(growable: false);
    final successes = metricResults.values
        .where((result) => result.status == HealthSyncStatus.success)
        .length;
    final missingPermissions = permitted.length != requested.length;
    final status = failures.isEmpty && !missingPermissions
        ? HealthSyncStatus.success
        : successes > 0
            ? HealthSyncStatus.partial
            : HealthSyncStatus.failed;
    return _combinedResult(
      metricResults,
      status: status,
      reasonCode: failures.isEmpty ? null : failures.first.reasonCode,
    );
  }

  Future<HealthMetricSynchronizationResult> _synchronizeMetric({
    required HealthDataProvider provider,
    required String providerId,
    required HealthMetric metric,
    required bool Function()? isCancelled,
  }) async {
    var recordsRead = 0;
    var rejected = 0;
    try {
      var checkpoint = await _repository.checkpointFor(providerId, metric) ??
          HealthSyncCheckpoint(
            providerId: providerId,
            metric: metric,
            historyStart: _clock().toUtc().subtract(initialHistory),
          );
      final incoming = <CanonicalHealthRecord>[];
      HealthSyncCheckpoint? finalCheckpoint;
      var pageCount = 0;
      var hasMore = true;
      var restartedAfterExpiry = false;
      while (hasMore) {
        if (isCancelled?.call() ?? false) {
          return HealthMetricSynchronizationResult(
            status: HealthSyncStatus.cancelled,
            recordsRead: recordsRead,
            reasonCode: 'synchronization_cancelled',
          );
        }
        if (++pageCount > 100) {
          throw StateError('provider_page_limit_exceeded');
        }
        var page = await provider.readChanges(checkpoint);
        if (page.checkpointExpired) {
          if (restartedAfterExpiry) {
            throw StateError('provider_checkpoint_remained_expired');
          }
          restartedAfterExpiry = true;
          incoming.clear();
          recordsRead = 0;
          checkpoint = HealthSyncCheckpoint(
            providerId: providerId,
            metric: metric,
            historyStart: _clock().toUtc().subtract(initialHistory),
          );
          page = await provider.readChanges(checkpoint);
          if (page.checkpointExpired) {
            throw StateError('provider_checkpoint_remained_expired');
          }
        }
        recordsRead += page.records.length;
        incoming.addAll(page.records);
        finalCheckpoint = page.nextCheckpoint;
        checkpoint = page.nextCheckpoint;
        hasMore = page.hasMore;
      }

      final existing = await _allRecords(providerId, metric);
      final reconciled = _reconcileDeletions(existing, incoming);
      late final List<CanonicalHealthRecord> classified;
      try {
        classified = _classifyDuplicates(existing, reconciled);
      } on FormatException {
        rejected += 1;
        rethrow;
      }
      final existingKeys = {
        for (final record in existing) record.providerRecordKey,
      };
      await _repository.commitImport(
        records: classified,
        checkpoint: finalCheckpoint!,
      );
      final inserted = classified
          .where((record) =>
              !record.isDeleted &&
              !existingKeys.contains(record.providerRecordKey))
          .length;
      final updated = classified
          .where((record) =>
              !record.isDeleted &&
              existingKeys.contains(record.providerRecordKey))
          .length;
      return HealthMetricSynchronizationResult(
        status: HealthSyncStatus.success,
        recordsRead: recordsRead,
        insertedCount: inserted,
        updatedCount: updated,
        deletedCount: classified.where((record) => record.isDeleted).length,
        duplicateCount: classified
            .where((record) => record.duplicateOfRecordId != null)
            .length,
        rejectedCount: rejected,
      );
    } on HealthDataProviderException catch (error) {
      return HealthMetricSynchronizationResult(
        status: HealthSyncStatus.failed,
        recordsRead: recordsRead,
        rejectedCount: rejected,
        reasonCode: error.reasonCode,
      );
    } catch (_) {
      return HealthMetricSynchronizationResult(
        status: HealthSyncStatus.failed,
        recordsRead: recordsRead,
        rejectedCount: rejected,
        reasonCode: 'provider_or_repository_failure',
      );
    }
  }

  HealthSynchronizationResult _combinedResult(
    Map<HealthMetric, HealthMetricSynchronizationResult> metricResults, {
    required HealthSyncStatus status,
    String? reasonCode,
  }) {
    final values = metricResults.values;
    int sum(int Function(HealthMetricSynchronizationResult) select) =>
        values.fold(0, (total, result) => total + select(result));
    final inserted = sum((result) => result.insertedCount);
    final updated = sum((result) => result.updatedCount);
    return HealthSynchronizationResult(
      status: status,
      recordsRead: sum((result) => result.recordsRead),
      importedCount: inserted + updated,
      insertedCount: inserted,
      updatedCount: updated,
      deletedCount: sum((result) => result.deletedCount),
      duplicateCount: sum((result) => result.duplicateCount),
      rejectedCount: sum((result) => result.rejectedCount),
      reasonCode: reasonCode,
      metricResults: Map.unmodifiable(metricResults),
    );
  }

  Future<List<CanonicalHealthRecord>> _allRecords(
    String providerId,
    HealthMetric metric,
  ) async {
    final records = <CanonicalHealthRecord>[];
    var offset = 0;
    while (true) {
      final page = await _repository.records(
        metrics: {metric},
        includeDeleted: true,
        includeDuplicates: true,
        limit: HealthDataRepository.maximumPageSize,
        offset: offset,
      );
      records.addAll(
        page.where((record) => record.providerId == providerId),
      );
      if (page.length < HealthDataRepository.maximumPageSize) return records;
      offset += page.length;
    }
  }

  List<CanonicalHealthRecord> _classifyDuplicates(
    List<CanonicalHealthRecord> existing,
    List<CanonicalHealthRecord> incoming,
  ) {
    final exact = <String, CanonicalHealthRecord>{
      for (final record in existing) record.providerRecordKey: record,
    };
    final fingerprintOwners = <String, String>{};
    for (final record in existing) {
      if (!record.isDeleted && record.duplicateOfRecordId == null) {
        fingerprintOwners[_fingerprint(record)] = record.id;
      }
    }

    final result = <CanonicalHealthRecord>[];
    for (final record in incoming) {
      record.validate();
      if (exact.containsKey(record.providerRecordKey) || record.isDeleted) {
        result.add(record);
        continue;
      }
      final fingerprint = _fingerprint(record);
      final owner = fingerprintOwners[fingerprint];
      if (owner == null) {
        fingerprintOwners[fingerprint] = record.id;
        result.add(record.copyWith(clearDuplicateOfRecordId: true));
      } else {
        result.add(record.copyWith(duplicateOfRecordId: owner));
      }
      exact[record.providerRecordKey] = record;
    }
    return result;
  }

  List<CanonicalHealthRecord> _reconcileDeletions(
    List<CanonicalHealthRecord> existing,
    List<CanonicalHealthRecord> incoming,
  ) {
    final existingByExternalId = <String, CanonicalHealthRecord>{
      for (final record in existing)
        if (record.providerId.isNotEmpty) record.externalRecordId: record,
    };
    return incoming.map((record) {
      if (!record.isDeleted) return record;
      final original = existingByExternalId[record.externalRecordId];
      return original?.asDeleted(
            ingestedAt: _clock().toUtc(),
            synchronizationVersion: record.synchronizationVersion,
          ) ??
          record;
    }).toList(growable: false);
  }

  String _fingerprint(CanonicalHealthRecord record) {
    final physicalSource = record.provenance.physicalDeviceId ??
        '${record.provenance.manufacturer ?? ''}|${record.provenance.deviceModel ?? ''}';
    return '${record.metric.name}|${record.semanticId}|${record.semanticVersion}|'
        '${record.startTime.toUtc().microsecondsSinceEpoch}|'
        '${record.endTime.toUtc().microsecondsSinceEpoch}|'
        '${record.value}|${record.unit.name}|${record.category ?? ''}|$physicalSource';
  }
}
