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
    notifications: true,
    bluetooth: false,
    health: false,
  );

  PermissionSummary get summary => _summary;

  Future<bool> requestAll() {
    return requestPermissions();
  }

  Future<bool> requestPermissions() async {
    _summary = const PermissionSummary(
      notifications: true,
      bluetooth: false,
      health: false,
    );
    return true;
  }

  Future<bool> hasAll() async {
    return _summary.allGranted;
  }
}
