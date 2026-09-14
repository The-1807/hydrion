import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/health_data.dart';
import '../repositories/health_data_repository.dart';
import '../storage/local_store.dart';
import 'health_data_sync_coordinator.dart';

enum HealthConnectionViewState {
  loading,
  providerUnavailable,
  installationRequired,
  updateRequired,
  unsupported,
  disconnected,
  consentRequired,
  permissionRequesting,
  permissionDenied,
  permissionPartiallyGranted,
  connectedNotSynchronized,
  synchronizing,
  synchronizedWithRecords,
  synchronizedNoRecords,
  synchronizationPartiallySuccessful,
  synchronizationFailed,
  permissionsRevoked,
}

class HealthConnectionController extends ChangeNotifier {
  final UserManagedHealthDataProvider _provider;
  final HealthDataSyncCoordinator _coordinator;
  final HealthDataRepository _repository;
  final HydrionLocalStore _store;
  final bool _persistenceReady;
  final DateTime Function() _clock;

  HealthConnectionViewState state = HealthConnectionViewState.loading;
  Set<HealthMetric> grantedMetrics = const {};
  DateTime? lastAttemptedSynchronization;
  DateTime? lastSuccessfulSynchronization;
  HealthSyncStatus? lastSynchronizationOutcome;
  int lastRecordsRead = 0;
  int lastInsertedCount = 0;
  int lastUpdatedCount = 0;
  int lastDeletedCount = 0;
  int lastRejectedCount = 0;
  int importedRecordCount = 0;
  DateTime? earliestRecordTime;
  DateTime? latestRecordTime;
  Set<HealthMetric> availableMetrics = const {};
  Map<String, int> contributingApplicationRecordCounts = const {};
  Map<HealthMetric, HealthMetricSynchronizationResult> lastMetricResults =
      const {};
  String? failureReason;
  bool _locallyConnected = false;
  bool _permissionRequested = false;
  bool _operationInProgress = false;
  bool _initialized = false;

  HealthConnectionController({
    required UserManagedHealthDataProvider provider,
    required HealthDataSyncCoordinator coordinator,
    required HealthDataRepository repository,
    required HydrionLocalStore store,
    bool persistenceReady = true,
    DateTime Function()? clock,
  })  : _provider = provider,
        _coordinator = coordinator,
        _repository = repository,
        _store = store,
        _persistenceReady = persistenceReady,
        _clock = clock ?? DateTime.now;

  bool get isConnected => _locallyConnected;
  String get providerId => _provider.providerId;
  Set<HealthMetric> get metrics => _provider.connectionMetrics;
  bool get readAuthorizationIsOpaque => _provider.readAuthorizationIsOpaque;
  Set<HealthMetric> get missingMetrics => metrics.difference(grantedMetrics);
  Set<HealthMetric> get successfulMetrics => lastMetricResults.entries
      .where((entry) => entry.value.status == HealthSyncStatus.success)
      .map((entry) => entry.key)
      .toSet();
  Set<HealthMetric> get failedMetrics => lastMetricResults.entries
      .where((entry) => entry.value.status == HealthSyncStatus.failed)
      .map((entry) => entry.key)
      .toSet();
  Set<String> get contributingApplications =>
      contributingApplicationRecordCounts.keys.toSet();

