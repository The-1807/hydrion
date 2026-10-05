import '../storage/local_store.dart';
import '../storage/protected_app_store.dart';
import '../storage/protected_reminder_record.dart';

enum ReminderStorageStatus {
  ready,
  cleanupPending,
  unavailable,
  unsupported,
  corrupt,
  deletionPending,
}

final class ReminderStorageUnavailable implements Exception {
  final ProtectedWriteStatus? writeStatus;
  const ReminderStorageUnavailable({this.writeStatus});

  bool get definitelyNotCommitted =>
      writeStatus == ProtectedWriteStatus.failed ||
      writeStatus == ProtectedWriteStatus.unsupported ||
      writeStatus == ProtectedWriteStatus.unavailable;
  @override
  String toString() => 'ReminderStorageUnavailable';
}

/// Strict legacy decoder: returns canonical protected state or throws
/// [FormatException] / [ProtectedContextSchemaUnsupported] for quarantine.
typedef ReminderLegacyDecoder = Map<String, Object?> Function(
    String? reminders, String? orphans);

/// I09-only migration/deletion ownership; no arbitrary key or record API.
/// Reminder definitions and the OS-cancellation set are one authority.
final class ReminderProtection {
  static const storageKey = 'hydrion.reminders.v1';
  static const orphanStorageKey = 'hydrion.reminder_orphans.v1';
  static const deletionKey = 'hydrion.reminder_state.deletion.v1';
  static const authorityKey = 'hydrion.reminder_state.authority.v1';
  static const _intent = '{"schemaVersion":1,"pending":true}';

  final HydrionLocalStore legacy;
  final ProtectedAppStore store;
  ReminderStorageStatus status = ReminderStorageStatus.unavailable;
  ProtectedReminderRecord? record;

  /// Existing derivation of OS notification IDs from reminder IDs. Kept as a
  /// dependency so deletion replay after restart derives the same IDs.
  final int Function(String reminderId) platformIdOf;
  ReminderLegacyDecoder? _decodeLegacy;
  ReminderProtection(this.legacy, this.store, {required this.platformIdOf});
  bool get isKnown =>
      status == ReminderStorageStatus.ready ||
      status == ReminderStorageStatus.cleanupPending;

  Future<ProtectedReminderRead> _read() async {
    final destination = store;
    if (destination is ProtectedReminderStore) {
      return (destination as ProtectedReminderStore).readReminders();
    }
    return ProtectedReminderRead(destination is UnavailableProtectedAppStore
        ? destination.status
        : ProtectedReadStatus.unavailable);
  }

  Future<bool> _write(ProtectedReminderRecord candidate) async =>
      await _writeVerified(candidate) == ProtectedWriteStatus.committed;

  Future<ProtectedWriteStatus> _writeVerified(
      ProtectedReminderRecord candidate) async {
    final destination = store;
    if (destination is! ProtectedReminderStore) {
      return ProtectedWriteStatus.unsupported;
    }
    final outcome =
        await (destination as ProtectedReminderStore).writeReminders(candidate);
    if (outcome != ProtectedWriteStatus.committed) return outcome;
    try {
      return (await _read()).record?.equivalentTo(candidate) == true
          ? ProtectedWriteStatus.committed
          : ProtectedWriteStatus.verificationFailed;
    } catch (_) {
      return ProtectedWriteStatus.verificationFailed;
    }
  }

  Future<bool> _remove(String key) async {
    final source = legacy;
    final acknowledged = source is SharedPreferencesHydrionStore
        ? await source.removeAcknowledged(key)
        : source is MemoryHydrionStore
            ? await source.removeAcknowledged(key)
            : false;
    return acknowledged && await source.readString(key) == null;
  }

  Future<void> load(ReminderLegacyDecoder decodeLegacy) async {
    _decodeLegacy = decodeLegacy;
    status = ReminderStorageStatus.unavailable;
    record = null;
    try {
      final intent = await legacy.readString(deletionKey);
      if (intent != null) {
        if (intent != _intent) {
          status = ReminderStorageStatus.corrupt;
          return;
        }
        status = ReminderStorageStatus.deletionPending;
        try {
          await _finishDeletion();
        } catch (_) {
          status = ReminderStorageStatus.deletionPending;
        }
        return;
      }
      final read = await _read();
      if (read.status != ProtectedReadStatus.found &&
          read.status != ProtectedReadStatus.absent) {
        status = switch (read.status) {
          ProtectedReadStatus.corrupt => ReminderStorageStatus.corrupt,
          ProtectedReadStatus.unsupported => ReminderStorageStatus.unsupported,
          _ => ReminderStorageStatus.unavailable,
        };
        return;
      }
      final existing = read.record;
      final reference = await legacy.readString(authorityKey);
      if (reference != null) {
        final revision = int.tryParse(reference);
        if (revision == null ||
            revision < 1 ||
            existing == null ||
            existing.revision < revision ||
            existing.phase == ContextRecordPhase.provisional) {
          status = ReminderStorageStatus.corrupt;
          return;
        }
      }
      if (existing != null &&
          existing.phase != ContextRecordPhase.provisional) {
        record = existing;
        await cleanup();
        return;
      }
      final state = decodeLegacy(await legacy.readString(storageKey),
          await legacy.readString(orphanStorageKey));
      final provisional = ProtectedReminderRecord(
          revision: 1, phase: ContextRecordPhase.provisional, state: state);
      if (existing != null && !existing.equivalentTo(provisional)) {
        status = ReminderStorageStatus.corrupt;
        return;
      }
      if (existing == null && !await _write(provisional)) return;
      final active = ProtectedReminderRecord(
          revision: 1, phase: ContextRecordPhase.active, state: state);
      if (!await _write(active)) return;
      record = active;
      await cleanup();
    } on ProtectedContextSchemaUnsupported {
      status = ReminderStorageStatus.unsupported;
    } on FormatException {
      status = ReminderStorageStatus.corrupt;
    } catch (_) {
      status = ReminderStorageStatus.unavailable;
    }
  }

