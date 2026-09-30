import '../storage/local_store.dart';
import '../storage/protected_app_store.dart';
import '../storage/protected_challenge_record.dart';

enum ChallengeStorageStatus {
  ready,
  cleanupPending,
  unavailable,
  unsupported,
  corrupt,
  deletionPending,
}

final class ChallengeStorageUnavailable implements Exception {
  const ChallengeStorageUnavailable();
  @override
  String toString() => 'ChallengeStorageUnavailable';
}

/// I08-only migration/deletion ownership; no arbitrary key or record API.
final class ChallengeProtection {
  static const storageKey = 'hydrion.joined_challenge.v1';
  static const deletionKey = 'hydrion.challenge_state.deletion.v1';
  static const authorityKey = 'hydrion.challenge_state.authority.v1';
  final HydrionLocalStore legacy;
  final ProtectedAppStore store;
  ChallengeStorageStatus status = ChallengeStorageStatus.unavailable;
  ProtectedChallengeRecord? record;
  Map<String, Object?> Function(String?)? _decodeLegacy;
  ChallengeProtection(this.legacy, this.store);
  bool get isKnown =>
      status == ChallengeStorageStatus.ready ||
      status == ChallengeStorageStatus.cleanupPending;

  Future<ProtectedChallengeRead> _read() async {
    final destination = store;
    if (destination is ProtectedChallengeStore) {
      return (destination as ProtectedChallengeStore).readChallenges();
    }
    return ProtectedChallengeRead(destination is UnavailableProtectedAppStore
        ? destination.status
        : ProtectedReadStatus.unavailable);
  }

  Future<bool> _write(ProtectedChallengeRecord candidate) async {
    final destination = store;
    if (destination is! ProtectedChallengeStore ||
        await (destination as ProtectedChallengeStore)
                .writeChallenges(candidate) !=
            ProtectedWriteStatus.committed) {
      return false;
    }
    return (await _read()).record?.equivalentTo(candidate) == true;
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

  Future<void> load(Map<String, Object?> Function(String?) decodeLegacy) async {
    _decodeLegacy = decodeLegacy;
    status = ChallengeStorageStatus.unavailable;
    record = null;
    try {
      final intent = await legacy.readString(deletionKey);
      if (intent != null) {
        if (intent != '{"schemaVersion":1,"pending":true}') {
          status = ChallengeStorageStatus.corrupt;
          return;
        }
        status = ChallengeStorageStatus.deletionPending;
        try {
          await _finishDeletion();
        } catch (_) {
          status = ChallengeStorageStatus.deletionPending;
        }
        return;
      }
      final read = await _read();
      if (read.status != ProtectedReadStatus.found &&
          read.status != ProtectedReadStatus.absent) {
        status = switch (read.status) {
          ProtectedReadStatus.corrupt => ChallengeStorageStatus.corrupt,
          ProtectedReadStatus.unsupported => ChallengeStorageStatus.unsupported,
          _ => ChallengeStorageStatus.unavailable,
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
          status = ChallengeStorageStatus.corrupt;
          return;
        }
      }
      if (existing != null &&
          existing.phase != ContextRecordPhase.provisional) {
        record = existing;
        await cleanup();
        return;
      }
      final state = decodeLegacy(await legacy.readString(storageKey));
      final provisional = ProtectedChallengeRecord(
          revision: 1, phase: ContextRecordPhase.provisional, state: state);
      if (existing != null && !existing.equivalentTo(provisional)) {
        status = ChallengeStorageStatus.corrupt;
        return;
      }
      if (existing == null && !await _write(provisional)) return;
      final active = ProtectedChallengeRecord(
          revision: 1, phase: ContextRecordPhase.active, state: state);
      if (!await _write(active)) return;
      record = active;
      await cleanup();
    } on ProtectedContextSchemaUnsupported {
      status = ChallengeStorageStatus.unsupported;
    } on FormatException {
      status = ChallengeStorageStatus.corrupt;
    } catch (_) {
      status = ChallengeStorageStatus.unavailable;
    }
  }

  Future<void> cleanup() async {
    try {
      final revision = record!.revision.toString();
      if (!await legacy.writeString(authorityKey, revision) ||
          await legacy.readString(authorityKey) != revision) {
        status = ChallengeStorageStatus.cleanupPending;
        return;
      }
      final raw = await legacy.readString(storageKey);
      if (raw != null) _decodeLegacy!(raw);
      status = raw == null || await _remove(storageKey)
          ? ChallengeStorageStatus.ready
          : ChallengeStorageStatus.cleanupPending;
    } catch (_) {
      status = ChallengeStorageStatus.cleanupPending;
    }
  }

  Future<void> save(Map<String, Object?> state) async {
    if (!isKnown) throw const ChallengeStorageUnavailable();
    try {
      final candidate = ProtectedChallengeRecord(
          revision: record!.revision + 1,
          phase: ContextRecordPhase.active,
          state: state);
      if (!await _write(candidate)) throw const ChallengeStorageUnavailable();
      record = candidate;
      await cleanup();
    } catch (_) {
      status = ChallengeStorageStatus.unavailable;
      throw const ChallengeStorageUnavailable();
    }
  }

  Future<void> clear() async {
    status = ChallengeStorageStatus.deletionPending;
    record = null;
    try {
      const intent = '{"schemaVersion":1,"pending":true}';
      if (!await legacy.writeString(deletionKey, intent) ||
          await legacy.readString(deletionKey) != intent ||
          !await _finishDeletion()) {
        throw const ChallengeStorageUnavailable();
      }
    } catch (_) {
      throw const ChallengeStorageUnavailable();
    }
  }

  Future<bool> _finishDeletion() async {
    final read = await _read();
    if (read.status != ProtectedReadStatus.found &&
        read.status != ProtectedReadStatus.absent) {
      return false;
    }
    final old = read.record;
    final tombstone = old?.phase == ContextRecordPhase.deleted
        ? old!
        : ProtectedChallengeRecord(
            revision: (old?.revision ?? 0) + 1,
            phase: ContextRecordPhase.deleted,
            state: const {
                'schemaVersion': 6,
                'activeChallenges': [],
                'challengeHistory': [],
              });
    if (!await _write(tombstone) ||
        !await legacy.writeString(
            authorityKey, tombstone.revision.toString()) ||
        await legacy.readString(authorityKey) !=
            tombstone.revision.toString() ||
        !await _remove(storageKey) ||
        !await _remove(deletionKey)) {
      return false;
    }
    record = tombstone;
    status = ChallengeStorageStatus.ready;
    return true;
  }
}
