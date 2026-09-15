import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/android_health_provider.dart';
import '../domain/health_data.dart';
import 'android_health_provider_discovery.dart';

abstract interface class HealthConnectBridge {
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]);

  Future<void> openSettings();
}

class MethodChannelHealthConnectBridge implements HealthConnectBridge {
  static const _channel = MethodChannel('hydrion/health_connect');

  const MethodChannelHealthConnectBridge();

  @override
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    final value = await _channel.invokeMapMethod<String, Object?>(
      method,
      arguments,
    );
    if (value == null) {
      throw const FormatException('Health Connect returned no result.');
    }
    return value;
  }

  @override
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');
}

class AndroidHealthConnectProvider implements UserManagedHealthDataProvider {
  static const id = 'android.health_connect';
  static const supportedMetrics = <HealthMetric>{
    HealthMetric.workout,
    HealthMetric.activeEnergy,
    HealthMetric.steps,
    HealthMetric.distance,
  };

  final HealthConnectBridge _bridge;
  final AndroidHealthProviderDiscovery _discovery;
  final DateTime Function() _clock;

  const AndroidHealthConnectProvider({
    HealthConnectBridge bridge = const MethodChannelHealthConnectBridge(),
    AndroidHealthProviderDiscovery discovery =
        const AndroidHealthProviderDiscovery(),
    DateTime Function()? clock,
  })  : _bridge = bridge,
        _discovery = discovery,
        _clock = clock ?? DateTime.now;

  @override
  String get providerId => id;

  @override
  Set<HealthMetric> get connectionMetrics => supportedMetrics;

  @override
  bool get readAuthorizationIsOpaque => false;

  @override
  Future<void> openSettings() => _bridge.openSettings();

  @override
  Future<HealthProviderAvailability> availability() async {
    final environment = await _discovery.discover();
    if (environment.healthConnectStatus ==
        AndroidHealthProviderStatus.available) {
      return const HealthProviderAvailability(
        HealthProviderAvailabilityStatus.available,
      );
    }
    if (environment.healthConnectStatus ==
        AndroidHealthProviderStatus.installationRequired) {
      return const HealthProviderAvailability(
        HealthProviderAvailabilityStatus.installationRequired,
        reasonCode: 'health_connect_installation_required',
      );
    }
    if (environment.healthConnectStatus ==
        AndroidHealthProviderStatus.updateRequired) {
      return const HealthProviderAvailability(
        HealthProviderAvailabilityStatus.updateRequired,
        reasonCode: 'health_connect_update_required',
      );
    }
    if (environment.healthConnectStatus ==
            AndroidHealthProviderStatus.unsupported ||
        environment.healthConnectStatus ==
            AndroidHealthProviderStatus.workProfileUnsupported) {
      return HealthProviderAvailability(
        HealthProviderAvailabilityStatus.unsupported,
        reasonCode: environment.healthConnectStatus.name,
      );
    }
    return HealthProviderAvailability(
      HealthProviderAvailabilityStatus.unavailable,
      reasonCode: environment.healthConnectStatus.name,
    );
  }

  @override
  Future<HealthProviderCapabilities> capabilities() async =>
      const HealthProviderCapabilities(
        readableMetrics: supportedMetrics,
        supportsIncrementalChanges: true,
        supportsDeletions: true,
        supportsBackgroundReads: false,
      );

  @override
  Future<HealthAuthorizationState> authorizationState(
    Set<HealthMetric> metrics,
  ) async {
    _validateMetrics(metrics);
    try {
      return _authorization(
          await _bridge.invoke('authorizationState', {
            'metrics': metrics.map((metric) => metric.name).toList(),
          }),
          metrics);
    } on MissingPluginException {
      return const HealthAuthorizationState(
        status: HealthPermissionStatus.unavailable,
      );
    }
  }

