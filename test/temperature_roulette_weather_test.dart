import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/temperature_roulette.dart';
import 'package:hydrion/services/weather_goal_service.dart';

WeatherSnapshot _forecast(double temperatureC) => WeatherSnapshot(
      temperatureC: temperatureC,
      humidityPercent: 60,
      uvIndex: 2,
      observedAt: DateTime(2026, 7, 24, 12),
      condition: 'Clear',
    );

void main() {
  const standard = [
    'Room temperature',
    'Cool',
    'Comfortably warm',
    'Room temperature',
    'Cool',
  ];

  test('hot weather overrides room-temperature standard with Cool', () {
    final plan = TemperatureRoulettePlanner.plan(
      standardSchedule: standard,
      weatherEnabled: true,
      forecast: _forecast(29),
    );
    expect(plan.schedule.first, 'Cool');
    expect(plan.source, TemperatureAssignmentSource.weatherRecommendation);
    expect(plan.explanation, contains('replacing'));
  });

  test('cold weather overrides a Cool standard with comfortably warm', () {
    final plan = TemperatureRoulettePlanner.plan(
      standardSchedule: const [
        'Cool',
        'Room temperature',
        'Comfortably warm',
      ],
      weatherEnabled: true,
      forecast: _forecast(4),
    );
    expect(plan.schedule.first, 'Comfortably warm');
    expect(plan.source, TemperatureAssignmentSource.weatherRecommendation);
  });

  test('unavailable and disabled weather preserve standard rotation', () {
    final unavailable = TemperatureRoulettePlanner.plan(
      standardSchedule: standard,
      weatherEnabled: true,
    );
    final disabled = TemperatureRoulettePlanner.plan(
      standardSchedule: standard,
      weatherEnabled: false,
      forecast: _forecast(30),
    );
    expect(unavailable.schedule, standard);
    expect(
      unavailable.source,
      TemperatureAssignmentSource.weatherUnavailableFallback,
    );
    expect(disabled.schedule, standard);
    expect(disabled.source, TemperatureAssignmentSource.weatherDisabled);
  });

  test('matching weather is distinguished from a true override', () {
    final plan = TemperatureRoulettePlanner.plan(
      standardSchedule: const ['Cool', 'Room temperature'],
      weatherEnabled: true,
      forecast: _forecast(30),
    );
    expect(plan.source, TemperatureAssignmentSource.weatherMatchedStandard);
    expect(plan.explanation, contains('already matched'));
  });
}
