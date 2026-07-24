enum PomodoroSessionLifecycle {
  notStarted,
  running,
  paused,
  completed,
  stopped,
  cancelled,
}

class PomodoroTimerSnapshot {
  final PomodoroSessionLifecycle lifecycle;
  final Duration totalDuration;
  final Duration remainingDuration;
  final Duration elapsedDuration;
  final double progress;
  final DateTime? startedAt;
  final DateTime? completionAt;
  final String? sessionId;
  final bool completionCommitted;

  const PomodoroTimerSnapshot({
    required this.lifecycle,
    required this.totalDuration,
    required this.remainingDuration,
    required this.elapsedDuration,
    required this.progress,
    required this.startedAt,
    required this.completionAt,
    required this.sessionId,
    required this.completionCommitted,
  });

  bool get isRunning => lifecycle == PomodoroSessionLifecycle.running;
  bool get isPaused => lifecycle == PomodoroSessionLifecycle.paused;
  bool get isCompleted => lifecycle == PomodoroSessionLifecycle.completed;
}

class PomodoroSessionHistoryEntry {
  final String sessionId;
  final int sessionNumber;
  final DateTime completedAt;
  final bool hasAuthenticTime;
  final bool endedEarly;

  const PomodoroSessionHistoryEntry({
    required this.sessionId,
    required this.sessionNumber,
    required this.completedAt,
    required this.hasAuthenticTime,
    required this.endedEarly,
  });

  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'sessionNumber': sessionNumber,
        'completedAt': completedAt.toIso8601String(),
        'hasAuthenticTime': hasAuthenticTime,
        'endedEarly': endedEarly,
      };

  static PomodoroSessionHistoryEntry? fromJson(Object? value) {
    if (value is! Map) return null;
    final sessionId = value['sessionId']?.toString().trim() ?? '';
    final sessionNumber = value['sessionNumber'];
    final rawCompletedAt = value['completedAt']?.toString().trim() ?? '';
    final completedAt = DateTime.tryParse(rawCompletedAt);
    if (sessionId.isEmpty ||
        sessionNumber is! num ||
        sessionNumber <= 0 ||
        completedAt == null) {
      return null;
    }
    final isDateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawCompletedAt);
    return PomodoroSessionHistoryEntry(
      sessionId: sessionId,
      sessionNumber: sessionNumber.round(),
      completedAt: completedAt,
      hasAuthenticTime: value['hasAuthenticTime'] is bool
          ? value['hasAuthenticTime'] as bool
          : !isDateOnly,
      endedEarly: value['endedEarly'] == true,
    );
  }
}

class PomodoroSessionState {
  static const schemaVersion = 1;

  final String challengeInstanceId;
  final String? sessionId;
  final int sessionNumber;
  final Duration totalDuration;
  final DateTime? startedAt;
  final DateTime? completionAt;
  final Duration pausedRemaining;
  final PomodoroSessionLifecycle lifecycle;
  final bool completionCommitted;
  final String? reminderId;
  final String? reminderSchedulingMode;
  final String? completionActionId;
  final DateTime updatedAt;
  final List<PomodoroSessionHistoryEntry> history;

  const PomodoroSessionState({
    required this.challengeInstanceId,
    required this.sessionId,
    required this.sessionNumber,
    required this.totalDuration,
    required this.startedAt,
    required this.completionAt,
    required this.pausedRemaining,
    required this.lifecycle,
    required this.completionCommitted,
    required this.reminderId,
    required this.reminderSchedulingMode,
    required this.completionActionId,
    required this.updatedAt,
    required this.history,
  });

  factory PomodoroSessionState.initial({
    required String challengeInstanceId,
    required Duration totalDuration,
    required DateTime now,
    int sessionNumber = 1,
    List<PomodoroSessionHistoryEntry> history = const [],
  }) {
    return PomodoroSessionState(
      challengeInstanceId: challengeInstanceId,
      sessionId: null,
      sessionNumber: sessionNumber,
      totalDuration: totalDuration,
      startedAt: null,
      completionAt: null,
      pausedRemaining: totalDuration,
      lifecycle: PomodoroSessionLifecycle.notStarted,
      completionCommitted: false,
      reminderId: null,
      reminderSchedulingMode: null,
      completionActionId: null,
      updatedAt: now,
      history: List.unmodifiable(history),
    );
  }

  PomodoroTimerSnapshot snapshot(DateTime now) {
    final totalSeconds = totalDuration.inSeconds.clamp(1, 86400);
    final remaining = switch (lifecycle) {
      PomodoroSessionLifecycle.running =>
        completionAt == null ? Duration.zero : completionAt!.difference(now),
      PomodoroSessionLifecycle.paused => pausedRemaining,
      PomodoroSessionLifecycle.completed => Duration.zero,
      _ => totalDuration,
    };
    final remainingSeconds = remaining.inSeconds.clamp(0, totalSeconds);
    final elapsedSeconds = totalSeconds - remainingSeconds;
    return PomodoroTimerSnapshot(
      lifecycle: lifecycle,
      totalDuration: Duration(seconds: totalSeconds),
      remainingDuration: Duration(seconds: remainingSeconds),
      elapsedDuration: Duration(seconds: elapsedSeconds),
      progress: (elapsedSeconds / totalSeconds).clamp(0.0, 1.0),
      startedAt: startedAt,
      completionAt: completionAt,
      sessionId: sessionId,
      completionCommitted: completionCommitted,
    );
  }