  @override
  Future<HealthAuthorizationState> requestReadAccess(
    Set<HealthMetric> metrics,
  ) async {
    _validateMetrics(metrics);
    return _authorization(
        await _bridge.invoke('requestPermissions', {
          'metrics': metrics.map((metric) => metric.name).toList(),
        }),
        metrics);
  }

  @override
  Future<HealthImportPage> readChanges(HealthSyncCheckpoint checkpoint) async {
    if (checkpoint.providerId != providerId ||
        !supportedMetrics.contains(checkpoint.metric)) {
      throw const FormatException('Invalid Health Connect checkpoint.');
    }
    final cursor = _decodeCursor(checkpoint.cursor);
    if (cursor == null || cursor['phase'] == 'initial') {
      return _readInitial(checkpoint, cursor);
    }
    if (cursor['phase'] != 'changes') {
      throw const FormatException('Unknown Health Connect checkpoint phase.');
    }
    final response = await _invokeRead('readChanges', {
      'metric': checkpoint.metric.name,
      'changesToken': _requiredString(cursor, 'token'),
    });
    final expired = response['tokenExpired'] == true;
    final nextToken = _string(response['changesToken']);
    return HealthImportPage(
      records: expired ? const [] : _records(response, checkpoint.metric),
      nextCheckpoint: HealthSyncCheckpoint(
        providerId: providerId,
        metric: checkpoint.metric,
        cursor: expired
            ? checkpoint.cursor
            : _encodeCursor({'phase': 'changes', 'token': nextToken}),
        historyStart: checkpoint.historyStart,
        lastSuccessfulSync: expired ? null : _clock().toUtc(),
      ),
      hasMore: !expired && response['hasMore'] == true,
      checkpointExpired: expired,
    );
  }

  Future<HealthImportPage> _readInitial(
    HealthSyncCheckpoint checkpoint,
    Map<String, Object?>? cursor,
  ) async {
    final end = cursor == null
        ? _clock().toUtc()
        : DateTime.parse(_requiredString(cursor, 'end')).toUtc();
    final response = await _invokeRead('readInitial', {
      'metric': checkpoint.metric.name,
      'historyStart': checkpoint.historyStart.toUtc().toIso8601String(),
      'historyEnd': end.toIso8601String(),
      if (cursor?['page'] is String) 'pageToken': cursor!['page'],
      if (cursor?['token'] is String) 'changesToken': cursor!['token'],
    });
    final token = _string(response['changesToken']);
    final page = _nullableString(response['pageToken']);
    final nextCursor = page == null
        ? {'phase': 'changes', 'token': token}
        : {
            'phase': 'initial',
            'token': token,
            'page': page,
            'end': end.toIso8601String(),
          };
    return HealthImportPage(
      records: _records(response, checkpoint.metric),
      nextCheckpoint: HealthSyncCheckpoint(
        providerId: providerId,
        metric: checkpoint.metric,
        cursor: _encodeCursor(nextCursor),
        historyStart: checkpoint.historyStart,
        lastSuccessfulSync: page == null ? _clock().toUtc() : null,
      ),
      hasMore: page != null,
    );
  }

  Future<Map<String, Object?>> _invokeRead(
    String method,
    Map<String, Object?> arguments,
  ) async {
    try {
      return await _bridge.invoke(method, arguments);
    } on PlatformException catch (error) {
      final reasonCode = switch (error.code) {
        'permission_denied' => 'permission_denied',
        'health_connect_io_failure' => 'health_connect_io_failure',
        'health_connect_invalid_request' => 'health_connect_invalid_request',
        _ => 'health_connect_read_failure',
      };
      throw HealthDataProviderException(reasonCode);
    }
  }

  List<CanonicalHealthRecord> _records(
    Map<String, Object?> response,
    HealthMetric expectedMetric,
  ) {
    final raw = response['records'];
    if (raw is! List<Object?> || raw.length > 250) {
      throw const FormatException('Invalid Health Connect record page.');
    }
    return raw
        .map((value) => _record(
              Map<String, Object?>.from(value! as Map),
              expectedMetric,
            ))
        .toList(growable: false);
  }

