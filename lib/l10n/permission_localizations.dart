import '../utils/permissions.dart';
import 'app_localizations.dart';

extension HydrionPermissionLocalizations on AppLocalizations {
  String permissionMessage(HydrionPermissionMessage message) =>
      switch (message) {
        HydrionPermissionMessage.notificationUnchecked =>
          permissionNotificationUnchecked,
        HydrionPermissionMessage.locationUnchecked =>
          permissionLocationUnchecked,
        HydrionPermissionMessage.alarmUnchecked => permissionAlarmUnchecked,
        HydrionPermissionMessage.notificationsAllowed =>
          permissionNotificationsAllowed,
        HydrionPermissionMessage.notificationsOff => permissionNotificationsOff,
        HydrionPermissionMessage.notificationsNotAsked =>
          permissionNotificationsNotAsked,
        HydrionPermissionMessage.notificationsBlocked =>
          permissionNotificationsBlocked,
        HydrionPermissionMessage.notificationStatusUnavailableAndroid =>
          permissionNotificationStatusUnavailableAndroid,
        HydrionPermissionMessage.notificationsUnsupported =>
          permissionNotificationsUnsupported,
        HydrionPermissionMessage.notificationStatusTemporary =>
          permissionNotificationStatusTemporary,
        HydrionPermissionMessage.preciseLocationAllowed =>
          permissionPreciseLocationAllowed,
        HydrionPermissionMessage.approximateLocationAllowed =>
          permissionApproximateLocationAllowed,
        HydrionPermissionMessage.locationOff => permissionLocationOff,
        HydrionPermissionMessage.locationNotAsked => permissionLocationNotAsked,
        HydrionPermissionMessage.locationBlocked => permissionLocationBlocked,
        HydrionPermissionMessage.locationRestricted =>
          permissionLocationRestricted,
        HydrionPermissionMessage.locationServicesOff =>
          permissionLocationServicesOff,
        HydrionPermissionMessage.locationUnsupported =>
          permissionLocationUnsupported,
        HydrionPermissionMessage.locationStatusTemporary =>
          permissionLocationStatusTemporary,
        HydrionPermissionMessage.exactAlarmNotRequired =>
          permissionExactAlarmNotRequired,
        HydrionPermissionMessage.exactAlarmAndroidOnly =>
          permissionExactAlarmAndroidOnly,
        HydrionPermissionMessage.exactSchedulingAvailable =>
          permissionExactSchedulingAvailable,
        HydrionPermissionMessage.exactSchedulingApproximate =>
          permissionExactSchedulingApproximate,
      };

  String permissionState(HydrionPermissionState state) => switch (state) {
        HydrionPermissionState.notRequested => permissionNotRequested,
        HydrionPermissionState.granted => enabled,
        HydrionPermissionState.approximateGranted =>
          permissionApproximateEnabled,
        HydrionPermissionState.preciseGranted => permissionPreciseEnabled,
        HydrionPermissionState.denied => permissionDenied,
        HydrionPermissionState.permanentlyDenied => permissionBlocked,
        HydrionPermissionState.restricted => permissionRestricted,
        HydrionPermissionState.notRequired => permissionNotRequired,
        HydrionPermissionState.unsupported => permissionUnsupported,
        HydrionPermissionState.temporarilyUnavailable =>
          permissionTemporarilyUnavailable,
        HydrionPermissionState.unknown => permissionStatusUnavailable,
      };
}
