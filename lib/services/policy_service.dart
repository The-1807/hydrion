class Result<T, E> {
  final T? _ok;
  final E? _err;

  const Result.ok(T value)
      : _ok = value,
        _err = null;

  const Result.err(E error)
      : _ok = null,
        _err = error;

  T? getOrElse(T? Function(E error) fallback) {
    final ok = _ok;
    if (ok != null) {
      return ok;
    }
    return fallback(_err as E);
  }
}

class Reminder {
  final int triggerTime;
  final String message;
  final int priority;

  const Reminder({
    required this.triggerTime,
    required this.message,
    required this.priority,
  });
}

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
}

class ReminderPolicy {
  bool shouldSendReminder(int remindersSentToday) {
    return remindersSentToday < 12;
  }

  Future<Result<Reminder, String>> scheduleReminder({
    required int shortfallMl,
    required double lastDrinkHoursAgo,
    required double hydrationPercent,
    required bool isActiveTime,
  }) async {
    final context = PolicyContext(
      shortfallMl: shortfallMl,
      lastDrinkHoursAgo: lastDrinkHoursAgo,
      hydrationPercent: hydrationPercent,
      isActiveTime: isActiveTime,
    );
    final urgency = _computeUrgency(context);
    final delayMinutes = _computeDelayMinutes(context, urgency);
    final trigger = DateTime.now()
        .add(Duration(minutes: delayMinutes))
        .millisecondsSinceEpoch;

    return Result.ok(
      Reminder(
        triggerTime: trigger,
        message: _composeMessage(context, urgency),
        priority: urgency,
      ),
    );
  }

  int _computeUrgency(PolicyContext context) {
    if (!context.isActiveTime) {
      return 1;
    }
    if (context.shortfallMl >= 600 || context.hydrationPercent < 40) {
      return 3;
    }
    if (context.shortfallMl >= 300 || context.lastDrinkHoursAgo >= 2.0) {
      return 2;
    }
    return 1;
  }

  int _computeDelayMinutes(PolicyContext context, int urgency) {
    final recentDrinkDelay = context.lastDrinkHoursAgo < 0.6 ? 15 : 0;
    return switch (urgency) {
      3 => 10 + recentDrinkDelay,
      2 => 25 + recentDrinkDelay,
      _ => 45 + recentDrinkDelay,
    };
  }

  String _composeMessage(PolicyContext context, int urgency) {
    final need = context.shortfallMl;
    if (urgency == 3) {
      return need > 0
          ? 'You are behind by ${need}ml. Take a solid sip now.'
          : 'Quick hydration check. Take a solid sip now.';
    }
    if (urgency == 2) {
      return need > 0
          ? 'About ${need}ml to go. A medium sip keeps you on pace.'
          : 'Stay steady. Grab a sip soon.';
    }
    return 'Small hydration nudge. A few sips will keep the habit moving.';
  }
}