  Future<void> initialize() async {
    if (_initialized) {
      await refresh();
      return;
    }
    final encoded = await _store.readString(_storageKey);
    if (encoded != null) {
      try {
        final value = jsonDecode(encoded) as Map<String, Object?>;
        _locallyConnected = value['connected'] == true;
        _permissionRequested = value['permissionRequested'] == true;
        lastAttemptedSynchronization = _date(value['lastAttempted']);
        lastSuccessfulSynchronization = _date(value['lastSuccessful']);
        lastSynchronizationOutcome = _syncStatus(value['lastOutcome']);
        lastRecordsRead = _nonNegativeInt(value['recordsRead']);
        lastInsertedCount = _nonNegativeInt(value['inserted']);
        lastUpdatedCount = _nonNegativeInt(value['updated']);
        lastDeletedCount = _nonNegativeInt(value['deleted']);
        lastRejectedCount = _nonNegativeInt(value['rejected']);
        failureReason = _safeCode(value['failureReason']);
        lastMetricResults = _metricResults(value['metricResults']);
      } on Object {
        _locallyConnected = false;
      }
    }
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    if (_operationInProgress) return;
    if (!_persistenceReady) {
      state = HealthConnectionViewState.synchronizationFailed;
      failureReason = 'protected_storage_unavailable';
      notifyListeners();
      return;
    }
    try {
      final availability = await _provider.availability();
      if (!availability.canConnect) {
        state = switch (availability.status) {
          HealthProviderAvailabilityStatus.installationRequired =>
            HealthConnectionViewState.installationRequired,
          HealthProviderAvailabilityStatus.updateRequired =>
            HealthConnectionViewState.updateRequired,
          HealthProviderAvailabilityStatus.unsupported =>
            HealthConnectionViewState.unsupported,
          _ => HealthConnectionViewState.providerUnavailable,
        };
        failureReason = availability.reasonCode;
        notifyListeners();
        return;
      }
      final authorization = await _provider.authorizationState(metrics);
      grantedMetrics = authorization.grantedMetrics;
      await _refreshRecordSummary();
      if (!_locallyConnected) {
        state = grantedMetrics.isEmpty
            ? _permissionRequested
                ? HealthConnectionViewState.permissionDenied
                : HealthConnectionViewState.consentRequired
            : HealthConnectionViewState.disconnected;
      } else if (grantedMetrics.isEmpty) {
        state = HealthConnectionViewState.permissionsRevoked;
      } else if (grantedMetrics.length < metrics.length) {
        state = HealthConnectionViewState.permissionPartiallyGranted;
      } else {
        state = _restoredConnectedState();
      }
      if (state != HealthConnectionViewState.synchronizationFailed) {
        failureReason = null;
      }
    } on Object {
      state = _locallyConnected
          ? HealthConnectionViewState.synchronizationFailed
          : HealthConnectionViewState.providerUnavailable;
      failureReason = 'provider_refresh_failed';
    }
    notifyListeners();
  }

  Future<void> connect() async {
    if (_operationInProgress) return;
    _operationInProgress = true;
    failureReason = null;
    _permissionRequested = true;
    state = HealthConnectionViewState.permissionRequesting;
    notifyListeners();
    try {
      final authorization = await _provider.requestReadAccess(metrics);
      grantedMetrics = authorization.grantedMetrics;
      _locallyConnected = grantedMetrics.isNotEmpty;
      await _persist();
    } on Object {
      _locallyConnected = false;
      state = HealthConnectionViewState.permissionDenied;
      failureReason = 'permission_request_failed';
    } finally {
      _operationInProgress = false;
    }
    await refresh();
  }

  Future<void> requestMissingPermissions() async {
    if (missingMetrics.isEmpty || _operationInProgress) return;
    _operationInProgress = true;
    _permissionRequested = true;
    state = HealthConnectionViewState.permissionRequesting;
    notifyListeners();
    try {
      final authorization = await _provider.requestReadAccess(missingMetrics);
      grantedMetrics = {...grantedMetrics, ...authorization.grantedMetrics};
      _locallyConnected = grantedMetrics.isNotEmpty;
      await _persist();
    } on Object {
      failureReason = 'permission_request_failed';
    } finally {
      _operationInProgress = false;
    }
    await refresh();
  }

