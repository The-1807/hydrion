import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum HydrionPermissionRevocationResult {
  scheduled,
  settingsRequired,
  unsupported,
  failed,
}

class AndroidPermissionRevocationService {
  static const _channel = MethodChannel('hydrion/permission_revocation');

  const AndroidPermissionRevocationService();

  Future<HydrionPermissionRevocationResult> revokeOnProfileDeletion() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return HydrionPermissionRevocationResult.unsupported;
    }
    try {
      final result = await _channel.invokeMethod<String>(
        'revokeRuntimePermissionsOnKill',
      );
      return switch (result) {
        'scheduled' => HydrionPermissionRevocationResult.scheduled,
        'settings_required' =>
          HydrionPermissionRevocationResult.settingsRequired,
        _ => HydrionPermissionRevocationResult.failed,
      };
    } on PlatformException {
      return HydrionPermissionRevocationResult.failed;
    } on MissingPluginException {
      return HydrionPermissionRevocationResult.unsupported;
    }
  }
}
