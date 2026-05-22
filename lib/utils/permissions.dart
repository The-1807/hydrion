// lib/utils/permissions.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';

class Permissions {
  Future<bool> requestAll() async {
    final results = await Future.wait<bool>([
      _requestBluetooth(),
      _requestNotifications(),
      _requestHealth(),
    ]);
    return results.every((ok) => ok);
  }

  Future<bool> _requestBluetooth() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return true;

      final req = <Permission>[
        if (Platform.isAndroid) Permission.bluetoothScan,
        if (Platform.isAndroid) Permission.bluetoothConnect,
        if (Platform.isAndroid) Permission.bluetooth,
        if (Platform.isAndroid) Permission.locationWhenInUse,
      ];

      final statuses = await req.request();
      final granted = statuses.values.every((s) => s.isGranted || s.isLimited);
      if (!granted && statuses.values.any((s) => s.isPermanentlyDenied)) {
        await openAppSettings();
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _requestNotifications() async {
    try {
      final status = await Permission.notification.request();
      if (!status.isGranted && status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return status.isGranted || status.isLimited;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _requestHealth() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return true;

      final health = HealthFactory(useHealthConnectIfAvailable: true);
      final types = <HealthDataType>[
        HealthDataType.WATER,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
      ];

      final access = types.map((_) => HealthDataAccess.READ).toList();
      final granted = await health.requestAuthorization(types, permissions: access);
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasAll() async {
    try {
      final btOk = await Permission.bluetoothScan.isGranted &&
          await Permission.bluetoothConnect.isGranted &&
          await Permission.bluetooth.isGranted;
      final notifOk = await Permission.notification.isGranted;
      final health = HealthFactory(useHealthConnectIfAvailable: true);
      final ok = await health.hasPermissions([HealthDataType.WATER]) ?? false;
      return btOk && notifOk && ok;
    } catch (_) {
      return false;
    }
  }
}
