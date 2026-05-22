import 'dart:async';

/// Minimal Either-style result with the `getOrElse` your caller expects.
class Result<T, E> {
  final T? _ok;
  final E? _err;
  const Result.ok(T value)
      : _ok = value,
        _err = null;
  const Result.err(E error)
      : _ok = null,
        _err = error;

  T? get ok => _ok;
  E? get err => _err;

  T? getOrElse(T? Function(E error) fallback) {
    if (_ok != null) return _ok;
    return fallback(_err as E);
  }
}

/// Reminder plan returned by the policy engine.
class Reminder {
  final int triggerTime; // epoch ms
  final String message;

  /// 1 = low, 2 = normal, 3 = high (maps to Android/iOS importance)
  final int priority;

  Reminder({
    required this.triggerTime,
    required this.message,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'triggerTime': triggerTime,
        'message': message,
        'priority': priority,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        triggerTime: j['triggerTime'] as int,
        message: j['message'] as String,
        priority: j['priority'] as int,
      );
}

/// Context payload expected by the policy.
class PolicyContext {
  final int shortfallMl;
  final double lastDrinkHoursAgo;
  final double hydrationPercent;
  final bool isActiveTime;

  const PolicyContext({
    required this.shortfallMl,
    required this.lastDrinkHoursAgo,
    required this.hydrationPercent,
    required this.isActiveTime,
  });

  Map<String, dynamic> toJson() => {
        'shortfallMl': shortfallMl,
        'lastDrinkHoursAgo': lastDrinkHoursAgo,
        'hydrationPercent': hydrationPercent,
        'isActiveTime': isActiveTime,
      };
}

/// Stable interface your app depends on (was policy.dart).
/// Internals can call Rust via flutter_rust_bridge later without touching callers.
class ReminderPolicy {
  ReminderPolicy();

  /// Lightweight gate to avoid over-notifying.
  bool shouldSendReminder(int remindersSentToday) {
    // Default guard: cap at 12/day (customize when Rust policy is wired).
    return remindersSentToday < 12;
    // When FRB is wired, delegate to native:
    // return _backend.shouldSendReminder(remindersSentToday);
  }

  /// Returns next reminder plan (time/message/priority).
  Future<Result<Reminder, String>> scheduleReminder({
    required int shortfallMl,
    required double lastDrinkHoursAgo,
    required double hydrationPercent,
    required bool isActiveTime,
  }) async {
    final ctx = PolicyContext(
      shortfallMl: shortfallMl,
      lastDrinkHoursAgo: lastDrinkHoursAgo,
      hydrationPercent: hydrationPercent,
      isActiveTime: isActiveTime,
    );

    try {
      // Replace this block with FRB backend once core_bridge.dart is generated.
      // --- Begin pure-Dart fallback (keeps app functional now) ---
      final now = DateTime.now();
      final urgency = _computeUrgency(ctx);
      final delayMinutes = _computeDelayMinutes(ctx, urgency);
      final trigger =
          now.add(Duration(minutes: delayMinutes)).millisecondsSinceEpoch;

      final msg = _composeMessage(ctx, urgency);
      final reminder = Reminder(
        triggerTime: trigger,
        message: msg,
        priority: urgency,
      );
      return Result.ok(reminder);
      // --- End fallback ---

      // FRB sample (uncomment when available):
      // final plan = await api.reminderPolicyGetNext(ctx.toJson());
      // return Result.ok(Reminder.fromJson(plan));
    } catch (e) {
      return Result.err('policy_error: $e');
    }
  }

  // ------- Fallback policy logic (deterministic, cheap) -------
  int _computeUrgency(PolicyContext c) {
    // Urgency tiers: 1 low, 2 normal, 3 high
    if (!c.isActiveTime) return 1;
    if (c.shortfallMl >= 600) return 3;
    if (c.shortfallMl >= 300) return 2;
    if (c.hydrationPercent < 40) return 3;
    if (c.lastDrinkHoursAgo >= 2.0) return 2;
    return 1;
  }

  int _computeDelayMinutes(PolicyContext c, int urgency) {
    // Shorter delays for higher urgency; respect recent intake.
    final recentPenalty = c.lastDrinkHoursAgo < 0.6 ? 15 : 0;
    switch (urgency) {
      case 3:
        return (10 + recentPenalty);
      case 2:
        return (25 + recentPenalty);
      default:
        return (45 + recentPenalty);
    }
  }

  String _composeMessage(PolicyContext c, int urgency) {
    final need = c.shortfallMl;
    if (urgency == 3) {
      return need > 0
          ? "You’re behind by ${need}ml. Take a solid sip now."
          : "Quick hydration check—top up with a big sip.";
    }
    if (urgency == 2) {
      return need > 0
          ? "About ${need}ml to go. A medium sip keeps you on pace."
          : "Stay steady—grab a sip soon.";
    }
    return "Hydration nudge—small sip to stay sharp.";
  }
}
