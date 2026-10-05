import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/body_metrics.dart';
import '../services/sensitive_body_metrics_store.dart';
import '../storage/local_store.dart';
import 'storage_recovery.dart';

enum BodyMetricsStatus {
  available,
  absent,
  pendingSecure,
  unsupported,
  unavailable,
  corrupt,
  ambiguous,
  deletionPending,
}

final class BodyMetricsDeletionIncomplete implements Exception {
  const BodyMetricsDeletionIncomplete();
  @override
  String toString() => 'BodyMetricsDeletionIncomplete';
}

enum BodyMetricsWriteStatus {
  notAttempted,
  verified,
  writeFailed,
  verificationFailed,
  localWriteFailed,
}

final class BodyMetricsState {
  final BodyMetricsStatus status;
  final HydrionBodyMetrics? value;
  final int revision;
  const BodyMetricsState._(this.status, this.value, this.revision);
  bool get isKnown => value != null;
  @override
  String toString() => 'BodyMetricsState(${status.name})';
}

final class BodyMetricsUnavailable implements Exception {
  final BodyMetricsStatus status;
  const BodyMetricsUnavailable(this.status);
  @override
  String toString() => 'BodyMetricsUnavailable(${status.name})';
}

/// HTD SEC-001 body aggregate: clinical values, routines and update history.
/// Units stay in preferences; profile/settings are a separately scoped store.
/// DATA-007 revision authority and DATA-008 deletion intent remain authoritative.
class BodyMetricsRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.body_metrics.v1';
  static const _migrationMarkerKey = 'hydrion.body_metrics.secure_migration.v1';
  static const _migrationCompleted = 'completed';
  static const _category = 'body_metrics';

  final HydrionLocalStore _store;
  final SensitiveBodyMetricsStore _secureStore;
  HydrionBodyMetrics _metrics;
  List<StorageRecoveryEvent> _recoveryEvents;
  int _revision = 0;
  BodyMetricsStatus _status = BodyMetricsStatus.available;
  BodyMetricsWriteStatus lastWriteStatus = BodyMetricsWriteStatus.notAttempted;
  Future<void> _tail = Future.value();
  static const _authorityKey = '_bodyAuthority';
  static const _secureRevisionKey = '_bodyRevision';
  static const _deletionKey = '_bodyDeletion';
  static const _deletionRecord =
      '{"_bodyDeletion":{"version":1,"pending":true}}';
  SensitiveBodyDeleteStatus? lastDeleteStatus;

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
    final repository = BodyMetricsRepository._(
      store,
      resolvedSecureStore,
      decoded.metrics,
      decoded.recoveryEvents,
    );
    await repository._restore(raw);
    return repository;
  }

  BodyMetricsState get state => BodyMetricsState._(
      _status,
      switch (_status) {
        BodyMetricsStatus.unavailable ||
        BodyMetricsStatus.corrupt ||
        BodyMetricsStatus.ambiguous ||
        BodyMetricsStatus.deletionPending =>
          null,
        _ => _metrics,
      },
      _revision);
  HydrionBodyMetrics get metrics =>
      state.value ?? (throw BodyMetricsUnavailable(_status));
  int? get wakeMinuteOfDay => state.value?.wakeMinuteOfDay;
  int? get sleepMinuteOfDay => state.value?.sleepMinuteOfDay;
  bool get canSave =>
      state.isKnown &&
      _status != BodyMetricsStatus.pendingSecure &&
      _status != BodyMetricsStatus.unsupported;

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> reload() => _serial(() async {
        if (_status == BodyMetricsStatus.deletionPending) {
          await _clear();
          return;
        }
        final loaded = await load(_store, secureStore: _secureStore);
        _metrics = loaded._metrics;
        _status = loaded._status;
        _revision = loaded._revision;
        _recoveryEvents = loaded._recoveryEvents;
        lastWriteStatus = loaded.lastWriteStatus;
        notifyListeners();
      });
  List<StorageRecoveryEvent> get recoveryEvents =>
      List.unmodifiable(_recoveryEvents);

  Future<bool> save(
    HydrionBodyMetrics value, {
    required bool femaleProfile,
    DateTime? now,
  }) =>
      _serial(() => _save(value, femaleProfile: femaleProfile, now: now));

  Future<bool> _save(
    HydrionBodyMetrics value, {
    required bool femaleProfile,
    DateTime? now,
  }) async {
    lastWriteStatus = BodyMetricsWriteStatus.notAttempted;
    if (!canSave) return false;
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
    final next = sanitized.copyWith(
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
    final accepted = await _persist(next);
    notifyListeners();
    return accepted;
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
    return _serial(() => _save(
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
        ));
  }

  Future<void> clear() => _serial(_clear);

  Future<void> _clear() async {
    _metrics = const HydrionBodyMetrics();
    _status = BodyMetricsStatus.deletionPending;
    _recoveryEvents = const [];
    lastDeleteStatus = null;
    notifyListeners();
    // Replaces plaintext and authority atomically with payload-free intent.
    // No secure mutation is allowed before native acknowledgement of intent.
    if (!await _writeDeletionRecord(storageKey, _deletionRecord)) {
      throw const BodyMetricsDeletionIncomplete();
    }
    try {
      lastDeleteStatus = await _secureStore.delete();
    } catch (_) {
      lastDeleteStatus = SensitiveBodyDeleteStatus.failed;
    }
    if (lastDeleteStatus != SensitiveBodyDeleteStatus.verifiedAbsent) {
      throw const BodyMetricsDeletionIncomplete();
    }
    // Blank acknowledged values avoid optimistic remove-cache readback being
    // mistaken for native deletion. Neither value contains profile data.
    if (!await _writeDeletionRecord(_migrationMarkerKey, '') ||
        !await _writeDeletionRecord(storageKey, '{}')) {
      throw const BodyMetricsDeletionIncomplete();
    }
    _revision = 0;
    _status = BodyMetricsStatus.absent;
    notifyListeners();
  }

  Future<bool> _writeDeletionRecord(String key, String value) async {
    try {
      if (await _store.writeString(key, value) &&
          await _store.readString(key) == value) {
        return true;
      }
    } catch (_) {
      // Only the typed state is exposed, never native exception payloads.
    }
    lastWriteStatus = BodyMetricsWriteStatus.localWriteFailed;
    return false;
  }

  Future<bool> _writeRecord(HydrionBodyMetrics value, int revision) async {
    final record = _plaintextJson(value);
    record[_authorityKey] = {
      'version': 2,
      'revision': revision,
      'pending': false
    };
    final encoded = jsonEncode(record);
    try {
      if (!await _store.writeString(storageKey, encoded)) {
        lastWriteStatus = BodyMetricsWriteStatus.localWriteFailed;
        return false;
      }
      if (await _store.readString(storageKey) != encoded) {
        lastWriteStatus = BodyMetricsWriteStatus.localWriteFailed;
        return false;
      }
      return true;
    } catch (_) {
      lastWriteStatus = BodyMetricsWriteStatus.localWriteFailed;
      return false;
    }
  }

  Future<SensitiveBodyRead> _readSecure() async {
    try {
      return await _secureStore.readResult();
    } catch (_) {
      return const SensitiveBodyRead.unavailable();
    }
  }

  Future<bool> _writeAndVerify(HydrionBodyMetrics value, int revision) async {
    if (!_secureStore.isSupported) {
      lastWriteStatus = BodyMetricsWriteStatus.writeFailed;
      return false;
    }
    final fields = {
      ..._secureFields(value),
      '_bodySchema': 2,
      _secureRevisionKey: revision,
    };
    try {
      await _secureStore.write(fields);
    } catch (_) {
      lastWriteStatus = BodyMetricsWriteStatus.writeFailed;
      return false;
    }
    final result = await _readSecure();
    if (result.status != SensitiveBodyReadStatus.found ||
        !_fieldsEqual(result.fields!, fields)) {
      lastWriteStatus = BodyMetricsWriteStatus.verificationFailed;
      return false;
    }
    lastWriteStatus = BodyMetricsWriteStatus.verified;
    return true;
  }

  Future<void> _markMigrated() async {
    // Compatibility hint only; authority is in the same record as the data.
    try {
      await _store.writeString(_migrationMarkerKey, _migrationCompleted);
    } catch (_) {
      // Losing this legacy hint cannot change revision ordering.
    }
  }

  Future<bool> _persist(HydrionBodyMetrics next) async {
    final revision = _revision + 1;
    final verified = await _writeAndVerify(next, revision);
    if (!verified) {
      // A failed acknowledgement may still have changed the secure copy.
      // Retain the editor's unsaved draft, but require reconciliation before
      // another write. Never publish it as saved or write it to preferences.
      _status = BodyMetricsStatus.unavailable;
      return false;
    }
    if (!await _writeRecord(next, revision)) {
      // A secure write may already exist. Do not reuse its revision or expose
      // uncertain old memory as authoritative; reload reconciles both stores.
      _status = BodyMetricsStatus.unavailable;
      return false;
    }
    _revision = revision;
    _metrics = next;
    _status = BodyMetricsStatus.available;
    await _markMigrated();
    return true;
  }

  Future<void> _restore(String? raw) async {
    if (_recoveryEvents.isNotEmpty) {
      _status = BodyMetricsStatus.corrupt;
      return;
    }
    Map? local;
    try {
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is Map) local = decoded;
    } on FormatException {
      // Existing malformed-record diagnostics are retained by _decode.
    }
    if (local != null && local.containsKey(_deletionKey)) {
      // Any deletion envelope fails closed, including unknown/corrupt versions.
      // It is never a metrics revision and never imports surviving secure data.
      _metrics = const HydrionBodyMetrics();
      _status = BodyMetricsStatus.deletionPending;
      return;
    }
    if (local != null &&
        !_validSecureFields({
          ..._secureFields(const HydrionBodyMetrics()),
          ...Map<String, Object?>.from(local),
        })) {
      _status = BodyMetricsStatus.corrupt;
      return;
    }
    final authority = local?[_authorityKey];
    var pending = false;
    if (authority != null) {
      if (authority is! Map ||
          ![1, 2].contains(authority['version']) ||
          authority['revision'] is! int ||
          authority['revision'] < 0 ||
          authority['pending'] is! bool) {
        _status = BodyMetricsStatus.corrupt;
        return;
      }
      _revision = authority['revision'] as int;
      pending = authority['pending'] as bool;
      if (authority['version'] == 2 && pending) {
        _status = BodyMetricsStatus.corrupt;
        return;
      }
      if (pending && !_validSecureFields(Map<String, Object?>.from(local!))) {
        _status = BodyMetricsStatus.corrupt;
        return;
      }
    }
    final migrated =
        await _store.readString(_migrationMarkerKey) == _migrationCompleted;
    var secure = await _readSecure();
    if (secure.status == SensitiveBodyReadStatus.found &&
        !_validSecureFields(secure.fields!)) {
      secure = const SensitiveBodyRead.corrupt();
    }
    if (secure.status == SensitiveBodyReadStatus.unsupported) {
      _status = (authority != null && !pending) ||
              (migrated && !_hasAnySensitiveField(_metrics) && !pending)
          ? BodyMetricsStatus.unavailable
          : BodyMetricsStatus.unsupported;
      return;
    }
    if (secure.status == SensitiveBodyReadStatus.unavailable ||
        secure.status == SensitiveBodyReadStatus.corrupt) {
      _status =
          pending || (authority == null && _hasAnySensitiveField(_metrics))
              ? BodyMetricsStatus.pendingSecure
              : secure.status == SensitiveBodyReadStatus.corrupt
                  ? BodyMetricsStatus.corrupt
                  : BodyMetricsStatus.unavailable;
      return;
    }
    if (secure.status == SensitiveBodyReadStatus.absent) {
      if (authority != null && !pending ||
          migrated && !pending && !_hasAnySensitiveField(_metrics)) {
        _status = BodyMetricsStatus.unavailable;
        return;
      }
      if (!pending && !_hasAnySensitiveField(_metrics)) {
        _status = BodyMetricsStatus.absent;
        return;
      }
      // Legacy plaintext starts revision 1 only after confirmed secure absence.
      final legacy = authority == null;
      if (legacy) {
        _revision = 1;
      }
      await _recoverPending();
      return;
    }

    final fields = secure.fields!;
    if (authority is Map &&
        authority['version'] == 2 &&
        fields['_bodySchema'] != 2) {
      _status = BodyMetricsStatus.unavailable;
      return;
    }
    final secureRevision = fields[_secureRevisionKey] as int? ?? 0;
    final secureMetrics = _applySecureFields(_metrics, fields);
    final equal =
        _fieldsEqual(_secureFields(_metrics), _secureFields(secureMetrics));
    if (authority == null &&
        local != null &&
        _secureFields(const HydrionBodyMetrics()).keys.any(local.containsKey) &&
        !equal) {
      _status = BodyMetricsStatus.ambiguous;
      return;
    }
    if (pending && _revision > secureRevision) {
      await _recoverPending();
      return;
    }
    if (pending && _revision == secureRevision && !equal) {
      _status = BodyMetricsStatus.ambiguous;
      return;
    }
    if (!pending && authority != null && secureRevision < _revision) {
      _status = BodyMetricsStatus.unavailable;
      return;
    }
    _metrics = secureMetrics;
    _revision = secureRevision;
    // Old secure records did not own routines/timestamps. Merge their legacy
    // local fields only once, verify the expanded aggregate, then strip them.
    if (fields['_bodySchema'] != 2 &&
        !await _writeAndVerify(_metrics, _revision)) {
      _status = BodyMetricsStatus.pendingSecure;
      return;
    }
    _status = BodyMetricsStatus.available;
    // Strip only after a verified matching/newer secure revision, never simply
    // because a secure entry exists.
    if (!await _writeRecord(_metrics, _revision)) {
      _status = BodyMetricsStatus.unavailable;
      return;
    }
    await _markMigrated();
  }

  Future<void> _recoverPending() async {
    _status = BodyMetricsStatus.pendingSecure;
    if (!await _writeAndVerify(_metrics, _revision)) return;
    if (!await _writeRecord(_metrics, _revision)) {
      return;
    }
    _status = BodyMetricsStatus.available;
    await _markMigrated();
  }

  static bool _validSecureFields(Map<String, Object?> fields) {
    if (!_clinicalFields(const HydrionBodyMetrics())
        .keys
        .every(fields.containsKey)) {
      return false;
    }
    final revision = fields[_secureRevisionKey];
    if (revision != null && (revision is! int || revision < 0)) return false;
    final schema = fields['_bodySchema'];
    if (schema != null && schema != 2) return false;
    if (schema == 2 &&
        !_secureFields(const HydrionBodyMetrics())
            .keys
            .every(fields.containsKey)) {
      return false;
    }
    for (final key in ['wakeMinuteOfDay', 'sleepMinuteOfDay']) {
      final value = fields[key];
      if (value != null && (value is! int || value < 0 || value >= 1440)) {
        return false;
      }
    }
    for (final key in ['updatedAt', 'weightUpdatedAt', 'heightUpdatedAt']) {
      final value = fields[key];
      if (value != null &&
          (value is! String || DateTime.tryParse(value) == null)) {
        return false;
      }
    }
    if (fields.containsKey('personalizationEnabled') &&
        fields['personalizationEnabled'] is! bool) {
      return false;
    }
    final weight = fields['weightKg'];
    final height = fields['heightCm'];
    final days = fields['pregnancyGestationalDays'];
    final target = fields['clinicianTargetMl'];
    return (weight == null ||
            weight is num &&
                HydrionBodyMetricsPolicy.validWeight(weight.toDouble())) &&
        (height == null ||
            height is num &&
                HydrionBodyMetricsPolicy.validHeight(height.toDouble())) &&
        (days == null ||
            days is int && HydrionBodyMetricsPolicy.validPregnancyDays(days)) &&
        (target == null || target is int && target >= 500 && target <= 5000) &&
        HydrionReproductiveHydrationState.values
            .any((v) => v.name == fields['reproductiveState']) &&
        HydrionFluidSafetyMode.values
            .any((v) => v.name == fields['fluidSafetyMode']) &&
        fields['allowAdjustmentsAboveClinicianTarget'] is bool;
  }

  static bool _hasAnySensitiveField(HydrionBodyMetrics metrics) =>
      metrics.weightKg != null ||
      metrics.heightCm != null ||
      metrics.reproductiveState != HydrionReproductiveHydrationState.none ||
      metrics.pregnancyGestationalDays != null ||
      metrics.fluidSafetyMode != HydrionFluidSafetyMode.none ||
      metrics.clinicianTargetMl != null ||
      metrics.allowAdjustmentsAboveClinicianTarget ||
      metrics.personalizationEnabled ||
      metrics.wakeMinuteOfDay != null ||
      metrics.sleepMinuteOfDay != null ||
      metrics.updatedAt != null ||
      metrics.weightUpdatedAt != null ||
      metrics.heightUpdatedAt != null;

  static bool _fieldsEqual(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static Map<String, Object?> _clinicalFields(HydrionBodyMetrics metrics) => {
        'weightKg': metrics.weightKg,
        'heightCm': metrics.heightCm,
        'reproductiveState': metrics.reproductiveState.name,
        'pregnancyGestationalDays': metrics.pregnancyGestationalDays,
        'fluidSafetyMode': metrics.fluidSafetyMode.name,
        'clinicianTargetMl': metrics.clinicianTargetMl,
        'allowAdjustmentsAboveClinicianTarget':
            metrics.allowAdjustmentsAboveClinicianTarget,
      };

  static Map<String, Object?> _secureFields(HydrionBodyMetrics metrics) => {
        ..._clinicalFields(metrics),
        'personalizationEnabled': metrics.personalizationEnabled,
        'wakeMinuteOfDay': metrics.wakeMinuteOfDay,
        'sleepMinuteOfDay': metrics.sleepMinuteOfDay,
        'updatedAt': metrics.updatedAt?.toIso8601String(),
        'weightUpdatedAt': metrics.weightUpdatedAt?.toIso8601String(),
        'heightUpdatedAt': metrics.heightUpdatedAt?.toIso8601String(),
      };

  /// Explicit allowlist: no sensitive payload or ambiguous default sentinels.
  static Map<String, Object?> _plaintextJson(HydrionBodyMetrics metrics) {
    return {
      'schemaVersion': metrics.schemaVersion,
      'preferredWeightUnit': metrics.preferredWeightUnit.name,
      'preferredHeightUnit': metrics.preferredHeightUnit.name,
      'preferredPregnancyDurationUnit':
          metrics.preferredPregnancyDurationUnit.name,
    };
  }

  static HydrionBodyMetrics _applySecureFields(
    HydrionBodyMetrics base,
    Map<String, Object?> secure,
  ) {
    if (secure['_bodySchema'] == 2) {
      return HydrionBodyMetrics.fromJson({...base.toJson(), ...secure});
    }
    final weight = secure['weightKg'];
    final height = secure['heightCm'];
    final pregnancyDays = secure['pregnancyGestationalDays'];
    final clinicianTargetMl = secure['clinicianTargetMl'];
    final safeWeight =
        weight is num && HydrionBodyMetricsPolicy.validWeight(weight.toDouble())
            ? weight.toDouble()
            : null;
    final safeHeight =
        height is num && HydrionBodyMetricsPolicy.validHeight(height.toDouble())
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
