// lib/services/wearable_service.dart
import 'dart:io';

import 'package:health/health.dart';
import '../utils/permissions.dart';

/// WearableService — Apple Health / Google Fit hydration sync
/// - Writes WATER samples
/// - Reads WATER samples in a time range
/// - Uses Permissions helper for preflight checks
class WearableService {
  final HealthFactory _health;
  final Permissions _permissions;

  WearableService({required Permissions permissions})
      : _permissions = permissions,
        _health = HealthFactory(useHealthConnectIfAvailable: true);

  /// Write a WATER sample (ml) at [timestamp].
  /// Returns true on success.
  Future<bool> syncHydration(int volumeMl, DateTime timestamp) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return false;
      if (!await _permissions.hasAll()) return false;

      final ok = await _health.writeHealthData(
        volumeMl.toDouble(),
        HealthDataType.WATER,
        timestamp,
        timestamp,
        unit: HealthDataUnit.MILLILITER,
      );
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Fetch WATER samples between [start] and [end].
  /// Returns a list of HealthDataPoint.
  Future<List<HealthDataPoint>> fetchHydrationData(
      DateTime start, DateTime end) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return const [];
      if (!await _permissions.hasAll()) return const [];

      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: const [HealthDataType.WATER],
      );

      // Deduplicate merged datapoints, if any
      return HealthFactory.removeDuplicates(points);
    } catch (_) {
      return const [];
    }
  }
}
