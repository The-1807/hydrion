enum HealthMetric {
  workout,
  activeEnergy,
  steps,
  distance,
  heartRate,
  restingHeartRate,
  hrvSdnn,
  hrvRmssd,
  sleep,
  respiratoryRate,
  skinTemperature,
  bodyTemperature,
  bloodOxygen,
  stressScore,
  recoveryScore,
  readinessScore,
  weight,
  bodyComposition,
}

enum HealthUnit {
  count,
  meter,
  kilocalorie,
  beatsPerMinute,
  minute,
  hour,
  kilogram,
  percent,
  celsius,
  millisecond,
}

enum HealthRecordShape { sample, interval, aggregate }

enum HealthTemporalPrecision { instant, second, minute, hour, day }

enum HealthValueOrigin {
  rawSensor,
  platformDerived,
  providerDerived,
  hydrionDerived
}

enum HealthEntryMethod { sensor, manual, unknown }

enum HealthAcquisitionRoute {
  healthKit,
  healthConnect,
  vendorCloud,
  vendorSdk,
  wearableCompanion,
  bluetooth,
  test,
}

enum HealthProviderAvailabilityStatus {
  available,
  unsupported,
  unavailable,
  installationRequired,
  updateRequired,
}

enum HealthPermissionStatus {
  notRequested,
  granted,
  partial,
  denied,
  revoked,
  unavailable,
}

enum HealthSyncStatus {
  success,
  partial,
  cancelled,
  unsupported,
  unavailable,
  permissionRequired,
  permissionDenied,
  failed,
}

class HealthProviderAvailability {
  final HealthProviderAvailabilityStatus status;
  final String? reasonCode;

  const HealthProviderAvailability(this.status, {this.reasonCode});

  bool get canConnect => status == HealthProviderAvailabilityStatus.available;
}

class HealthProviderCapabilities {
  final Set<HealthMetric> readableMetrics;
  final bool supportsIncrementalChanges;
  final bool supportsDeletions;
  final bool supportsBackgroundReads;

  const HealthProviderCapabilities({
    required this.readableMetrics,
    required this.supportsIncrementalChanges,
    required this.supportsDeletions,
    required this.supportsBackgroundReads,
  });

  const HealthProviderCapabilities.unsupported()
      : readableMetrics = const <HealthMetric>{},
        supportsIncrementalChanges = false,
        supportsDeletions = false,
        supportsBackgroundReads = false;
}

class HealthAuthorizationState {
  final HealthPermissionStatus status;
  final Set<HealthMetric> grantedMetrics;

  const HealthAuthorizationState({
    required this.status,
    this.grantedMetrics = const <HealthMetric>{},
  });

  bool permits(HealthMetric metric) => grantedMetrics.contains(metric);
}

class HealthProvenance {
  final String sourcePlatform;
  final String sourceApplicationId;
  final String? sourceApplicationName;
  final String? physicalDeviceId;
  final String? manufacturer;
  final String? deviceModel;
  final String? deviceHardwareVersion;
  final String? deviceSoftwareVersion;
  final HealthAcquisitionRoute acquisitionRoute;
  final HealthEntryMethod entryMethod;

  const HealthProvenance({
    required this.sourcePlatform,
    required this.sourceApplicationId,
    this.sourceApplicationName,
    this.physicalDeviceId,
    this.manufacturer,
    this.deviceModel,
    this.deviceHardwareVersion,
    this.deviceSoftwareVersion,
    required this.acquisitionRoute,
    required this.entryMethod,
  });

  String get sourceKey => '$sourcePlatform|$sourceApplicationId';
}

class CanonicalHealthRecord {
  static const currentSchemaVersion = 1;
  static const allowedProviderMetadataKeys = <String>{
    'providerDataType',
    'providerSourceRevision',
    'workoutActivityType',
  };

  final int schemaVersion;
  final String id;
  final String providerId;
  final String externalRecordId;
  final String synchronizationVersion;
  final HealthMetric metric;
  final String semanticId;
  final int semanticVersion;
  final double value;
  final HealthUnit originalUnit;
  final HealthUnit unit;
  final String? category;
  final DateTime startTime;
  final DateTime endTime;
  final String? sourceTimeZone;
  final Duration? sourceUtcOffset;
  final DateTime? recordedAt;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final DateTime ingestedAt;
  final HealthTemporalPrecision temporalPrecision;
  final HealthRecordShape shape;
  final String? aggregationMethod;
  final HealthValueOrigin valueOrigin;
  final HealthProvenance provenance;
  final String quality;
  final bool isDeleted;
  final String? supersedesExternalRecordId;
  final String? duplicateOfRecordId;
  final String? algorithmVersion;
  final List<String> contributingRecordIds;
  final int providerMetadataVersion;
  final Map<String, String> providerMetadata;