  PomodoroSessionState copyWith({
    String? sessionId,
    int? sessionNumber,
    Duration? totalDuration,
    DateTime? startedAt,
    DateTime? completionAt,
    Duration? pausedRemaining,
    PomodoroSessionLifecycle? lifecycle,
    bool? completionCommitted,
    String? reminderId,
    String? reminderSchedulingMode,
    String? completionActionId,
    DateTime? updatedAt,
    List<PomodoroSessionHistoryEntry>? history,
    bool clearSessionId = false,
    bool clearStartedAt = false,
    bool clearCompletionAt = false,
    bool clearReminderId = false,
    bool clearReminderSchedulingMode = false,
    bool clearCompletionActionId = false,
  }) {
    return PomodoroSessionState(
      challengeInstanceId: challengeInstanceId,
      sessionId: clearSessionId ? null : sessionId ?? this.sessionId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      totalDuration: totalDuration ?? this.totalDuration,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
      completionAt:
          clearCompletionAt ? null : completionAt ?? this.completionAt,
      pausedRemaining: pausedRemaining ?? this.pausedRemaining,
      lifecycle: lifecycle ?? this.lifecycle,
      completionCommitted: completionCommitted ?? this.completionCommitted,
      reminderId: clearReminderId ? null : reminderId ?? this.reminderId,
      reminderSchedulingMode: clearReminderSchedulingMode
          ? null
          : reminderSchedulingMode ?? this.reminderSchedulingMode,
      completionActionId: clearCompletionActionId
          ? null
          : completionActionId ?? this.completionActionId,
      updatedAt: updatedAt ?? this.updatedAt,
      history: List.unmodifiable(history ?? this.history),
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'challengeInstanceId': challengeInstanceId,
        if (sessionId != null) 'sessionId': sessionId,
        'sessionNumber': sessionNumber,
        'totalSeconds': totalDuration.inSeconds,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (completionAt != null)
          'completionAt': completionAt!.toIso8601String(),
        'pausedRemainingSeconds': pausedRemaining.inSeconds,
        'lifecycle': lifecycle.name,
        'completionCommitted': completionCommitted,
        if (reminderId != null) 'reminderId': reminderId,
        if (reminderSchedulingMode != null)
          'reminderSchedulingMode': reminderSchedulingMode,
        if (completionActionId != null)
          'completionActionId': completionActionId,
        'updatedAt': updatedAt.toIso8601String(),
        'history': history.map((entry) => entry.toJson()).toList(),
      };

  static PomodoroSessionState? fromJson(Object? value) {
    if (value is! Map) return null;
    final challengeInstanceId =
        value['challengeInstanceId']?.toString().trim() ?? '';
    final totalSeconds = value['totalSeconds'];
    final sessionNumber = value['sessionNumber'];
    final updatedAt = DateTime.tryParse(value['updatedAt']?.toString() ?? '');
    if (challengeInstanceId.isEmpty ||
        totalSeconds is! num ||
        totalSeconds <= 0 ||
        sessionNumber is! num ||
        sessionNumber <= 0 ||
        updatedAt == null) {
      return null;
    }
    final lifecycleName = value['lifecycle']?.toString();
    final lifecycle = PomodoroSessionLifecycle.values.firstWhere(
      (candidate) => candidate.name == lifecycleName,
      orElse: () => PomodoroSessionLifecycle.stopped,
    );
    final history = value['history'] is List
        ? (value['history'] as List)
            .map(PomodoroSessionHistoryEntry.fromJson)
            .whereType<PomodoroSessionHistoryEntry>()
            .toList(growable: false)
        : const <PomodoroSessionHistoryEntry>[];
    return PomodoroSessionState(
      challengeInstanceId: challengeInstanceId,
      sessionId: _optionalText(value['sessionId']),
      sessionNumber: sessionNumber.round(),
      totalDuration: Duration(seconds: totalSeconds.round().clamp(1, 86400)),
      startedAt: DateTime.tryParse(value['startedAt']?.toString() ?? ''),
      completionAt: DateTime.tryParse(value['completionAt']?.toString() ?? ''),
      pausedRemaining: Duration(
        seconds: ((value['pausedRemainingSeconds'] as num?) ?? totalSeconds)
            .round()
            .clamp(0, 86400),
      ),
      lifecycle: lifecycle,
      completionCommitted: value['completionCommitted'] == true,
      reminderId: _optionalText(value['reminderId']),
      reminderSchedulingMode: _optionalText(value['reminderSchedulingMode']),
      completionActionId: _optionalText(value['completionActionId']),
      updatedAt: updatedAt,
      history: List.unmodifiable(history),
    );
  }

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
