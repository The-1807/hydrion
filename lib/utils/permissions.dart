class PermissionSummary {
  final bool notifications;
  final bool bluetooth;
  final bool health;

  const PermissionSummary({
    required this.notifications,
    required this.bluetooth,
    required this.health,
  });

  bool get allGranted => notifications && bluetooth && health;
}

class Permissions {
  PermissionSummary _summary = const PermissionSummary(
    notifications: false,
    bluetooth: false,
    health: false,
  );

  PermissionSummary get summary => _summary;

  Future<bool> requestAll() {
    return requestPermissions();
  }

  Future<bool> requestPermissions() async {
    _summary = const PermissionSummary(
      notifications: false,
      bluetooth: false,
      health: false,
    );
    return false;
  }

  Future<bool> hasAll() async {
    return _summary.allGranted;
  }
}