  const CanonicalHealthRecord({
    this.schemaVersion = currentSchemaVersion,
    required this.id,
    required this.providerId,
    required this.externalRecordId,
    required this.synchronizationVersion,
    required this.metric,
    required this.semanticId,
    this.semanticVersion = 1,
    required this.value,
    HealthUnit? originalUnit,
    required this.unit,
    this.category,
    required this.startTime,
    required this.endTime,
    this.sourceTimeZone,
    this.sourceUtcOffset,
    this.recordedAt,
    this.createdAt,
    this.modifiedAt,
    required this.ingestedAt,
    this.temporalPrecision = HealthTemporalPrecision.instant,
    required this.shape,
    this.aggregationMethod,
    required this.valueOrigin,
    required this.provenance,
    this.quality = 'unknown',
    this.isDeleted = false,
    this.supersedesExternalRecordId,
    this.duplicateOfRecordId,
    this.algorithmVersion,
    this.contributingRecordIds = const <String>[],
    this.providerMetadataVersion = 1,
    this.providerMetadata = const <String, String>{},
  }) : originalUnit = originalUnit ?? unit;

  String get providerRecordKey =>
      '$providerId|${provenance.sourceKey}|$externalRecordId';

  bool get isDerived => valueOrigin == HealthValueOrigin.hydrionDerived;

  void validate() {
    if (schemaVersion <= 0 ||
        id.trim().isEmpty ||
        providerId.trim().isEmpty ||
        externalRecordId.trim().isEmpty ||
        semanticId.trim().isEmpty ||
        synchronizationVersion.trim().isEmpty) {
      throw const FormatException('Health record identity is incomplete.');
    }
    if (!value.isFinite || endTime.isBefore(startTime)) {
      throw const FormatException(
          'Health record value or time range is invalid.');
    }
    if (providerMetadataVersion <= 0 ||
        !providerMetadata.keys.every(allowedProviderMetadataKeys.contains)) {
      throw const FormatException(
        'Provider metadata must be versioned and use allowlisted keys.',
      );
    }
    if (isDerived &&
        ((algorithmVersion?.trim().isEmpty ?? true) ||
            contributingRecordIds.isEmpty)) {
      throw const FormatException(
        'Derived records require algorithm and contributing-record metadata.',
      );
    }
  }

  CanonicalHealthRecord copyWith({
    String? duplicateOfRecordId,
    bool clearDuplicateOfRecordId = false,
  }) {
    return CanonicalHealthRecord(
      schemaVersion: schemaVersion,
      id: id,
      providerId: providerId,
      externalRecordId: externalRecordId,
      synchronizationVersion: synchronizationVersion,
      metric: metric,
      semanticId: semanticId,
      semanticVersion: semanticVersion,
      value: value,
      originalUnit: originalUnit,
      unit: unit,
      category: category,
      startTime: startTime,
      endTime: endTime,
      sourceTimeZone: sourceTimeZone,
      sourceUtcOffset: sourceUtcOffset,
      recordedAt: recordedAt,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      ingestedAt: ingestedAt,
      temporalPrecision: temporalPrecision,
      shape: shape,
      aggregationMethod: aggregationMethod,
      valueOrigin: valueOrigin,
      provenance: provenance,
      quality: quality,
      isDeleted: isDeleted,
      supersedesExternalRecordId: supersedesExternalRecordId,
      duplicateOfRecordId: clearDuplicateOfRecordId
          ? null
          : duplicateOfRecordId ?? this.duplicateOfRecordId,
      algorithmVersion: algorithmVersion,
      contributingRecordIds: contributingRecordIds,
      providerMetadataVersion: providerMetadataVersion,
      providerMetadata: providerMetadata,
    );
  }
}

class HealthSyncCheckpoint {
  final String providerId;
  final HealthMetric metric;
  final String? cursor;
  final DateTime historyStart;
  final DateTime? lastSuccessfulSync;

  const HealthSyncCheckpoint({
    required this.providerId,
    required this.metric,
    this.cursor,
    required this.historyStart,
    this.lastSuccessfulSync,
  });
}

class HealthImportPage {
  final List<CanonicalHealthRecord> records;
  final HealthSyncCheckpoint nextCheckpoint;
  final bool hasMore;
  final bool checkpointExpired;

  const HealthImportPage({
    required this.records,
    required this.nextCheckpoint,
    this.hasMore = false,
    this.checkpointExpired = false,
  });
}

class HealthSynchronizationResult {
  final HealthSyncStatus status;
  final int importedCount;
  final int deletedCount;
  final int duplicateCount;
  final String? reasonCode;

  const HealthSynchronizationResult({
    required this.status,
    this.importedCount = 0,
    this.deletedCount = 0,
    this.duplicateCount = 0,
    this.reasonCode,
  });
}

abstract interface class HealthDataProvider {
  String get providerId;

  Future<HealthProviderAvailability> availability();

  Future<HealthProviderCapabilities> capabilities();

  Future<HealthAuthorizationState> authorizationState(
    Set<HealthMetric> metrics,
  );

  Future<HealthAuthorizationState> requestReadAccess(
    Set<HealthMetric> metrics,
  );

  Future<HealthImportPage> readChanges(HealthSyncCheckpoint checkpoint);
}
