import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../repositories/settings_repository.dart';
import '../storage/local_store.dart';
import 'location_service.dart';
import 'notifications.dart';

abstract class WeatherProvider {
  Future<WeatherSnapshot> currentForecast();
}

abstract class DailyWeatherProvider {
  String get providerId;

  bool get isConfigured;

  Future<WeatherSnapshot> fetchDailyForecast(
    HydrionCoordinates coordinates, {
    DateTime? now,
  });
}

class WeatherSnapshot {
  final double temperatureC;
  final double? humidityPercent;
  final double uvIndex;
  final DateTime observedAt;
  final String condition;
  final String providerId;
  final DateTime retrievedAt;

  const WeatherSnapshot({
    required this.temperatureC,
    this.humidityPercent,
    required this.uvIndex,
    required this.observedAt,
    this.condition = 'Unknown',
    this.providerId = 'unknown',
    DateTime? retrievedAt,
  }) : retrievedAt = retrievedAt ?? observedAt;

  Map<String, dynamic> toJson() {
    return {
      'temperatureC': temperatureC,
      'humidityPercent': humidityPercent,
      'uvIndex': uvIndex,
      'observedAt': observedAt.toIso8601String(),
      'condition': condition,
      'providerId': providerId,
      'retrievedAt': retrievedAt.toIso8601String(),
    };
  }

  static WeatherSnapshot? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final temperature = value['temperatureC'];
    final humidity = value['humidityPercent'];
    final uv = value['uvIndex'];
    final observedAt =
        DateTime.tryParse((value['observedAt'] ?? '').toString());
    final retrievedAt =
        DateTime.tryParse((value['retrievedAt'] ?? '').toString());
    if (temperature is! num ||
        !temperature.isFinite ||
        uv is! num ||
        !uv.isFinite ||
        observedAt == null) {
      return null;
    }
    return WeatherSnapshot(
      temperatureC: temperature.toDouble(),
      humidityPercent:
          humidity is num && humidity.isFinite ? humidity.toDouble() : null,
      uvIndex: uv.toDouble(),
      observedAt: observedAt,
      condition: (value['condition'] ?? 'Unknown').toString(),
      providerId: (value['providerId'] ?? 'unknown').toString(),
      retrievedAt: retrievedAt,
    );
  }
}

enum WeatherForecastStatus {
  success,
  unconfigured,
  missingApiKey,
  timeout,
  invalidResponse,
  rateLimited,
  noNetwork,
  serviceUnavailable,
  providerFailure,
  staleCache,
}

class WeatherProviderException implements Exception {
  final WeatherForecastStatus status;
  final String message;

  const WeatherProviderException(this.status, this.message);

  @override
  String toString() => 'WeatherProviderException($status): $message';
}

class WeatherForecastResult {
  final WeatherForecastStatus status;
  final WeatherSnapshot? forecast;
  final bool fromCache;
  final String? message;

  const WeatherForecastResult({
    required this.status,
    this.forecast,
    this.fromCache = false,
    this.message,
  });

  bool get isSuccess =>
      status == WeatherForecastStatus.success && forecast != null;
}

class WeatherForecastCacheRepository {
  static const storageKey = 'hydrion.weather_forecast_cache.v1';

  final HydrionLocalStore _store;

  const WeatherForecastCacheRepository(this._store);

  Future<CachedWeatherForecast?> read() async {
    final raw = await _store.readString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final localDateKey = (decoded['localDateKey'] ?? '').toString();
      if (!_isLocalDateKey(localDateKey)) {
        return null;
      }
      final forecast = WeatherSnapshot.fromJson(decoded['forecast']);
      if (forecast == null) {
        return null;
      }
      return CachedWeatherForecast(
        localDateKey: localDateKey,
        forecast: forecast,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> write({
    required String localDateKey,
    required WeatherSnapshot forecast,
  }) async {
    await _store.writeString(
      storageKey,
      jsonEncode({
        'localDateKey': localDateKey,
        'forecast': forecast.toJson(),
      }),
    );
  }

  Future<void> clear() {
    return _store.remove(storageKey);
  }

  static bool _isLocalDateKey(String value) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);
  }
}

class WeatherForecastService {
  final DailyWeatherProvider _provider;
  final WeatherForecastCacheRepository _cache;

