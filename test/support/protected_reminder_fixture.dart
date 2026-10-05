import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/storage/local_store.dart';

import 'memory_protected_app_store.dart';

// Explicit test-owned protected destinations survive facade reconstruction;
// production repositories never fall back to memory.
final _destinations = Expando<MemoryProtectedAppStore>();

MemoryProtectedAppStore protectedReminderDestination(HydrionLocalStore store) =>
    _destinations[store] ??= MemoryProtectedAppStore();

Future<ReminderRepository> loadTestReminderRepository(HydrionLocalStore store,
    {MemoryProtectedAppStore? protectedStore}) {
  final destination = protectedStore ?? protectedReminderDestination(store);
  return ReminderRepository.load(store, protectedStore: destination);
}
