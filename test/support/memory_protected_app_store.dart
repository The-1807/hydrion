import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/storage/protected_settings_record.dart';
import 'package:hydrion/storage/protected_challenge_record.dart';

/// Explicit test adapter, never a production platform fallback.
class MemoryProtectedAppStore
    implements
        ProtectedAppStore,
        ProtectedSettingsStore,
        ProtectedChallengeStore {
  ProtectedChallengeRecord? challengeRecord;
  ProtectedWriteStatus? challengeWriteFailure;
  ProtectedReadStatus? challengeReadFailure;
  @override
  Future<ProtectedChallengeRead> readChallenges() async =>
      challengeReadFailure != null
          ? ProtectedChallengeRead(challengeReadFailure!)
          : ProtectedChallengeRead(
              challengeRecord == null ||
                      challengeRecord!.phase == ContextRecordPhase.deleted
                  ? ProtectedReadStatus.absent
                  : ProtectedReadStatus.found,
              challengeRecord);
  @override
  Future<ProtectedWriteStatus> writeChallenges(
      ProtectedChallengeRecord value) async {
    if (challengeWriteFailure != null) return challengeWriteFailure!;
    challengeRecord = value;
    return ProtectedWriteStatus.committed;
  }

  ProtectedSettingsRecord? settingsRecord;
  ProtectedWriteStatus? settingsWriteFailure;
  ProtectedReadStatus? settingsReadFailure;

  @override
  Future<ProtectedSettingsRead> readSettings() async =>
      settingsReadFailure != null
          ? ProtectedSettingsRead(settingsReadFailure!)
          : ProtectedSettingsRead(
              settingsRecord == null
                  ? ProtectedReadStatus.absent
                  : ProtectedReadStatus.found,
              settingsRecord);

  @override
  Future<ProtectedWriteStatus> writeSettings(
      ProtectedSettingsRecord value) async {
    if (settingsWriteFailure != null) return settingsWriteFailure!;
    settingsRecord = value;
    return ProtectedWriteStatus.committed;
  }

  ProtectedContextRecord? record;
  ProtectedWriteStatus? writeFailure;
  ProtectedDeleteStatus? deleteFailure;
  ProtectedReadStatus? readFailure;
  int writes = 0;
  @override
  Future<ProtectedContextRead> readDailyContext() async => readFailure != null
      ? ProtectedContextRead(readFailure!)
      : ProtectedContextRead(
          record == null || record!.phase == ContextRecordPhase.deleted
              ? ProtectedReadStatus.absent
              : ProtectedReadStatus.found,
          record);
  @override
  Future<ProtectedWriteStatus> writeDailyContext(
      ProtectedContextRecord value) async {
    writes++;
    if (writeFailure != null) return writeFailure!;
    record = value;
    return ProtectedWriteStatus.committed;
  }

  @override
  Future<ProtectedDeleteStatus> deleteDailyContext(int revision) async {
    if (deleteFailure != null) return deleteFailure!;
    record = ProtectedContextRecord(
        revision: revision,
        phase: ContextRecordPhase.deleted,
        contexts: const []);
    return ProtectedDeleteStatus.verifiedAbsent;
  }

  @override
  Future<void> close() async {}
}
