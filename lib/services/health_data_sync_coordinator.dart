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

    var recordsRead = 0;
    var inserted = 0;
    var updated = 0;
    var deleted = 0;
    var duplicates = 0;
    var rejected = 0;
    try {
      for (final metric in permitted) {
        if (isCancelled?.call() ?? false) {
          return HealthSynchronizationResult(
            status: HealthSyncStatus.cancelled,
            recordsRead: recordsRead,
            importedCount: inserted + updated,
            insertedCount: inserted,
            updatedCount: updated,
            deletedCount: deleted,
            duplicateCount: duplicates,
            rejectedCount: rejected,
            reasonCode: 'synchronization_cancelled',
          );
        }
        var checkpoint = await _repository.checkpointFor(providerId, metric) ??
            HealthSyncCheckpoint(
              providerId: providerId,
              metric: metric,
              historyStart: _clock().toUtc().subtract(initialHistory),
            );
        var hasMore = true;
        while (hasMore) {
          if (isCancelled?.call() ?? false) {
            return HealthSynchronizationResult(
              status: HealthSyncStatus.cancelled,
              recordsRead: recordsRead,
              importedCount: inserted + updated,
              insertedCount: inserted,
              updatedCount: updated,
              deletedCount: deleted,
              duplicateCount: duplicates,
              rejectedCount: rejected,
              reasonCode: 'synchronization_cancelled',
            );
          }
          var page = await provider.readChanges(checkpoint);
          if (page.checkpointExpired) {
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
          final existing = await _allRecords(metric);
          final reconciled = _reconcileDeletions(existing, page.records);
          recordsRead += page.records.length;
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
            checkpoint: page.nextCheckpoint,
          );
          duplicates +=
              classified.where((r) => r.duplicateOfRecordId != null).length;
          inserted += classified
              .where((r) =>
                  !r.isDeleted && !existingKeys.contains(r.providerRecordKey))
              .length;
          updated += classified
              .where((r) =>
                  !r.isDeleted && existingKeys.contains(r.providerRecordKey))
              .length;
          deleted += classified.where((r) => r.isDeleted).length;
          checkpoint = page.nextCheckpoint;
          hasMore = page.hasMore;
        }
      }
    } on HealthDataProviderException catch (error) {
      return HealthSynchronizationResult(
        status: inserted + updated + deleted > 0
            ? HealthSyncStatus.partial
            : HealthSyncStatus.failed,
        recordsRead: recordsRead,
        importedCount: inserted + updated,
        insertedCount: inserted,
        updatedCount: updated,
        deletedCount: deleted,
        duplicateCount: duplicates,
        rejectedCount: rejected,
        reasonCode: error.reasonCode,
      );
    } catch (_) {
      return HealthSynchronizationResult(
        status: inserted + updated + deleted > 0
            ? HealthSyncStatus.partial
            : HealthSyncStatus.failed,
        recordsRead: recordsRead,
        importedCount: inserted + updated,
        insertedCount: inserted,
        updatedCount: updated,
        deletedCount: deleted,
        duplicateCount: duplicates,
        rejectedCount: rejected,
        reasonCode: 'provider_or_repository_failure',
      );
    }

    return HealthSynchronizationResult(
      status: permitted.length == requested.length
          ? HealthSyncStatus.success
          : HealthSyncStatus.partial,
      recordsRead: recordsRead,
      importedCount: inserted + updated,
      insertedCount: inserted,
      updatedCount: updated,
      deletedCount: deleted,
      duplicateCount: duplicates,
      rejectedCount: rejected,
    );
  }

  Future<List<CanonicalHealthRecord>> _allRecords(HealthMetric metric) async {
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
      records.addAll(page);
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