  const WeatherForecastService({
    required DailyWeatherProvider provider,
    required WeatherForecastCacheRepository cache,
  })  : _provider = provider,
        _cache = cache;

  String get providerId => _provider.providerId;

  bool get isConfigured => _provider.isConfigured;

  Future<WeatherForecastResult> getDailyForecast({
    required HydrionCoordinates coordinates,
    DateTime? now,
    bool forceRefresh = false,
  }) async {
    final currentTime = now ?? DateTime.now();
    final localDateKey = _localDateKey(currentTime);
    final cached = await _cache.read();
    if (!forceRefresh &&
        cached != null &&
        cached.localDateKey == localDateKey &&
        !_isStale(cached.forecast, currentTime)) {
      return WeatherForecastResult(
        status: WeatherForecastStatus.success,
        forecast: cached.forecast,
        fromCache: true,
      );
    }
    if (!_provider.isConfigured) {
      return WeatherForecastResult(
        status: WeatherForecastStatus.missingApiKey,
        forecast: _staleFallback(cached),
        fromCache: cached != null,
        message: 'Weather provider is not configured.',
      );
    }

    try {
      final forecast = await _provider.fetchDailyForecast(
        coordinates,
        now: currentTime,
      );
      await _cache.write(localDateKey: localDateKey, forecast: forecast);
      return WeatherForecastResult(
        status: WeatherForecastStatus.success,
        forecast: forecast,
      );
    } on WeatherProviderException catch (error) {
      return WeatherForecastResult(
        status:
            cached == null ? error.status : WeatherForecastStatus.staleCache,
        forecast: _staleFallback(cached),
        fromCache: cached != null,
        message: error.message,
      );
    } on TimeoutException {
      return WeatherForecastResult(
        status: cached == null
            ? WeatherForecastStatus.timeout
            : WeatherForecastStatus.staleCache,
        forecast: _staleFallback(cached),
        fromCache: cached != null,
        message: 'Weather request timed out.',
      );
    }
  }

  WeatherSnapshot? _staleFallback(CachedWeatherForecast? cached) {
    return cached?.forecast;
  }

  bool _isStale(WeatherSnapshot forecast, DateTime now) {
    return now.difference(forecast.retrievedAt).abs() >
        const Duration(hours: 18);
  }

