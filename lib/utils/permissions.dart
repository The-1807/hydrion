import 'package:flutter/foundation.dart';

import '../repositories/settings_repository.dart';
import '../services/location_service.dart';
import '../services/notifications.dart';

enum HydrionPermissionState {
  notRequested,
  granted,
  approximateGranted,
  preciseGranted,
  denied,
  permanentlyDenied,
  restricted,
  notRequired,
  unsupported,
  temporarilyUnavailable,
  unknown,
}

enum HydrionPermissionPlatform {
  android,
  ios,
  web,
  desktop,
  unknown,
}

class HydrionPermissionCapability {
  final HydrionPermissionState state;
  final HydrionPermissionPlatform platform;
  final bool canRequestDirectly;
  final bool settingsRequired;
  final bool fallbackAvailable;
  final bool previouslyDeclined;
  final String explanation;
  final String? internalFailureReason;

  const HydrionPermissionCapability({
    required this.state,
    required this.platform,
    required this.canRequestDirectly,
    required this.settingsRequired,
    required this.fallbackAvailable,
    required this.previouslyDeclined,
    required this.explanation,
    this.internalFailureReason,
  });

  bool get isGranted =>
      state == HydrionPermissionState.granted ||
      state == HydrionPermissionState.approximateGranted ||
      state == HydrionPermissionState.preciseGranted ||
      state == HydrionPermissionState.notRequired;
}

class HydrionPermissionSnapshot {
  final HydrionPermissionCapability notifications;
  final HydrionPermissionCapability location;
  final HydrionPermissionCapability exactAlarms;
  final DateTime refreshedAt;

  const HydrionPermissionSnapshot({
    required this.notifications,
    required this.location,
    required this.exactAlarms,
    required this.refreshedAt,
  });

