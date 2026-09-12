import '../repositories/health_data_repository.dart';

enum HealthPersistenceStatus {
  ready,
  unsupportedPlatform,
  missingKey,
  inaccessibleKey,
  unreadableOrCorrupt,
}

class HealthPersistenceResult {
  final HealthPersistenceStatus status;
  final HealthDataRepository? repository;

  const HealthPersistenceResult(this.status, {this.repository});

  bool get isReady =>
      status == HealthPersistenceStatus.ready && repository != null;
}