  /// Removes both legacy keys only after the revision reference is
  /// acknowledged. Uninterpretable retained source stays preserved.
  Future<void> cleanup() async {
    try {
      final revision = record!.revision.toString();
      if (!await legacy.writeString(authorityKey, revision) ||
          await legacy.readString(authorityKey) != revision) {
        status = ReminderStorageStatus.cleanupPending;
        return;
      }
      final reminders = await legacy.readString(storageKey);
      final orphans = await legacy.readString(orphanStorageKey);
      if (reminders != null || orphans != null) {
        _decodeLegacy!(reminders, orphans);
      }
      final clean = (reminders == null || await _remove(storageKey)) &&
          (orphans == null || await _remove(orphanStorageKey));
      status = clean
          ? ReminderStorageStatus.ready
          : ReminderStorageStatus.cleanupPending;
    } catch (_) {
      status = ReminderStorageStatus.cleanupPending;
    }
  }

  Future<void> save(Map<String, Object?> state) async {
    if (!isKnown) throw const ReminderStorageUnavailable();
    final ProtectedReminderRecord candidate;
    try {
      candidate = ProtectedReminderRecord(
          revision: record!.revision + 1,
          phase: ContextRecordPhase.active,
          state: state);
    } on FormatException {
      // A caller supplied a value outside the closed schema. Nothing was
      // written, so the protected authority stays known and unchanged.
      throw ArgumentError('Reminder state is outside the protected schema.');
    }
    try {
      final outcome = await _writeVerified(candidate);
      if (outcome != ProtectedWriteStatus.committed) {
        throw ReminderStorageUnavailable(writeStatus: outcome);
      }
      record = candidate;
      await cleanup();
    } on ReminderStorageUnavailable {
      status = ReminderStorageStatus.unavailable;
      rethrow;
    } catch (_) {
      status = ReminderStorageStatus.unavailable;
      throw const ReminderStorageUnavailable();
    }
  }

  /// Deletes reminder definitions. Outstanding orphan IDs, plus the platform
  /// IDs of the deleted definitions, remain until OS cancellation is
  /// confirmed through [save].
  Future<void> clear() async {
    status = ReminderStorageStatus.deletionPending;
    record = null;
    try {
      if (!await legacy.writeString(deletionKey, _intent) ||
          await legacy.readString(deletionKey) != _intent ||
          !await _finishDeletion()) {
        throw const ReminderStorageUnavailable();
      }
    } catch (_) {
      throw const ReminderStorageUnavailable();
    }
  }

  Map<String, Object?>? _tryDecodeLegacy(String? reminders, String? orphans) {
    final decode = _decodeLegacy;
    if (decode == null) return null;
    try {
      return decode(reminders, orphans);
    } catch (_) {
      return null;
    }
  }

  Iterable<int> _platformIds(Iterable<Map<String, Object?>> reminders) =>
      reminders.map((e) => platformIdOf(e['id'] as String));

  Future<bool> _finishDeletion() async {
    final read = await _read();
    if (read.status != ProtectedReadStatus.found &&
        read.status != ProtectedReadStatus.absent) {
      return false;
    }
    final old = read.record;
    // Legacy cleanup work survives deletion when it can be interpreted. An
    // uninterpretable source is preserved and reported as cleanup-pending.
    final legacyOrphans = await legacy.readString(orphanStorageKey);
    final decodedOrphans =
        legacyOrphans == null ? null : _tryDecodeLegacy(null, legacyOrphans);
    final retainOrphanSource = legacyOrphans != null && decodedOrphans == null;
    final ProtectedReminderRecord tombstone;
    if (old?.phase == ContextRecordPhase.deleted) {
      // Replay: the first pass already merged any interpretable legacy set.
      tombstone = old!;
    } else {
      final orphans = <int>{
        if (old != null) ...old.orphanNotificationIds,
        if (old != null) ..._platformIds(old.reminders),
        if (decodedOrphans != null)
          ...(decodedOrphans['orphanNotificationIds'] as List).cast<int>(),
      };
      if (old == null) {
        // Never-migrated definitions may still have OS schedules.
        final legacyReminders = await legacy.readString(storageKey);
        final decoded = legacyReminders == null
            ? null
            : _tryDecodeLegacy(legacyReminders, null);
        if (decoded != null) {
          orphans.addAll(_platformIds((decoded['reminders'] as List)
              .map((e) => (e as Map).cast<String, Object?>())));
        }
      }
      tombstone = ProtectedReminderRecord(
          revision: (old?.revision ?? 0) + 1,
          phase: ContextRecordPhase.deleted,
          state: ProtectedReminderRecord.canonicalState(
              reminders: const [], orphanNotificationIds: orphans));
    }
    if (!await _write(tombstone) ||
        !await legacy.writeString(
            authorityKey, tombstone.revision.toString()) ||
        await legacy.readString(authorityKey) !=
            tombstone.revision.toString() ||
        !await _remove(storageKey) ||
        (legacyOrphans != null &&
            !retainOrphanSource &&
            !await _remove(orphanStorageKey)) ||
        !await _remove(deletionKey)) {
      return false;
    }
    record = tombstone;
    status = retainOrphanSource
        ? ReminderStorageStatus.cleanupPending
        : ReminderStorageStatus.ready;
    return true;
  }
}
