import '../domain/pomodoro_session.dart';
import '../repositories/challenge_repository.dart';
import '../repositories/hydration_repository.dart';
import 'notifications.dart';

class PomodoroSessionService {
  static const challengeId = 'pomodoro-sip';
  static const _stateKey = 'pomodoroSession';
  static const _consumedSessionIdsKey = 'pomodoroConsumedSessionIds';
  static const _pendingDrinkKey = 'pomodoroPendingDrink';
  static const _completionMessage =
      'Focus session complete. Take your planned sip when you’re ready.';

  final ChallengeRepository _challenges;
  final NotificationService _notifications;
  final DateTime Function() _now;
  final Set<String> _inFlightOperations = <String>{};
  Future<PomodoroSessionState?>? _timerTransition;

  PomodoroSessionService({
    required ChallengeRepository challengeRepository,
    required NotificationService notificationService,
    DateTime Function()? now,
  })  : _challenges = challengeRepository,
        _notifications = notificationService,
        _now = now ?? DateTime.now;

  PomodoroSessionState? currentState() {
    final challenge = _challenges.activeChallengeFor(challengeId);
    return challenge == null ? null : stateFor(challenge);
  }

  PomodoroSessionState stateFor(
    JoinedChallenge challenge, {
    DateTime? now,
  }) {
    final currentTime = now ?? _now();
    final stored =
        PomodoroSessionState.fromJson(challenge.parameters[_stateKey]);
    if (stored != null && stored.challengeInstanceId == challenge.instanceId) {
      return stored;
    }
    return _migrateLegacyState(challenge, currentTime);
  }

  Future<PomodoroSessionState?> start() {
    return _runTimerTransition(_startTransition);
  }

