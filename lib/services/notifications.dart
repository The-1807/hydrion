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

  bool get scheduled => state == ReminderScheduleState.scheduled;
}

abstract class HydrionNotificationAdapter {
  bool get supportsScheduling;

  Future<void> initialize();

  Future<HydrionNotificationPermissionState> checkPermission();

  Future<HydrionNotificationPermissionState> requestPermission();

  Future<void> schedule(ScheduledReminder reminder);

  Future<void> cancel(ScheduledReminder reminder);

  Future<void> cancelAll();

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
  Future<void> schedule(ScheduledReminder reminder) async {
    if (!supportsScheduling || !reminder.enabled) {
      return;
    }
    await initialize();
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
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
  Future<void> cancelAll() async {
    if (!supportsScheduling) {
      return;
    }
    await initialize();
    await _plugin.cancelAll();
  }

  @override
  Future<bool> openAppSettings() {
    return geo.Geolocator.openAppSettings();
  }
}

class FakeHydrionNotificationAdapter implements HydrionNotificationAdapter {
  HydrionNotificationPermissionState permission;
  bool failScheduling;
  bool initialized = false;
  final Set<int> scheduledIds = <int>{};
  int requestCount = 0;
  int settingsOpenCount = 0;

  FakeHydrionNotificationAdapter({
    this.permission = HydrionNotificationPermissionState.granted,
    this.failScheduling = false,
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
  Future<void> schedule(ScheduledReminder reminder) async {
    if (failScheduling) {
      throw StateError('fake scheduling failure');
    }
    scheduledIds.add(reminder.platformNotificationId);
  }

  @override
  Future<void> cancel(ScheduledReminder reminder) async {
    scheduledIds.remove(reminder.platformNotificationId);
  }

  @override
  Future<void> cancelAll() async {
    scheduledIds.clear();
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

  NotificationService({
    required ReminderPolicy reminderPolicy,
    ReminderRepository? reminderRepository,
    HydrionNotificationAdapter? adapter,
  })  : _policy = reminderPolicy,
        _reminderRepository = reminderRepository ?? ReminderRepository.memory(),
        _adapter = adapter ?? FlutterLocalNotificationsHydrionAdapter();

  List<ScheduledReminder> get scheduledReminders =>
      _reminderRepository.reminders;

  bool get supportsOsNotifications => _adapter.supportsScheduling;

  Future<void> initialize() {
    return _adapter.initialize();
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
    return scheduleResult.reminder;
  }

  Future<NotificationScheduleResult> createReminder({
    required DateTime triggerTime,
    required String message,
    required int priority,
    bool enabled = true,
    bool requestPermissionIfNeeded = false,
  }) async {
    final duplicate = _findDuplicate(
      triggerTime: triggerTime,
      message: message,
    );
    if (duplicate != null) {
      return NotificationScheduleResult(
        reminder: duplicate,
        state: duplicate.scheduleState,
        duplicatePrevented: true,
      );
    }

    final reminder = await _reminderRepository.save(
      triggerTime: triggerTime,
      message: message,
      priority: priority,
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
        state: ReminderScheduleState.failed,
        message: 'Reminder not found.',
      );
    }
    await _adapter.cancel(current);
    final updated = await _reminderRepository.update(
      id: id,
      triggerTime: triggerTime,
      message: message,
      priority: priority,
      enabled: enabled,
      scheduleState: ReminderScheduleState.pending,
      clearScheduleError: true,
      clearLastScheduledAt: true,
    );
    if (updated == null) {
      return NotificationScheduleResult(
        reminder: current,
        state: ReminderScheduleState.failed,
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
      await _adapter.cancel(reminder);
    }
    return _reminderRepository.delete(id);
  }

  Future<void> reconcileSchedules({
    bool requestPermissionIfNeeded = false,
  }) async {
    final seen = <int>{};
    for (final reminder in _reminderRepository.reminders) {
      if (!reminder.enabled) {
        await _adapter.cancel(reminder);
        await _reminderRepository.setScheduleState(
          id: reminder.id,
          state: ReminderScheduleState.disabled,
        );
        continue;
      }
      if (!seen.add(reminder.platformNotificationId)) {
        await _adapter.cancel(reminder);
        await _reminderRepository.setScheduleState(
          id: reminder.id,
          state: ReminderScheduleState.failed,
          error: 'Duplicate platform notification id.',
        );
        continue;
      }
      await _schedulePersistedReminder(
        reminder,
        requestPermissionIfNeeded: requestPermissionIfNeeded,
      );
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
    if (!_adapter.supportsScheduling) {
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: ReminderScheduleState.unsupported,
        error: 'OS notification scheduling is unsupported on this platform.',
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: ReminderScheduleState.unsupported,
      );
    }

    var permission = await _adapter.checkPermission();
    if (permission != HydrionNotificationPermissionState.granted &&
        requestPermissionIfNeeded) {
      permission = await _adapter.requestPermission();
    }
    if (permission != HydrionNotificationPermissionState.granted) {
      final state =
          permission == HydrionNotificationPermissionState.permanentlyDenied
              ? ReminderScheduleState.permanentlyDenied
              : ReminderScheduleState.permissionDenied;
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: state,
        error: permission.name,
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: state,
      );
    }

    try {
      await _adapter.cancel(reminder);
      await _adapter.schedule(reminder);
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: ReminderScheduleState.scheduled,
        scheduledAt: DateTime.now(),
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: ReminderScheduleState.scheduled,
      );
    } catch (error) {
      final updated = await _reminderRepository.setScheduleState(
        id: reminder.id,
        state: ReminderScheduleState.failed,
        error: error.runtimeType.toString(),
      );
      return NotificationScheduleResult(
        reminder: updated ?? reminder,
        state: ReminderScheduleState.failed,
        message: error.toString(),
      );
    }
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
}
