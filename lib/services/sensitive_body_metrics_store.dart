import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for the subset of `HydrionBodyMetrics` fields that are
/// high/medium-high sensitivity health, reproductive, or clinical data
/// (HYD-SEC-001; see `HYD_SEC_001_STORAGE_DESIGN.md` Tier 1).
///
/// This deliberately covers only the fields that feed
/// `PersonalizedHydrationEngine`'s target derivation: weight, height,
/// reproductive state, pregnancy duration, fluid-safety mode, clinician
/// target, and the clinician-adjustment-allowance flag. It follows the same
/// Keychain/Keystore-backed pattern already used for the wearable health
/// database key in `health_database_key_store.dart`, reusing the existing
/// `flutter_secure_storage` dependency rather than introducing a second
/// encryption mechanism.
abstract interface class SensitiveBodyMetricsStore {
  /// Returns the stored field map, or null if nothing has been migrated or
  /// written yet (including when secure storage is unsupported on this
  /// platform).
  Future<Map<String, Object?>?> read();

  /// Overwrites the stored field map atomically as a single value.
  Future<void> write(Map<String, Object?> fields);

  /// Deletes the stored field map, if any.
  Future<void> delete();

  /// False on platforms with no Keychain/Keystore-backed secure storage
  /// (matching `health_database_key_store.dart`'s own platform gate).
  /// Callers must keep sensitive fields in the existing plaintext store as
  /// a fail-safe fallback when this is false, never block on it.
  bool get isSupported;
}

class PlatformSensitiveBodyMetricsStore implements SensitiveBodyMetricsStore {
  static const _storageKey = 'hydrion.body_metrics.sensitive.v1';
  static const _androidOptions = AndroidOptions(
    resetOnError: false,
    storageNamespace: 'hydrion_body_metrics',
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
    accountName: 'com.the1807.hydrion.body-metrics',
  );

  final FlutterSecureStorage _storage;

  PlatformSensitiveBodyMetricsStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<Map<String, Object?>?> read() async {
    if (!isSupported) return null;
    try {
      final raw = await _storage.read(
        key: _storageKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      // Corrupt or inaccessible secure storage must never crash the app or
      // be mistaken for "no sensitive data exists" that would license
      // deleting the plaintext fallback. Treat as unavailable this run.
      return null;
    }
  }

  @override
  Future<void> write(Map<String, Object?> fields) async {
    if (!isSupported) return;
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(fields),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (_) {
      // A failed write must never crash or corrupt caller state. Callers
      // that require confirmation (BodyMetricsRepository) always verify by
      // read-back before treating sensitive data as migrated, so a
      // swallowed failure here safely degrades to "not yet migrated"
      // rather than losing data.
    }
  }

  @override
  Future<void> delete() async {
    if (!isSupported) return;
    try {
      await _storage.delete(
        key: _storageKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (_) {
      // Best-effort: nothing else to fall back to for a delete.
    }
  }
}

/// In-memory fake for tests. [supported] defaults to true; set it false to
/// exercise the "secure storage unavailable on this platform" fallback path.
class MemorySensitiveBodyMetricsStore implements SensitiveBodyMetricsStore {
  Map<String, Object?>? _value;
  final bool supported;

  MemorySensitiveBodyMetricsStore({
    Map<String, Object?>? initial,
    this.supported = true,
  }) : _value = initial == null ? null : Map<String, Object?>.from(initial);

  @override
  bool get isSupported => supported;

  @override
  Future<Map<String, Object?>?> read() async =>
      !supported || _value == null ? null : Map<String, Object?>.from(_value!);

  @override
  Future<void> write(Map<String, Object?> fields) async {
    if (!supported) return;
    _value = Map<String, Object?>.from(fields);
  }

  @override
  Future<void> delete() async {
    _value = null;
  }
}
