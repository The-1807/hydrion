import 'health_data_persistence_types.dart';

Future<HealthPersistenceResult> initializeHealthDataPersistence() async {
  return const HealthPersistenceResult(
    HealthPersistenceStatus.unsupportedPlatform,
  );
}
