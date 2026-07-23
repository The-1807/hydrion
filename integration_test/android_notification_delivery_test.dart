import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/policy_service.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android posts an exact Hydrion reminder within ten seconds',
    (tester) async {
      expect(
        defaultTargetPlatform,
        TargetPlatform.android,
        reason: 'This delivery test must run on an Android device or emulator.',
      );

      final plugin = FlutterLocalNotificationsPlugin();
      final adapter = FlutterLocalNotificationsHydrionAdapter(plugin: plugin);
      final service = NotificationService(
        reminderPolicy: ReminderPolicy(),
        reminderRepository: ReminderRepository.memory(),
        adapter: adapter,
      );

      await service.initialize();
      var notificationPermission = await service.checkPermission();
      if (notificationPermission !=
          HydrionNotificationPermissionState.granted) {
        notificationPermission = await service.requestPermission();
      }
      expect(
        notificationPermission,
        HydrionNotificationPermissionState.granted,
        reason: 'Grant notification access when Android asks.',
      );

      var precise = await adapter.canSchedulePrecisely();
      if (!precise) {
        precise = await adapter.requestPreciseSchedulingPermission();
      }
      expect(
        precise,
        isTrue,
        reason: 'Grant Alarms & reminders access when Android asks.',
      );

      const message = 'Hydrion Android delivery test';
      final result = await service.createReminder(
        triggerTime: DateTime.now().add(const Duration(seconds: 7)),
        message: message,
        priority: 1,
      );
      expect(result.scheduled, isTrue);
      expect(result.state, ReminderScheduleState.scheduledExactly);
      final notificationId = result.reminder!.platformNotificationId;

      final pending = await plugin.pendingNotificationRequests();
      expect(
        pending.any((notification) => notification.id == notificationId),
        isTrue,
        reason: 'Android must accept the future reminder before delivery.',
      );

      final stopwatch = Stopwatch()..start();
      var active = <ActiveNotification>[];
      while (stopwatch.elapsed < const Duration(seconds: 10)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await tester.pump();
        active = await plugin.getActiveNotifications();
        if (active.any(
          (notification) =>
              notification.id == notificationId && notification.body == message,
        )) {
          break;
        }
      }
      stopwatch.stop();
      expect(
        active.any(
          (notification) =>
              notification.id == notificationId && notification.body == message,
        ),
        isTrue,
        reason:
            'The scheduled notification must be visible in Android within ten seconds.',
      );
      expect(
        (await plugin.pendingNotificationRequests())
            .any((notification) => notification.id == notificationId),
        isFalse,
        reason: 'A delivered one-shot reminder must no longer be pending.',
      );

      await plugin.cancel(id: notificationId);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'Android accepts approximate fallback when exact access is unavailable',
    (tester) async {
      expect(defaultTargetPlatform, TargetPlatform.android);
      final plugin = FlutterLocalNotificationsPlugin();
      final adapter = _ApproximateOnlyAndroidAdapter(plugin: plugin);
      final service = NotificationService(
        reminderPolicy: ReminderPolicy(),
        reminderRepository: ReminderRepository.memory(),
        adapter: adapter,
      );

      await service.initialize();
      var permission = await service.checkPermission();
      if (permission != HydrionNotificationPermissionState.granted) {
        permission = await service.requestPermission();
      }
      expect(
        permission,
        HydrionNotificationPermissionState.granted,
        reason: 'Grant notification access when Android asks.',
      );

      final result = await service.createReminder(
        triggerTime: DateTime.now().add(const Duration(minutes: 2)),
        message: 'Hydrion approximate delivery test',
        priority: 1,
      );
      expect(result.state, ReminderScheduleState.scheduledApproximately);
      final notificationId = result.reminder!.platformNotificationId;
      expect(
        (await plugin.pendingNotificationRequests())
            .any((notification) => notification.id == notificationId),
        isTrue,
        reason:
            'Approximate delivery timing is controlled by Android, so this test verifies accepted registration without a ten-second deadline.',
      );

      await service.deleteReminder(result.reminder!.id);
      await tester.pump();
      expect(
        (await plugin.pendingNotificationRequests())
            .any((notification) => notification.id == notificationId),
        isFalse,
      );
    },
  );

  testWidgets('expired timestamps are rejected before Android registration',
      (tester) async {
    final adapter = FakeHydrionNotificationAdapter();
    final service = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: ReminderRepository.memory(),
      adapter: adapter,
    );

    final result = await service.createReminder(
      triggerTime: DateTime.now().subtract(const Duration(seconds: 1)),
      message: 'Expired Android test',
      priority: 1,
    );

    expect(result.scheduled, isFalse);
    expect(result.reminder, isNull);
    expect(adapter.scheduledIds, isEmpty);
    await tester.pump();
  });
}

class _ApproximateOnlyAndroidAdapter
    extends FlutterLocalNotificationsHydrionAdapter {
  _ApproximateOnlyAndroidAdapter({
    required super.plugin,
  });

  @override
  Future<bool> canSchedulePrecisely() async => false;

  @override
  Future<bool> requestPreciseSchedulingPermission() async => false;
}
