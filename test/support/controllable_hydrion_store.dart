import 'dart:async';

import 'package:hydrion/storage/local_store.dart';

/// How [ControllableHydrionStore] answers a write or removal it is told to
/// fault.
enum ControllableStoreFault {
  /// Persist and acknowledge (the default).
  none,

  /// Do not persist; return `false` (a rejected platform write/removal).
  reject,

  /// Do not persist but return `true` (an acknowledgement that lies).
  acknowledgeWithoutWriting,

  /// Throw [ControllableHydrionStore.error].
  throwError,
}

/// A pending hold created by [ControllableHydrionStore.hold].
class ControllableStoreHold {
  final Completer<void> _entered = Completer<void>();
  final Completer<void> _released = Completer<void>();

  /// Completes when a held operation reaches the store.
  Future<void> get entered => _entered.future;
  bool get engaged => _entered.isCompleted;

  /// Lets the held operation continue.
  void release() {
    if (!_released.isCompleted) _released.complete();
  }
}

/// The one controllable [HydrionLocalStore] fake for tests: counts, faults
/// (reject, lying acknowledgement, throw) and holds writes and removals.
///
/// Faults apply to every write/removal unless [faultWhen]/[removeFaultWhen]
/// narrow them. Counters are incremented before the predicates run, so a
/// predicate can select "the third write to key X".
class ControllableHydrionStore extends MemoryHydrionStore {
  ControllableHydrionStore([super.initialValues]);

  ControllableStoreFault writeFault = ControllableStoreFault.none;
  bool Function(String key)? faultWhen;
  ControllableStoreFault removeFault = ControllableStoreFault.none;
  bool Function(String key)? removeFaultWhen;
  Object error = StateError('synthetic local store failure');

  int writes = 0;
  int removals = 0;
  final Map<String, int> writeCounts = <String, int>{};

  ControllableStoreHold? _hold;
  bool Function(String key)? _holdWhen;
  bool _holdRemovals = false;
  bool _holdOnce = false;

  /// Number of operations that were actually held.
  int holdsEngaged = 0;

  /// Holds writes (and, with [includeRemovals], removals) whose key matches
  /// [when] until [ControllableStoreHold.release]. With [once], only the
  /// first matching operation is held.
  ControllableStoreHold hold({
    bool Function(String key)? when,
    bool includeRemovals = false,
    bool once = false,
  }) {
    final hold = ControllableStoreHold();
    _hold = hold;
    _holdWhen = when;
    _holdRemovals = includeRemovals;
    _holdOnce = once;
    return hold;
  }

  @override
  Future<bool> writeString(String key, String value) async {
    writes++;
    writeCounts.update(key, (count) => count + 1, ifAbsent: () => 1);
    await _awaitHold(key);
    final fault = (faultWhen?.call(key) ?? true)
        ? writeFault
        : ControllableStoreFault.none;
    switch (fault) {
      case ControllableStoreFault.none:
        return super.writeString(key, value);
      case ControllableStoreFault.reject:
        return false;
      case ControllableStoreFault.acknowledgeWithoutWriting:
        return true;
      case ControllableStoreFault.throwError:
        throw error;
    }
  }

  @override
  Future<void> remove(String key) async {
    removals++;
    await _awaitHold(key, removal: true);
    if (_removeFault(key) == ControllableStoreFault.throwError) throw error;
    if (_removeFault(key) == ControllableStoreFault.none) {
      await super.remove(key);
    }
  }

  @override
  Future<bool> removeAcknowledged(String key) async {
    removals++;
    await _awaitHold(key, removal: true);
    switch (_removeFault(key)) {
      case ControllableStoreFault.none:
        // Not super.removeAcknowledged: it re-enters the counted [remove].
        await super.remove(key);
        return true;
      case ControllableStoreFault.reject:
        return false;
      case ControllableStoreFault.acknowledgeWithoutWriting:
        return true;
      case ControllableStoreFault.throwError:
        throw error;
    }
  }

  ControllableStoreFault _removeFault(String key) =>
      (removeFaultWhen?.call(key) ?? true)
          ? removeFault
          : ControllableStoreFault.none;

  Future<void> _awaitHold(String key, {bool removal = false}) async {
    final hold = _hold;
    if (hold == null || (removal && !_holdRemovals)) return;
    if (!(_holdWhen?.call(key) ?? true)) return;
    if (_holdOnce || hold._released.isCompleted) _hold = null;
    if (hold._released.isCompleted) return;
    holdsEngaged++;
    if (!hold._entered.isCompleted) hold._entered.complete();
    await hold._released.future;
  }
}
