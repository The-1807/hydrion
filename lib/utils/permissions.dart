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

enum HydrionPermissionMessage {
  notificationUnchecked,
  locationUnchecked,
  alarmUnchecked,
  notificationsAllowed,
  notificationsOff,
  notificationsNotAsked,
  notificationsBlocked,
  notificationStatusUnavailableAndroid,
  notificationsUnsupported,
  notificationStatusTemporary,
  preciseLocationAllowed,
  approximateLocationAllowed,
  locationOff,
  locationNotAsked,
  locationBlocked,
  locationRestricted,
  locationServicesOff,
  locationUnsupported,
  locationStatusTemporary,
  exactAlarmNotRequired,
  exactAlarmAndroidOnly,
  exactSchedulingAvailable,
  exactSchedulingApproximate,
}

class HydrionPermissionCapability {
  final HydrionPermissionState state;
  final HydrionPermissionPlatform platform;
  final bool canRequestDirectly;
  final bool settingsRequired;
  final bool fallbackAvailable;
  final bool previouslyDeclined;
  final HydrionPermissionMessage message;
  final String? internalFailureReason;

  const HydrionPermissionCapability({
    required this.state,
    required this.platform,
    required this.canRequestDirectly,
    required this.settingsRequired,
    required this.fallbackAvailable,
    required this.previouslyDeclined,
    required this.message,
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
    HydrionPermissionCapability pending(HydrionPermissionMessage message) {
      return HydrionPermissionCapability(
        state: HydrionPermissionState.unknown,
        platform: platform,
        canRequestDirectly: false,
        settingsRequired: false,
        fallbackAvailable: true,
        previouslyDeclined: false,
        message: message,
      );
    }

    return HydrionPermissionSnapshot(
      notifications: pending(HydrionPermissionMessage.notificationUnchecked),
      location: pending(HydrionPermissionMessage.locationUnchecked),
      exactAlarms: pending(HydrionPermissionMessage.alarmUnchecked),
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
          HydrionPermissionMessage.notificationsAllowed,
          fallback: false,
        ),
      HydrionNotificationPermissionState.denied => _capability(
          prompted
              ? HydrionPermissionState.denied
              : HydrionPermissionState.notRequested,
          prompted
              ? HydrionPermissionMessage.notificationsOff
              : HydrionPermissionMessage.notificationsNotAsked,
          canRequest: true,
          declined: prompted,
        ),
      HydrionNotificationPermissionState.permanentlyDenied => _capability(
          HydrionPermissionState.permanentlyDenied,
          HydrionPermissionMessage.notificationsBlocked,
          settingsRequired: true,
          declined: true,
        ),
      HydrionNotificationPermissionState.unsupported => _capability(
          platform == HydrionPermissionPlatform.android
              ? HydrionPermissionState.unknown
              : HydrionPermissionState.unsupported,
          platform == HydrionPermissionPlatform.android
              ? HydrionPermissionMessage.notificationStatusUnavailableAndroid
              : HydrionPermissionMessage.notificationsUnsupported,
          failure: platform == HydrionPermissionPlatform.android
              ? 'notification_query_unavailable'
              : null,
        ),
      HydrionNotificationPermissionState.unknown => _capability(
          HydrionPermissionState.unknown,
          HydrionPermissionMessage.notificationStatusTemporary,
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
            HydrionPermissionMessage.preciseLocationAllowed,
            fallback: false,
          );
        }
        return _capability(
          HydrionPermissionState.approximateGranted,
          HydrionPermissionMessage.approximateLocationAllowed,
          fallback: false,
        );
      case HydrionLocationPermissionState.denied:
        return _capability(
          prompted
              ? HydrionPermissionState.denied
              : HydrionPermissionState.notRequested,
          prompted
              ? HydrionPermissionMessage.locationOff
              : HydrionPermissionMessage.locationNotAsked,
          canRequest: true,
          declined: prompted,
        );
      case HydrionLocationPermissionState.permanentlyDenied:
        return _capability(
          HydrionPermissionState.permanentlyDenied,
          HydrionPermissionMessage.locationBlocked,
          settingsRequired: true,
          declined: true,
        );
      case HydrionLocationPermissionState.restricted:
        return _capability(
          HydrionPermissionState.restricted,
          HydrionPermissionMessage.locationRestricted,
          settingsRequired: true,
        );
      case HydrionLocationPermissionState.serviceDisabled:
        return _capability(
          HydrionPermissionState.temporarilyUnavailable,
          HydrionPermissionMessage.locationServicesOff,
          settingsRequired: true,
        );
      case HydrionLocationPermissionState.unsupported:
        return _capability(
          HydrionPermissionState.unsupported,
          HydrionPermissionMessage.locationUnsupported,
        );
      case HydrionLocationPermissionState.unknown:
        return _capability(
          HydrionPermissionState.unknown,
          HydrionPermissionMessage.locationStatusTemporary,
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
            ? HydrionPermissionMessage.exactAlarmNotRequired
            : HydrionPermissionMessage.exactAlarmAndroidOnly,
      );
    }
    if (available) {
      return _capability(
        HydrionPermissionState.granted,
        HydrionPermissionMessage.exactSchedulingAvailable,
        fallback: false,
      );
    }
    return _capability(
      HydrionPermissionState.denied,
      HydrionPermissionMessage.exactSchedulingApproximate,
      settingsRequired: true,
    );
  }

  HydrionPermissionCapability _capability(
    HydrionPermissionState state,
    HydrionPermissionMessage message, {
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
      message: message,
      internalFailureReason: failure,
    );
  }
}
