import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../repositories/reminder_repository.dart';
import 'policy_service.dart';

enum HydrionNotificationPermissionState {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
  unknown,
}

enum ReminderSchedulePrecision {
  exact,
  approximate,
}

class NotificationScheduleResult {
  final ScheduledReminder? reminder;
  final ReminderScheduleState state;
  final String? message;
  final bool duplicatePrevented;

  const NotificationScheduleResult({
    required this.reminder,
    required this.state,
    this.message,
    this.duplicatePrevented = false,
  });

  bool get scheduled =>
      state == ReminderScheduleState.scheduledExactly ||
      state == ReminderScheduleState.scheduledApproximately;

  bool get isExact => state == ReminderScheduleState.scheduledExactly;
}

abstract class HydrionNotificationAdapter {
  bool get supportsScheduling;

  Future<void> initialize();

  Future<HydrionNotificationPermissionState> checkPermission();

  Future<HydrionNotificationPermissionState> requestPermission();

  Future<bool> canSchedulePrecisely();

  Future<bool> requestPreciseSchedulingPermission();

  Future<void> schedule(
    ScheduledReminder reminder, {
    required ReminderSchedulePrecision precision,
  });

  Future<void> cancel(ScheduledReminder reminder);

  Future<void> cancelByPlatformId(int id);

  Future<void> cancelAll();

  Future<Set<int>?> pendingNotificationIds();

  Future<bool> openAppSettings();
}

