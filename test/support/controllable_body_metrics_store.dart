import 'dart:async';

import 'package:hydrion/services/sensitive_body_metrics_store.dart';

/// The one controllable secure body-metrics store fake for tests: fails,
/// ignores or holds writes, makes reads unavailable, fails deletes, counts.
class ControllableBodyMetricsSecureStore
    extends MemorySensitiveBodyMetricsStore {
  ControllableBodyMetricsSecureStore({super.initial, super.supported});

  /// Throw [writeError] instead of writing.
  bool failWrites = false;
  Object writeError = StateError('synthetic secure write failure');

  /// Return normally without persisting (a swallowed native failure).
  bool ignoreWrites = false;

  /// Report [SensitiveBodyReadStatus.unavailable] for every read.
  bool readUnavailable = false;

  /// Return this status from [delete] without deleting.
  SensitiveBodyDeleteStatus? deleteFailure;

  /// Runs at the start of every write, before any fault applies.
  void Function()? beforeWrite;

  /// While set, writes wait for it to complete.
  Completer<void>? holdWrites;

  int writes = 0;
  int deletes = 0;

  @override
  Future<void> write(Map<String, Object?> fields) async {
    writes++;
    beforeWrite?.call();
    final hold = holdWrites;
    if (hold != null) await hold.future;
    if (failWrites) throw writeError;
    if (ignoreWrites) return;
    await super.write(fields);
  }

  @override
  Future<SensitiveBodyRead> readResult() async =>
      readUnavailable ? const SensitiveBodyRead.unavailable() : super.readResult();

  @override
  Future<SensitiveBodyDeleteStatus> delete() async {
    deletes++;
    return deleteFailure ?? await super.delete();
  }
}