  CanonicalHealthRecord _record(
    Map<String, Object?> value,
    HealthMetric expectedMetric,
  ) {
    final metric = _enumByName(HealthMetric.values, _string(value['metric']));
    if (metric != expectedMetric || !supportedMetrics.contains(metric)) {
      throw const FormatException('Health Connect metric mismatch.');
    }
    final externalId = _bounded(_string(value['recordId']), 512);
    final deleted = value['deleted'] == true;
    if (deleted) {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      return CanonicalHealthRecord(
        id: '$providerId:${metric.name}:$externalId',
        providerId: providerId,
        externalRecordId: externalId,
        synchronizationVersion: 'deleted',
        metric: metric,
        semanticId: _semanticId(metric),
        value: 0,
        unit: _canonicalUnit(metric),
        startTime: epoch,
        endTime: epoch,
        ingestedAt: _clock().toUtc(),
        shape: HealthRecordShape.interval,
        valueOrigin: HealthValueOrigin.rawSensor,
        provenance: const HealthProvenance(
          sourcePlatform: 'android',
          sourceApplicationId: 'unknown',
          acquisitionRoute: HealthAcquisitionRoute.healthConnect,
          entryMethod: HealthEntryMethod.unknown,
        ),
        isDeleted: true,
      );
    }
    final number = value['value'];
    if (number is! num || !number.isFinite || number < 0) {
      throw const FormatException('Invalid Health Connect value.');
    }
    final originalUnit =
        _enumByName(HealthUnit.values, _string(value['originalUnit']));
    final canonicalUnit = _canonicalUnit(metric);
    if (originalUnit != canonicalUnit) {
      throw const FormatException('Incompatible Health Connect unit.');
    }
    final start = DateTime.parse(_string(value['startTime'])).toUtc();
    final end = DateTime.parse(_string(value['endTime'])).toUtc();
    final modified = DateTime.parse(_string(value['lastModifiedTime'])).toUtc();
    final sourceApplicationId =
        _bounded(_string(value['sourceApplicationId']), 512);
    final category = _nullableString(value['category']);
    return CanonicalHealthRecord(
      id: '$providerId:${metric.name}:$externalId',
      providerId: providerId,
      externalRecordId: externalId,
      synchronizationVersion:
          '${modified.microsecondsSinceEpoch}:${_string(value['clientRecordVersion'])}',
      metric: metric,
      semanticId: _semanticId(metric),
      value: number.toDouble(),
      originalUnit: originalUnit,
      unit: canonicalUnit,
      category: category,
      startTime: start,
      endTime: end,
      sourceUtcOffset: _offset(value['startOffsetSeconds']),
      modifiedAt: modified,
      ingestedAt: _clock().toUtc(),
      temporalPrecision: HealthTemporalPrecision.second,
      shape: HealthRecordShape.interval,
      valueOrigin: HealthValueOrigin.rawSensor,
      provenance: HealthProvenance(
        sourcePlatform: 'android',
        sourceApplicationId: sourceApplicationId,
        manufacturer: _nullableBounded(value['deviceManufacturer'], 200),
        deviceModel: _nullableBounded(value['deviceModel'], 200),
        acquisitionRoute: HealthAcquisitionRoute.healthConnect,
        entryMethod: _entryMethod(value['recordingMethod']),
      ),
      providerMetadata: {
        'providerDataType': metric.name,
        if (metric == HealthMetric.workout && category != null)
          'workoutActivityType': _bounded(category, 64),
      },
    )..validate();
  }