class FlutterLocalNotificationsHydrionAdapter
    implements HydrionNotificationAdapter {
  static const _channelId = 'hydrion_hydration_reminders';
  static const _channelName = 'Hydration reminders';
  static const _channelDescription =
      'Local reminders for user-created Hydrion hydration check-ins.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  FlutterLocalNotificationsHydrionAdapter({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  bool get supportsScheduling {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Future<void> initialize() async {
    if (_initialized || !supportsScheduling) {
      return;
    }
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    _initialized = true;
  }

  @override
  Future<HydrionNotificationPermissionState> checkPermission() async {
    if (!supportsScheduling) {
      return HydrionNotificationPermissionState.unsupported;
    }
    await initialize();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled == true
          ? HydrionNotificationPermissionState.granted
          : HydrionNotificationPermissionState.denied;
    } on PlatformException {
      return HydrionNotificationPermissionState.unknown;
    }
  }

  @override
  Future<HydrionNotificationPermissionState> requestPermission() async {
    if (!supportsScheduling) {
      return HydrionNotificationPermissionState.unsupported;
    }
    await initialize();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted == true
          ? HydrionNotificationPermissionState.granted
          : HydrionNotificationPermissionState.denied;
    } on PlatformException {
      return HydrionNotificationPermissionState.unknown;
    }
  }

  @override
  Future<bool> canSchedulePrecisely() async {
    if (!supportsScheduling) {
      return false;
    }
    await initialize();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.canScheduleExactNotifications() == true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> requestPreciseSchedulingPermission() async {
    if (!supportsScheduling) {
      return false;
    }
    await initialize();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestExactAlarmsPermission();
      if (granted == true) {
        return true;
      }
      return await android?.canScheduleExactNotifications() == true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> schedule(
    ScheduledReminder reminder, {
    required ReminderSchedulePrecision precision,
  }) async {
    if (!supportsScheduling || !reminder.enabled) {
      return;
    }
    await initialize();
    if (!reminder.triggerTime.isAfter(DateTime.now())) {
      throw ArgumentError.value(
        reminder.triggerTime,
        'triggerTime',
        'Reminder time must be in the future.',
      );
    }
    final scheduledAt = tz.TZDateTime.from(reminder.triggerTime, tz.local);
    await _plugin.zonedSchedule(
      id: reminder.platformNotificationId,
      title: 'Hydrion reminder',
      body: reminder.message,
      scheduledDate: scheduledAt,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: precision == ReminderSchedulePrecision.exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(ScheduledReminder reminder) async {
    if (!supportsScheduling) {
      return;
    }
    await initialize();
    await _plugin.cancel(id: reminder.platformNotificationId);
  }

  @override
  Future<void> cancelByPlatformId(int id) async {
    if (!supportsScheduling) {
      return;
    }
    await initialize();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    if (!supportsScheduling) {
      return;
    }
    await initialize();
    await _plugin.cancelAll();
  }

  @override
  Future<Set<int>?> pendingNotificationIds() async {
    if (!supportsScheduling) {
      return null;
    }
    await initialize();
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((notification) => notification.id).toSet();
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<bool> openAppSettings() {
    return geo.Geolocator.openAppSettings();
  }
}

class FakeHydrionNotificationAdapter implements HydrionNotificationAdapter {
  HydrionNotificationPermissionState permission;
  bool failScheduling;
  bool failExactScheduling;
  bool failApproximateScheduling;
  bool failCancellation;
  bool failCancelAll;
  bool preciseScheduling;
  bool grantPreciseSchedulingOnRequest;
  bool initialized = false;
  final Set<int> scheduledIds = <int>{};
  int requestCount = 0;
  int precisePermissionRequestCount = 0;
  int settingsOpenCount = 0;

  FakeHydrionNotificationAdapter({
    this.permission = HydrionNotificationPermissionState.granted,
    this.failScheduling = false,
    this.failExactScheduling = false,
    this.failApproximateScheduling = false,
    this.failCancellation = false,
    this.failCancelAll = false,
    this.preciseScheduling = true,
    this.grantPreciseSchedulingOnRequest = false,
  });

  @override
  bool get supportsScheduling => true;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<HydrionNotificationPermissionState> checkPermission() async {
    return permission;
  }

  @override
  Future<HydrionNotificationPermissionState> requestPermission() async {
    requestCount += 1;
    return permission;
  }

  @override
  Future<bool> canSchedulePrecisely() async {
    return preciseScheduling;
  }

  @override
  Future<bool> requestPreciseSchedulingPermission() async {
    precisePermissionRequestCount += 1;
    if (grantPreciseSchedulingOnRequest) {
      preciseScheduling = true;
    }
    return preciseScheduling;
  }

  @override
  Future<void> schedule(
    ScheduledReminder reminder, {
    required ReminderSchedulePrecision precision,
  }) async {
    if (!reminder.triggerTime.isAfter(DateTime.now())) {
      throw ArgumentError.value(reminder.triggerTime, 'triggerTime');
    }
    if (failScheduling ||
        (precision == ReminderSchedulePrecision.exact && failExactScheduling) ||
        (precision == ReminderSchedulePrecision.approximate &&
            failApproximateScheduling)) {
      throw StateError('fake scheduling failure');
    }
    scheduledIds.add(reminder.platformNotificationId);
  }

  @override
  Future<void> cancel(ScheduledReminder reminder) async {
    if (failCancellation) {
      throw StateError('fake cancellation failure');
    }
    scheduledIds.remove(reminder.platformNotificationId);
  }

  @override
  Future<void> cancelByPlatformId(int id) async {
    if (failCancellation) {
      throw StateError('fake cancellation failure');
    }
    scheduledIds.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    if (failCancelAll) {
      throw StateError('fake cancellation failure');
    }
    scheduledIds.clear();
  }

  @override
  Future<Set<int>?> pendingNotificationIds() async {
    return Set<int>.of(scheduledIds);
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpenCount += 1;
    return true;
  }
}

class NotificationService {
  final ReminderPolicy _policy;
  final ReminderRepository _reminderRepository;
  final HydrionNotificationAdapter _adapter;
  final DateTime Function() _now;

  NotificationService({
    required ReminderPolicy reminderPolicy,
    ReminderRepository? reminderRepository,
    HydrionNotificationAdapter? adapter,
    DateTime Function()? now,
  })  : _policy = reminderPolicy,
        _reminderRepository = reminderRepository ?? ReminderRepository.memory(),
        _adapter = adapter ?? FlutterLocalNotificationsHydrionAdapter(),
        _now = now ?? DateTime.now;

  List<ScheduledReminder> get scheduledReminders =>
      _reminderRepository.reminders;

  bool get supportsOsNotifications => _adapter.supportsScheduling;

  Future<void> initialize() async {
    await _adapter.initialize();
    await retryOrphanCleanup();
  }

  Future<HydrionNotificationPermissionState> checkPermission() {
    return _adapter.checkPermission();
  }

  Future<HydrionNotificationPermissionState> requestPermission() {
    return _adapter.requestPermission();
  }

  Future<bool> openAppSettings() {
    return _adapter.openAppSettings();
  }

  Future<ScheduledReminder?> scheduleReminder({
    required int shortfallMl,
    required double lastDrinkHoursAgo,
    required double hydrationPercent,
    required bool isActiveTime,
    int remindersSentToday = 0,
  }) async {
    if (!_policy.shouldSendReminder(remindersSentToday)) {
      return null;
    }

    final result = await _policy.scheduleReminder(
      shortfallMl: shortfallMl,
      lastDrinkHoursAgo: lastDrinkHoursAgo,
      hydrationPercent: hydrationPercent,
      isActiveTime: isActiveTime,
    );
    final reminder = result.getOrElse((_) => null);

    if (reminder == null) {
      return null;
    }

    final scheduleResult = await createReminder(
      triggerTime: DateTime.fromMillisecondsSinceEpoch(reminder.triggerTime),
      message: reminder.message,
      priority: reminder.priority,
      requestPermissionIfNeeded: true,
    );
    return scheduleResult.scheduled ? scheduleResult.reminder : null;
  }

  Future<NotificationScheduleResult> createReminder({
    required DateTime triggerTime,
    required String message,
    required int priority,
    bool enabled = true,
    bool requestPermissionIfNeeded = false,
  }) async {
    final safeTriggerTime = _nextFutureTriggerTime(triggerTime);
    final safeMessage = ScheduledReminder.safeMessage(message);
    final safePriority = ScheduledReminder.safePriority(priority);
    if (safeTriggerTime == null ||
        safeMessage == null ||
        safePriority == null) {
      return const NotificationScheduleResult(
        reminder: null,
        state: ReminderScheduleState.schedulingFailed,
        message: 'Check the reminder time and message.',
      );
    }
    final duplicate = _findDuplicate(
      triggerTime: safeTriggerTime,
      message: safeMessage,
    );
    if (duplicate != null) {
      return NotificationScheduleResult(
        reminder: duplicate,
        state: duplicate.scheduleState,
        duplicatePrevented: true,
      );
    }

    final reminder = await _reminderRepository.save(
      triggerTime: safeTriggerTime,
      message: safeMessage,
      priority: safePriority,
      enabled: enabled,
    );
    return _schedulePersistedReminder(
      reminder,
      requestPermissionIfNeeded: requestPermissionIfNeeded,
    );
  }

  Future<NotificationScheduleResult> updateReminder({
    required String id,
    DateTime? triggerTime,
    String? message,
    int? priority,
    bool? enabled,
    bool requestPermissionIfNeeded = false,
  }) async {
    final current = _reminderRepository.byId(id);
    if (current == null) {
      return const NotificationScheduleResult(
        reminder: null,
        state: ReminderScheduleState.schedulingFailed,
        message: 'Reminder not found.',
      );
    }
    final safeTriggerTime =
        triggerTime == null ? null : _nextFutureTriggerTime(triggerTime);
    final safeMessage =
        message == null ? null : ScheduledReminder.safeMessage(message);
    final safePriority =
        priority == null ? null : ScheduledReminder.safePriority(priority);
    if ((triggerTime != null && safeTriggerTime == null) ||
        (message != null && safeMessage == null) ||
        (priority != null && safePriority == null)) {
      return NotificationScheduleResult(
        reminder: current,
        state: ReminderScheduleState.schedulingFailed,
        message: 'Check the reminder time and message.',
      );
    }
    await _adapter.cancel(current);
    final updated = await _reminderRepository.update(
      id: id,
      triggerTime: safeTriggerTime,
      message: safeMessage,
      priority: safePriority,
      enabled: enabled,
      scheduleState: ReminderScheduleState.pending,
      clearScheduleError: true,
      clearLastScheduledAt: true,
    );
    if (updated == null) {
      return NotificationScheduleResult(
        reminder: current,
        state: ReminderScheduleState.schedulingFailed,
        message: 'Reminder update was invalid.',
      );
    }
    return _schedulePersistedReminder(
      updated,
      requestPermissionIfNeeded: requestPermissionIfNeeded,
    );
  }

  Future<bool> deleteReminder(String id) async {
    final reminder = _reminderRepository.byId(id);
    if (reminder != null) {
      try {
        await _adapter.cancel(reminder);
      } catch (_) {
        await _reminderRepository.recordOrphanNotificationIds(
          <int>[reminder.platformNotificationId],
        );
      }
    }
    return _reminderRepository.delete(id);
  }

  Future<bool> cancelAllReminders() async {
    final ids = _reminderRepository.reminders
        .map((reminder) => reminder.platformNotificationId)
        .toSet();
    try {
      await _adapter.cancelAll();
      return true;
    } catch (_) {
      await _reminderRepository.recordOrphanNotificationIds(ids);
      return false;
    }
  }

  Future<void> reconcileSchedules({
    bool requestPermissionIfNeeded = false,
  }) async {
    await retryOrphanCleanup();
    final pendingIds = await _adapter.pendingNotificationIds();
    final seen = <int>{};
    for (final reminder in _reminderRepository.reminders) {
      if (!reminder.enabled) {
        try {
          await _adapter.cancel(reminder);
        } catch (_) {
          await _reminderRepository.recordOrphanNotificationIds(
            <int>[reminder.platformNotificationId],
          );
        }
        await _reminderRepository.setScheduleState(
          id: reminder.id,
          state: ReminderScheduleState.disabled,
        );
        continue;
      }
      if (!seen.add(reminder.platformNotificationId)) {
        try {
          await _adapter.cancel(reminder);
        } catch (_) {
          await _reminderRepository.recordOrphanNotificationIds(
            <int>[reminder.platformNotificationId],
          );
        }
        await _reminderRepository.setScheduleState(
          id: reminder.id,
          state: ReminderScheduleState.schedulingFailed,
          error: 'duplicate_notification',
        );
        continue;
      }
      final alreadyRegistered =
          pendingIds?.contains(reminder.platformNotificationId) == true;
      final activeState =
          reminder.scheduleState == ReminderScheduleState.scheduledExactly ||
              reminder.scheduleState ==
                  ReminderScheduleState.scheduledApproximately;
      if (alreadyRegistered && activeState) {
        continue;
      }
      await _schedulePersistedReminder(
        reminder,
        requestPermissionIfNeeded: requestPermissionIfNeeded,
      );
    }
  }

  Future<void> retryOrphanCleanup() async {
    for (final id
        in _reminderRepository.orphanNotificationIds.toList(growable: false)) {
      try {
        await _adapter.cancelByPlatformId(id);
        await _reminderRepository.resolveOrphanNotificationId(id);
      } catch (_) {
        // Retain the ID for a later safe retry.
      }
    }
  }

  Future<NotificationScheduleResult> _schedulePersistedReminder(
    ScheduledReminder reminder, {
    required bool requestPermissionIfNeeded,
  }) async {
    if (!reminder.enabled) {
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: ReminderScheduleState.disabled,
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: ReminderScheduleState.disabled,
      );
    }
    if (!reminder.triggerTime.toLocal().isAfter(_now().toLocal())) {
      try {
        await _adapter.cancel(reminder);
      } catch (_) {
        await _reminderRepository.recordOrphanNotificationIds(
          <int>[reminder.platformNotificationId],
        );
      }
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: ReminderScheduleState.needsRescheduling,
        error: 'time_passed',
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: ReminderScheduleState.needsRescheduling,
        message:
            'That reminder time has passed. Choose a new time to schedule it.',
      );
    }
    if (!_adapter.supportsScheduling) {
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: ReminderScheduleState.unsupported,
        error: 'scheduling_unavailable',
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: ReminderScheduleState.unsupported,
        message: 'Reminders are not available on this device.',
      );
    }

    var permission = await _adapter.checkPermission();
    if (permission != HydrionNotificationPermissionState.granted &&
        requestPermissionIfNeeded) {
      permission = await _adapter.requestPermission();
    }
    if (permission != HydrionNotificationPermissionState.granted) {
      final state = switch (permission) {
        HydrionNotificationPermissionState.permanentlyDenied ||
        HydrionNotificationPermissionState.denied =>
          ReminderScheduleState.permissionRequired,
        _ => ReminderScheduleState.schedulingFailed,
      };
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: state,
        error: state == ReminderScheduleState.schedulingFailed
            ? 'permission_check_failed'
            : 'notification_permission_required',
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: state,
        message: state == ReminderScheduleState.schedulingFailed
            ? 'Hydrion could not check notification access. Try again.'
            : 'Allow notifications to receive this reminder.',
      );
    }

    var canSchedulePrecisely = await _adapter.canSchedulePrecisely();
    if (!canSchedulePrecisely && requestPermissionIfNeeded) {
      canSchedulePrecisely =
          await _adapter.requestPreciseSchedulingPermission();
    }
    if (!reminder.triggerTime.toLocal().isAfter(_now().toLocal())) {
      return _markNeedsRescheduling(reminder);
    }

    try {
      await _adapter.cancel(reminder);
    } catch (_) {
      await _reminderRepository.recordOrphanNotificationIds(
        <int>[reminder.platformNotificationId],
      );
    }

    if (canSchedulePrecisely) {
      try {
        await _adapter.schedule(
          reminder,
          precision: ReminderSchedulePrecision.exact,
        );
        return await _persistSuccessfulSchedule(
          reminder,
          ReminderScheduleState.scheduledExactly,
        );
      } on ArgumentError {
        return _markNeedsRescheduling(reminder);
      } catch (_) {
        try {
          await _adapter.cancel(reminder);
        } catch (_) {
          await _reminderRepository.recordOrphanNotificationIds(
            <int>[reminder.platformNotificationId],
          );
        }
      }
    }

    try {
      if (!reminder.triggerTime.toLocal().isAfter(_now().toLocal())) {
        return _markNeedsRescheduling(reminder);
      }
      await _adapter.schedule(
        reminder,
        precision: ReminderSchedulePrecision.approximate,
      );
      return await _persistSuccessfulSchedule(
        reminder,
        ReminderScheduleState.scheduledApproximately,
      );
    } on ArgumentError {
      return _markNeedsRescheduling(reminder);
    } on PlatformException {
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: ReminderScheduleState.schedulingFailed,
        error: 'android_schedule_failed',
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: ReminderScheduleState.schedulingFailed,
        message:
            'Android did not accept this reminder. Edit the time or try again.',
      );
    } catch (_) {
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: ReminderScheduleState.schedulingFailed,
        error: 'schedule_failed',
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: ReminderScheduleState.schedulingFailed,
        message:
            'Android did not accept this reminder. Edit the time or try again.',
      );
    }
  }

  Future<NotificationScheduleResult> _persistSuccessfulSchedule(
    ScheduledReminder reminder,
    ReminderScheduleState state,
  ) async {
    try {
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: state,
        scheduledAt: _now(),
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: state,
        message: state == ReminderScheduleState.scheduledApproximately
            ? 'Reminder active. Android may deliver it slightly after the selected time.'
            : 'Reminder active. The reminder is scheduled for the selected time.',
      );
    } catch (_) {
      try {
        await _adapter.cancel(reminder);
      } catch (_) {
        await _reminderRepository.recordOrphanNotificationIds(
          <int>[reminder.platformNotificationId],
        );
      }
      rethrow;
    }
  }

  Future<NotificationScheduleResult> _markNeedsRescheduling(
    ScheduledReminder reminder,
  ) async {
    final updated = await _reminderRepository.setScheduleState(
      id: reminder.id,
      state: ReminderScheduleState.needsRescheduling,
      error: 'time_passed',
    );
    return NotificationScheduleResult(
      reminder: updated ?? reminder,
      state: ReminderScheduleState.needsRescheduling,
      message: 'The time has passed. Choose a new time.',
    );
  }

  ScheduledReminder? _findDuplicate({
    required DateTime triggerTime,
    required String message,
  }) {
    final normalizedMessage = message.trim();
    for (final reminder in _reminderRepository.reminders) {
      final sameMessage = reminder.message.trim() == normalizedMessage;
      final sameMinute =
          reminder.triggerTime.difference(triggerTime).inSeconds.abs() < 60;
      if (sameMessage && sameMinute) {
        return reminder;
      }
    }
    return null;
  }

  DateTime? _nextFutureTriggerTime(DateTime triggerTime) {
    if (triggerTime.year < 2000 || triggerTime.year > 2100) {
      return null;
    }
    final next = triggerTime.toLocal();
    return next.isAfter(_now().toLocal()) ? next : null;
  }
}
