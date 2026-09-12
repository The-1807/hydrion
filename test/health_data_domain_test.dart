import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';

void main() {
  group('canonical health record', () {
    test('preserves provider, physical-device and acquisition provenance', () {
      final record = _record();

      expect(record.providerId, 'health-connect');
      expect(record.provenance.sourceApplicationId, 'com.vendor.health');
      expect(record.provenance.physicalDeviceId, 'watch-42');
      expect(
        record.provenance.acquisitionRoute,
        HealthAcquisitionRoute.healthConnect,
      );
      expect(record.providerRecordKey, contains('external-1'));
      expect(record.isDerived, isFalse);
      expect(record.validate, returnsNormally);
    });

    test('rejects invalid time ranges and non-finite values', () {
      final backwards = _record(
        start: DateTime.utc(2026, 9, 11, 11),
        end: DateTime.utc(2026, 9, 11, 10),
      );
      final nonFinite = _record(value: double.nan);

      expect(backwards.validate, throwsFormatException);
      expect(nonFinite.validate, throwsFormatException);
    });

    test('derived records require algorithm and contributing records', () {
      final invalid = _record(valueOrigin: HealthValueOrigin.hydrionDerived);
      final valid = _record(
        valueOrigin: HealthValueOrigin.hydrionDerived,
        algorithmVersion: 'test-v1',
        contributingRecordIds: const ['source-1'],
      );

      expect(invalid.validate, throwsFormatException);
      expect(valid.validate, returnsNormally);
    });

    test('keeps provider correction and supersession identity', () {
      final corrected = CanonicalHealthRecord(
        id: 'local-2',
        providerId: 'health-connect',
        externalRecordId: 'external-2',
        synchronizationVersion: '2',
        metric: HealthMetric.workout,
        semanticId: 'exercise.session.duration',
        value: 35,
        unit: HealthUnit.minute,
        startTime: DateTime.utc(2026, 9, 11, 10),
        endTime: DateTime.utc(2026, 9, 11, 10, 35),
        ingestedAt: DateTime.utc(2026, 9, 11, 12),
        shape: HealthRecordShape.interval,
        valueOrigin: HealthValueOrigin.platformDerived,
        provenance: const HealthProvenance(
          sourcePlatform: 'android',
          sourceApplicationId: 'com.vendor.health',
          acquisitionRoute: HealthAcquisitionRoute.healthConnect,
          entryMethod: HealthEntryMethod.sensor,
        ),
        supersedesExternalRecordId: 'external-1',
      );

      expect(corrected.supersedesExternalRecordId, 'external-1');
      expect(corrected.synchronizationVersion, '2');
      expect(corrected.validate, returnsNormally);
    });

    test('preserves unit conversion context and temporal lifecycle metadata',
        () {
      final record = CanonicalHealthRecord(
        id: 'converted',
        providerId: 'health-connect',
        externalRecordId: 'energy-1',
        synchronizationVersion: '1',
        metric: HealthMetric.activeEnergy,
        semanticId: 'active.energy',
        value: 125,
        originalUnit: HealthUnit.kilocalorie,
        unit: HealthUnit.kilocalorie,
        startTime: DateTime.utc(2026, 9, 11, 10),
        endTime: DateTime.utc(2026, 9, 11, 11),
        sourceTimeZone: 'America/Toronto',
        sourceUtcOffset: const Duration(hours: -4),
        temporalPrecision: HealthTemporalPrecision.minute,
        recordedAt: DateTime.utc(2026, 9, 11, 11),
        createdAt: DateTime.utc(2026, 9, 11, 11, 1),
        modifiedAt: DateTime.utc(2026, 9, 11, 11, 2),
        ingestedAt: DateTime.utc(2026, 9, 11, 11, 3),
        shape: HealthRecordShape.aggregate,
        valueOrigin: HealthValueOrigin.platformDerived,
        provenance: const HealthProvenance(
          sourcePlatform: 'android',
          sourceApplicationId: 'com.vendor.health',
          acquisitionRoute: HealthAcquisitionRoute.healthConnect,
          entryMethod: HealthEntryMethod.sensor,
        ),
        providerMetadata: const {
          'providerDataType': 'ActiveCaloriesBurnedRecord',
        },
      );

      expect(record.originalUnit, HealthUnit.kilocalorie);
      expect(record.temporalPrecision, HealthTemporalPrecision.minute);
      expect(record.sourceTimeZone, 'America/Toronto');
      expect(record.sourceUtcOffset, const Duration(hours: -4));
      expect(record.validate, returnsNormally);
    });

    test('rejects unversioned or non-allowlisted provider extensions', () {
      final unknown = _recordWithMetadata({'vendorBlob': 'opaque'});
      final unversioned = _recordWithMetadata(
        const {'providerDataType': 'Workout'},
        version: 0,
      );

      expect(unknown.validate, throwsFormatException);
      expect(unversioned.validate, throwsFormatException);
    });
  });

  test('availability and granular permissions are explicit', () {
    const unavailable = HealthProviderAvailability(
      HealthProviderAvailabilityStatus.installationRequired,
      reasonCode: 'health_connect_install_required',
    );
    const partial = HealthAuthorizationState(
      status: HealthPermissionStatus.partial,
      grantedMetrics: {HealthMetric.workout},
    );

    expect(unavailable.canConnect, isFalse);
    expect(partial.permits(HealthMetric.workout), isTrue);
    expect(partial.permits(HealthMetric.heartRate), isFalse);
  });
}

