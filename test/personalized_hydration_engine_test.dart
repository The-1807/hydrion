import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/domain/hydration_recommendation.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/personalized_hydration_engine.dart';
import 'package:hydrion/services/weather_goal_service.dart';

void main() {
  const engine = PersonalizedHydrationEngine();
  final now = DateTime(2026, 7, 28, 12);

  PersonalizedHydrationInputs inputs({
    int baseline = 2200,
    HydrationBaselineSource source = HydrationBaselineSource.personalized,
    int? age = 30,
    HydrionSex? sex = HydrionSex.female,
    HydrionBodyMetrics metrics = const HydrionBodyMetrics(
      personalizationEnabled: true,
      weightKg: 70,
      heightCm: 170,
    ),
    DailyHydrationContext? context,
    WeatherSnapshot? weather,
    bool weatherEnabled = false,
    bool permission = true,
    bool cached = false,
  }) {
    return PersonalizedHydrationInputs(
      existingBaselineGoalMl: baseline,
      requestedBaselineSource: source,
      age: age,
      sex: sex,
      bodyMetrics: metrics,
      dailyContext: context,
      weather: weather,
      weatherEnabled: weatherEnabled,
      locationPermissionGranted: permission,
      cachedWeatherUsed: cached,
      localDateKey: '2026-07-28',
      calculatedAt: now,
    );
  }

  group('body metrics and BMI', () {
    test('canonical conversions do not drift across repeated display switches',
        () {
      const original = 73.4;
      var canonical = original;
      for (var i = 0; i < 100; i++) {
        final pounds = HydrionBodyMetricsPolicy.kilogramsToPounds(canonical);
        canonical = HydrionBodyMetricsPolicy.poundsToKilograms(pounds);
      }
      expect(canonical, closeTo(original, 1e-10));

      const centimetres = 181.5;
      final inches = HydrionBodyMetricsPolicy.centimetresToInches(centimetres);
      expect(
        HydrionBodyMetricsPolicy.inchesToCentimetres(inches),
        closeTo(centimetres, 1e-10),
      );
    });

    test('validation accepts boundaries and rejects invalid finite values', () {
      expect(HydrionBodyMetricsPolicy.validWeight(25), isTrue);
      expect(HydrionBodyMetricsPolicy.validWeight(300), isTrue);
      expect(HydrionBodyMetricsPolicy.validWeight(24.9), isFalse);
      expect(HydrionBodyMetricsPolicy.validWeight(300.1), isFalse);
      expect(HydrionBodyMetricsPolicy.validWeight(double.nan), isFalse);
      expect(HydrionBodyMetricsPolicy.validWeight(double.infinity), isFalse);
      expect(HydrionBodyMetricsPolicy.validHeight(120), isTrue);
      expect(HydrionBodyMetricsPolicy.validHeight(230), isTrue);
      expect(HydrionBodyMetricsPolicy.validHeight(119.9), isFalse);
      expect(HydrionBodyMetricsPolicy.validHeight(230.1), isFalse);
    });

    test('BMI formula and adult category boundaries are deterministic', () {
      const metrics = HydrionBodyMetrics(weightKg: 70, heightCm: 175);
      expect(metrics.adultBmi, closeTo(22.857, 0.001));
      expect(metrics.adultBmi!.toStringAsFixed(1), '22.9');
      expect(
        adultBmiCategory(age: 20, bmi: 18.4),
        HydrionAdultBmiCategory.belowStandardRange,
      );
      expect(
        adultBmiCategory(age: 20, bmi: 18.5),
        HydrionAdultBmiCategory.standardRange,
      );
      expect(
        adultBmiCategory(age: 20, bmi: 24.9),
        HydrionAdultBmiCategory.standardRange,
      );
      expect(
        adultBmiCategory(age: 20, bmi: 25),
        HydrionAdultBmiCategory.aboveStandardRange,
      );
      expect(
        adultBmiCategory(age: 20, bmi: 29.9),
        HydrionAdultBmiCategory.aboveStandardRange,
      );
      expect(
        adultBmiCategory(age: 20, bmi: 30),
        HydrionAdultBmiCategory.higherStandardRange,
      );
      expect(adultBmiCategory(age: 19, bmi: 30), isNull);
      expect(const HydrionBodyMetrics(weightKg: 70).adultBmi, isNull);
      expect(const HydrionBodyMetrics(heightCm: 170).adultBmi, isNull);
    });

    test('malformed JSON cannot invent believable measurements', () {
      final metrics = HydrionBodyMetrics.fromJson(jsonDecode(
        '{"schemaVersion":1,"personalizationEnabled":true,'
        '"weightKg":"heavy","heightCm":0}',
      ));
      expect(metrics.weightKg, isNull);
      expect(metrics.heightCm, isNull);
      expect(metrics.adultBmi, isNull);
    });
  });

  group('personalized baseline', () {
    test('uses bounded calculation weight and nearest-50 rounding', () {
      final result = engine.calculate(inputs());
      expect(result.calculationWeightKg, 70);
      expect(result.baselineGoalMl, 2100);
      expect(result.bodyMetricsAdjustmentMl, -100);
    });

    test('applies 40 kg floor and 1500 ml baseline floor', () {
      final result = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 25,
          heightCm: 170,
        ),
      ));
      expect(result.calculationWeightKg, 40);
      expect(result.baselineGoalMl, 1500);
    });

    test('applies height cap, 100 kg ceiling, and 3000 ml ceiling', () {
      final heightCapped = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 200,
          heightCm: 150,
        ),
      ));
      expect(heightCapped.calculationWeightKg, closeTo(67.5, 0.001));
      expect(heightCapped.baselineGoalMl, 2050);

      final absoluteCapped = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 300,
          heightCm: 230,
        ),
      ));
      expect(absoluteCapped.calculationWeightKg, 100);
      expect(absoluteCapped.baselineGoalMl, 3000);
    });

    test('under-20 and missing metrics preserve existing baseline', () {
      final underTwenty = engine.calculate(inputs(age: 19));
      expect(underTwenty.baselineGoalMl, 2200);
      expect(underTwenty.skippedFactors,
          contains(HydrationFactorCode.underTwenty));

      final missing = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(personalizationEnabled: true),
      ));
      expect(missing.baselineGoalMl, 2200);
      expect(
        missing.skippedFactors,
        contains(HydrationFactorCode.missingBodyMetrics),
      );
    });

    test('manual source is preserved even when metrics exist', () {
      final result =
          engine.calculate(inputs(source: HydrationBaselineSource.manual));
      expect(result.baselineGoalMl, 2200);
      expect(result.baselineSource, HydrationBaselineSource.manual);
    });

    test('BMI category never directly changes the target', () {
      final lowerBmi = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 90,
          heightCm: 200,
        ),
      ));
      final higherBmi = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 90,
          heightCm: 160,
        ),
      ));
      expect(lowerBmi.calculationWeightKg, 90);
      expect(higherBmi.calculationWeightKg, closeTo(76.8, 0.001));
      expect(higherBmi.baselineGoalMl, lessThan(lowerBmi.baselineGoalMl));
    });
  });

  group('reproductive and activity modifiers', () {
    test('female explicit states add only their bounded adjustment', () {
      final pregnant = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 70,
          heightCm: 170,
          reproductiveState: HydrionReproductiveHydrationState.pregnant,
        ),
      ));
      expect(pregnant.reproductiveAdjustmentMl, 300);

      final lactating = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 70,
          heightCm: 170,
          reproductiveState: HydrionReproductiveHydrationState.lactating,
        ),
      ));
      expect(lactating.reproductiveAdjustmentMl, 700);
    });

    test('pregnancy duration never changes the fixed adjustment', () {
      for (final days in [1, 84, 168, 294]) {
        final result = engine.calculate(inputs(
          metrics: HydrionBodyMetrics(
            personalizationEnabled: true,
            weightKg: 70,
            heightCm: 170,
            reproductiveState: HydrionReproductiveHydrationState.pregnant,
            pregnancyGestationalDays: days,
          ),
        ));
        expect(result.reproductiveAdjustmentMl, 300, reason: '$days days');
        expect(result.baselineGoalMl, 2100, reason: '$days days');
      }
    });

    test('non-female profiles ignore incompatible persisted state', () {
      for (final sex in [
        HydrionSex.male,
        HydrionSex.intersex,
        HydrionSex.preferNotToSay,
      ]) {
        final result = engine.calculate(inputs(
          sex: sex,
          metrics: const HydrionBodyMetrics(
            personalizationEnabled: true,
            weightKg: 70,
            heightCm: 170,
            reproductiveState: HydrionReproductiveHydrationState.pregnant,
          ),
        ));
        expect(result.reproductiveAdjustmentMl, 0);
      }
    });

    test('activity duration boundaries and sweat cap are exact', () {
      int adjustment(HydrionActivityIntensity intensity, int minutes,
          [HydrionSweatLevel sweat = HydrionSweatLevel.unknown]) {
        return engine
            .calculate(inputs(
              context: DailyHydrationContext(
                localDateKey: '2026-07-28',
                activityIntensity: intensity,
                activityMinutes: minutes,
                sweatLevel: sweat,
                updatedAt: now,
              ),
            ))
            .activityAdjustmentMl;
      }

      expect(adjustment(HydrionActivityIntensity.moderate, 29), 0);
      expect(adjustment(HydrionActivityIntensity.moderate, 30), 250);
      expect(adjustment(HydrionActivityIntensity.moderate, 59), 250);
      expect(adjustment(HydrionActivityIntensity.moderate, 60), 500);
      expect(adjustment(HydrionActivityIntensity.moderate, 119), 500);
      expect(adjustment(HydrionActivityIntensity.moderate, 120), 500);
      expect(adjustment(HydrionActivityIntensity.vigorous, 30), 500);
      expect(adjustment(HydrionActivityIntensity.vigorous, 60), 750);
      expect(
        adjustment(
          HydrionActivityIntensity.vigorous,
          120,
          HydrionSweatLevel.high,
        ),
        750,
      );
    });
  });

  group('weather and safety', () {
    WeatherSnapshot weather({
      double temperature = 30,
      double? apparent,
      double? humidity,
      double uv = 0,
    }) =>
        WeatherSnapshot(
          temperatureC: temperature,
          apparentTemperatureC: apparent,
          humidityPercent: humidity,
          uvIndex: uv,
          observedAt: now,
        );

    DailyHydrationContext context(
      HydrionEnvironmentExposure exposure, {
      HydrionTemporaryCondition condition = HydrionTemporaryCondition.none,
    }) =>
        DailyHydrationContext(
          localDateKey: '2026-07-28',
          environment: exposure,
          temporaryCondition: condition,
          updatedAt: now,
        );

    test('apparent temperature prevents humidity double counting', () {
      final apparent = engine.calculate(inputs(
        weatherEnabled: true,
        weather: weather(apparent: 30, humidity: 90),
        context: context(HydrionEnvironmentExposure.mostlyOutdoors),
      ));
      expect(apparent.weatherAdjustmentMl, 300);

      final fallback = engine.calculate(inputs(
        weatherEnabled: true,
        weather: weather(humidity: 90),
        context: context(HydrionEnvironmentExposure.mostlyOutdoors),
      ));
      expect(fallback.weatherAdjustmentMl, 400);
    });

    test('exposure scales weather at zero, half, and full', () {
      int result(HydrionEnvironmentExposure exposure) => engine
          .calculate(inputs(
            weatherEnabled: true,
            weather: weather(apparent: 35),
            context: context(exposure),
          ))
          .weatherAdjustmentMl;
      expect(result(HydrionEnvironmentExposure.mostlyIndoors), 0);
      expect(result(HydrionEnvironmentExposure.mixed), 250);
      expect(result(HydrionEnvironmentExposure.mostlyOutdoors), 450);
    });

    test('cold weather never reduces baseline or final recommendation', () {
      for (final temperature in [-20.0, 0.0, 25.9]) {
        for (final exposure in [
          HydrionEnvironmentExposure.mixed,
          HydrionEnvironmentExposure.mostlyOutdoors,
        ]) {
          final result = engine.calculate(inputs(
            weatherEnabled: true,
            weather: weather(temperature: temperature),
            context: context(exposure),
          ));
          expect(result.weatherAdjustmentMl, 0);
          expect(
            result.roundedRecommendedGoalMl,
            greaterThanOrEqualTo(result.baselineGoalMl),
          );
        }
      }
    });

    test('weather denial and unavailable data preserve baseline', () {
      final denied = engine.calculate(inputs(
        weatherEnabled: true,
        permission: false,
        weather: weather(),
        context: context(HydrionEnvironmentExposure.mostlyOutdoors),
      ));
      expect(denied.weatherAdjustmentMl, 0);
      expect(
        denied.skippedFactors,
        contains(HydrationFactorCode.weatherPermissionDenied),
      );
      final missing = engine.calculate(inputs(
        weatherEnabled: true,
        weather: null,
        context: context(HydrionEnvironmentExposure.mostlyOutdoors),
      ));
      expect(missing.weatherAdjustmentMl, 0);
    });

    test('illness adds guidance but no precise illness adjustment', () {
      final normal = engine.calculate(inputs(
        context: context(HydrionEnvironmentExposure.mostlyIndoors),
      ));
      final fever = engine.calculate(inputs(
        context: context(
          HydrionEnvironmentExposure.mostlyIndoors,
          condition: HydrionTemporaryCondition.fever,
        ),
      ));
      expect(fever.roundedRecommendedGoalMl, normal.roundedRecommendedGoalMl);
      expect(
        fever.safetyNotices,
        contains(HydrationFactorCode.illnessGuidance),
      );
      expect(fever.mayAutoApply, isFalse);
    });

    test('clinician target overrides factors unless explicitly allowed', () {
      final protected = engine.calculate(inputs(
        weatherEnabled: true,
        weather: weather(apparent: 35),
        context: context(HydrionEnvironmentExposure.mostlyOutdoors),
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 70,
          heightCm: 170,
          fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
          clinicianTargetMl: 1800,
        ),
      ));
      expect(protected.roundedRecommendedGoalMl, 1800);
      expect(protected.clinicianTargetOverrodeFactors, isTrue);

      final allowed = engine.calculate(inputs(
        context: DailyHydrationContext(
          localDateKey: '2026-07-28',
          activityIntensity: HydrionActivityIntensity.moderate,
          activityMinutes: 30,
          updatedAt: now,
        ),
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 70,
          heightCm: 170,
          fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
          clinicianTargetMl: 1800,
          allowAdjustmentsAboveClinicianTarget: true,
        ),
      ));
      expect(allowed.roundedRecommendedGoalMl, 2050);
    });

    test(
      'clinician-governed target is never auto-applicable, even without '
      'fluid restriction or a temporary condition',
      () {
        final protectedNoStacking = engine.calculate(inputs(
          metrics: const HydrionBodyMetrics(
            personalizationEnabled: true,
            weightKg: 70,
            heightCm: 170,
            fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
            clinicianTargetMl: 1800,
          ),
        ));
        expect(protectedNoStacking.mayAutoApply, isFalse);

        // Domain safety must hold even when adjustments are explicitly
        // allowed to stack above the clinician target — auto-apply is
        // never solely the user's/UI's decision to make for this mode.
        final protectedWithStacking = engine.calculate(inputs(
          context: DailyHydrationContext(
            localDateKey: '2026-07-28',
            activityIntensity: HydrionActivityIntensity.moderate,
            activityMinutes: 30,
            updatedAt: now,
          ),
          metrics: const HydrionBodyMetrics(
            personalizationEnabled: true,
            weightKg: 70,
            heightCm: 170,
            fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
            clinicianTargetMl: 1800,
            allowAdjustmentsAboveClinicianTarget: true,
          ),
        ));
        expect(protectedWithStacking.mayAutoApply, isFalse);
      },
    );

    test('unsure fluid safety mode disables automatic application', () {
      final result = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 70,
          heightCm: 170,
          fluidSafetyMode: HydrionFluidSafetyMode.unsure,
        ),
      ));
      expect(result.mayAutoApply, isFalse);
    });

    test(
      'a safe personalized recommendation with no clinician/fluid/illness '
      'factors may auto-apply',
      () {
        final result = engine.calculate(inputs(
          weatherEnabled: true,
          weather: weather(apparent: 32),
          context: context(HydrionEnvironmentExposure.mostlyOutdoors),
        ));
        expect(result.mayAutoApply, isTrue);
      },
    );

    test('fluid restriction disables automatic application', () {
      final result = engine.calculate(inputs(
        metrics: const HydrionBodyMetrics(
          personalizationEnabled: true,
          weightKg: 70,
          heightCm: 170,
          fluidSafetyMode: HydrionFluidSafetyMode.fluidRestrictionWithoutTarget,
        ),
      ));
      expect(result.mayAutoApply, isFalse);
      expect(
        result.safetyNotices,
        contains(HydrationFactorCode.fluidRestriction),
      );
    });
  });
}
