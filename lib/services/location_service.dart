import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;

enum HydrionLocationPermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  serviceDisabled,
  unsupported,
  unknown,
}

enum HydrionLocationAccuracy {
  approximate,
  precise,
  unknown,
}

enum HydrionLocationLookupStatus {
  success,
  permissionDenied,
  permanentlyDenied,
  serviceDisabled,
  timeout,
  unavailable,
  unsupported,
  platformError,
}

class HydrionCoordinates {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime capturedAt;

  const HydrionCoordinates({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.accuracyMeters,
  });

  bool get isUsable {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}

class HydrionLocationLookupResult {
  final HydrionLocationLookupStatus status;
  final HydrionCoordinates? coordinates;
  final String? message;

  const HydrionLocationLookupResult._({
    required this.status,
    this.coordinates,
    this.message,
  });

  const HydrionLocationLookupResult.success(HydrionCoordinates coordinates)
      : this._(
          status: HydrionLocationLookupStatus.success,
          coordinates: coordinates,
        );

  const HydrionLocationLookupResult.failure(
    HydrionLocationLookupStatus status, {
    String? message,
  }) : this._(status: status, message: message);

  bool get isSuccess =>
      status == HydrionLocationLookupStatus.success && coordinates != null;
}

abstract class HydrionLocationService {
  Future<HydrionLocationPermissionState> checkPermission();

  Future<HydrionLocationPermissionState> requestPermission();

  Future<HydrionLocationAccuracy> checkAccuracy();

  Future<HydrionLocationLookupResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 12),
  });

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

class GeolocatorHydrionLocationService implements HydrionLocationService {
  const GeolocatorHydrionLocationService();

  @override
  Future<HydrionLocationPermissionState> checkPermission() async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return HydrionLocationPermissionState.serviceDisabled;
      }
      return _mapPermission(await geo.Geolocator.checkPermission());
    } on PlatformException {
      return HydrionLocationPermissionState.unsupported;
    }
  }

  @override
  Future<HydrionLocationPermissionState> requestPermission() async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return HydrionLocationPermissionState.serviceDisabled;
      }
      return _mapPermission(await geo.Geolocator.requestPermission());
    } on PlatformException {
      return HydrionLocationPermissionState.unsupported;
    }
  }

  @override
  Future<HydrionLocationAccuracy> checkAccuracy() async {
    try {
      final accuracy = await geo.Geolocator.getLocationAccuracy();
      return accuracy == geo.LocationAccuracyStatus.precise
          ? HydrionLocationAccuracy.precise
          : HydrionLocationAccuracy.approximate;
    } on PlatformException {
      return HydrionLocationAccuracy.unknown;
    }
  }

  @override
  Future<HydrionLocationLookupResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      final permission = await checkPermission();
      switch (permission) {
        case HydrionLocationPermissionState.granted:
          break;
        case HydrionLocationPermissionState.denied:
          return const HydrionLocationLookupResult.failure(
            HydrionLocationLookupStatus.permissionDenied,
          );
        case HydrionLocationPermissionState.permanentlyDenied:
          return const HydrionLocationLookupResult.failure(
            HydrionLocationLookupStatus.permanentlyDenied,
          );
        case HydrionLocationPermissionState.restricted:
          return const HydrionLocationLookupResult.failure(
            HydrionLocationLookupStatus.permissionDenied,
          );
        case HydrionLocationPermissionState.serviceDisabled:
          return const HydrionLocationLookupResult.failure(
            HydrionLocationLookupStatus.serviceDisabled,
          );
        case HydrionLocationPermissionState.unsupported:
          return const HydrionLocationLookupResult.failure(
            HydrionLocationLookupStatus.unsupported,
          );
        case HydrionLocationPermissionState.unknown:
          return const HydrionLocationLookupResult.failure(
            HydrionLocationLookupStatus.unavailable,
          );
      }

      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: geo.LocationAccuracy.low,
          timeLimit: timeout,
        ),
      );
      final coordinates = HydrionCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters:
            position.accuracy.isFinite ? position.accuracy.toDouble() : null,
        capturedAt: DateTime.now(),
      );
      if (!coordinates.isUsable) {
        return const HydrionLocationLookupResult.failure(
          HydrionLocationLookupStatus.unavailable,
        );
      }
      return HydrionLocationLookupResult.success(coordinates);
    } on TimeoutException {
      return const HydrionLocationLookupResult.failure(
        HydrionLocationLookupStatus.timeout,
      );
    } on geo.LocationServiceDisabledException {
      return const HydrionLocationLookupResult.failure(
        HydrionLocationLookupStatus.serviceDisabled,
      );
    } on geo.PermissionDeniedException {
      return const HydrionLocationLookupResult.failure(
        HydrionLocationLookupStatus.permissionDenied,
      );
    } on PlatformException catch (error) {
      return HydrionLocationLookupResult.failure(
        HydrionLocationLookupStatus.platformError,
        message: error.code,
      );
    }
  }

  @override
  Future<bool> openAppSettings() {
    return geo.Geolocator.openAppSettings();
  }

  @override
  Future<bool> openLocationSettings() {
    return geo.Geolocator.openLocationSettings();
  }

  HydrionLocationPermissionState _mapPermission(
    geo.LocationPermission permission,
  ) {
    return switch (permission) {
      geo.LocationPermission.always ||
      geo.LocationPermission.whileInUse =>
        HydrionLocationPermissionState.granted,
      geo.LocationPermission.denied => HydrionLocationPermissionState.denied,
      geo.LocationPermission.deniedForever =>
        HydrionLocationPermissionState.permanentlyDenied,
      geo.LocationPermission.unableToDetermine =>
        HydrionLocationPermissionState.unknown,
    };
  }
}

class FakeHydrionLocationService implements HydrionLocationService {
  HydrionLocationPermissionState permission;
  HydrionLocationAccuracy accuracy;
  HydrionLocationLookupResult lookupResult;
  int requestCount = 0;
  int lookupCount = 0;
  int appSettingsOpenCount = 0;
  int locationSettingsOpenCount = 0;

  FakeHydrionLocationService({
    this.permission = HydrionLocationPermissionState.granted,
    this.accuracy = HydrionLocationAccuracy.approximate,
    HydrionLocationLookupResult? lookupResult,
  }) : lookupResult = lookupResult ??
            HydrionLocationLookupResult.success(
              HydrionCoordinates(
                latitude: 43.6532,
                longitude: -79.3832,
                capturedAt: DateTime(2026, 7, 5, 12),
              ),
            );

  @override
  Future<HydrionLocationPermissionState> checkPermission() async => permission;

  @override
  Future<HydrionLocationAccuracy> checkAccuracy() async => accuracy;

  @override
  Future<HydrionLocationPermissionState> requestPermission() async {
    requestCount += 1;
    return permission;
  }

  @override
  Future<HydrionLocationLookupResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    lookupCount += 1;
    return lookupResult;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpenCount += 1;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpenCount += 1;
    return true;
  }
}
