import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/storage/local_store.dart';

import 'memory_protected_app_store.dart';

// Explicit test-owned destinations survive facade reconstruction, never an
// implicit memory fallback in a production repository.
final _destinations = Expando<MemoryProtectedAppStore>();

Future<ChallengeRepository> loadTestChallengeRepository(HydrionLocalStore store,
    {MemoryProtectedAppStore? protectedStore}) {
  final destination =
      protectedStore ?? (_destinations[store] ??= MemoryProtectedAppStore());
  return ChallengeRepository.load(store, protectedStore: destination);
}
