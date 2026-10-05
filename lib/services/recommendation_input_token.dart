import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/daily_hydration_context.dart';
import '../domain/hydration_recommendation.dart';
import '../repositories/settings_repository.dart';
import 'personalized_hydration_engine.dart';

/// Positional, versioned equality input; never persist or log this representation.
/// Inventory and exclusions: HTD.md, SEC-003 implementation record.
String canonicalRecommendationInput(PersonalizedHydrationInputs input) {
  final body = input.bodyMetrics;
  final context = input.dailyContext;
  final weather = input.weather;
  final personalized =
      input.requestedBaselineSource == HydrationBaselineSource.personalized &&
          body.personalizationEnabled;
  final adult = (input.age ?? -1) >= 20;
  final useMeasurements = personalized && adult;
  final weatherPermitted =
      input.weatherEnabled && input.locationPermissionGranted;
  final outdoor = context != null &&
      context.environment != HydrionEnvironmentExposure.mostlyIndoors;
  return jsonEncode([
    'recommendation-input-v1',
    input.localDateKey,
    input.existingBaselineGoalMl,
    personalized,
    personalized ? adult : null,
    input.sex == HydrionSex.female,
    useMeasurements ? body.weightKg : null,
    useMeasurements ? body.heightCm : null,
    body.reproductiveState.name,
    body.fluidSafetyMode.name,
    body.clinicianTargetMl,
    body.allowAdjustmentsAboveClinicianTarget,
    (context?.activityIntensity ?? HydrionActivityIntensity.rest).name,
    context?.activityMinutes ?? 0,
    (context?.environment ?? HydrionEnvironmentExposure.mostlyIndoors).name,
    (context?.sweatLevel ?? HydrionSweatLevel.unknown).name,
    (context?.temporaryCondition ?? HydrionTemporaryCondition.none).name,
    context?.userAdjustmentMl ?? 0,
    input.weatherEnabled,
    input.weatherEnabled ? input.locationPermissionGranted : null,
    !weatherPermitted || weather == null
        ? null
        : !outdoor
            ? const [true]
            : [
                weather.apparentTemperatureC ?? weather.temperatureC,
                weather.apparentTemperatureC == null
                    ? weather.humidityPercent ?? 0
                    : null,
                weather.uvIndex,
              ],
    weatherPermitted && weather != null && outdoor
        ? input.cachedWeatherUsed
        : null,
  ]);
}

enum RecommendationTokenStatus { persistent, memoryOnly }

class RecommendationTokenResetIncomplete implements Exception {
  const RecommendationTokenResetIncomplete();
  @override
  String toString() => 'RecommendationTokenResetIncomplete';
}

/// Dedicated local HMAC key, independent of body and health-database keys.
/// No secure key or canonical source is exposed through result/diagnostic APIs.
class RecommendationInputTokens {
  static const storageKey = 'hydrion.recommendation.equality.key.v1';
  static const _domain = 'hydrion/recommendation-input-token/v1\u0000';
  static const _prefix = 'recommendation-input-token-v1:';
  static final _tokenPattern = RegExp('^$_prefix[a-f0-9]{64}\$');
  static const _android = AndroidOptions(
    resetOnError: false,
    migrateWithBackup: true,
    storageNamespace: 'hydrion_recommendation_equality',
  );
  static const _ios = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
    accountName: 'com.the1807.hydrion.recommendation-equality',
  );
  // Coordinate creation/deletion across instances in this isolate.
  static Future<void>? _tail;
  final FlutterSecureStorage _storage;
  final bool _memoryOnly;
  List<int> _ephemeralKey = _randomKey();
  RecommendationTokenStatus _status = RecommendationTokenStatus.memoryOnly;

  RecommendationInputTokens({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _memoryOnly = false;

  RecommendationInputTokens.memory()
      : _storage = const FlutterSecureStorage(),
        _memoryOnly = true;

  RecommendationTokenStatus get status => _status;
  static bool isPersistable(Object? token) =>
      token is String && _tokenPattern.hasMatch(token);
  bool get _supported =>
      !_memoryOnly &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static List<int> _randomKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  static Future<T> _serial<T>(Future<T> Function() operation) async {
    final previous = _tail;
    final completed = Completer<void>();
    _tail = completed.future;
    try {
      if (previous != null) await previous;
      return await operation();
    } finally {
      // Release before returning, including when a caller uses a fake async
      // zone. Do not leave a completed operation chained to a disposed zone.
      if (identical(_tail, completed.future)) _tail = null;
      completed.complete();
    }
  }

  Future<List<int>?> _obtain() async {
    if (!_supported) return null;
    try {
      final encoded = await _storage.read(
          key: storageKey, aOptions: _android, iOptions: _ios);
      if (encoded != null) {
        final key = base64Url.decode(encoded);
        return key.length == 32 ? key : null;
      }
      final key = _randomKey();
      final value = base64UrlEncode(key);
      await _storage.write(
          key: storageKey, value: value, aOptions: _android, iOptions: _ios);
      final verified = await _storage.read(
          key: storageKey, aOptions: _android, iOptions: _ios);
      return verified == value ? key : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> canPersist() => _serial(() async {
        final available = await _obtain() != null;
        _status = available
            ? RecommendationTokenStatus.persistent
            : RecommendationTokenStatus.memoryOnly;
        return available;
      });

  Future<String> create(String canonicalInput) => _serial(() async {
        final secureKey = await _obtain();
        _status = secureKey == null
            ? RecommendationTokenStatus.memoryOnly
            : RecommendationTokenStatus.persistent;
        final digest = Hmac(sha256, secureKey ?? _ephemeralKey)
            .convert(utf8.encode('$_domain$canonicalInput'));
        return '${secureKey == null ? 'memory:' : _prefix}$digest';
      });

  Future<void> clear() => _serial(() async {
        _ephemeralKey = _randomKey();
        _status = RecommendationTokenStatus.memoryOnly;
        if (!_supported) return;
        try {
          await _storage.delete(
              key: storageKey, aOptions: _android, iOptions: _ios);
          if (await _storage.read(
                  key: storageKey, aOptions: _android, iOptions: _ios) !=
              null) {
            throw const RecommendationTokenResetIncomplete();
          }
        } catch (_) {
          throw const RecommendationTokenResetIncomplete();
        }
      });
}
