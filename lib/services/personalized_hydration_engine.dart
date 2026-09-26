import 'dart:math' as math;

import '../domain/body_metrics.dart';
import '../domain/daily_hydration_context.dart';
import '../domain/hydration_recommendation.dart';
import '../repositories/settings_repository.dart';
import 'weather_goal_service.dart';

class PersonalizedHydrationPolicy {
  static const personalizedMlPerKg = 30;
  static const minCalculationWeightKg = 40.0;
  static const maxCalculationWeightKg = 100.0;
  static const heightWeightCapBmi = 30.0;
  static const minPersonalizedBaselineMl = 1500;
  static const maxPersonalizedBaselineMl = 3000;
  static const maxActivityAdjustmentMl = 750;
  static const maxWeatherAdjustmentMl = 600;
  static const pregnancyAdjustmentMl = 300;
  static const lactationAdjustmentMl = 700;
  static const minFinalGoalMl = 500;
  static const maxFinalGoalMl = 5000;

  const PersonalizedHydrationPolicy._();

  static int roundTo50(num value) => (value / 50).round() * 50;
}

class PersonalizedHydrationInputs {
  final int existingBaselineGoalMl;
  final HydrationBaselineSource requestedBaselineSource;
  final int? age;
  final HydrionSex? sex;
  final HydrionBodyMetrics bodyMetrics;
  final DailyHydrationContext? dailyContext;
  final WeatherSnapshot? weather;
  final bool weatherEnabled;
  final bool locationPermissionGranted;
  final bool cachedWeatherUsed;
  final String localDateKey;
  final DateTime calculatedAt;

  const PersonalizedHydrationInputs({
    required this.existingBaselineGoalMl,
    required this.requestedBaselineSource,
    required this.age,
    required this.sex,
    required this.bodyMetrics,
    required this.dailyContext,
    required this.weather,
    required this.weatherEnabled,
    required this.locationPermissionGranted,
    required this.cachedWeatherUsed,
    required this.localDateKey,
    required this.calculatedAt,
  });
}

class PersonalizedHydrationEngine {
  const PersonalizedHydrationEngine();

