import 'health_data_persistence_stub.dart'
    if (dart.library.io) 'health_data_persistence_io.dart' as implementation;
import 'health_data_persistence_types.dart';

export 'health_data_persistence_types.dart';

Future<HealthPersistenceResult> initializeHealthDataPersistence() =>
    implementation.initializeHealthDataPersistence();
