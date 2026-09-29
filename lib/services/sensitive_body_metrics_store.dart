import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SensitiveBodyReadStatus {
  found,
  absent,
  unavailable,
  corrupt,
  unsupported
}

enum SensitiveBodyDeleteStatus {
  verifiedAbsent,
  unavailable,
  failed,
  verificationFailed,
  unsupported,
}

final class SensitiveBodyRead {
  final SensitiveBodyReadStatus status;
  final Map<String, Object?>? fields;

  const SensitiveBodyRead._(this.status, [this.fields]);
  SensitiveBodyRead.found(Map<String, Object?> fields)
      : this._(SensitiveBodyReadStatus.found, Map.unmodifiable(fields));
  const SensitiveBodyRead.absent() : this._(SensitiveBodyReadStatus.absent);
  const SensitiveBodyRead.unavailable()
      : this._(SensitiveBodyReadStatus.unavailable);
  const SensitiveBodyRead.corrupt() : this._(SensitiveBodyReadStatus.corrupt);
  const SensitiveBodyRead.unsupported()
      : this._(SensitiveBodyReadStatus.unsupported);

  @override
  String toString() => 'SensitiveBodyRead(${status.name})';
}

/// Native secure aggregate for HTD SEC-001 body clinical values, routines and
/// update history. The repository versions and verifies its payload; this
/// adapter retains the accepted DATA-007/008 platform and deletion contracts.
abstract interface class SensitiveBodyMetricsStore {
  Future<SensitiveBodyRead> readResult();

  /// Overwrites the stored field map atomically as a single value.
  Future<void> write(Map<String, Object?> fields);

  /// Deletes the stored field map and verifies logical absence, not erasure.
  Future<SensitiveBodyDeleteStatus> delete();

  /// False on platforms with no Keychain/Keystore-backed secure storage
  /// (matching `health_database_key_store.dart`'s own platform gate).
  /// Legacy plaintext is preserved read-only when false, never newly written.
  /// A secured record without a recoverable copy remains unavailable.
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
  Future<SensitiveBodyRead> readResult() async {
    if (!isSupported) return const SensitiveBodyRead.unsupported();
    try {
      final raw = await _storage.read(
        key: _storageKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      if (raw == null) return const SensitiveBodyRead.absent();
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? SensitiveBodyRead.found(decoded)
          : const SensitiveBodyRead.corrupt();
    } on FormatException {
      return const SensitiveBodyRead.corrupt();
    } catch (_) {
      return const SensitiveBodyRead.unavailable();
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
      throw StateError('secure_body_write_failed');
    }
  }

  @override
  Future<SensitiveBodyDeleteStatus> delete() async {
    if (!isSupported) return SensitiveBodyDeleteStatus.unsupported;
    try {
      await _storage.delete(
        key: _storageKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (_) {
      return SensitiveBodyDeleteStatus.failed;
    }
    return switch ((await readResult()).status) {
      SensitiveBodyReadStatus.absent =>
        SensitiveBodyDeleteStatus.verifiedAbsent,
      SensitiveBodyReadStatus.unavailable =>
        SensitiveBodyDeleteStatus.unavailable,
      SensitiveBodyReadStatus.unsupported =>
        SensitiveBodyDeleteStatus.unsupported,
      _ => SensitiveBodyDeleteStatus.verificationFailed,
    };
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

  Future<Map<String, Object?>?> read() async =>
      !supported || _value == null ? null : Map<String, Object?>.from(_value!);

  @override
  Future<SensitiveBodyRead> readResult() async {
    if (!supported) return const SensitiveBodyRead.unsupported();
    final fields = await read();
    return fields == null
        ? const SensitiveBodyRead.absent()
        : SensitiveBodyRead.found(fields);
  }

  @override
  Future<void> write(Map<String, Object?> fields) async {
    if (!supported) return;
    _value = Map<String, Object?>.from(fields);
  }

  @override
  Future<SensitiveBodyDeleteStatus> delete() async {
    if (!supported) return SensitiveBodyDeleteStatus.unsupported;
    _value = null;
    return SensitiveBodyDeleteStatus.verifiedAbsent;
  }
}
