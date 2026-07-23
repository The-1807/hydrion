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
    final trigger = DateTime.now().add(const Duration(hours: 1));

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

    expect(first.state, ReminderScheduleState.scheduledExactly);
    expect(repository.reminders.single.scheduleState,
        ReminderScheduleState.scheduledExactly);
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
      triggerTime: DateTime.now().add(const Duration(hours: 1)),
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    final edited = await service.updateReminder(
      id: created.reminder!.id,
      triggerTime: DateTime.now().add(const Duration(hours: 2)),
      message: 'Refill bottle',
      priority: 2,
      requestPermissionIfNeeded: true,
    );
    final deleted = await service.deleteReminder(created.reminder!.id);

    expect(edited.state, ReminderScheduleState.scheduledExactly);
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
      triggerTime: DateTime.now().add(const Duration(hours: 1)),
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(denied.state, ReminderScheduleState.permissionRequired);
    expect(
      deniedRepository.reminders.single.scheduleError,
      'notification_permission_required',
    );

    final permanentAdapter = FakeHydrionNotificationAdapter(
      permission: HydrionNotificationPermissionState.permanentlyDenied,
    );
    final permanentService = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: ReminderRepository.memory(),
      adapter: permanentAdapter,
    );
    final permanent = await permanentService.createReminder(
      triggerTime: DateTime.now().add(const Duration(hours: 1)),
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(permanent.state, ReminderScheduleState.permissionRequired);
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
      triggerTime: DateTime.now().add(const Duration(hours: 1)),
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(failed.state, ReminderScheduleState.schedulingFailed);
    expect(failingRepository.reminders.single.scheduleError, 'schedule_failed');

    final disabledRepository = ReminderRepository.memory();
    final disabledService = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: disabledRepository,
      adapter: FakeHydrionNotificationAdapter(),
    );

    final disabled = await disabledService.createReminder(
      triggerTime: DateTime.now().add(const Duration(hours: 1)),
      message: 'Drink water',
      priority: 1,
      enabled: false,
      requestPermissionIfNeeded: true,
    );

    expect(disabled.state, ReminderScheduleState.disabled);
    expect(disabledRepository.reminders.single.enabled, isFalse);
  });

  test('missing exact-alarm access falls back to approximate scheduling',
      () async {
    final adapter = FakeHydrionNotificationAdapter(
      preciseScheduling: false,
    );
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: adapter,
    );

    final result = await service.createReminder(
      triggerTime: DateTime.now().add(const Duration(seconds: 8)),
      message: 'Eight-second hydration check',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(result.state, ReminderScheduleState.scheduledApproximately);
    expect(result.scheduled, isTrue);
    expect(adapter.precisePermissionRequestCount, 1);
    expect(
      adapter.scheduledIds,
      contains(result.reminder!.platformNotificationId),
    );
    expect(
      repository.reminders.single.scheduleError,
      isNull,
    );
  });

  test('granting exact-alarm access schedules the requested reminder',
      () async {
    final adapter = FakeHydrionNotificationAdapter(
      preciseScheduling: false,
      grantPreciseSchedulingOnRequest: true,
    );
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: ReminderRepository.memory(),
      adapter: adapter,
    );

    final result = await service.createReminder(
      triggerTime: DateTime.now().add(const Duration(seconds: 8)),
      message: 'Eight-second hydration check',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(result.scheduled, isTrue);
    expect(adapter.precisePermissionRequestCount, 1);
    expect(
      adapter.scheduledIds,
      contains(result.reminder!.platformNotificationId),
    );
  });

  test('exact scheduling failure falls back once to approximate scheduling',
      () async {
    final adapter = FakeHydrionNotificationAdapter(
      failExactScheduling: true,
    );
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: adapter,
    );

    final result = await service.createReminder(
      triggerTime: DateTime.now().add(const Duration(minutes: 5)),
      message: 'Fallback reminder',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(result.state, ReminderScheduleState.scheduledApproximately);
    expect(result.scheduled, isTrue);
    expect(repository.reminders.single.scheduleError, isNull);
    expect(
      adapter.scheduledIds,
      contains(result.reminder!.platformNotificationId),
    );
  });

  test('exact and approximate scheduling failure remains recoverable',
      () async {
    final adapter = FakeHydrionNotificationAdapter(
      failExactScheduling: true,
      failApproximateScheduling: true,
    );
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: adapter,
    );

    final result = await service.createReminder(
      triggerTime: DateTime.now().add(const Duration(minutes: 5)),
      message: 'Rejected reminder',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(result.state, ReminderScheduleState.schedulingFailed);
    expect(result.scheduled, isFalse);
    expect(repository.reminders.single.scheduleError, 'schedule_failed');
    expect(adapter.scheduledIds, isEmpty);
  });

  test(
      'restart reconciliation schedules enabled reminders and cancels disabled',
      () async {
    final adapter = FakeHydrionNotificationAdapter();
    final repository = ReminderRepository.memory();
    final enabled = await repository.save(
      triggerTime: DateTime.now().add(const Duration(hours: 1)),
      message: 'Drink water',
      priority: 1,
    );
    await repository.save(
      triggerTime: DateTime.now().add(const Duration(hours: 2)),
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
        ReminderScheduleState.scheduledExactly);
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
      triggerTime: DateTime.now().add(const Duration(hours: 1)),
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
      ReminderScheduleState.permissionRequired,
    );

    adapter.permission = HydrionNotificationPermissionState.granted;
    await service.reconcileSchedules(requestPermissionIfNeeded: true);

    expect(adapter.scheduledIds, contains(reminder.platformNotificationId));
    expect(
      repository.reminders.single.scheduleState,
      ReminderScheduleState.scheduledExactly,
    );
  });

  test('timezone and day rollover trigger times are retained', () async {
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: FakeHydrionNotificationAdapter(),
    );
    final now = DateTime.now();
    final trigger = DateTime(now.year, now.month, now.day, 23, 55).add(
      const Duration(minutes: 20),
    );

    final result = await service.createReminder(
      triggerTime: trigger,
      message: 'Next day check-in',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(result.state, ReminderScheduleState.scheduledExactly);
    expect(
      repository.reminders.single.triggerTime,
      trigger,
    );
    expect(
      repository.reminders.single.triggerTime.day,
      DateTime(now.year, now.month, now.day + 1).day,
    );
  });

  test('same-day past one-time reminder requires a new time', () async {
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: FakeHydrionNotificationAdapter(),
    );
    final now = DateTime.now();
    final trigger = now.subtract(const Duration(minutes: 10));

    final result = await service.createReminder(
      triggerTime: trigger,
      message: 'Drink water',
      priority: 1,
      requestPermissionIfNeeded: true,
    );

    expect(result.state, ReminderScheduleState.schedulingFailed);
    expect(repository.reminders, isEmpty);
  });

  test('fake adapter rejects an expired trigger before registration', () async {
    final adapter = FakeHydrionNotificationAdapter();
    final reminder = ScheduledReminder(
      id: 'expired',
      triggerTime: DateTime.now().subtract(const Duration(seconds: 1)),
      message: 'Expired',
      priority: 1,
    );

    await expectLater(
      adapter.schedule(
        reminder,
        precision: ReminderSchedulePrecision.approximate,
      ),
      throwsArgumentError,
    );
    expect(adapter.scheduledIds, isEmpty);
  });

  test('delete records failed Android cancellation and retries on startup',
      () async {
    final adapter = FakeHydrionNotificationAdapter();
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: adapter,
    );
    final created = await service.createReminder(
      triggerTime: DateTime.now().add(const Duration(hours: 1)),
      message: 'Delete safely',
      priority: 1,
      requestPermissionIfNeeded: true,
    );
    final platformId = created.reminder!.platformNotificationId;
    adapter.failCancellation = true;

    expect(await service.deleteReminder(created.reminder!.id), isTrue);
    expect(repository.reminders, isEmpty);
    expect(repository.orphanNotificationIds, contains(platformId));

    adapter.failCancellation = false;
    await service.retryOrphanCleanup();

    expect(repository.orphanNotificationIds, isEmpty);
    expect(adapter.scheduledIds, isNot(contains(platformId)));
  });

  test('expired persisted reminder is not sent back to Android', () async {
    final adapter = FakeHydrionNotificationAdapter();
    final repository = ReminderRepository.memory();
    await repository.save(
      triggerTime: DateTime.now().subtract(const Duration(minutes: 1)),
      message: 'Old reminder',
      priority: 1,
    );
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: adapter,
    );

    await service.reconcileSchedules();

    expect(adapter.scheduledIds, isEmpty);
    expect(
      repository.reminders.single.scheduleState,
      ReminderScheduleState.needsRescheduling,
    );
    expect(repository.reminders.single.scheduleError, 'time_passed');
  });

  test('invalid reminder input is rejected before persistence', () async {
    final repository = ReminderRepository.memory();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: repository,
      adapter: FakeHydrionNotificationAdapter(),
    );

    final blank = await service.createReminder(
      triggerTime: DateTime.now().add(const Duration(minutes: 5)),
      message: '   ',
      priority: 1,
      requestPermissionIfNeeded: true,
    );
    final impossiblePriority = await service.createReminder(
      triggerTime: DateTime.now().add(const Duration(minutes: 5)),
      message: 'Drink water',
      priority: 99,
      requestPermissionIfNeeded: true,
    );

    expect(blank.state, ReminderScheduleState.schedulingFailed);
    expect(impossiblePriority.state, ReminderScheduleState.schedulingFailed);
    expect(repository.reminders, isEmpty);
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
