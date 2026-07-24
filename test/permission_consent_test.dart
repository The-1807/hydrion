import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/policy_service.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/utils/permissions.dart';

Permissions _permissions({
  required FakeHydrionNotificationAdapter notifications,
  required FakeHydrionLocationService location,
  HydrionPermissionPlatform platform = HydrionPermissionPlatform.android,
}) {
  return Permissions(
    notifications: NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: ReminderRepository.memory(),
      adapter: notifications,
    ),
    location: location,
    settings: UserSettingsRepository.memory(),
    platform: platform,
    now: () => DateTime(2026, 7, 24, 12),
  );
}

void main() {
  test('Android permission model reports real states and optional fallback',
      () async {
    final notificationAdapter = FakeHydrionNotificationAdapter(
      permission: HydrionNotificationPermissionState.denied,
      preciseScheduling: false,
    );
    final location = FakeHydrionLocationService(
      permission: HydrionLocationPermissionState.denied,
    );
    final permissions = _permissions(
      notifications: notificationAdapter,
      location: location,
    );

    await permissions.refresh();
    expect(
      permissions.snapshot.notifications.state,
      HydrionPermissionState.notRequested,
    );
    expect(
      permissions.snapshot.location.state,
      HydrionPermissionState.notRequested,
    );
    expect(
      permissions.snapshot.exactAlarms.state,
      HydrionPermissionState.denied,
    );
    expect(permissions.snapshot.exactAlarms.fallbackAvailable, isTrue);

    await permissions.requestNotifications();
    await permissions.requestLocation();
    expect(notificationAdapter.requestCount, 1);
    expect(location.requestCount, 1);
    expect(
      permissions.snapshot.notifications.state,
      HydrionPermissionState.denied,
    );
    expect(
      permissions.snapshot.location.state,
      HydrionPermissionState.denied,
    );
  });

  test('approximate, precise, blocked, and settings actions are explicit',
      () async {
    final notificationAdapter = FakeHydrionNotificationAdapter(
      permission: HydrionNotificationPermissionState.permanentlyDenied,
    );
    final location = FakeHydrionLocationService(
      permission: HydrionLocationPermissionState.granted,
      accuracy: HydrionLocationAccuracy.approximate,
    );
    final permissions = _permissions(
      notifications: notificationAdapter,
      location: location,
    );

    await permissions.refresh();
    expect(
      permissions.snapshot.notifications.state,
      HydrionPermissionState.permanentlyDenied,
    );
    expect(permissions.snapshot.notifications.settingsRequired, isTrue);
    expect(
      permissions.snapshot.location.state,
      HydrionPermissionState.approximateGranted,
    );

    location.accuracy = HydrionLocationAccuracy.precise;
    await permissions.refresh();
    expect(
      permissions.snapshot.location.state,
      HydrionPermissionState.preciseGranted,
    );
    await permissions.openNotificationSettings();
    await permissions.openLocationSettings();
    expect(notificationAdapter.settingsOpenCount, 1);
    expect(location.appSettingsOpenCount, 1);
  });

  testWidgets('permission center is functional and has no dead Check action',
      (tester) async {
    final services = HydrionServices.memory(
      notificationAdapter: FakeHydrionNotificationAdapter(
        permission: HydrionNotificationPermissionState.granted,
      ),
      locationService: FakeHydrionLocationService(),
    );
    await tester.pumpWidget(
      HydrionApp(services: services, initialRoute: '/permissions'),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('permission-notifications-card')), findsOneWidget);
    expect(find.byKey(const Key('permission-location-card')), findsOneWidget);
    expect(
        find.byKey(const Key('permission-exact-alarm-card')), findsOneWidget);
    expect(find.text('Check'), findsNothing);
    expect(find.textContaining('standalone'), findsNothing);
    expect(find.byKey(const Key('refresh-permission-status')), findsOneWidget);
  });

  testWidgets('onboarding offers independent enable and Not now choices',
      (tester) async {
    final store = MemoryHydrionStore();
    const settings = UserSettings(
      locale: Locale('en'),
      onboardingCompleted: false,
      onboardingStep: 5,
    );
    await store.writeString(
      UserSettingsRepository.storageKey,
      jsonEncode(settings.toJson()),
    );
    final services = await HydrionServices.fromStore(store);
    await tester.pumpWidget(
      HydrionApp(services: services, initialRoute: '/onboarding'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-reminder-capability')),
        findsOneWidget);
    expect(
        find.byKey(const Key('onboarding-weather-capability')), findsOneWidget);
    expect(
        find.byKey(const Key('onboarding-reminders-not-now')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-weather-not-now')), findsOneWidget);
  });
}
