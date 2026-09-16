import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/health_data.dart';

abstract interface class HealthKitBridge {
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]);

  Future<void> openSettings();
}

class MethodChannelHealthKitBridge implements HealthKitBridge {
  static const _channel = MethodChannel('hydrion/health_kit');

  const MethodChannelHealthKitBridge();

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
      throw const FormatException('HealthKit returned no result.');
    }
    return value;
  }

  @override
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');
}

class AppleHealthKitProvider implements UserManagedHealthDataProvider {
  static const id = 'apple.health_kit';
  static const _schemaVersion = 1;
  static const _maximumAnchorLength = 16384;
  static const supportedMetrics = <HealthMetric>{
    HealthMetric.workout,
    HealthMetric.activeEnergy,
    HealthMetric.steps,
    HealthMetric.distance,
  };

  final HealthKitBridge _bridge;
  final DateTime Function() _clock;

  const AppleHealthKitProvider({
    HealthKitBridge bridge = const MethodChannelHealthKitBridge(),
    DateTime Function()? clock,
  })  : _bridge = bridge,
        _clock = clock ?? DateTime.now;

  @override
  String get providerId => id;

  @override
  Set<HealthMetric> get connectionMetrics => supportedMetrics;

  // HealthKit deliberately does not reveal whether read access was denied.
  @override
  bool get readAuthorizationIsOpaque => true;