CanonicalHealthRecord _recordWithMetadata(
  Map<String, String> metadata, {
  int version = 1,
}) {
  return CanonicalHealthRecord(
    id: 'metadata',
    providerId: 'health-connect',
    externalRecordId: 'metadata-1',
    synchronizationVersion: '1',
    metric: HealthMetric.workout,
    semanticId: 'exercise.session.duration',
    value: 30,
    unit: HealthUnit.minute,
    startTime: DateTime.utc(2026, 9, 11, 10),
    endTime: DateTime.utc(2026, 9, 11, 10, 30),
    ingestedAt: DateTime.utc(2026, 9, 11, 12),
    shape: HealthRecordShape.interval,
    valueOrigin: HealthValueOrigin.rawSensor,
    provenance: const HealthProvenance(
      sourcePlatform: 'android',
      sourceApplicationId: 'com.vendor.health',
      acquisitionRoute: HealthAcquisitionRoute.healthConnect,
      entryMethod: HealthEntryMethod.sensor,
    ),
    providerMetadataVersion: version,
    providerMetadata: metadata,
  );
}

CanonicalHealthRecord _record({
  DateTime? start,
  DateTime? end,
  double value = 30,
  HealthValueOrigin valueOrigin = HealthValueOrigin.rawSensor,
  String? algorithmVersion,
  List<String> contributingRecordIds = const [],
}) {
  return CanonicalHealthRecord(
    id: 'local-1',
    providerId: 'health-connect',
    externalRecordId: 'external-1',
    synchronizationVersion: '1',
    metric: HealthMetric.workout,
    semanticId: 'exercise.session.duration',
    value: value,
    unit: HealthUnit.minute,
    startTime: start ?? DateTime.utc(2026, 9, 11, 10),
    endTime: end ?? DateTime.utc(2026, 9, 11, 10, 30),
    ingestedAt: DateTime.utc(2026, 9, 11, 12),
    shape: HealthRecordShape.interval,
    valueOrigin: valueOrigin,
    provenance: const HealthProvenance(
      sourcePlatform: 'android',
      sourceApplicationId: 'com.vendor.health',
      physicalDeviceId: 'watch-42',
      manufacturer: 'Vendor',
      deviceModel: 'Watch',
      acquisitionRoute: HealthAcquisitionRoute.healthConnect,
      entryMethod: HealthEntryMethod.sensor,
    ),
    algorithmVersion: algorithmVersion,
    contributingRecordIds: contributingRecordIds,
  );
}