  Future<HealthSynchronizationResult> synchronize({
    Set<HealthMetric>? requestedMetrics,
  }) async {
    if (!_locallyConnected || _operationInProgress) {
      return const HealthSynchronizationResult(
        status: HealthSyncStatus.cancelled,
        reasonCode: 'synchronization_not_started',
      );
    }
    _operationInProgress = true;
    state = HealthConnectionViewState.synchronizing;
    lastAttemptedSynchronization = _clock().toUtc();
    failureReason = null;
    notifyListeners();
    late final HealthSynchronizationResult result;
    try {
      result = await _coordinator.synchronize(
        providerId: _provider.providerId,
        metrics: requestedMetrics ?? metrics,
      );
    } on Object {
      result = const HealthSynchronizationResult(
        status: HealthSyncStatus.failed,
        reasonCode: 'provider_or_repository_failure',
      );
    }
    lastSynchronizationOutcome = result.status;
    lastRecordsRead = result.recordsRead;
    lastInsertedCount = result.insertedCount;
    lastUpdatedCount = result.updatedCount;
    lastDeletedCount = result.deletedCount;
    lastRejectedCount = result.rejectedCount;
    lastMetricResults = Map.unmodifiable(result.metricResults);
    if (result.status == HealthSyncStatus.success) {
      lastSuccessfulSynchronization = _clock().toUtc();
      state = HealthConnectionViewState.synchronizedWithRecords;
    } else if (result.status == HealthSyncStatus.partial) {
      if (successfulMetrics.isNotEmpty) {
        lastSuccessfulSynchronization = _clock().toUtc();
      }
      state = HealthConnectionViewState.synchronizationPartiallySuccessful;
      failureReason = result.reasonCode;
    } else if (result.status == HealthSyncStatus.permissionDenied ||
        result.status == HealthSyncStatus.permissionRequired) {
      state = HealthConnectionViewState.permissionsRevoked;
    } else {
      state = HealthConnectionViewState.synchronizationFailed;
      failureReason = result.reasonCode;
    }
    await _refreshRecordSummary();
    if (result.status == HealthSyncStatus.success && importedRecordCount == 0) {
      state = HealthConnectionViewState.synchronizedNoRecords;
    }
    try {
      await _persist();
    } finally {
      _operationInProgress = false;
    }
    notifyListeners();
    return result;
  }

  Future<HealthSynchronizationResult> retryFailedMetrics() {
    final retryMetrics = failedMetrics;
    if (retryMetrics.isEmpty) {
      return Future.value(const HealthSynchronizationResult(
        status: HealthSyncStatus.cancelled,
        reasonCode: 'no_failed_metrics_to_retry',
      ));
    }
    return synchronize(requestedMetrics: retryMetrics);
  }

  Future<void> disconnect() async {
    _locallyConnected = false;
    state = HealthConnectionViewState.disconnected;
    await _persist();
    notifyListeners();
  }

  Future<int> deleteImportedData() async {
    final count =
        await _repository.deleteImportedProvider(_provider.providerId);
    await _refreshRecordSummary();
    lastSynchronizationOutcome = null;
    lastSuccessfulSynchronization = null;
    lastRecordsRead = 0;
    lastInsertedCount = 0;
    lastUpdatedCount = 0;
    lastDeletedCount = 0;
    lastRejectedCount = 0;
    lastMetricResults = const {};
    failureReason = null;
    state = _locallyConnected
        ? HealthConnectionViewState.connectedNotSynchronized
        : HealthConnectionViewState.disconnected;
    await _persist();
    notifyListeners();
    return count;
  }

  Future<void> openSettings() => _provider.openSettings();

  String get _storageKey => _provider.providerId == 'android.health_connect'
      ? 'health_connect_connection_v1'
      : 'health_connection_${_provider.providerId}_v1';

