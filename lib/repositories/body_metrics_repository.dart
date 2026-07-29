import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/body_metrics.dart';
import '../storage/local_store.dart';
import 'storage_recovery.dart';

class BodyMetricsRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.body_metrics.v1';
  static const _category = 'body_metrics';

  final HydrionLocalStore _store;
  HydrionBodyMetrics _metrics;
  List<StorageRecoveryEvent> _recoveryEvents;

  BodyMetricsRepository._(
    this._store,
    this._metrics,
    this._recoveryEvents,
  );

  BodyMetricsRepository.memory([
    HydrionBodyMetrics metrics = const HydrionBodyMetrics(),
  ]) : this._(MemoryHydrionStore(), metrics, const []);

  static Future<BodyMetricsRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    final decoded = _decode(raw);
    return BodyMetricsRepository._(
      store,
      decoded.metrics,
      decoded.recoveryEvents,
    );
  }

  HydrionBodyMetrics get metrics => _metrics;
  List<StorageRecoveryEvent> get recoveryEvents =>
      List.unmodifiable(_recoveryEvents);

  Future<bool> save(
    HydrionBodyMetrics value, {
    required bool femaleProfile,
    DateTime? now,
  }) async {
    if (value.weightKg != null &&
        !HydrionBodyMetricsPolicy.validWeight(value.weightKg)) {
      return false;
    }
    if (value.heightCm != null &&
        !HydrionBodyMetricsPolicy.validHeight(value.heightCm)) {
      return false;
    }
    if (value.pregnancyGestationalDays != null &&
        !HydrionBodyMetricsPolicy.validPregnancyDays(
          value.pregnancyGestationalDays,
        )) {
      return false;
    }
    _metrics = value
        .sanitized(femaleProfile: femaleProfile)
        .copyWith(updatedAt: now ?? DateTime.now());
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> update({
    bool? personalizationEnabled,
    double? weightKg,
    bool clearWeight = false,
    double? heightCm,
    bool clearHeight = false,
    HydrionWeightUnit? preferredWeightUnit,
    HydrionHeightUnit? preferredHeightUnit,
    HydrionReproductiveHydrationState? reproductiveState,
    int? pregnancyGestationalDays,
    bool clearPregnancyDuration = false,
    HydrionPregnancyDurationUnit? preferredPregnancyDurationUnit,
    HydrionFluidSafetyMode? fluidSafetyMode,
    int? clinicianTargetMl,
    bool clearClinicianTarget = false,
    bool? allowAdjustmentsAboveClinicianTarget,
    int? wakeMinuteOfDay,
    bool clearWakeTime = false,
    int? sleepMinuteOfDay,
    bool clearSleepTime = false,
    required bool femaleProfile,
    DateTime? now,
  }) {
    return save(
      _metrics.copyWith(
        personalizationEnabled: personalizationEnabled,
        weightKg: weightKg,
        clearWeight: clearWeight,
        heightCm: heightCm,
        clearHeight: clearHeight,
        preferredWeightUnit: preferredWeightUnit,
        preferredHeightUnit: preferredHeightUnit,
        reproductiveState: reproductiveState,
        pregnancyGestationalDays: pregnancyGestationalDays,
        clearPregnancyDuration: clearPregnancyDuration,
        preferredPregnancyDurationUnit: preferredPregnancyDurationUnit,
        fluidSafetyMode: fluidSafetyMode,
        clinicianTargetMl: clinicianTargetMl,
        clearClinicianTarget: clearClinicianTarget,
        allowAdjustmentsAboveClinicianTarget:
            allowAdjustmentsAboveClinicianTarget,
        wakeMinuteOfDay: wakeMinuteOfDay,
        clearWakeTime: clearWakeTime,
        sleepMinuteOfDay: sleepMinuteOfDay,
        clearSleepTime: clearSleepTime,
      ),
      femaleProfile: femaleProfile,
      now: now,
    );
  }

  Future<void> clear() async {
    _metrics = const HydrionBodyMetrics();
    _recoveryEvents = const [];
    await _store.remove(storageKey);
    notifyListeners();
  }

  Future<void> _persist() =>
      _store.writeString(storageKey, jsonEncode(_metrics.toJson()));

  static _BodyMetricsDecodeResult _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _BodyMetricsDecodeResult(HydrionBodyMetrics());
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const _BodyMetricsDecodeResult(
          HydrionBodyMetrics(),
          [
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.wrongTopLevelType,
              action: StorageRecoveryActions.fallbackDefaults,
            ),
          ],
        );
      }
      final version = storageSchemaVersion(decoded) ?? 1;
      if (version > HydrionBodyMetricsPolicy.schemaVersion) {
        return _BodyMetricsDecodeResult(
          const HydrionBodyMetrics(),
          [
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.unsupportedSchemaVersion,
              action: StorageRecoveryActions.preserveRawFallback,
              schemaVersion: version,
            ),
          ],
        );
      }
      final metrics = HydrionBodyMetrics.fromJson(decoded);
      final invalidValues =
          (decoded['weightKg'] != null && metrics.weightKg == null) ||
              (decoded['heightCm'] != null && metrics.heightCm == null) ||
              (decoded['pregnancyGestationalDays'] != null &&
                  decoded['reproductiveState'] == 'pregnant' &&
                  metrics.pregnancyGestationalDays == null);
      return _BodyMetricsDecodeResult(
        metrics,
        invalidValues
            ? const [
                StorageRecoveryEvent(
                  category: _category,
                  code: StorageRecoveryCodes.invalidValue,
                  action: StorageRecoveryActions.fallbackDefaults,
                ),
              ]
            : const [],
      );
    } on FormatException {
      return const _BodyMetricsDecodeResult(
        HydrionBodyMetrics(),
        [
          StorageRecoveryEvent(
            category: _category,
            code: StorageRecoveryCodes.malformedJson,
            action: StorageRecoveryActions.fallbackDefaults,
            errorType: 'FormatException',
          ),
        ],
      );
    }
  }
}

class _BodyMetricsDecodeResult {
  final HydrionBodyMetrics metrics;
  final List<StorageRecoveryEvent> recoveryEvents;

  const _BodyMetricsDecodeResult(
    this.metrics, [
    this.recoveryEvents = const [],
  ]);
}
