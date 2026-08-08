import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/app_locale_repository.dart';
import 'package:hydrion/services/timed_session_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('running, paused, and stopped states share one notification identity',
      () async {
    final adapter = FakeTimedSessionNotificationAdapter();
    final service = TimedSessionNotificationService(
      localeRepository: AppLocaleRepository.memory(),
      adapter: adapter,
    );
    final completion = DateTime(2026, 8, 1, 12, 25);
    final running = HydrionTimedSessionNotification(
      kind: HydrionTimedSessionKind.pomodoro,
      lifecycle: HydrionTimedSessionLifecycle.running,
      remaining: const Duration(minutes: 25),
      completionAt: completion,
    );

    await service.sync(running);
    await service.sync(running);
    expect(adapter.showCount, 1);
    expect(adapter.active, hasLength(1));

    await service.sync(
      const HydrionTimedSessionNotification(
        kind: HydrionTimedSessionKind.pomodoro,
        lifecycle: HydrionTimedSessionLifecycle.paused,
        remaining: Duration(minutes: 12),
      ),
    );
    expect(adapter.active[HydrionTimedSessionKind.pomodoro]?.lifecycle,
        HydrionTimedSessionLifecycle.paused);

    await service.cancel(HydrionTimedSessionKind.pomodoro);
    expect(adapter.active, isEmpty);
  });

  test('Pomodoro and Homework use separate stable ongoing surfaces', () async {
    final adapter = FakeTimedSessionNotificationAdapter();
    final service = TimedSessionNotificationService(
      localeRepository: AppLocaleRepository.memory(),
      adapter: adapter,
    );
    for (final kind in HydrionTimedSessionKind.values) {
      await service.sync(
        HydrionTimedSessionNotification(
          kind: kind,
          lifecycle: HydrionTimedSessionLifecycle.running,
          remaining: const Duration(minutes: 20),
          completionAt: DateTime(2026, 8, 1, 12, 20),
        ),
      );
    }
    expect(adapter.active.keys, containsAll(HydrionTimedSessionKind.values));
    await service.cancelAll();
    expect(adapter.active, isEmpty);
  });

  test('zero remaining time never leaves an ongoing notification', () async {
    final adapter = FakeTimedSessionNotificationAdapter();
    final service = TimedSessionNotificationService(
      localeRepository: AppLocaleRepository.memory(),
      adapter: adapter,
    );
    await service.sync(
      const HydrionTimedSessionNotification(
        kind: HydrionTimedSessionKind.homework,
        lifecycle: HydrionTimedSessionLifecycle.running,
        remaining: Duration.zero,
      ),
    );
    expect(adapter.active, isEmpty);
  });

  test('language changes refresh an active notification without duplication',
      () async {
    final adapter = FakeTimedSessionNotificationAdapter();
    final localeRepository = AppLocaleRepository.memory();
    final service = TimedSessionNotificationService(
      localeRepository: localeRepository,
      adapter: adapter,
    );
    await service.sync(
      HydrionTimedSessionNotification(
        kind: HydrionTimedSessionKind.pomodoro,
        lifecycle: HydrionTimedSessionLifecycle.running,
        remaining: const Duration(minutes: 20),
        completionAt: DateTime(2026, 8, 1, 12, 20),
      ),
    );
    await localeRepository.selectLocale(const Locale('es'));
    await Future<void>.delayed(Duration.zero);
    expect(adapter.showCount, 2);
    expect(adapter.active, hasLength(1));
  });
}