  @override
  Future<HealthProviderAvailability> availability() async {
    try {
      final response = await _bridge.invoke('availability');
      return response['available'] == true
          ? const HealthProviderAvailability(
              HealthProviderAvailabilityStatus.available,
            )
          : const HealthProviderAvailability(
              HealthProviderAvailabilityStatus.unsupported,
              reasonCode: 'health_kit_unavailable',
            );
    } on MissingPluginException {
      return const HealthProviderAvailability(
        HealthProviderAvailabilityStatus.unsupported,
        reasonCode: 'health_kit_unavailable',
      );
    }
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
        metrics,
      );
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
      metrics,
    );
  }

  @override
  Future<HealthImportPage> readChanges(HealthSyncCheckpoint checkpoint) async {
    if (checkpoint.providerId != providerId ||
        !supportedMetrics.contains(checkpoint.metric)) {
      throw const FormatException('Invalid HealthKit checkpoint.');
    }
    final cursor = _decodeCursor(checkpoint.cursor);
    final historyEnd = cursor?['historyEnd'] is String
        ? DateTime.parse(cursor!['historyEnd']! as String).toUtc()
        : _clock().toUtc();
    late final Map<String, Object?> response;
    try {
      response = await _bridge.invoke('readAnchored', {
        'metric': checkpoint.metric.name,
        'historyStart': checkpoint.historyStart.toUtc().toIso8601String(),
        'historyEnd': historyEnd.toIso8601String(),
        if (cursor?['anchor'] case final String anchor) 'anchor': anchor,
      });
    } on PlatformException catch (error) {
      if (error.code == 'invalid_anchor') {
        return HealthImportPage(
          records: const [],
          nextCheckpoint: checkpoint,
          checkpointExpired: true,
        );
      }
      throw HealthDataProviderException(switch (error.code) {
        'health_kit_read_failed' => 'health_kit_read_failed',
        'health_kit_mapping_failed' => 'health_kit_mapping_failed',
        'invalid_request' => 'health_kit_invalid_request',
        _ => 'health_kit_provider_failure',
      });
    }
    if (response['schemaVersion'] != _schemaVersion) {
      throw const FormatException('Unsupported HealthKit response schema.');
    }
    final anchor = _string(response['anchor']);
    final hasMore = response['hasMore'] == true;
    return HealthImportPage(
      records: _records(response, checkpoint.metric),
      nextCheckpoint: HealthSyncCheckpoint(
        providerId: providerId,
        metric: checkpoint.metric,
        cursor: _encodeCursor(
          anchor,
          historyEnd: hasMore ? historyEnd : null,
        ),
        historyStart: checkpoint.historyStart,
        lastSuccessfulSync: hasMore ? null : _clock().toUtc(),
      ),
      hasMore: hasMore,
    );
  }

  @override
  Future<void> openSettings() => _bridge.openSettings();

  HealthAuthorizationState _authorization(
    Map<String, Object?> value,
    Set<HealthMetric> requested,
  ) {
    final status = value['requestStatus'];
    if (status == 'shouldRequest') {
      return const HealthAuthorizationState(
        status: HealthPermissionStatus.notRequested,
      );
    }
    if (status != 'unnecessary') {
      return const HealthAuthorizationState(
        status: HealthPermissionStatus.unavailable,
      );
    }
    // These categories are authorized to be queried, not known to be granted.
    // A denied HealthKit read returns no samples by design.
    return HealthAuthorizationState(
      status: HealthPermissionStatus.requestCompleted,
      grantedMetrics: requested,
    );
  }

  List<CanonicalHealthRecord> _records(
    Map<String, Object?> response,
    HealthMetric expectedMetric,
  ) {
    final raw = response['records'];
    if (raw is! List<Object?> || raw.length > 250) {
      throw const FormatException('Invalid HealthKit record page.');
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
    if (value['schemaVersion'] != _schemaVersion) {
      throw const FormatException('Unsupported HealthKit record schema.');
    }
    final metric = _enumByName(HealthMetric.values, _string(value['metric']));
    if (metric != expectedMetric || !supportedMetrics.contains(metric)) {
      throw const FormatException('HealthKit metric mismatch.');
    }
    final externalId = _bounded(_string(value['recordId']), 512);
    if (value['deleted'] == true) {
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
          sourcePlatform: 'ios',
          sourceApplicationId: 'unknown',
          acquisitionRoute: HealthAcquisitionRoute.healthKit,
          entryMethod: HealthEntryMethod.unknown,
        ),
        isDeleted: true,
      );
    }
    final number = value['value'];
    if (number is! num || !number.isFinite || number < 0) {
      throw const FormatException('Invalid HealthKit value.');
    }
    final originalUnit =
        _enumByName(HealthUnit.values, _string(value['originalUnit']));
    final canonicalUnit = _canonicalUnit(metric);
    if (originalUnit != canonicalUnit) {
      throw const FormatException('Incompatible HealthKit unit.');
    }
    final start = DateTime.parse(_string(value['startTime'])).toUtc();
    final end = DateTime.parse(_string(value['endTime'])).toUtc();
    final sourceApplicationId =
        _bounded(_string(value['sourceApplicationId']), 512);
    final sourceApplicationName =
        _nullableBounded(value['sourceApplicationName'], 200);
    final category = _nullableString(value['category']);
    return CanonicalHealthRecord(
      id: '$providerId:${metric.name}:$externalId',
      providerId: providerId,
      externalRecordId: externalId,
      synchronizationVersion: _bounded(
        _string(value['synchronizationVersion']),
        512,
      ),
      metric: metric,
      semanticId: _semanticId(metric),
      value: number.toDouble(),
      originalUnit: originalUnit,
      unit: canonicalUnit,
      category: category,
      startTime: start,
      endTime: end,
      sourceTimeZone: _nullableBounded(value['sourceTimeZone'], 100),
      sourceUtcOffset: _offset(value['startOffsetSeconds']),
      ingestedAt: _clock().toUtc(),
      temporalPrecision: HealthTemporalPrecision.second,
      shape: HealthRecordShape.interval,
      valueOrigin: HealthValueOrigin.rawSensor,
      provenance: HealthProvenance(
        sourcePlatform: 'ios',
        sourceApplicationId: sourceApplicationId,
        sourceApplicationName: sourceApplicationName,
        physicalDeviceId: _nullableBounded(value['physicalDeviceId'], 512),
        manufacturer: _nullableBounded(value['deviceManufacturer'], 200),
        deviceModel: _nullableBounded(value['deviceModel'], 200),
        deviceHardwareVersion:
            _nullableBounded(value['deviceHardwareVersion'], 200),
        deviceSoftwareVersion:
            _nullableBounded(value['deviceSoftwareVersion'], 200),
        acquisitionRoute: HealthAcquisitionRoute.healthKit,
        entryMethod: _entryMethod(value['recordingMethod']),
      ),
      providerMetadata: {
        'providerDataType': metric.name,
        if (_nullableBounded(value['sourceRevision'], 512)
            case final String revision)
          'providerSourceRevision': revision,
        if (metric == HealthMetric.workout && category != null)
          'workoutActivityType': _bounded(category, 64),
      },
    )..validate();
  }

  void _validateMetrics(Set<HealthMetric> metrics) {
    if (metrics.isEmpty || !supportedMetrics.containsAll(metrics)) {
      throw const FormatException('Unsupported HealthKit metric request.');
    }
  }

  static String _encodeCursor(
    String anchor, {
    DateTime? historyEnd,
  }) =>
      jsonEncode({
        'version': _schemaVersion,
        'anchor': _bounded(anchor, _maximumAnchorLength),
        if (historyEnd != null) 'historyEnd': historyEnd.toIso8601String(),
      });

  static Map<String, Object?>? _decodeCursor(String? cursor) {
    if (cursor == null || cursor.trim().isEmpty) return null;
    final trimmed = cursor.trim();
    if (!trimmed.startsWith('{')) {
      return {'version': 0, 'anchor': _bounded(trimmed, _maximumAnchorLength)};
    }
    final decoded = jsonDecode(trimmed);
    if (decoded is! Map<String, Object?> ||
        decoded['version'] != _schemaVersion) {
      throw const FormatException('Unsupported HealthKit checkpoint schema.');
    }
    final anchor = _bounded(_string(decoded['anchor']), _maximumAnchorLength);
    final historyEnd = _nullableString(decoded['historyEnd']);
    if (historyEnd != null) DateTime.parse(historyEnd);
    return {
      'version': _schemaVersion,
      'anchor': anchor,
      if (historyEnd != null) 'historyEnd': historyEnd,
    };
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
        'manual' => HealthEntryMethod.manual,
        'sensor' => HealthEntryMethod.sensor,
        _ => HealthEntryMethod.unknown,
      };

  static Duration? _offset(Object? seconds) => seconds is int
      ? Duration(seconds: seconds)
      : seconds is num
          ? Duration(seconds: seconds.toInt())
          : null;

  static String _string(Object? value) {
    if (value is! String || value.isEmpty) {
      throw const FormatException('Required HealthKit field is missing.');
    }
    return value;
  }

  static String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static String _bounded(String value, int maximum) {
    if (value.length > maximum) {
      throw const FormatException('HealthKit field is too long.');
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