  HydrationRecommendation calculate(PersonalizedHydrationInputs inputs) {
    final applied = <HydrationFactorCode>[];
    final skipped = <HydrationFactorCode>[];
    final safety = <HydrationFactorCode>[];
    final manualBaseline = inputs.existingBaselineGoalMl.clamp(
      PersonalizedHydrationPolicy.minFinalGoalMl,
      PersonalizedHydrationPolicy.maxFinalGoalMl,
    );

    var baseline = manualBaseline;
    var baselineSource = HydrationBaselineSource.manual;
    double? calculationWeight;
    var bodyAdjustment = 0;

    final personalizedRequested = inputs.requestedBaselineSource ==
            HydrationBaselineSource.personalized &&
        inputs.bodyMetrics.personalizationEnabled;
    if (personalizedRequested &&
        (inputs.age ?? -1) >= 20 &&
        inputs.bodyMetrics.hasValidMeasurements) {
      final heightMetres = inputs.bodyMetrics.heightCm! / 100;
      final heightCap = PersonalizedHydrationPolicy.heightWeightCapBmi *
          heightMetres *
          heightMetres;
      calculationWeight = math.min(
        inputs.bodyMetrics.weightKg!,
        math.min(heightCap, PersonalizedHydrationPolicy.maxCalculationWeightKg),
      );
      calculationWeight = math.max(
        calculationWeight,
        PersonalizedHydrationPolicy.minCalculationWeightKg,
      );
      baseline = PersonalizedHydrationPolicy.roundTo50(
        calculationWeight * PersonalizedHydrationPolicy.personalizedMlPerKg,
      ).clamp(
        PersonalizedHydrationPolicy.minPersonalizedBaselineMl,
        PersonalizedHydrationPolicy.maxPersonalizedBaselineMl,
      );
      bodyAdjustment = baseline - manualBaseline;
      baselineSource = HydrationBaselineSource.personalized;
      applied.add(HydrationFactorCode.personalizedBaseline);
    } else {
      applied.add(HydrationFactorCode.manualBaseline);
      if (personalizedRequested && (inputs.age ?? -1) < 20) {
        skipped.add(HydrationFactorCode.underTwenty);
      } else if (personalizedRequested) {
        skipped.add(HydrationFactorCode.missingBodyMetrics);
      }
    }

    final reproductiveAdjustment =
        _reproductiveAdjustment(inputs, applied, skipped);
    final activityAdjustment =
        _activityAdjustment(inputs.dailyContext, applied);
    final weatherAdjustment = _weatherAdjustment(inputs, applied, skipped);
    final userAdjustment = inputs.dailyContext?.userAdjustmentMl ?? 0;
    if (userAdjustment != 0) applied.add(HydrationFactorCode.userAdjustment);

    final condition = inputs.dailyContext?.temporaryCondition ??
        HydrionTemporaryCondition.none;
    if (condition != HydrionTemporaryCondition.none &&
        condition != HydrionTemporaryCondition.preferNotToSay) {
      safety.add(HydrationFactorCode.illnessGuidance);
    }

    final metrics = inputs.bodyMetrics;
    var clinicianOverride = false;
    int finalGoal;
    if (metrics.fluidSafetyMode == HydrionFluidSafetyMode.clinicianTarget &&
        metrics.clinicianTargetMl != null) {
      finalGoal = metrics.clinicianTargetMl!;
      if (metrics.allowAdjustmentsAboveClinicianTarget) {
        finalGoal += reproductiveAdjustment +
            activityAdjustment +
            weatherAdjustment +
            userAdjustment;
      }
      clinicianOverride = true;
      applied.add(HydrationFactorCode.clinicianTarget);
      safety.add(HydrationFactorCode.clinicianTarget);
    } else {
      finalGoal = baseline +
          reproductiveAdjustment +
          activityAdjustment +
          weatherAdjustment +
          userAdjustment;
      if (metrics.fluidSafetyMode ==
              HydrionFluidSafetyMode.fluidRestrictionWithoutTarget ||
          metrics.fluidSafetyMode == HydrionFluidSafetyMode.unsure) {
        safety.add(HydrationFactorCode.fluidRestriction);
      }
    }
    final bounded = finalGoal.clamp(
      PersonalizedHydrationPolicy.minFinalGoalMl,
      PersonalizedHydrationPolicy.maxFinalGoalMl,
    );
    if (bounded != finalGoal) applied.add(HydrationFactorCode.finalClamp);
    final rounded = PersonalizedHydrationPolicy.roundTo50(bounded).clamp(
      PersonalizedHydrationPolicy.minFinalGoalMl,
      PersonalizedHydrationPolicy.maxFinalGoalMl,
    );

    final restricted = metrics.fluidSafetyMode ==
            HydrionFluidSafetyMode.fluidRestrictionWithoutTarget ||
        metrics.fluidSafetyMode == HydrionFluidSafetyMode.unsure;
    // A clinician-governed target must never be silently auto-applied,
    // regardless of whether allowAdjustmentsAboveClinicianTarget is set.
    final clinicianGoverned =
        metrics.fluidSafetyMode == HydrionFluidSafetyMode.clinicianTarget;
    final confidence = clinicianOverride
        ? HydrationRecommendationConfidence.clinicianSet
        : weatherAdjustment != 0
            ? HydrationRecommendationConfidence.weatherInformed
            : inputs.dailyContext != null &&
                    (activityAdjustment != 0 || userAdjustment != 0)
                ? HydrationRecommendationConfidence.dailyContextInformed
                : baselineSource == HydrationBaselineSource.personalized
                    ? HydrationRecommendationConfidence.profileInformed
                    : HydrationRecommendationConfidence.manual;

    return HydrationRecommendation(
      baselineGoalMl: baseline,
      baselineSource: baselineSource,
      calculationWeightKg: calculationWeight,
      bodyMetricsAdjustmentMl: bodyAdjustment,
      reproductiveAdjustmentMl: reproductiveAdjustment,
      activityAdjustmentMl: activityAdjustment,
      weatherAdjustmentMl: weatherAdjustment,
      userAdjustmentMl: userAdjustment,
      clinicianTargetMl: metrics.clinicianTargetMl,
      finalRecommendedGoalMl: bounded,
      roundedRecommendedGoalMl: rounded,
      confidenceLevel: confidence,
      localDateKey: inputs.localDateKey,
      calculatedAt: inputs.calculatedAt,
      appliedFactors: List.unmodifiable(applied),
      skippedFactors: List.unmodifiable(skipped),
      safetyNotices: List.unmodifiable(safety),
      mayAutoApply: !restricted &&
          !clinicianGoverned &&
          condition == HydrionTemporaryCondition.none,
      userConfirmationRequired: true,
      weatherUsed: weatherAdjustment != 0,
      cachedWeatherUsed: inputs.cachedWeatherUsed && weatherAdjustment != 0,
      clinicianTargetOverrodeFactors: clinicianOverride,
    );
  }

