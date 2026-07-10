import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/policy_service.dart';

void main() {
  test('initialization and permission states are delegated to adapter',
      () async {
    final adapter = FakeHydrionNotificationAdapter(
      permission: HydrionNotificationPermissionState.denied,
    );
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: ReminderRepository.memory(),
      adapter: adapter,
    );

    await service.initialize();
    final denied = await service.checkPermission();
    adapter.permission = HydrionNotificationPermissionState.granted;
    final granted = await service.requestPermission();

    expect(adapter.initialized, isTrue);
    expect(denied, HydrionNotificationPermissionState.denied);
    expect(granted, HydrionNotificationPermissionState.granted);
    expect(adapter.requestCount, 1);
  });

  test('create schedule records scheduled state and prevents duplicates',
      () async {
    final adapter = FakeHydrionNotificationAdapter();
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: adapter,
    );
    final trigger = DateTime(2026, 7, 5, 9);

    final first = await service.createReminder(
      triggerTime: trigger,
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );
    final duplicate = await service.createReminder(
      triggerTime: trigger.add(const Duration(seconds: 30)),
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(first.state, ReminderScheduleState.scheduled);
    expect(repository.reminders.single.scheduleState,
        ReminderScheduleState.scheduled);
    expect(
        adapter.scheduledIds, contains(first.reminder!.platformNotificationId));
    expect(duplicate.duplicatePrevented, isTrue);
    expect(repository.reminders, hasLength(1));
  });

  test('edit reschedules and delete cancels prior schedule', () async {
    final adapter = FakeHydrionNotificationAdapter();
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: adapter,
    );
    final created = await service.createReminder(
      triggerTime: DateTime(2026, 7, 5, 9),
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    final edited = await service.updateReminder(
      id: created.reminder!.id,
      triggerTime: DateTime(2026, 7, 5, 10),
      message: 'Refill bottle',
      priority: 2,
      requestPermissionIfNeeded: true,
    );
    final deleted = await service.deleteReminder(created.reminder!.id);

    expect(edited.state, ReminderScheduleState.scheduled);
    expect(edited.reminder?.message, 'Refill bottle');
    expect(edited.reminder?.priority, 2);
    expect(deleted, isTrue);
    expect(repository.reminders, isEmpty);
    expect(adapter.scheduledIds, isEmpty);
  });

  test('permission denied and permanently denied are persisted accurately',
      () async {
    final deniedAdapter = FakeHydrionNotificationAdapter(
      permission: HydrionNotificationPermissionState.denied,
    );
    final deniedRepository = ReminderRepository.memory();
    final deniedService = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: deniedRepository,
      adapter: deniedAdapter,
    );

    final denied = await deniedService.createReminder(
      triggerTime: DateTime(2026, 7, 5, 9),
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(denied.state, ReminderScheduleState.permissionDenied);
    expect(deniedRepository.reminders.single.scheduleError, 'denied');

    final permanentAdapter = FakeHydrionNotificationAdapter(
      permission: HydrionNotificationPermissionState.permanentlyDenied,
    );
    final permanentService = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: ReminderRepository.memory(),
      adapter: permanentAdapter,
    );
    final permanent = await permanentService.createReminder(
      triggerTime: DateTime(2026, 7, 5, 9),
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(permanent.state, ReminderScheduleState.permanentlyDenied);
  });

  test('scheduling failure and disabled reminder do not claim active schedule',
      () async {
    final failingRepository = ReminderRepository.memory();
    final failingService = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: failingRepository,
      adapter: FakeHydrionNotificationAdapter(failScheduling: true),
    );

    final failed = await failingService.createReminder(
      triggerTime: DateTime(2026, 7, 5, 9),
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(failed.state, ReminderScheduleState.failed);
    expect(failingRepository.reminders.single.scheduleError, 'StateError');

    final disabledRepository = ReminderRepository.memory();
    final disabledService = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: disabledRepository,
      adapter: FakeHydrionNotificationAdapter(),
    );

    final disabled = await disabledService.createReminder(
      triggerTime: DateTime(2026, 7, 5, 9),
      message: 'Drink water',
      priority: 1,
      enabled: false,
      requestPermissionIfNeeded: true,
    );

    expect(disabled.state, ReminderScheduleState.disabled);
    expect(disabledRepository.reminders.single.enabled, isFalse);
  });

  test(
      'restart reconciliation schedules enabled reminders and cancels disabled',
      () async {
    final adapter = FakeHydrionNotificationAdapter();
    final repository = ReminderRepository.memory();
    final enabled = await repository.save(
      triggerTime: DateTime(2026, 7, 5, 9),
      message: 'Drink water',
      priority: 1,
    );
    await repository.save(
      triggerTime: DateTime(2026, 7, 5, 10),
      message: 'Disabled',
      priority: 1,
      enabled: false,
    );
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: adapter,
    );

    await service.reconcileSchedules(requestPermissionIfNeeded: true);

    expect(adapter.scheduledIds, contains(enabled.platformNotificationId));
    expect(repository.reminders.first.scheduleState,
        ReminderScheduleState.scheduled);
    expect(repository.reminders.last.scheduleState,
        ReminderScheduleState.disabled);
  });

  test('reconciliation reschedules reminders after permission becomes granted',
      () async {
    final adapter = FakeHydrionNotificationAdapter(
      permission: HydrionNotificationPermissionState.denied,
    );
    final repository = ReminderRepository.memory();
    final reminder = await repository.save(
      triggerTime: DateTime(2026, 7, 5, 9),
      message: 'Drink water',
      priority: 1,
    );
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: adapter,
    );

    await service.reconcileSchedules(requestPermissionIfNeeded: true);

    expect(adapter.scheduledIds, isEmpty);
    expect(
      repository.reminders.single.scheduleState,
      ReminderScheduleState.permissionDenied,
    );

    adapter.permission = HydrionNotificationPermissionState.granted;
    await service.reconcileSchedules(requestPermissionIfNeeded: true);

    expect(adapter.scheduledIds, contains(reminder.platformNotificationId));
    expect(
      repository.reminders.single.scheduleState,
      ReminderScheduleState.scheduled,
    );
  });

  test('timezone and day rollover trigger times are retained', () async {
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: FakeHydrionNotificationAdapter(),
    );
    final trigger = DateTime(2026, 7, 5, 23, 55).add(
      const Duration(minutes: 20),
    );

    final result = await service.createReminder(
      triggerTime: trigger,
      message: 'Next day check-in',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(result.state, ReminderScheduleState.scheduled);
    expect(repository.reminders.single.triggerTime.day, 6);
  });

  test('app settings route is exposed through the adapter', () async {
    final adapter = FakeHydrionNotificationAdapter();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: ReminderRepository.memory(),
      adapter: adapter,
    );

    final opened = await service.openAppSettings();

    expect(opened, isTrue);
    expect(adapter.settingsOpenCount, 1);
  });
}