  Future<PomodoroSessionState?> _startTransition() async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    final existing = stateFor(challenge);
    if (existing.lifecycle == PomodoroSessionLifecycle.running) {
      return existing;
    }
    return _startFresh(
      challenge,
      sessionNumber: _freshSessionNumber(existing),
      history: existing.history,
    );
  }

  Future<PomodoroSessionState?> pause() {
    return _runTimerTransition(_pauseTransition);
  }

  Future<PomodoroSessionState?> _pauseTransition() async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    final state = stateFor(challenge);
    if (state.lifecycle != PomodoroSessionLifecycle.running) return state;
    final snapshot = state.snapshot(_now());
    if (snapshot.remainingDuration == Duration.zero) {
      return _complete(
        endedEarly: false,
        completedAt: state.completionAt ?? _now(),
      );
    }
    await _cancelReminder(state.reminderId);
    final paused = state.copyWith(
      lifecycle: PomodoroSessionLifecycle.paused,
      pausedRemaining: snapshot.remainingDuration,
      updatedAt: _now(),
      clearCompletionAt: true,
      clearReminderId: true,
      clearReminderSchedulingMode: true,
    );
    await _persistState(paused);
    return paused;
  }

  Future<PomodoroSessionState?> resume() {
    return _runTimerTransition(_resumeTransition);
  }

  Future<PomodoroSessionState?> _resumeTransition() async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    final state = stateFor(challenge);
    if (state.lifecycle != PomodoroSessionLifecycle.paused ||
        state.sessionId == null) {
      return state;
    }
    final now = _now();
    final remaining = state.pausedRemaining.inSeconds <= 0
        ? const Duration(seconds: 1)
        : state.pausedRemaining;
    var resumed = state.copyWith(
      lifecycle: PomodoroSessionLifecycle.running,
      completionAt: now.add(remaining),
      updatedAt: now,
      clearReminderId: true,
      clearReminderSchedulingMode: true,
    );
    await _persistState(resumed);
    resumed = await _scheduleReminder(resumed);
    return resumed;
  }

  Future<PomodoroSessionState?> restart() {
    return _runTimerTransition(_restartTransition);
  }

  Future<PomodoroSessionState?> _restartTransition() async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    final state = stateFor(challenge);
    await _cancelReminder(state.reminderId);
    return _startFresh(
      challenge,
      sessionNumber: _freshSessionNumber(state),
      history: state.history,
    );
  }

  Future<PomodoroSessionState?> stop() {
    return _runTimerTransition(_stopTransition);
  }

  Future<PomodoroSessionState?> _stopTransition() async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    final state = stateFor(challenge);
    await _cancelReminder(state.reminderId);
    final stopped = state.copyWith(
      lifecycle: PomodoroSessionLifecycle.stopped,
      pausedRemaining: state.snapshot(_now()).remainingDuration,
      updatedAt: _now(),
      clearCompletionAt: true,
      clearReminderId: true,
      clearReminderSchedulingMode: true,
    );
    await _persistState(stopped);
    return stopped;
  }

  Future<PomodoroSessionState?> syncReminderPreference() {
    return _runTimerTransition(_syncReminderPreferenceTransition);
  }

  Future<PomodoroSessionState?> _syncReminderPreferenceTransition() async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    var state = stateFor(challenge);
    final enabled =
        challenge.parameters['notifications']?.toString().toLowerCase() ==
            'enabled';
    if (!enabled) {
      await _cancelReminder(state.reminderId);
      state = state.copyWith(
        updatedAt: _now(),
        clearReminderId: true,
        clearReminderSchedulingMode: true,
      );
      await _persistState(state);
      return state;
    }
    final reminderStillExists = state.reminderId != null &&
        _notifications.scheduledReminders.any(
          (reminder) => reminder.id == state.reminderId,
        );
    if (state.lifecycle != PomodoroSessionLifecycle.running ||
        state.completionAt == null ||
        !state.completionAt!.isAfter(_now()) ||
        reminderStillExists) {
      return state;
    }
    if (state.reminderId != null) {
      state = state.copyWith(
        clearReminderId: true,
        clearReminderSchedulingMode: true,
      );
      await _persistState(state);
    }
    return _scheduleReminder(state);
  }

  Future<PomodoroSessionState?> completeEarly() {
    return _runTimerTransition(
      () => _complete(endedEarly: true, completedAt: _now()),
    );
  }

  Future<PomodoroSessionState?> completeNaturally() {
    return _runTimerTransition(_completeNaturallyTransition);
  }

  Future<PomodoroSessionState?> _completeNaturallyTransition() async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    final state = stateFor(challenge);
    if (state.lifecycle == PomodoroSessionLifecycle.completed &&
        state.completionCommitted) {
      return state;
    }
    if (state.lifecycle != PomodoroSessionLifecycle.running) return state;
    final snapshot = state.snapshot(_now());
    if (snapshot.remainingDuration > Duration.zero) return state;
    return _complete(
      endedEarly: false,
      completedAt: state.completionAt ?? _now(),
    );
  }

  Future<PomodoroSessionState?> reconcile() async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    final state = stateFor(challenge);
    if (state.lifecycle == PomodoroSessionLifecycle.running &&
        state.snapshot(_now()).remainingDuration == Duration.zero) {
      return completeNaturally();
    }
    if (PomodoroSessionState.fromJson(challenge.parameters[_stateKey]) ==
        null) {
      await _persistState(state);
    }
    return state;
  }

  Future<PomodoroSessionState?> _runTimerTransition(
    Future<PomodoroSessionState?> Function() operation,
  ) async {
    final existing = _timerTransition;
    if (existing != null) return existing;
    final transition = operation();
    _timerTransition = transition;
    try {
      return await transition;
    } finally {
      if (identical(_timerTransition, transition)) {
        _timerTransition = null;
      }
    }
  }

  Future<HydrationLog?> recordSip({
    required HydrationRepository hydrationRepository,
  }) {
    final challenge = _challenges.activeChallengeFor(challengeId);
    final amount = (challenge?.parameters['amountMl'] as num?)?.round() ?? 0;
    return recordMeasuredDrink(
      hydrationRepository: hydrationRepository,
      amountMl: amount,
    );
  }

  Future<HydrationLog?> recordMeasuredDrink({
    required HydrationRepository hydrationRepository,
    required int amountMl,
    HydrationMetadata metadata = const HydrationMetadata(),
  }) async {
    if (amountMl <= 0) return null;
    await reconcile();
    var challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    final state = stateFor(challenge);
    final sessionId = state.sessionId;
    if (state.lifecycle != PomodoroSessionLifecycle.completed ||
        !state.completionCommitted ||
        sessionId == null ||
        _consumedSessionIds(challenge).contains(sessionId) ||
        !_inFlightOperations.add('drink:$sessionId')) {
      return null;
    }
    try {
      final pending = challenge.parameters[_pendingDrinkKey];
      final pendingForSession = pending is Map &&
          pending['sessionId']?.toString() == sessionId &&
          (pending['actionKey']?.toString().trim() ?? '').isNotEmpty &&
          DateTime.tryParse(pending['eventAt']?.toString() ?? '') != null &&
          pending['amountMl'] is num;
      final eventAt = pendingForSession
          ? DateTime.parse(pending['eventAt'].toString())
          : _now();
      final persistedAmount =
          pendingForSession ? (pending['amountMl'] as num).round() : amountMl;
      final actionKey = pendingForSession
          ? pending['actionKey'].toString()
          : 'pomodoro-session-$sessionId-drink';
      if (!pendingForSession) {
        await _persistState(
          state,
          extraParameters: {
            _pendingDrinkKey: {
              'sessionId': sessionId,
              'actionKey': actionKey,
              'eventAt': eventAt.toIso8601String(),
              'amountMl': persistedAmount,
            },
          },
        );
        challenge = _challenges.activeChallengeFor(challengeId);
        if (challenge == null) return null;
      }
      final actionId =
          '${challenge.instanceId}:${_localDayToken(eventAt)}:$actionKey';
      HydrationLog? log;
      if (challenge.completedActionIds.contains(actionId)) {
        for (final candidate in hydrationRepository.logs) {
          if (candidate.actionId == actionId) {
            log = candidate;
            break;
          }
        }
      } else {
        log = await _challenges.completeHydrationAction(
          hydrationRepository: hydrationRepository,
          volumeMl: persistedAmount,
          actionKey: actionKey,
          timestamp: eventAt,
          challengeId: challengeId,
          metadata: metadata,
        );
      }
      if (log == null) return null;
      challenge = _challenges.activeChallengeFor(challengeId);
      if (challenge == null) return log;
      await _advanceAfterDrink(challenge, state);
      return log;
    } finally {
      _inFlightOperations.remove('drink:$sessionId');
    }
  }

  Future<PomodoroSessionState?> _startFresh(
    JoinedChallenge challenge, {
    required int sessionNumber,
    required List<PomodoroSessionHistoryEntry> history,
  }) async {
    final now = _now();
    final total = _configuredDuration(challenge);
    final sessionId =
        '${challenge.instanceId}-session-$sessionNumber-${now.microsecondsSinceEpoch}';
    var running = PomodoroSessionState(
      challengeInstanceId: challenge.instanceId,
      sessionId: sessionId,
      sessionNumber: sessionNumber,
      totalDuration: total,
      startedAt: now,
      completionAt: now.add(total),
      pausedRemaining: total,
      lifecycle: PomodoroSessionLifecycle.running,
      completionCommitted: false,
      reminderId: null,
      reminderSchedulingMode: null,
      completionActionId: '$sessionId:completed',
      updatedAt: now,
      history: List.unmodifiable(history),
    );
    await _persistState(running);
    running = await _scheduleReminder(running);
    return running;
  }

  Future<PomodoroSessionState?> _complete({
    required bool endedEarly,
    required DateTime completedAt,
  }) async {
    var challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return null;
    final state = stateFor(challenge);
    final sessionId = state.sessionId;
    if (sessionId == null) return state;
    if (!_inFlightOperations.add('complete:$sessionId')) {
      return stateFor(
        _challenges.activeChallengeFor(challengeId) ?? challenge,
      );
    }
    try {
      challenge = _challenges.activeChallengeFor(challengeId);
      if (challenge == null) return null;
      final latest = stateFor(challenge);
      if (latest.completionCommitted ||
          latest.history.any((entry) => entry.sessionId == sessionId)) {
        return latest;
      }
      await _cancelReminder(latest.reminderId);
      final history = <PomodoroSessionHistoryEntry>[
        ...latest.history,
        PomodoroSessionHistoryEntry(
          sessionId: sessionId,
          sessionNumber: latest.sessionNumber,
          completedAt: completedAt,
          hasAuthenticTime: true,
          endedEarly: endedEarly,
        ),
      ];
      final completed = latest.copyWith(
        lifecycle: PomodoroSessionLifecycle.completed,
        completionAt: completedAt,
        pausedRemaining: Duration.zero,
        completionCommitted: true,
        completionActionId: latest.completionActionId ?? '$sessionId:completed',
        updatedAt: _now(),
        history: history,
        clearReminderId: true,
        clearReminderSchedulingMode: true,
      );
      await _persistState(completed);
      return completed;
    } finally {
      _inFlightOperations.remove('complete:$sessionId');
    }
  }

  Future<void> _advanceAfterDrink(
    JoinedChallenge challenge,
    PomodoroSessionState completedState,
  ) async {
    final sessionId = completedState.sessionId!;
    final consumed = <String>{..._consumedSessionIds(challenge), sessionId};
    final planned =
        ((challenge.parameters['sessionsPerDay'] as num?) ?? 1).round();
    if (completedState.sessionNumber >= planned) {
      await _persistState(
        completedState,
        extraParameters: {
          _consumedSessionIdsKey: consumed.toList()..sort(),
          _pendingDrinkKey: null,
        },
      );
      return;
    }
    final nextNumber = completedState.sessionNumber + 1;
    final autoStart =
        challenge.parameters['autoStartNext']?.toString().toLowerCase() ==
            'enabled';
    if (autoStart) {
      await _persistState(
        completedState,
        extraParameters: {
          _consumedSessionIdsKey: consumed.toList()..sort(),
          _pendingDrinkKey: null,
        },
      );
      final latest = _challenges.activeChallengeFor(challengeId);
      if (latest != null) {
        await _startFresh(
          latest,
          sessionNumber: nextNumber,
          history: completedState.history,
        );
      }
      return;
    }
    final waiting = PomodoroSessionState.initial(
      challengeInstanceId: challenge.instanceId,
      totalDuration: _configuredDuration(challenge),
      now: _now(),
      sessionNumber: nextNumber,
      history: completedState.history,
    ).copyWith(lifecycle: PomodoroSessionLifecycle.stopped);
    await _persistState(
      waiting,
      extraParameters: {
        _consumedSessionIdsKey: consumed.toList()..sort(),
        _pendingDrinkKey: null,
      },
    );
  }

  Future<PomodoroSessionState> _scheduleReminder(
    PomodoroSessionState state,
  ) async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    final end = state.completionAt;
    if (challenge == null ||
        end == null ||
        challenge.parameters['notifications']?.toString().toLowerCase() !=
            'enabled') {
      return state;
    }
    if (!end.isAfter(_now())) return state;
    final result = await _notifications.createReminder(
      triggerTime: end,
      message: _completionMessage,
      priority: 1,
      requestPermissionIfNeeded: true,
    );
    if (!result.scheduled || result.reminder == null) return state;
    final scheduled = state.copyWith(
      reminderId: result.reminder!.id,
      reminderSchedulingMode: result.state.name,
      updatedAt: _now(),
    );
    try {
      await _persistState(scheduled);
    } catch (_) {
      await _notifications.deleteReminder(result.reminder!.id);
      rethrow;
    }
    return scheduled;
  }

  Future<void> _cancelReminder(String? reminderId) async {
    if (reminderId == null || reminderId.isEmpty) return;
    await _notifications.deleteReminder(reminderId);
  }

  Future<void> _persistState(
    PomodoroSessionState state, {
    Map<String, Object?> extraParameters = const {},
  }) async {
    final challenge = _challenges.activeChallengeFor(challengeId);
    if (challenge == null) return;
    await _challenges.updateParameters({
      ...challenge.parameters,
      ...extraParameters,
      _stateKey: state.toJson(),
      'timerStatus': switch (state.lifecycle) {
        PomodoroSessionLifecycle.running => 'running',
        PomodoroSessionLifecycle.paused => 'paused',
        PomodoroSessionLifecycle.completed => 'complete',
        PomodoroSessionLifecycle.stopped => 'stopped',
        PomodoroSessionLifecycle.cancelled => 'cancelled',
        PomodoroSessionLifecycle.notStarted => 'stopped',
      },
      'timerSession': state.sessionNumber,
      'timerSessionId': state.sessionId ?? '',
      'timerStartedAt': state.startedAt?.toIso8601String() ?? '',
      'timerEndsAt': state.completionAt?.toIso8601String() ?? '',
      'timerPausedSeconds': state.pausedRemaining.inSeconds,
      'timerReminderId': state.reminderId ?? '',
    }, challengeId: challengeId);
  }

  PomodoroSessionState _migrateLegacyState(
    JoinedChallenge challenge,
    DateTime now,
  ) {
    final parameters = challenge.parameters;
    final total = _configuredDuration(challenge);
    final sessionNumber =
        ((parameters['timerSession'] as num?) ?? 1).round().clamp(1, 1000);
    final startedAt =
        DateTime.tryParse(parameters['timerStartedAt']?.toString() ?? '');
    final completionAt =
        DateTime.tryParse(parameters['timerEndsAt']?.toString() ?? '');
    final pausedSeconds =
        ((parameters['timerPausedSeconds'] as num?) ?? total.inSeconds)
            .round()
            .clamp(0, total.inSeconds);
    final legacyStatus = parameters['timerStatus']?.toString().toLowerCase();
    final lifecycle = switch (legacyStatus) {
      'running' => PomodoroSessionLifecycle.running,
      'paused' => PomodoroSessionLifecycle.paused,
      'complete' || 'completed' => PomodoroSessionLifecycle.completed,
      'cancelled' => PomodoroSessionLifecycle.cancelled,
      'stopped' => PomodoroSessionLifecycle.stopped,
      _ => PomodoroSessionLifecycle.notStarted,
    };
    final hasSession = startedAt != null ||
        completionAt != null ||
        lifecycle == PomodoroSessionLifecycle.completed;
    final sessionId = hasSession
        ? '${challenge.instanceId}-legacy-session-$sessionNumber-'
            '${(startedAt ?? completionAt ?? challenge.joinedAt).microsecondsSinceEpoch}'
        : null;
    return PomodoroSessionState(
      challengeInstanceId: challenge.instanceId,
      sessionId: sessionId,
      sessionNumber: sessionNumber,
      totalDuration: total,
      startedAt: startedAt,
      completionAt: completionAt,
      pausedRemaining: Duration(seconds: pausedSeconds),
      lifecycle: lifecycle,
      completionCommitted: false,
      reminderId: _optionalText(parameters['timerReminderId']),
      reminderSchedulingMode: null,
      completionActionId: sessionId == null ? null : '$sessionId:completed',
      updatedAt: now,
      history: _legacyHistory(parameters),
    );
  }

  List<PomodoroSessionHistoryEntry> _legacyHistory(
    Map<String, Object?> parameters,
  ) {
    final raw = parameters['pomodoroSessionHistory'];
    if (raw is! List) return const [];
    return raw
        .map(PomodoroSessionHistoryEntry.fromJson)
        .whereType<PomodoroSessionHistoryEntry>()
        .toList(growable: false);
  }

  Set<String> _consumedSessionIds(JoinedChallenge challenge) {
    final value = challenge.parameters[_consumedSessionIdsKey];
    if (value is! List) return const {};
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Duration _configuredDuration(JoinedChallenge challenge) {
    final minutes =
        ((challenge.parameters['sessionMinutes'] as num?) ?? 25).round();
    return Duration(minutes: minutes.clamp(1, 1440));
  }

  int _freshSessionNumber(PomodoroSessionState state) {
    final now = _now().toLocal();
    final updated = state.updatedAt.toLocal();
    final sameDay = now.year == updated.year &&
        now.month == updated.month &&
        now.day == updated.day;
    return sameDay ? state.sessionNumber : 1;
  }

  String _localDayToken(DateTime time) =>
      '${time.year.toString().padLeft(4, '0')}-'
      '${time.month.toString().padLeft(2, '0')}-'
      '${time.day.toString().padLeft(2, '0')}';

  String? _optionalText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