  HealthAuthorizationState _authorization(
    Map<String, Object?> value,
    Set<HealthMetric> requested,
  ) {
    final raw = value['grantedMetrics'];
    if (raw is! List<Object?>) {
      throw const FormatException('Invalid Health Connect authorization.');
    }
    final granted = raw
        .map((name) => _enumByName(HealthMetric.values, _string(name)))
        .where(requested.contains)
        .toSet();
    return HealthAuthorizationState(
      status: granted.length == requested.length
          ? HealthPermissionStatus.granted
          : granted.isNotEmpty
              ? HealthPermissionStatus.partial
              : HealthPermissionStatus.denied,
      grantedMetrics: granted,
    );
  }

  void _validateMetrics(Set<HealthMetric> metrics) {
    if (metrics.isEmpty || !supportedMetrics.containsAll(metrics)) {
      throw const FormatException('Unsupported Health Connect metric request.');
    }
  }

  static const _checkpointVersion = 1;
  static const _maximumLegacyTokenLength = 4096;

  static String _encodeCursor(Map<String, Object?> value) => jsonEncode({
        'version': _checkpointVersion,
        ...value,
      });

  static Map<String, Object?>? _decodeCursor(String? cursor) {
    if (cursor == null || cursor.trim().isEmpty) return null;
    final trimmed = cursor.trim();
    if (!trimmed.startsWith('{')) {
      if (trimmed.length > _maximumLegacyTokenLength) {
        throw const FormatException(
            'Legacy Health Connect checkpoint is too long.');
      }
      return <String, Object?>{
        'version': 0,
        'phase': 'changes',
        'token': trimmed,
      };
    }
    late final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      throw const FormatException('Malformed Health Connect checkpoint.');
    }
    if (decoded is! Map) {
      throw const FormatException('Invalid Health Connect checkpoint.');
    }
    final value = Map<String, Object?>.from(decoded);
    final version = value['version'];
    if (version != null && version != _checkpointVersion) {
      throw const FormatException(
          'Unsupported Health Connect checkpoint version.');
    }
    final phase = value['phase'];
    if (phase != 'initial' && phase != 'changes') {
      throw const FormatException('Unknown Health Connect checkpoint phase.');
    }
    return value;
  }

  static String _semanticId(HealthMetric metric) => switch (metric) {
        HealthMetric.workout => 'exercise.session.duration',
        HealthMetric.activeEnergy => 'activity.active_energy',
        HealthMetric.steps => 'activity.steps',
        HealthMetric.distance => 'activity.distance',
        _ => throw const FormatException('Unsupported metric.'),
      };

  static HealthUnit _canonicalUnit(HealthMetric metric) => switch (metric) {
        HealthMetric.workout => HealthUnit.minute,
        HealthMetric.activeEnergy => HealthUnit.kilocalorie,
        HealthMetric.steps => HealthUnit.count,
        HealthMetric.distance => HealthUnit.meter,
        _ => throw const FormatException('Unsupported metric.'),
      };

  static HealthEntryMethod _entryMethod(Object? value) => switch (value) {
        'sensor' => HealthEntryMethod.sensor,
        'manual' => HealthEntryMethod.manual,
        _ => HealthEntryMethod.unknown,
      };

  static Duration? _offset(Object? seconds) => seconds is int
      ? Duration(seconds: seconds)
      : seconds is num
          ? Duration(seconds: seconds.toInt())
          : null;

  static String _requiredString(Map<String, Object?> value, String key) =>
      _string(value[key]);

  static String _string(Object? value) {
    if (value is! String || value.isEmpty) {
      throw const FormatException('Required Health Connect field is missing.');
    }
    return value;
  }

  static String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static String _bounded(String value, int maximum) {
    if (value.length > maximum) {
      throw const FormatException('Health Connect field is too long.');
    }
    return value;
  }

  static String? _nullableBounded(Object? value, int maximum) {
    final text = _nullableString(value);
    return text == null ? null : _bounded(text, maximum);
  }

  static T _enumByName<T extends Enum>(List<T> values, String name) =>
      values.firstWhere(
        (entry) => entry.name == name,
        orElse: () => throw const FormatException('Unknown enum value.'),
      );
}
