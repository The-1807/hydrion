import 'app_persistence_stub.dart'
    if (dart.library.io) 'app_persistence_io.dart' as implementation;
import 'protected_app_store.dart';

Future<ProtectedAppStore> openProtectedAppStore() =>
    implementation.openProtectedAppStore();
