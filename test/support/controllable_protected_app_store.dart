import 'dart:async';

import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/storage/protected_challenge_record.dart';
import 'package:hydrion/storage/protected_reminder_record.dart';

import 'memory_protected_app_store.dart';

/// [MemoryProtectedAppStore] with hold, reject-activation and lost-read
/// controls. Plain fail/read-failure statuses are already fields of
/// [MemoryProtectedAppStore] (`reminderWriteFailure`, `challengeReadFailure`…).
class ControllableProtectedAppStore extends MemoryProtectedAppStore {
  ControllableProtectedAppStore({
    this.rejectChallengeActivation = false,
    this.rejectContextActivation = false,
  });

  /// While set, reminder writes wait for it to complete.
  Completer<void>? holdReminderWrites;

  /// While set, challenge writes wait for it to complete.
  Completer<void>? holdChallengeWrites;

  /// Fail writes of an active-phase challenge record.
  bool rejectChallengeActivation;

  /// Fail writes of an active-phase daily-context record.
  bool rejectContextActivation;

  /// Report the next reminder read as unavailable (a verification read that
  /// loses access after a committed write).
  bool loseNextReminderRead = false;

  int challengeWrites = 0;

  @override
  Future<ProtectedReminderRead> readReminders() async {
    if (loseNextReminderRead) {
      loseNextReminderRead = false;
      return const ProtectedReminderRead(ProtectedReadStatus.unavailable);
    }
    return super.readReminders();
  }

  @override
  Future<ProtectedWriteStatus> writeReminders(
      ProtectedReminderRecord value) async {
    final hold = holdReminderWrites;
    if (hold != null) await hold.future;
    return super.writeReminders(value);
  }

  @override
  Future<ProtectedWriteStatus> writeChallenges(
      ProtectedChallengeRecord value) async {
    challengeWrites++;
    final hold = holdChallengeWrites;
    if (hold != null) await hold.future;
    if (rejectChallengeActivation &&
        value.phase == ContextRecordPhase.active) {
      return ProtectedWriteStatus.failed;
    }
    return super.writeChallenges(value);
  }

  @override
  Future<ProtectedWriteStatus> writeDailyContext(
      ProtectedContextRecord value) async {
    if (rejectContextActivation && value.phase == ContextRecordPhase.active) {
      return ProtectedWriteStatus.failed;
    }
    return super.writeDailyContext(value);
  }
}