  static String _localDateKey(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

class OpenMeteoWeatherProvider implements DailyWeatherProvider {
  final http.Client _client;
  final Uri _endpoint;
  final Duration timeout;

  OpenMeteoWeatherProvider({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        _endpoint = endpoint ?? Uri.https('api.open-meteo.com', '/v1/forecast');

  @override
  String get providerId => 'open-meteo';

  @override
  bool get isConfigured => true;

  @override
  Future<WeatherSnapshot> fetchDailyForecast(
    HydrionCoordinates coordinates, {
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final uri = _endpoint.replace(
      queryParameters: {
        'latitude': coordinates.latitude.toStringAsFixed(4),
        'longitude': coordinates.longitude.toStringAsFixed(4),
        'daily': 'temperature_2m_max,weather_code',
        'current': 'temperature_2m,relative_humidity_2m,weather_code',
        'forecast_days': '1',
        'timezone': 'auto',
      },
    );

    http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const WeatherProviderException(
        WeatherForecastStatus.timeout,
        'Weather request timed out.',
      );
    } on http.ClientException catch (error) {
      throw WeatherProviderException(
        WeatherForecastStatus.noNetwork,
        error.message,
      );
    }

    if (response.statusCode == 429) {
      throw const WeatherProviderException(
        WeatherForecastStatus.rateLimited,
        'Weather provider rate limit reached.',
      );
    }
    if (response.statusCode >= 500) {
      throw WeatherProviderException(
        WeatherForecastStatus.serviceUnavailable,
        'Weather provider unavailable (${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WeatherProviderException(
        WeatherForecastStatus.providerFailure,
        'Weather provider HTTP ${response.statusCode}.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const WeatherProviderException(
        WeatherForecastStatus.invalidResponse,
        'Weather response was not valid JSON.',
      );
    }
    if (decoded is! Map) {
      throw const WeatherProviderException(
        WeatherForecastStatus.invalidResponse,
        'Weather response had an invalid shape.',
      );
    }

    final current = decoded['current'];
    final daily = decoded['daily'];
    final currentTemperature = _numAt(current, 'temperature_2m');
    final dailyMax = _listNumAt(daily, 'temperature_2m_max', 0);
    final temperature = dailyMax ?? currentTemperature;
    if (temperature == null) {
      throw const WeatherProviderException(
        WeatherForecastStatus.invalidResponse,
        'Weather response did not include temperature.',
      );
    }
    final humidity = _numAt(current, 'relative_humidity_2m');
    final weatherCode =
        _numAt(current, 'weather_code') ?? _listNumAt(daily, 'weather_code', 0);

    return WeatherSnapshot(
      temperatureC: temperature.clamp(-60, 60).toDouble(),
      humidityPercent: humidity?.clamp(0, 100).toDouble(),
      uvIndex: 0,
      observedAt: currentTime,
      retrievedAt: currentTime,
      condition: _conditionFromCode(weatherCode?.round()),
      providerId: providerId,
    );
  }

  num? _numAt(Object? value, String key) {
    if (value is! Map) {
      return null;
    }
    final number = value[key];
    return number is num && number.isFinite ? number : null;
  }

  num? _listNumAt(Object? value, String key, int index) {
    if (value is! Map) {
      return null;
    }
    final list = value[key];
    if (list is! List || index >= list.length) {
      return null;
    }
    final number = list[index];
    return number is num && number.isFinite ? number : null;
  }

  String _conditionFromCode(int? code) {
    if (code == null) {
      return 'Unknown';
    }
    if (code == 0) {
      return 'Clear';
    }
    if (code <= 3) {
      return 'Cloudy';
    }
    if (code == 45 || code == 48) {
      return 'Fog';
    }
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return 'Rain';
    }
    if (code >= 71 && code <= 77) {
      return 'Snow';
    }
    if (code >= 95) {
      return 'Storm';
    }
    return 'Mixed';
  }
}

class CachedWeatherForecast {
  final String localDateKey;
  final WeatherSnapshot forecast;

  const CachedWeatherForecast({
    required this.localDateKey,
    required this.forecast,
  });
}

class WeatherGoalInputs {
  final int baselineGoalMl;
  final int? age;
  final HydrionSex? sex;
  final WeatherSnapshot weather;
  final int userAdjustmentMl;
  final bool locationPermissionGranted;
  final bool notificationPermissionGranted;

  const WeatherGoalInputs({
    required this.baselineGoalMl,
    required this.age,
    required this.sex,
    required this.weather,
    this.userAdjustmentMl = 0,
    this.locationPermissionGranted = false,
    this.notificationPermissionGranted = false,
  });
}

class WeatherGoalDecision {
  final int baselineGoalMl;
  final int weatherAdjustmentMl;
  final int userAdjustmentMl;
  final int recommendedGoalMl;
  final String explanation;
  final bool eligible;

  const WeatherGoalDecision({
    required this.baselineGoalMl,
    required this.weatherAdjustmentMl,
    required this.userAdjustmentMl,
    required this.recommendedGoalMl,
    required this.explanation,
    required this.eligible,
  });
}

class DeterministicWeatherGoalService {
  static const maxWeatherAdjustmentMl = 600;
  static const minUserAdjustmentMl = -500;
  static const maxUserAdjustmentMl = 500;

  const DeterministicWeatherGoalService();

  WeatherGoalDecision recommend(WeatherGoalInputs inputs) {
    final baseline = inputs.baselineGoalMl.clamp(
      UserSettings.minDailyGoalMl,
      UserSettings.maxDailyGoalMl,
    );
    if (!_eligible(inputs)) {
      return WeatherGoalDecision(
        baselineGoalMl: baseline,
        weatherAdjustmentMl: 0,
        userAdjustmentMl: 0,
        recommendedGoalMl: baseline,
        explanation:
            'Manual goal kept because weather-informed goals require age, an explicit sex option, location permission, notification permission, and a forecast provider.',
        eligible: false,
      );
    }

    final temperatureAdjustment = switch (inputs.weather.temperatureC) {
      >= 35 => 450,
      >= 30 => 300,
      >= 26 => 150,
      <= 0 => -100,
      _ => 0,
    };
    final humidityAdjustment =
        (inputs.weather.humidityPercent ?? 0) >= 70 ? 100 : 0;
    final uvAdjustment = inputs.weather.uvIndex >= 8 ? 100 : 0;
    final weatherAdjustment =
        (temperatureAdjustment + humidityAdjustment + uvAdjustment)
            .clamp(-100, maxWeatherAdjustmentMl);
    final userAdjustment = inputs.userAdjustmentMl.clamp(
      minUserAdjustmentMl,
      maxUserAdjustmentMl,
    );
    final recommended = (baseline + weatherAdjustment + userAdjustment).clamp(
      UserSettings.minDailyGoalMl,
      UserSettings.maxDailyGoalMl,
    );

    return WeatherGoalDecision(
      baselineGoalMl: baseline,
      weatherAdjustmentMl: weatherAdjustment,
      userAdjustmentMl: userAdjustment,
      recommendedGoalMl: _roundToNearest50(recommended),
      explanation:
          'Baseline $baseline ml plus bounded weather adjustment $weatherAdjustment ml and user adjustment $userAdjustment ml.',
      eligible: true,
    );
  }

  bool shouldAskForDailyDecision({
    required DateTime now,
    required DateTime? lastDecisionAt,
  }) {
    if (lastDecisionAt == null) {
      return true;
    }
    return now.difference(lastDecisionAt) >= const Duration(hours: 24) ||
        !_sameLocalDay(now, lastDecisionAt);
  }

  bool _eligible(WeatherGoalInputs inputs) {
    return inputs.age != null &&
        inputs.sex != null &&
        inputs.sex != HydrionSex.preferNotToSay &&
        inputs.locationPermissionGranted &&
        inputs.notificationPermissionGranted;
  }

  int _roundToNearest50(int value) {
    return (value / 50).round() * 50;
  }

  bool _sameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

enum DailyWeatherGoalStatus {
  goalModeManual,
  onboardingRequired,
  legalAcknowledgementRequired,
  profileIncomplete,
  locationPermissionRequired,
  notificationPermissionRequired,
  locationUnavailable,
  weatherUnavailable,
  alreadyHandledToday,
  manualGoalChangedToday,
  promptReady,
  autoApplied,
}

class DailyWeatherGoalResult {
  final DailyWeatherGoalStatus status;
  final WeatherGoalDecision? decision;
  final WeatherSnapshot? forecast;
  final String? message;

  const DailyWeatherGoalResult({
    required this.status,
    this.decision,
    this.forecast,
    this.message,
  });
}

class DailyWeatherGoalCoordinator {
  final UserSettingsRepository _settingsRepository;
  final HydrionLocationService _locationService;
  final WeatherForecastService _weatherService;
  final NotificationService _notificationService;
  final DeterministicWeatherGoalService _goalService;

  const DailyWeatherGoalCoordinator({
    required UserSettingsRepository settingsRepository,
    required HydrionLocationService locationService,
    required WeatherForecastService weatherService,
    required NotificationService notificationService,
    DeterministicWeatherGoalService goalService =
        const DeterministicWeatherGoalService(),
  })  : _settingsRepository = settingsRepository,
        _locationService = locationService,
        _weatherService = weatherService,
        _notificationService = notificationService,
        _goalService = goalService;

  Future<DailyWeatherGoalResult> evaluate({
    DateTime? now,
    bool requestLocationPermission = false,
    bool requestNotificationPermission = false,
  }) async {
    final currentTime = now ?? DateTime.now();
    final localDateKey = WeatherForecastService._localDateKey(currentTime);
    var settings = _settingsRepository.settings;

    if (settings.goalMode != HydrionGoalMode.weatherInformed) {
      return const DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.goalModeManual,
      );
    }
    if (!settings.onboardingCompleted) {
      return const DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.onboardingRequired,
      );
    }
    if (!settings.legalAndHealthAcknowledged) {
      return const DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.legalAcknowledgementRequired,
      );
    }
    if (settings.age == null ||
        settings.sex == null ||
        settings.sex == HydrionSex.preferNotToSay) {
      return const DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.profileIncomplete,
      );
    }
    if (settings.lastWeatherGoalLocalDate == localDateKey) {
      return DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.alreadyHandledToday,
        message: settings.lastWeatherGoalExplanation,
      );
    }
    if (_sameLocalDay(settings.lastManualGoalEditAt, currentTime) &&
        !settings.weatherAdjustedGoalActive) {
      return const DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.manualGoalChangedToday,
        message:
            'Manual goal was edited today, so Hydrion will not replace it silently.',
      );
    }

    final locationPermission = await _ensureLocationPermission(
      currentTime,
      requestPermission: requestLocationPermission,
    );
    settings = _settingsRepository.settings;
    if (locationPermission != HydrionLocationPermissionState.granted) {
      return DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.locationPermissionRequired,
        message: locationPermission.name,
      );
    }

    final notificationPermission = await _ensureNotificationPermission(
      currentTime,
      requestPermission: requestNotificationPermission,
    );
    settings = _settingsRepository.settings;
    if (notificationPermission != HydrionNotificationPermissionState.granted) {
      return DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.notificationPermissionRequired,
        message: notificationPermission.name,
      );
    }

    final location = await _locationService.getCurrentLocation();
    if (!location.isSuccess || location.coordinates == null) {
      return DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.locationUnavailable,
        message: location.status.name,
      );
    }

    final forecastResult = await _weatherService.getDailyForecast(
      coordinates: location.coordinates!,
      now: currentTime,
    );
    if (!forecastResult.isSuccess || forecastResult.forecast == null) {
      return DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.weatherUnavailable,
        forecast: forecastResult.forecast,
        message: forecastResult.status.name,
      );
    }

    final decision = _goalService.recommend(
      WeatherGoalInputs(
        baselineGoalMl: settings.baselineDailyGoalMl,
        age: settings.age,
        sex: settings.sex,
        weather: forecastResult.forecast!,
        locationPermissionGranted: true,
        notificationPermissionGranted: true,
      ),
    );

    if (settings.weatherGoalAutoApplyEnabled &&
        !settings.weatherGoalDailyConfirmationEnabled) {
      await _settingsRepository.applyWeatherGoal(
        goalMl: decision.recommendedGoalMl,
        decidedAt: currentTime,
        explanation: decision.explanation,
        localDateKey: localDateKey,
        autoApplyEnabled: true,
      );
      return DailyWeatherGoalResult(
        status: DailyWeatherGoalStatus.autoApplied,
        decision: decision,
        forecast: forecastResult.forecast,
      );
    }

    return DailyWeatherGoalResult(
      status: DailyWeatherGoalStatus.promptReady,
      decision: decision,
      forecast: forecastResult.forecast,
    );
  }

  Future<void> acceptRecommendation({
    required WeatherGoalDecision decision,
    DateTime? now,
    bool doNotAskEachDay = false,
  }) async {
    final currentTime = now ?? DateTime.now();
    await _settingsRepository.applyWeatherGoal(
      goalMl: decision.recommendedGoalMl,
      decidedAt: currentTime,
      explanation: decision.explanation,
      localDateKey: WeatherForecastService._localDateKey(currentTime),
      autoApplyEnabled: doNotAskEachDay,
    );
    if (doNotAskEachDay) {
      await _settingsRepository.setWeatherGoalDailyConfirmationEnabled(false);
    }
  }

  Future<void> keepPreviousGoal({
    required String explanation,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    return _settingsRepository.keepPreviousWeatherGoal(
      decidedAt: currentTime,
      localDateKey: WeatherForecastService._localDateKey(currentTime),
      explanation: explanation,
    );
  }

  Future<HydrionLocationPermissionState> _ensureLocationPermission(
    DateTime now, {
    required bool requestPermission,
  }) async {
    final current = await _locationService.checkPermission();
    if (current == HydrionLocationPermissionState.granted ||
        !requestPermission ||
        _sameLocalDay(
          _settingsRepository.settings.locationPermissionPromptedAt,
          now,
        )) {
      return current;
    }
    await _settingsRepository.recordLocationPermissionPrompt(now);
    return _locationService.requestPermission();
  }

  Future<HydrionNotificationPermissionState> _ensureNotificationPermission(
    DateTime now, {
    required bool requestPermission,
  }) async {
    final current = await _notificationService.checkPermission();
    if (current == HydrionNotificationPermissionState.granted ||
        !requestPermission ||
        _sameLocalDay(
          _settingsRepository.settings.notificationPermissionPromptedAt,
          now,
        )) {
      return current;
    }
    await _settingsRepository.recordNotificationPermissionPrompt(now);
    return _notificationService.requestPermission();
  }

  bool _sameLocalDay(DateTime? a, DateTime b) {
    if (a == null) {
      return false;
    }
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }
}
