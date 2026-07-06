import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/reminder_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/policy_service.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  group('location and daily weather goal flow', () {
    test('first eligible day prompts and same-day reopen does not repeat',
        () async {
      final harness = await _GoalHarness.create();
      final first = await harness.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 8),
      );

      expect(first.status, DailyWeatherGoalStatus.promptReady);
      expect(first.decision?.recommendedGoalMl, 2450);

      await harness.coordinator.acceptRecommendation(
        decision: first.decision!,
        now: DateTime(2026, 7, 5, 8),
      );

      final sameDay = await harness.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 12),
      );

      expect(sameDay.status, DailyWeatherGoalStatus.alreadyHandledToday);
      expect(harness.settings.settings.dailyGoalMl, 2450);
      expect(harness.settings.settings.baselineDailyGoalMl, 2200);
      expect(harness.settings.settings.lastWeatherGoalExplanation,
          contains('Baseline 2200 ml'));
    });

    test('next-day auto apply can be restored to confirmation', () async {
      final harness = await _GoalHarness.create();
      await harness.settings.setWeatherGoalDailyConfirmationEnabled(false);

      final autoApplied = await harness.coordinator.evaluate(
        now: DateTime(2026, 7, 6, 8),
      );

      expect(autoApplied.status, DailyWeatherGoalStatus.autoApplied);
      expect(harness.settings.settings.weatherGoalAutoApplyEnabled, isTrue);

      await harness.settings.setWeatherGoalDailyConfirmationEnabled(true);
      expect(
        harness.settings.settings.weatherGoalDailyConfirmationEnabled,
        isTrue,
      );
      expect(harness.settings.settings.weatherGoalAutoApplyEnabled, isFalse);
    });

    test('denied and permanently denied permissions block without lookup',
        () async {
      final denied = await _GoalHarness.create(
        locationPermission: HydrionLocationPermissionState.denied,
      );
      final deniedResult = await denied.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 8),
      );

      expect(deniedResult.status,
          DailyWeatherGoalStatus.locationPermissionRequired);
      expect(denied.location.lookupCount, 0);

      final permanent = await _GoalHarness.create(
        locationPermission: HydrionLocationPermissionState.permanentlyDenied,
      );
      final permanentResult = await permanent.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 8),
      );

      expect(permanentResult.status,
          DailyWeatherGoalStatus.locationPermissionRequired);
      expect(permanentResult.message, 'permanentlyDenied');
    });

    test(
        'service disabled timeout and unavailable coordinates fall back safely',
        () async {
      for (final result in [
        const HydrionLocationLookupResult.failure(
          HydrionLocationLookupStatus.serviceDisabled,
        ),
        const HydrionLocationLookupResult.failure(
          HydrionLocationLookupStatus.timeout,
        ),
        const HydrionLocationLookupResult.failure(
          HydrionLocationLookupStatus.unavailable,
        ),
      ]) {
        final harness = await _GoalHarness.create(locationResult: result);
        final evaluation = await harness.coordinator.evaluate(
          now: DateTime(2026, 7, 5, 8),
        );

        expect(evaluation.status, DailyWeatherGoalStatus.locationUnavailable);
        expect(harness.settings.settings.dailyGoalMl, 2200);
      }
    });

    test('manual mode and same-day manual override preserve baseline',
        () async {
      final manual =
          await _GoalHarness.create(goalMode: HydrionGoalMode.manual);
      final manualResult = await manual.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 8),
      );

      expect(manualResult.status, DailyWeatherGoalStatus.goalModeManual);

      final edited = await _GoalHarness.create();
      await edited.settings.setDailyGoalMl(
        2400,
        now: DateTime(2026, 7, 5, 7),
      );
      final editedResult = await edited.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 8),
      );

      expect(
          editedResult.status, DailyWeatherGoalStatus.manualGoalChangedToday);
      expect(edited.settings.settings.dailyGoalMl, 2400);
    });

    test('no repeated permission prompting on the same local day', () async {
      final harness = await _GoalHarness.create(
        locationPermission: HydrionLocationPermissionState.denied,
      );

      await harness.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 8),
        requestLocationPermission: true,
      );
      await harness.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 9),
        requestLocationPermission: true,
      );

      expect(harness.location.requestCount, 1);
    });

    test('notification denial does not block weather recommendation', () async {
      final harness = await _GoalHarness.create(
        notificationPermission: HydrionNotificationPermissionState.denied,
      );

      final result = await harness.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 8),
      );

      expect(result.status, DailyWeatherGoalStatus.promptReady);
      expect(result.decision?.eligible, isTrue);
      expect(harness.notificationAdapter.requestCount, 0);
      expect(harness.location.lookupCount, 1);
    });

    test('weather mode setup fetches forecast without notification permission',
        () async {
      final harness =
          await _GoalHarness.create(goalMode: HydrionGoalMode.manual);

      final result = await harness.coordinator.prepareWeatherMode(
        now: DateTime(2026, 7, 5, 8),
        requestLocationPermission: true,
      );

      expect(result.status, WeatherModeSetupStatus.ready);
      expect(result.forecast?.condition, 'Humid');
      expect(result.decision?.recommendedGoalMl, 2450);
      expect(harness.weatherProvider.calls, 1);
      expect(harness.location.lookupCount, 1);
      expect(harness.notificationAdapter.requestCount, 0);
      expect(harness.settings.settings.goalMode, HydrionGoalMode.manual);
    });

    test('weather mode setup stays manual when location is denied', () async {
      final harness = await _GoalHarness.create(
        goalMode: HydrionGoalMode.manual,
        locationPermission: HydrionLocationPermissionState.denied,
      );

      final result = await harness.coordinator.prepareWeatherMode(
        now: DateTime(2026, 7, 5, 8),
        requestLocationPermission: true,
      );

      expect(result.status, WeatherModeSetupStatus.locationPermissionRequired);
      expect(harness.location.requestCount, 1);
      expect(harness.location.lookupCount, 0);
      expect(harness.weatherProvider.calls, 0);
      expect(harness.settings.settings.goalMode, HydrionGoalMode.manual);
    });

    test('manual logging is independent from location denial', () async {
      final harness = await _GoalHarness.create(
        locationPermission: HydrionLocationPermissionState.denied,
      );
      final hydration = HydrationRepository.memory();

      expect(harness.settings.settings.dailyGoalMl, 2200);
      final log = await hydration.addLog(
        volumeMl: 300,
        timestamp: DateTime(2026, 7, 5, 8),
      );

      expect(log, isNotNull);
      expect(hydration.totalForDay(DateTime(2026, 7, 5, 8)), 300);
      final weatherResult = await harness.coordinator.evaluate(
        now: DateTime(2026, 7, 5, 8),
      );
      expect(
        weatherResult.status,
        DailyWeatherGoalStatus.locationPermissionRequired,
      );
      expect(hydration.totalForDay(DateTime(2026, 7, 5, 8)), 300);
    });
  });

  group('weather provider and cache', () {
    test('Open-Meteo successful forecast parses daily and current data',
        () async {
      final provider = OpenMeteoWeatherProvider(
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'current': {
                'temperature_2m': 29.0,
                'relative_humidity_2m': 74,
                'weather_code': 3,
              },
              'daily': {
                'temperature_2m_max': [33.2],
                'weather_code': [3],
              },
            }),
            200,
          );
        }),
      );

      final forecast = await provider.fetchDailyForecast(
        _toronto,
        now: DateTime(2026, 7, 5, 10),
      );

      expect(forecast.temperatureC, 33.2);
      expect(forecast.humidityPercent, 74);
      expect(forecast.condition, 'Cloudy');
      expect(forecast.providerId, 'open-meteo');
    });

    test('weather failures classify invalid response timeout and rate limit',
        () async {
      final invalid = OpenMeteoWeatherProvider(
        client: MockClient((_) async => http.Response('not-json', 200)),
      );
      expect(
        () => invalid.fetchDailyForecast(_toronto),
        throwsA(isA<WeatherProviderException>().having(
          (error) => error.status,
          'status',
          WeatherForecastStatus.invalidResponse,
        )),
      );

      final rateLimited = OpenMeteoWeatherProvider(
        client: MockClient((_) async => http.Response('{}', 429)),
      );
      expect(
        () => rateLimited.fetchDailyForecast(_toronto),
        throwsA(isA<WeatherProviderException>().having(
          (error) => error.status,
          'status',
          WeatherForecastStatus.rateLimited,
        )),
      );

      final timeout = OpenMeteoWeatherProvider(
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('{}', 200);
        }),
      );
      expect(
        () => timeout.fetchDailyForecast(_toronto),
        throwsA(isA<WeatherProviderException>().having(
          (error) => error.status,
          'status',
          WeatherForecastStatus.timeout,
        )),
      );
    });

    test('same-day cache is reused and next-day refreshes provider', () async {
      final store = MemoryHydrionStore();
      final provider = _CountingWeatherProvider();
      final service = WeatherForecastService(
        provider: provider,
        cache: WeatherForecastCacheRepository(store),
      );

      final first = await service.getDailyForecast(
        coordinates: _toronto,
        now: DateTime(2026, 7, 5, 8),
      );
      final sameDay = await service.getDailyForecast(
        coordinates: _toronto,
        now: DateTime(2026, 7, 5, 18),
      );
      final nextDay = await service.getDailyForecast(
        coordinates: _toronto,
        now: DateTime(2026, 7, 6, 8),
      );

      expect(first.fromCache, isFalse);
      expect(sameDay.fromCache, isTrue);
      expect(nextDay.fromCache, isFalse);
      expect(provider.calls, 2);
      expect(store.snapshot[WeatherForecastCacheRepository.storageKey],
          isNot(contains('43.6532')));
    });

    test('provider failure falls back to stale cache without applying success',
        () async {
      final store = MemoryHydrionStore();
      final cache = WeatherForecastCacheRepository(store);
      await cache.write(
        localDateKey: '2026-07-04',
        forecast: WeatherSnapshot(
          temperatureC: 27,
          humidityPercent: 50,
          uvIndex: 0,
          observedAt: DateTime(2026, 7, 4, 8),
        ),
      );
      final service = WeatherForecastService(
        provider:
            const _FailingWeatherProvider(WeatherForecastStatus.noNetwork),
        cache: cache,
      );

      final result = await service.getDailyForecast(
        coordinates: _toronto,
        now: DateTime(2026, 7, 5, 8),
      );

      expect(result.status, WeatherForecastStatus.staleCache);
      expect(result.fromCache, isTrue);
      expect(result.forecast?.temperatureC, 27);
    });

    test('extreme temperature and humidity values are bounded', () async {
      final provider = OpenMeteoWeatherProvider(
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'current': {
                'temperature_2m': 400,
                'relative_humidity_2m': 140,
                'weather_code': 0,
              },
            }),
            200,
          );
        }),
      );

      final forecast = await provider.fetchDailyForecast(_toronto);

      expect(forecast.temperatureC, 60);
      expect(forecast.humidityPercent, 100);
    });
  });
}

