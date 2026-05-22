// lib/services/ble_service.dart
import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hydrion/utils/permissions.dart';

/// BLEService — discovers and connects to smart bottles.
/// Notes:
/// - Filters by device name prefix or by advertised Service UUID if provided.
/// - Provides read of a configurable characteristic.
/// - Call [dispose] to stop scans and free resources.
class BLEService {
  final FlutterBluePlus _ble = FlutterBluePlus.instance;
  final Permissions _permissions;

  // Optionally set a specific service/characteristic UUID if your bottle exposes one
  final Guid? serviceUuid;
  final Guid? levelCharacteristicUuid;

  StreamSubscription<List<ScanResult>>? _scanSub;

  BLEService({
    required Permissions permissions,
    this.serviceUuid,
    this.levelCharacteristicUuid,
  }) : _permissions = permissions;

  Future<BluetoothDevice?> connectToBottle({
    Duration scanTimeout = const Duration(seconds: 10),
    String namePrefix = 'HydrionBottle',
  }) async {
    try {
      if (!await _permissions.hasAll()) return null;

      // Ensure Bluetooth is on
      final state = await _ble.state.first;
      if (state != BluetoothState.on) return null;

      // Start scan
      await _ble.startScan(
        withServices: serviceUuid != null ? [serviceUuid!] : const [],
        timeout: scanTimeout,
      );

      final completer = Completer<BluetoothDevice?>();
      _scanSub = _ble.scanResults.listen((results) async {
        for (final r in results) {
          final name = r.device.platformName;
          final matchesName = name.isNotEmpty && name.contains(namePrefix);
          final matchesService =
              serviceUuid == null || (r.advertisementData.serviceUuids.contains(serviceUuid!.str128));

          if (matchesName && matchesService) {
            if (!completer.isCompleted) completer.complete(r.device);
            break;
          }
        }
      });

      final device = await completer.future.timeout(scanTimeout, onTimeout: () => null);
      await _ble.stopScan();
      await _scanSub?.cancel();

      if (device == null) return null;

      await device.connect(timeout: const Duration(seconds: 8));
      return device;
    } catch (_) {
      try {
        await _ble.stopScan();
      } catch (_) {}
      try {
        await _scanSub?.cancel();
      } catch (_) {}
      return null;
    }
  }

  /// Reads current water level (ml) from a connected device.
  /// Returns null if unavailable.
  Future<int?> readWaterLevel(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      // Find characteristic
      BluetoothCharacteristic? ch;
      if (levelCharacteristicUuid != null) {
        for (final s in services) {
          ch ??= s.characteristics
              .firstWhere(
                (c) => c.uuid == levelCharacteristicUuid,
                orElse: () => null as BluetoothCharacteristic,
              );
          if (ch != null) break;
        }
      } else {
        // Fallback: guess a readable characteristic with 0x2A prefix (not reliable, but a last resort)
        ch = services
            .expand((s) => s.characteristics)
            .where((c) => c.properties.read)
            .firstWhere(
              (c) => c.uuid.toString().toLowerCase().startsWith('00002a'),
              orElse: () => null as BluetoothCharacteristic,
            );
      }

      if (ch == null) return null;

      final data = await ch.read();
      if (data.isEmpty) return null;

      // Interpret first two bytes as little-endian ml if present, else first byte.
      if (data.length >= 2) {
        final ml = data[0] | (data[1] << 8);
        return ml;
      }
      return data[0];
    } catch (_) {
      return null;
    }
  }

  Future<void> disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _ble.stopScan();
    } catch (_) {}
    try {
      await _scanSub?.cancel();
    } catch (_) {}
  }
}