  factory HydrionPermissionSnapshot.unknown(
    HydrionPermissionPlatform platform,
  ) {
    HydrionPermissionCapability pending(String explanation) {
      return HydrionPermissionCapability(
        state: HydrionPermissionState.unknown,
        platform: platform,
        canRequestDirectly: false,
        settingsRequired: false,
        fallbackAvailable: true,
        previouslyDeclined: false,
        explanation: explanation,
      );
    }

    return HydrionPermissionSnapshot(
      notifications: pending('Notification status has not been checked yet.'),
      location: pending('Location status has not been checked yet.'),
      exactAlarms: pending('Alarm scheduling status has not been checked yet.'),
      refreshedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class Permissions extends ChangeNotifier {
  final NotificationService _notifications;
  final HydrionLocationService _location;
  final UserSettingsRepository _settings;
  final HydrionPermissionPlatform platform;
  final DateTime Function() _now;

  late HydrionPermissionSnapshot _snapshot;
  bool _refreshing = false;

  Permissions({
    required NotificationService notifications,
    required HydrionLocationService location,
    required UserSettingsRepository settings,
    HydrionPermissionPlatform? platform,
    DateTime Function()? now,
  })  : _notifications = notifications,
        _location = location,
        _settings = settings,
        platform = platform ?? detectPlatform(),
        _now = now ?? DateTime.now {
    _snapshot = HydrionPermissionSnapshot.unknown(this.platform);
  }

  HydrionPermissionSnapshot get snapshot => _snapshot;
  bool get refreshing => _refreshing;

  static HydrionPermissionPlatform detectPlatform() {
    if (kIsWeb) return HydrionPermissionPlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => HydrionPermissionPlatform.android,
      TargetPlatform.iOS => HydrionPermissionPlatform.ios,
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        HydrionPermissionPlatform.desktop,
      _ => HydrionPermissionPlatform.unknown,
    };
  }

  Future<HydrionPermissionSnapshot> refresh() async {
    if (_refreshing) return _snapshot;
    _refreshing = true;
    notifyListeners();
    try {
      final notificationState = await _safeNotificationState();
      final locationState = await _safeLocationState();
      final exactAvailable = await _safeExactAlarmState();
      _snapshot = HydrionPermissionSnapshot(
        notifications: _notificationCapability(notificationState),
        location: await _locationCapability(locationState),
        exactAlarms: _exactAlarmCapability(exactAvailable),
        refreshedAt: _now(),
      );
      return _snapshot;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<HydrionPermissionSnapshot> requestNotifications() async {
    final current = await _safeNotificationState();
    if (current != HydrionNotificationPermissionState.granted) {
      await _settings.recordNotificationPermissionPrompt(_now());
      await _notifications.requestPermission();
    }
    return refresh();
  }

  Future<HydrionPermissionSnapshot> requestLocation() async {
    final current = await _safeLocationState();
    if (current != HydrionLocationPermissionState.granted) {
      await _settings.recordLocationPermissionPrompt(_now());
      await _location.requestPermission();
    }
    return refresh();
  }

  Future<HydrionPermissionSnapshot> requestExactAlarms() async {
    if (platform == HydrionPermissionPlatform.android) {
      await _notifications.requestPreciseSchedulingPermission();
    }
    return refresh();
  }

  Future<bool> openNotificationSettings() => _notifications.openAppSettings();
  Future<bool> openLocationSettings() => _location.openAppSettings();
  Future<bool> openLocationServices() => _location.openLocationSettings();
  Future<bool> openAppSettings() => _notifications.openAppSettings();

  Future<HydrionNotificationPermissionState> _safeNotificationState() async {
    try {
      return await _notifications.checkPermission();
    } catch (_) {
      return HydrionNotificationPermissionState.unknown;
    }
  }

  Future<HydrionLocationPermissionState> _safeLocationState() async {
    try {
      return await _location.checkPermission();
    } catch (_) {
      return HydrionLocationPermissionState.unknown;
    }
  }

  Future<bool?> _safeExactAlarmState() async {
    if (platform != HydrionPermissionPlatform.android ||
        !_notifications.supportsOsNotifications) {
      return null;
    }
    try {
      return await _notifications.canSchedulePrecisely();
    } catch (_) {
      return false;
    }
  }

  HydrionPermissionCapability _notificationCapability(
    HydrionNotificationPermissionState state,
  ) {
    final prompted =
        _settings.settings.notificationPermissionPromptedAt != null;
    return switch (state) {
      HydrionNotificationPermissionState.granted => _capability(
          HydrionPermissionState.granted,
          'Notifications are allowed for Hydrion.',
          fallback: false,
        ),
      HydrionNotificationPermissionState.denied => _capability(
          prompted
              ? HydrionPermissionState.denied
              : HydrionPermissionState.notRequested,
          prompted
              ? 'Notifications are off. You can allow them here or in device settings.'
              : 'Hydrion has not asked to send notifications yet.',
          canRequest: true,
          declined: prompted,
        ),
      HydrionNotificationPermissionState.permanentlyDenied => _capability(
          HydrionPermissionState.permanentlyDenied,
          'Notifications are blocked. Open device settings to allow them.',
          settingsRequired: true,
          declined: true,
        ),
      HydrionNotificationPermissionState.unsupported => _capability(
          platform == HydrionPermissionPlatform.android
              ? HydrionPermissionState.unknown
              : HydrionPermissionState.unsupported,
          platform == HydrionPermissionPlatform.android
              ? 'Hydrion could not read the Android notification status.'
              : 'Hydrion notifications are not supported on this platform.',
          failure: platform == HydrionPermissionPlatform.android
              ? 'notification_query_unavailable'
              : null,
        ),
      HydrionNotificationPermissionState.unknown => _capability(
          HydrionPermissionState.unknown,
          'Notification status is temporarily unavailable. Refresh to try again.',
          failure: 'notification_query_failed',
        ),
    };
  }

  Future<HydrionPermissionCapability> _locationCapability(
    HydrionLocationPermissionState state,
  ) async {
    final prompted = _settings.settings.locationPermissionPromptedAt != null;
    switch (state) {
      case HydrionLocationPermissionState.granted:
        final accuracy = await _location.checkAccuracy();
        if (accuracy == HydrionLocationAccuracy.precise) {
          return _capability(
            HydrionPermissionState.preciseGranted,
            'Precise foreground location is allowed. Approximate location is sufficient for Hydrion weather.',
            fallback: false,
          );
        }
        return _capability(
          HydrionPermissionState.approximateGranted,
          'Approximate foreground location is allowed and is sufficient for weather assistance.',
          fallback: false,
        );
      case HydrionLocationPermissionState.denied:
        return _capability(
          prompted
              ? HydrionPermissionState.denied
              : HydrionPermissionState.notRequested,
          prompted
              ? 'Location is off. Your standard hydration goal still works.'
              : 'Hydrion has not asked for location yet.',
          canRequest: true,
          declined: prompted,
        );
      case HydrionLocationPermissionState.permanentlyDenied:
        return _capability(
          HydrionPermissionState.permanentlyDenied,
          'Location is blocked. Open device settings to enable weather assistance.',
          settingsRequired: true,
          declined: true,
        );
      case HydrionLocationPermissionState.restricted:
        return _capability(
          HydrionPermissionState.restricted,
          'Location access is restricted by the device.',
          settingsRequired: true,
        );
      case HydrionLocationPermissionState.serviceDisabled:
        return _capability(
          HydrionPermissionState.temporarilyUnavailable,
          'Device location services are off. Your standard goal remains available.',
          settingsRequired: true,
        );
      case HydrionLocationPermissionState.unsupported:
        return _capability(
          HydrionPermissionState.unsupported,
          'Location-based weather assistance is not supported on this platform.',
        );
      case HydrionLocationPermissionState.unknown:
        return _capability(
          HydrionPermissionState.unknown,
          'Location status is temporarily unavailable. Refresh to try again.',
          failure: 'location_query_failed',
        );
    }
  }

  HydrionPermissionCapability _exactAlarmCapability(bool? available) {
    if (available == null) {
      return _capability(
        platform == HydrionPermissionPlatform.android
            ? HydrionPermissionState.notRequired
            : HydrionPermissionState.unsupported,
        platform == HydrionPermissionPlatform.android
            ? 'Special exact-alarm access is not required on this device.'
            : 'Exact-alarm access is Android-specific.',
      );
    }
    if (available) {
      return _capability(
        HydrionPermissionState.granted,
        'Exact reminder scheduling is available.',
        fallback: false,
      );
    }
    return _capability(
      HydrionPermissionState.denied,
      'Exact scheduling is unavailable. Hydrion will continue with approximate reminders.',
      settingsRequired: true,
    );
  }

  HydrionPermissionCapability _capability(
    HydrionPermissionState state,
    String explanation, {
    bool canRequest = false,
    bool settingsRequired = false,
    bool fallback = true,
    bool declined = false,
    String? failure,
  }) {
    return HydrionPermissionCapability(
      state: state,
      platform: platform,
      canRequestDirectly: canRequest,
      settingsRequired: settingsRequired,
      fallbackAvailable: fallback,
      previouslyDeclined: declined,
      explanation: explanation,
      internalFailureReason: failure,
    );
  }
}