  Future<void> _refreshRecordSummary() async {
    final records = <CanonicalHealthRecord>[];
    var offset = 0;
    while (true) {
      final page = await _repository.records(
        metrics: metrics,
        limit: HealthDataRepository.maximumPageSize,
        offset: offset,
      );
      records.addAll(
          page.where((record) => record.providerId == _provider.providerId));
      if (page.length < HealthDataRepository.maximumPageSize) break;
      offset += page.length;
    }
    importedRecordCount = records.length;
    availableMetrics = records.map((record) => record.metric).toSet();
    earliestRecordTime = records.isEmpty
        ? null
        : records
            .map((record) => record.startTime)
            .reduce((a, b) => a.isBefore(b) ? a : b);
    latestRecordTime = records.isEmpty
        ? null
        : records
            .map((record) => record.endTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);
    final sourceCounts = <String, int>{};
    for (final record in records) {
      final source = record.provenance.sourceApplicationName?.trim();
      final id = record.provenance.sourceApplicationId.trim();
      final label = source?.isNotEmpty == true ? source! : id;
      if (label.isEmpty || label == 'unknown') continue;
      sourceCounts.update(label, (count) => count + 1, ifAbsent: () => 1);
    }
    contributingApplicationRecordCounts = Map.unmodifiable(sourceCounts);
  }

  Future<void> _persist() => _store.writeString(
        _storageKey,
        jsonEncode({
          'connected': _locallyConnected,
          'permissionRequested': _permissionRequested,
          'lastAttempted': lastAttemptedSynchronization?.toIso8601String(),
          'lastSuccessful': lastSuccessfulSynchronization?.toIso8601String(),
          'lastOutcome': lastSynchronizationOutcome?.name,
          'recordsRead': lastRecordsRead,
          'inserted': lastInsertedCount,
          'updated': lastUpdatedCount,
          'deleted': lastDeletedCount,
          'rejected': lastRejectedCount,
          'failureReason': failureReason,
          'metricResults': {
            for (final entry in lastMetricResults.entries)
              entry.key.name: {
                'status': entry.value.status.name,
                'reasonCode': entry.value.reasonCode,
              },
          },
        }),
      );

  HealthConnectionViewState _restoredConnectedState() =>
      switch (lastSynchronizationOutcome) {
        HealthSyncStatus.success => importedRecordCount == 0
            ? HealthConnectionViewState.synchronizedNoRecords
            : HealthConnectionViewState.synchronizedWithRecords,
        HealthSyncStatus.partial =>
          HealthConnectionViewState.synchronizationPartiallySuccessful,
        HealthSyncStatus.failed ||
        HealthSyncStatus.unavailable ||
        HealthSyncStatus.unsupported ||
        HealthSyncStatus.cancelled =>
          HealthConnectionViewState.synchronizationFailed,
        HealthSyncStatus.permissionDenied ||
        HealthSyncStatus.permissionRequired =>
          HealthConnectionViewState.permissionsRevoked,
        null => HealthConnectionViewState.connectedNotSynchronized,
      };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  static int _nonNegativeInt(Object? value) =>
      value is int && value >= 0 ? value : 0;

  static String? _safeCode(Object? value) =>
      value is String && RegExp(r'^[a-z0-9_]{1,80}$').hasMatch(value)
          ? value
          : null;

  static HealthSyncStatus? _syncStatus(Object? value) {
    if (value is! String) return null;
    for (final status in HealthSyncStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  static Map<HealthMetric, HealthMetricSynchronizationResult> _metricResults(
    Object? value,
  ) {
    if (value is! Map) return const {};
    final results = <HealthMetric, HealthMetricSynchronizationResult>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! Map) continue;
      HealthMetric? metric;
      for (final candidate in HealthMetric.values) {
        if (candidate.name == entry.key) {
          metric = candidate;
          break;
        }
      }
      if (metric == null) continue;
      final encoded = entry.value as Map;
      final status = _syncStatus(encoded['status']);
      if (status == null) continue;
      results[metric] = HealthMetricSynchronizationResult(
        status: status,
        reasonCode: _safeCode(encoded['reasonCode']),
      );
    }
    return Map.unmodifiable(results);
  }
}
