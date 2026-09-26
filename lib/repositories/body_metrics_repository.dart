import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/body_metrics.dart';
import '../services/sensitive_body_metrics_store.dart';
import '../storage/local_store.dart';
import 'storage_recovery.dart';

/// Fields covered by the HYD-SEC-001 secure-storage migration (Tier 1 of
/// `HYD_SEC_001_STORAGE_DESIGN.md`), scoped to those that feed
/// `PersonalizedHydrationEngine`'s target derivation. `nickname`, `age`, and
/// `sex` (also Tier 1 in the full design) live in `UserSettingsRepository`,
/// a separate repository/store key with many non-sensitive fields, and are
/// intentionally out of scope for this migration — see the Gate 1 report
/// for that scoping decision. The profile photo (Tier 2) is a different
/// storage shape (a file, not a scalar) and is also out of scope here.
class BodyMetricsRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.body_metrics.v1';
  static const _migrationMarkerKey =
      'hydrion.body_metrics.secure_migration.v1';
  static const _migrationCompleted = 'completed';
  static const _category = 'body_metrics';

  final HydrionLocalStore _store;
  final SensitiveBodyMetricsStore _secureStore;
  HydrionBodyMetrics _metrics;
  List<StorageRecoveryEvent> _recoveryEvents;

  BodyMetricsRepository._(
    this._store,
    this._secureStore,
    this._metrics,
    this._recoveryEvents,
  );

  BodyMetricsRepository.memory([
    HydrionBodyMetrics metrics = const HydrionBodyMetrics(),
  ]) : this._(
          MemoryHydrionStore(),
          MemorySensitiveBodyMetricsStore(),
          metrics,
          const [],
        );

  static Future<BodyMetricsRepository> load(
    HydrionLocalStore store, {
    SensitiveBodyMetricsStore? secureStore,
  }) async {
    final resolvedSecureStore =
        secureStore ?? PlatformSensitiveBodyMetricsStore();
    final raw = await store.readString(storageKey);
    final decoded = _decode(raw);
    final merged = await _mergeWithSecureStore(
      store: store,
      secureStore: resolvedSecureStore,
      plaintextMetrics: decoded.metrics,
    );
    return BodyMetricsRepository._(
      store,
      resolvedSecureStore,
      merged,
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
    final savedAt = now ?? DateTime.now();
    final sanitized = value.sanitized(femaleProfile: femaleProfile);
    final weightChanged = sanitized.weightKg != _metrics.weightKg;
    final heightChanged = sanitized.heightCm != _metrics.heightCm;
    _metrics = sanitized.copyWith(
      updatedAt: savedAt,
      weightUpdatedAt: weightChanged && sanitized.weightKg != null
          ? savedAt
          : sanitized.weightUpdatedAt,
      clearWeightUpdatedAt: sanitized.weightKg == null,
      heightUpdatedAt: heightChanged && sanitized.heightCm != null
          ? savedAt
          : sanitized.heightUpdatedAt,
      clearHeightUpdatedAt: sanitized.heightCm == null,
    );
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
    await _store.remove(_migrationMarkerKey);
    await _secureStore.delete();
    notifyListeners();
  }

  /// Writes the current metrics. Never strips the sensitive fields from
  /// the plaintext blob unless the secure copy is confirmed by read-back —
  /// an unsupported platform, a transient Keystore/Keychain failure, or
  /// any other write error all safely fall back to the pre-migration
  /// plaintext-only write rather than risking data loss.
  Future<void> _persist() async {
    if (_secureStore.isSupported) {
      final fields = _secureFields(_metrics);
      final verified = await _writeAndVerify(fields);
      if (verified) {
        await _store.writeString(
          storageKey,
          jsonEncode(_plaintextJson(_metrics)),
        );
        await _store.writeString(_migrationMarkerKey, _migrationCompleted);
        return;
      }
    }
    await _store.writeString(storageKey, jsonEncode(_metrics.toJson()));
  }

  Future<bool> _writeAndVerify(Map<String, Object?> fields) async {
    try {
      await _secureStore.write(fields);
      final verified = await _secureStore.read();
      return verified != null && _fieldsEqual(verified, fields);
    } catch (_) {
      return false;
    }
  }

  /// Merges the plaintext-decoded metrics with secure storage, performing
  /// the HYD-SEC-001 migration when needed.
  ///
  /// Idempotent and safe to run on every app start:
  /// - If secure storage already holds a value, it is authoritative for the
  ///   Tier-1 fields; if the plaintext blob still also carries those field
  ///   values (i.e. this is the first load after a previous run wrote the
  ///   secure copy but had not yet stripped plaintext), the plaintext
  ///   original is stripped now, on this separate, later app start — never
  ///   on the same run that first wrote the secure copy.
  /// - If secure storage holds nothing yet, the Tier-1 values already
  ///   present in the plaintext blob are copied to secure storage and
  ///   verified by read-back. Only once verified does the plaintext strip
  ///   happen (on the next load, per above) — a failed or unverifiable
  ///   write leaves the plaintext original untouched and is retried on the
  ///   next load.
  /// - On unsupported platforms, or when nothing has ever been saved, this
  ///   is a no-op and the plaintext blob remains the sole source, exactly
  ///   as before this migration existed.
  static Future<HydrionBodyMetrics> _mergeWithSecureStore({
    required HydrionLocalStore store,
    required SensitiveBodyMetricsStore secureStore,
    required HydrionBodyMetrics plaintextMetrics,
  }) async {
    if (!secureStore.isSupported) {
      return plaintextMetrics;
    }

    final existingSecure = await secureStore.read();
    if (existingSecure != null) {
      final merged = _applySecureFields(plaintextMetrics, existingSecure);
      // Verified secure copy already exists (marker may be stale after an
      // app reinstall/restore) — strip any lingering plaintext Tier-1
      // values now, on this later app start.
      if (_hasAnySensitiveField(plaintextMetrics)) {
        await store.writeString(
          BodyMetricsRepository.storageKey,
          jsonEncode(_plaintextJson(plaintextMetrics)),
        );
      }
      await store.writeString(
        BodyMetricsRepository._migrationMarkerKey,
        BodyMetricsRepository._migrationCompleted,
      );
      return merged;
    }

    if (!_hasAnySensitiveField(plaintextMetrics)) {
      // Nothing sensitive has ever been saved — nothing to migrate.
      return plaintextMetrics;
    }

    // First migration attempt for this install: write, then verify by
    // read-back before trusting the secure copy. Do NOT strip the
    // plaintext original on this same run even if verification succeeds —
    // that happens on the next load (see the branch above), so an
    // interruption between this write and the next app start never loses
    // data.
    final candidate = _secureFields(plaintextMetrics);
    await secureStore.write(candidate);
    final verified = await secureStore.read();
    if (verified != null && _fieldsEqual(verified, candidate)) {
      await store.writeString(
        BodyMetricsRepository._migrationMarkerKey,
        BodyMetricsRepository._migrationCompleted,
      );
    }
    // Whether or not verification succeeded, the plaintext original (still
    // fully intact) remains the safe fallback for this run.
    return plaintextMetrics;
  }

  static bool _hasAnySensitiveField(HydrionBodyMetrics metrics) =>
      metrics.weightKg != null ||
      metrics.heightCm != null ||
      metrics.reproductiveState != HydrionReproductiveHydrationState.none ||
      metrics.pregnancyGestationalDays != null ||
      metrics.fluidSafetyMode != HydrionFluidSafetyMode.none ||
      metrics.clinicianTargetMl != null ||
      metrics.allowAdjustmentsAboveClinicianTarget;

  static bool _fieldsEqual(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static Map<String, Object?> _secureFields(HydrionBodyMetrics metrics) => {
        'weightKg': metrics.weightKg,
        'heightCm': metrics.heightCm,
        'reproductiveState': metrics.reproductiveState.name,
        'pregnancyGestationalDays': metrics.pregnancyGestationalDays,
        'fluidSafetyMode': metrics.fluidSafetyMode.name,
        'clinicianTargetMl': metrics.clinicianTargetMl,
        'allowAdjustmentsAboveClinicianTarget':
            metrics.allowAdjustmentsAboveClinicianTarget,
      };

  /// The plaintext blob written once migration is active: everything
  /// `HydrionBodyMetrics.toJson()` produces, minus the Tier-1 secure
  /// fields, which are represented as absent/default rather than
  /// duplicated in plaintext.
  static Map<String, Object?> _plaintextJson(HydrionBodyMetrics metrics) {
    final json = metrics.toJson();
    json['weightKg'] = null;
    json['heightCm'] = null;
    json['reproductiveState'] = HydrionReproductiveHydrationState.none.name;
    json['pregnancyGestationalDays'] = null;
    json['fluidSafetyMode'] = HydrionFluidSafetyMode.none.name;
    json['clinicianTargetMl'] = null;
    json['allowAdjustmentsAboveClinicianTarget'] = false;
    return json;
  }

  static HydrionBodyMetrics _applySecureFields(
    HydrionBodyMetrics base,
    Map<String, Object?> secure,
  ) {
    final weight = secure['weightKg'];
    final height = secure['heightCm'];
    final pregnancyDays = secure['pregnancyGestationalDays'];
    final clinicianTargetMl = secure['clinicianTargetMl'];
    final safeWeight =
        weight is num && HydrionBodyMetricsPolicy.validWeight(weight.toDouble())
            ? weight.toDouble()
            : null;
    final safeHeight = height is num &&
            HydrionBodyMetricsPolicy.validHeight(height.toDouble())
        ? height.toDouble()
        : null;
    final safePregnancyDays = pregnancyDays is num &&
            HydrionBodyMetricsPolicy.validPregnancyDays(pregnancyDays.toInt())
        ? pregnancyDays.toInt()
        : null;
    final safeClinicianTarget = clinicianTargetMl is num
        ? clinicianTargetMl.round().clamp(500, 5000)
        : null;
    return base.copyWith(
      weightKg: safeWeight,
      clearWeight: safeWeight == null,
      heightCm: safeHeight,
      clearHeight: safeHeight == null,
      reproductiveState: _enumOrDefault(
        HydrionReproductiveHydrationState.values,
        secure['reproductiveState'],
        HydrionReproductiveHydrationState.none,
      ),
      pregnancyGestationalDays: safePregnancyDays,
      clearPregnancyDuration: safePregnancyDays == null,
      fluidSafetyMode: _enumOrDefault(
        HydrionFluidSafetyMode.values,
        secure['fluidSafetyMode'],
        HydrionFluidSafetyMode.none,
      ),
      clinicianTargetMl: safeClinicianTarget,
      clearClinicianTarget: safeClinicianTarget == null,
      allowAdjustmentsAboveClinicianTarget:
          secure['allowAdjustmentsAboveClinicianTarget'] == true,
    );
  }

  static T _enumOrDefault<T extends Enum>(
    List<T> values,
    Object? raw,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }

  static _BodyMetricsDecodeResult _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _BodyMetricsDecodeResult(HydrionBodyMetrics());
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const _BodyMetricsDecodeResult(HydrionBodyMetrics(), [
          StorageRecoveryEvent(
            category: _category,
            code: StorageRecoveryCodes.wrongTopLevelType,
            action: StorageRecoveryActions.fallbackDefaults,
          ),
        ]);
      }
      final version = storageSchemaVersion(decoded) ?? 1;
      if (version > HydrionBodyMetricsPolicy.schemaVersion) {
        return _BodyMetricsDecodeResult(const HydrionBodyMetrics(), [
          StorageRecoveryEvent(
            category: _category,
            code: StorageRecoveryCodes.unsupportedSchemaVersion,
            action: StorageRecoveryActions.preserveRawFallback,
            schemaVersion: version,
          ),
        ]);
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
      return const _BodyMetricsDecodeResult(HydrionBodyMetrics(), [
        StorageRecoveryEvent(
          category: _category,
          code: StorageRecoveryCodes.malformedJson,
          action: StorageRecoveryActions.fallbackDefaults,
          errorType: 'FormatException',
        ),
      ]);
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
