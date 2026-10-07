import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/services/ai_provider_config.dart';
import 'package:hydrion/services/health_data_persistence_types.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/profile_photo_service.dart';
import 'package:hydrion/services/sensitive_body_metrics_store.dart';
import 'package:hydrion/services/timed_session_notification_service.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';

import 'memory_protected_app_store.dart';

/// Composes [HydrionServices] through the production [HydrionServices.fromStore]
/// path with every platform adapter replaced by an in-memory fake, so widget
/// tests never await a real platform channel inside the fake-async zone and
/// need no `tester.runAsync` workaround.
///
/// Pass a specific fake to observe or control one adapter; everything not
/// passed is a deterministic fake.
Future<HydrionServices> composeTestServices({
  HydrionLocalStore? store,
  ProtectedAppStore? protectedAppStore,
  SensitiveBodyMetricsStore? bodyMetricsSecureStore,
  HydrionLocationService? locationService,
  HydrionNotificationAdapter? notificationAdapter,
  HydrionTimedSessionNotificationAdapter? timedSessionNotificationAdapter,
  DailyWeatherProvider? weatherProvider,
  HydrionProfilePhotoPicker? profilePhotoPicker,
  UserManagedHealthDataProvider? healthProvider,
  HealthPersistenceResult healthPersistence = const HealthPersistenceResult(
    HealthPersistenceStatus.unsupportedPlatform,
  ),
  HydrionAiRuntimeConfig aiRuntimeConfig = const HydrionAiRuntimeConfig(),
}) =>
    HydrionServices.fromStore(
      store ?? MemoryHydrionStore(),
      protectedAppStore: protectedAppStore ?? MemoryProtectedAppStore(),
      bodyMetricsSecureStore:
          bodyMetricsSecureStore ?? MemorySensitiveBodyMetricsStore(),
      aiRuntimeConfig: aiRuntimeConfig,
      locationService: locationService ?? FakeHydrionLocationService(),
      notificationAdapter: notificationAdapter ??
          FakeHydrionNotificationAdapter(
            permission: HydrionNotificationPermissionState.granted,
          ),
      timedSessionNotificationAdapter: timedSessionNotificationAdapter ??
          FakeTimedSessionNotificationAdapter(),
      weatherProvider: weatherProvider ?? FixedTestWeatherProvider(),
      profilePhotoPicker: profilePhotoPicker ?? FakeHydrionProfilePhotoPicker(),
      healthProvider: healthProvider ?? FakeUserManagedHealthProvider(),
      healthPersistence: healthPersistence,
    );

/// Deterministic weather: mild and dry, observed "now".
class FixedTestWeatherProvider implements DailyWeatherProvider {
  FixedTestWeatherProvider({this.temperatureC = 24, this.humidityPercent = 45});

  final double temperatureC;
  final double humidityPercent;
  int fetches = 0;

  @override
  String get providerId => 'fixed-test-weather';

  @override
  bool get isConfigured => true;

  @override
  Future<WeatherSnapshot> fetchDailyForecast(
    HydrionCoordinates coordinates, {
    DateTime? now,
  }) async {
    fetches++;
    final time = now ?? DateTime.now();
    return WeatherSnapshot(
      temperatureC: temperatureC,
      humidityPercent: humidityPercent,
      uvIndex: 0,
      observedAt: time,
      retrievedAt: time,
      condition: 'Test clear',
      providerId: providerId,
    );
  }
}

/// A health provider that is never connected unless told otherwise; it
/// records requests and never touches Health Connect or HealthKit.
class FakeUserManagedHealthProvider implements UserManagedHealthDataProvider {
  FakeUserManagedHealthProvider({
    this.availabilityStatus = HealthProviderAvailabilityStatus.unsupported,
    this.permission = HealthPermissionStatus.notRequested,
  });

  HealthProviderAvailabilityStatus availabilityStatus;
  HealthPermissionStatus permission;
  int accessRequests = 0;
  int settingsOpened = 0;

  @override
  String get providerId => 'fake-test-health';

  @override
  Set<HealthMetric> get connectionMetrics => const <HealthMetric>{};

  @override
  bool get readAuthorizationIsOpaque => false;

  @override
  Future<HealthProviderAvailability> availability() async =>
      HealthProviderAvailability(availabilityStatus);

  @override
  Future<HealthProviderCapabilities> capabilities() async =>
      const HealthProviderCapabilities.unsupported();

  @override
  Future<HealthAuthorizationState> authorizationState(
    Set<HealthMetric> metrics,
  ) async =>
      HealthAuthorizationState(status: permission);

  @override
  Future<HealthAuthorizationState> requestReadAccess(
    Set<HealthMetric> metrics,
  ) async {
    accessRequests++;
    return HealthAuthorizationState(status: permission);
  }

  @override
  Future<HealthImportPage> readChanges(
    HealthSyncCheckpoint checkpoint,
  ) async =>
      HealthImportPage(records: const [], nextCheckpoint: checkpoint);

  @override
  Future<void> openSettings() async => settingsOpened++;
}