final _toronto = HydrionCoordinates(
  latitude: 43.6532,
  longitude: -79.3832,
  capturedAt: DateTime(2026, 7, 5),
);

class _GoalHarness {
  final UserSettingsRepository settings;
  final FakeHydrionLocationService location;
  final FakeHydrionNotificationAdapter notificationAdapter;
  final _CountingWeatherProvider weatherProvider;
  final DailyWeatherGoalCoordinator coordinator;

  const _GoalHarness({
    required this.settings,
    required this.location,
    required this.notificationAdapter,
    required this.weatherProvider,
    required this.coordinator,
  });

  static Future<_GoalHarness> create({
    HydrionGoalMode goalMode = HydrionGoalMode.weatherInformed,
    HydrionLocationPermissionState locationPermission =
        HydrionLocationPermissionState.granted,
    HydrionNotificationPermissionState notificationPermission =
        HydrionNotificationPermissionState.granted,
    HydrionLocationLookupResult? locationResult,
  }) async {
    final settings = UserSettingsRepository.memory();
    await settings.setProfile(
      nickname: 'Weather Tester',
      age: 31,
      sex: HydrionSex.female,
    );
    await settings.setGoalMode(goalMode);
    final location = FakeHydrionLocationService(
      permission: locationPermission,
      lookupResult: locationResult,
    );
    final notificationAdapter = FakeHydrionNotificationAdapter(
      permission: notificationPermission,
    );
    final notifications = NotificationService(
      reminderPolicy: ReminderPolicy(),
      reminderRepository: ReminderRepository.memory(),
      adapter: notificationAdapter,
    );
    final weatherProvider = _CountingWeatherProvider();
    final weatherService = WeatherForecastService(
      provider: weatherProvider,
      cache: WeatherForecastCacheRepository(MemoryHydrionStore()),
    );
    final coordinator = DailyWeatherGoalCoordinator(
      settingsRepository: settings,
      locationService: location,
      weatherService: weatherService,
      notificationService: notifications,
    );
    return _GoalHarness(
      settings: settings,
      location: location,
      notificationAdapter: notificationAdapter,
      weatherProvider: weatherProvider,
      coordinator: coordinator,
    );
  }
}

class _CountingWeatherProvider implements DailyWeatherProvider {
  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  String get providerId => 'counting-weather';

  @override
  Future<WeatherSnapshot> fetchDailyForecast(
    HydrionCoordinates coordinates, {
    DateTime? now,
  }) async {
    calls += 1;
    final currentTime = now ?? DateTime.now();
    return WeatherSnapshot(
      temperatureC: 27,
      humidityPercent: 72,
      uvIndex: 0,
      observedAt: currentTime,
      retrievedAt: currentTime,
      condition: 'Humid',
      providerId: providerId,
    );
  }
}

class _FailingWeatherProvider implements DailyWeatherProvider {
  final WeatherForecastStatus status;

  const _FailingWeatherProvider(this.status);

  @override
  bool get isConfigured => true;

  @override
  String get providerId => 'failing-weather';

  @override
  Future<WeatherSnapshot> fetchDailyForecast(
    HydrionCoordinates coordinates, {
    DateTime? now,
  }) async {
    throw WeatherProviderException(status, status.name);
  }
}