  int _reproductiveAdjustment(
    PersonalizedHydrationInputs inputs,
    List<HydrationFactorCode> applied,
    List<HydrationFactorCode> skipped,
  ) {
    if (inputs.sex != HydrionSex.female) {
      if (inputs.bodyMetrics.reproductiveState !=
          HydrionReproductiveHydrationState.none) {
        skipped.add(HydrationFactorCode.reproductiveIneligible);
      }
      return 0;
    }
    return switch (inputs.bodyMetrics.reproductiveState) {
      HydrionReproductiveHydrationState.pregnant => () {
          applied.add(HydrationFactorCode.reproductivePregnant);
          return PersonalizedHydrationPolicy.pregnancyAdjustmentMl;
        }(),
      HydrionReproductiveHydrationState.lactating => () {
          applied.add(HydrationFactorCode.reproductiveLactating);
          return PersonalizedHydrationPolicy.lactationAdjustmentMl;
        }(),
      HydrionReproductiveHydrationState.none => 0,
    };
  }

  int _activityAdjustment(
    DailyHydrationContext? context,
    List<HydrationFactorCode> applied,
  ) {
    if (context == null) return 0;
    final minutes = context.activityMinutes;
    var result = switch (context.activityIntensity) {
      HydrionActivityIntensity.moderate when minutes >= 60 => 500,
      HydrionActivityIntensity.moderate when minutes >= 30 => 250,
      HydrionActivityIntensity.vigorous when minutes >= 60 => 750,
      HydrionActivityIntensity.vigorous when minutes >= 30 => 500,
      _ => 0,
    };
    if (context.sweatLevel == HydrionSweatLevel.high &&
        (minutes >= 30 ||
            context.environment == HydrionEnvironmentExposure.mostlyOutdoors)) {
      result = (result + 250).clamp(
        0,
        PersonalizedHydrationPolicy.maxActivityAdjustmentMl,
      );
      applied.add(HydrationFactorCode.highSweat);
    }
    if (result != 0) applied.add(HydrationFactorCode.activity);
    return result;
  }

  int _weatherAdjustment(
    PersonalizedHydrationInputs inputs,
    List<HydrationFactorCode> applied,
    List<HydrationFactorCode> skipped,
  ) {
    if (!inputs.weatherEnabled) return 0;
    if (!inputs.locationPermissionGranted) {
      skipped.add(HydrationFactorCode.weatherPermissionDenied);
      return 0;
    }
    final weather = inputs.weather;
    if (weather == null) {
      skipped.add(HydrationFactorCode.weatherUnavailable);
      return 0;
    }
    final exposure = inputs.dailyContext?.environment ??
        HydrionEnvironmentExposure.mostlyIndoors;
    if (exposure == HydrionEnvironmentExposure.mostlyIndoors) {
      skipped.add(HydrationFactorCode.indoorWeatherSkipped);
      return 0;
    }
    final effective = weather.apparentTemperatureC ?? weather.temperatureC;
    var raw = switch (effective) {
      >= 35 => 450,
      >= 30 => 300,
      >= 26 => 150,
      _ => 0,
    };
    if (weather.apparentTemperatureC == null &&
        (weather.humidityPercent ?? 0) >= 70 &&
        effective >= 26) {
      raw += 100;
    }
    if (weather.uvIndex >= 8) raw += 100;
    raw = raw.clamp(
      0,
      PersonalizedHydrationPolicy.maxWeatherAdjustmentMl,
    );
    final multiplier = exposure == HydrionEnvironmentExposure.mixed ? 0.5 : 1.0;
    final result = PersonalizedHydrationPolicy.roundTo50(raw * multiplier);
    if (result != 0) applied.add(HydrationFactorCode.weather);
    return result;
  }
}
