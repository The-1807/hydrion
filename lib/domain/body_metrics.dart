import 'dart:math' as math;

enum HydrionWeightUnit { kilograms, pounds }

enum HydrionHeightUnit { centimetres, feetAndInches }

enum HydrionPregnancyDurationUnit {
  days,
  weeks,
  months,
}

enum HydrionReproductiveHydrationState {
  none,
  pregnant,
  lactating,
}

enum HydrionFluidSafetyMode {
  none,
  clinicianTarget,
  fluidRestrictionWithoutTarget,
  unsure,
}

class HydrionBodyMetricsPolicy {
  static const schemaVersion = 2;

  static const minWeightKg = 25.0;
  static const maxWeightKg = 300.0;

  static const minHeightCm = 120.0;
  static const maxHeightCm = 230.0;

  static const poundsPerKilogram = 2.2046226218;
  static const centimetresPerInch = 2.54;

  // Pregnancy duration is stored canonically as total gestational days.
  static const minPregnancyDays = 1;
  static const maxPregnancyDays = 294; // 42 weeks.

  static const minPregnancyWeeks = minPregnancyDays / daysPerWeek;
  static const maxPregnancyWeeks = 42.0;

  static const daysPerWeek = 7.0;
  static const averageDaysPerMonth = 30.436875;
  static const averageWeeksPerMonth = averageDaysPerMonth / daysPerWeek;

  const HydrionBodyMetricsPolicy._();

  static bool validWeight(double? value) =>
      value != null &&
      value.isFinite &&
      value >= minWeightKg &&
      value <= maxWeightKg;

  static bool validHeight(double? value) =>
      value != null &&
      value.isFinite &&
      value >= minHeightCm &&
      value <= maxHeightCm;

  static bool validPregnancyDays(int? value) =>
      value != null && value >= minPregnancyDays && value <= maxPregnancyDays;

  static bool validPregnancyWeeks(num? value) =>
      value != null &&
      value.isFinite &&
      value >= minPregnancyWeeks &&
      value <= maxPregnancyWeeks;

  static bool validPregnancyMonths(num? value) {
    if (value == null || !value.isFinite || value <= 0) {
      return false;
    }

    return validPregnancyDays(
      pregnancyMonthsToDays(value),
    );
  }

  static int pregnancyWeeksToDays(num weeks) => (weeks * daysPerWeek).round();

  static double pregnancyDaysToWeeks(int days) => days / daysPerWeek;

  static int pregnancyMonthsToDays(num months) =>
      (months * averageDaysPerMonth).round();

  static double pregnancyDaysToMonths(int days) => days / averageDaysPerMonth;

  static int pregnancyMonthsToWeeks(num months) =>
      (months * averageWeeksPerMonth).round();

  static double pregnancyWeeksToMonths(num weeks) =>
      weeks / averageWeeksPerMonth;

  static double kilogramsToPounds(double kilograms) =>
      kilograms * poundsPerKilogram;

  static double poundsToKilograms(double pounds) => pounds / poundsPerKilogram;

  static double inchesToCentimetres(double inches) =>
      inches * centimetresPerInch;

  static double centimetresToInches(double centimetres) =>
      centimetres / centimetresPerInch;
}

class HydrionBodyMetrics {
  final bool personalizationEnabled;

  final double? weightKg;
  final double? heightCm;

  final HydrionWeightUnit preferredWeightUnit;
  final HydrionHeightUnit preferredHeightUnit;

  final HydrionReproductiveHydrationState reproductiveState;

  /// Canonical pregnancy duration.
  ///
  /// This is only retained when [reproductiveState] is pregnant.
  final int? pregnancyGestationalDays;

  final HydrionPregnancyDurationUnit preferredPregnancyDurationUnit;

  final HydrionFluidSafetyMode fluidSafetyMode;
  final int? clinicianTargetMl;
  final bool allowAdjustmentsAboveClinicianTarget;

  final int? wakeMinuteOfDay;
  final int? sleepMinuteOfDay;

  final DateTime? updatedAt;
  final int schemaVersion;

  const HydrionBodyMetrics({
    this.personalizationEnabled = false,
    this.weightKg,
    this.heightCm,
    this.preferredWeightUnit = HydrionWeightUnit.kilograms,
    this.preferredHeightUnit = HydrionHeightUnit.centimetres,
    this.reproductiveState = HydrionReproductiveHydrationState.none,
    this.pregnancyGestationalDays,
    this.preferredPregnancyDurationUnit = HydrionPregnancyDurationUnit.weeks,
    this.fluidSafetyMode = HydrionFluidSafetyMode.none,
    this.clinicianTargetMl,
    this.allowAdjustmentsAboveClinicianTarget = false,
    this.wakeMinuteOfDay,
    this.sleepMinuteOfDay,
    this.updatedAt,
    this.schemaVersion = HydrionBodyMetricsPolicy.schemaVersion,
  });

  bool get hasValidMeasurements =>
      HydrionBodyMetricsPolicy.validWeight(weightKg) &&
      HydrionBodyMetricsPolicy.validHeight(heightCm);

  bool get hasValidPregnancyDuration =>
      reproductiveState == HydrionReproductiveHydrationState.pregnant &&
      HydrionBodyMetricsPolicy.validPregnancyDays(
        pregnancyGestationalDays,
      );

  double? get pregnancyGestationalWeeks {
    final days = pregnancyGestationalDays;

    if (!HydrionBodyMetricsPolicy.validPregnancyDays(days)) {
      return null;
    }

    return HydrionBodyMetricsPolicy.pregnancyDaysToWeeks(
      days!,
    );
  }

  double? get pregnancyGestationalMonths {
    final days = pregnancyGestationalDays;

    if (!HydrionBodyMetricsPolicy.validPregnancyDays(days)) {
      return null;
    }

    return HydrionBodyMetricsPolicy.pregnancyDaysToMonths(
      days!,
    );
  }

  double? get adultBmi {
    if (!hasValidMeasurements) {
      return null;
    }

    final metres = heightCm! / 100;
    final value = weightKg! / (metres * metres);

    return value.isFinite ? value : null;
  }

  HydrionBodyMetrics copyWith({
    bool? personalizationEnabled,
    double? weightKg,
    bool clearWeight = false,
    double? heightCm,
    bool clearHeight = false,
    HydrionWeightUnit? preferredWeightUnit,
    HydrionHeightUnit? preferredHeightUnit,
    HydrionReproductiveHydrationState? reproductiveState,
    int? pregnancyGestationalDays,
    bool clearPregnancyDuration = false,
    HydrionPregnancyDurationUnit? preferredPregnancyDurationUnit,
    HydrionFluidSafetyMode? fluidSafetyMode,
    int? clinicianTargetMl,
    bool clearClinicianTarget = false,
    bool? allowAdjustmentsAboveClinicianTarget,
    int? wakeMinuteOfDay,
    bool clearWakeTime = false,
    int? sleepMinuteOfDay,
    bool clearSleepTime = false,
    DateTime? updatedAt,
  }) {
    return HydrionBodyMetrics(
      personalizationEnabled:
          personalizationEnabled ?? this.personalizationEnabled,
      weightKg: clearWeight ? null : weightKg ?? this.weightKg,
      heightCm: clearHeight ? null : heightCm ?? this.heightCm,
      preferredWeightUnit: preferredWeightUnit ?? this.preferredWeightUnit,
      preferredHeightUnit: preferredHeightUnit ?? this.preferredHeightUnit,
      reproductiveState: reproductiveState ?? this.reproductiveState,
      pregnancyGestationalDays: clearPregnancyDuration
          ? null
          : pregnancyGestationalDays ?? this.pregnancyGestationalDays,
      preferredPregnancyDurationUnit:
          preferredPregnancyDurationUnit ?? this.preferredPregnancyDurationUnit,
      fluidSafetyMode: fluidSafetyMode ?? this.fluidSafetyMode,
      clinicianTargetMl: clearClinicianTarget
          ? null
          : clinicianTargetMl ?? this.clinicianTargetMl,
      allowAdjustmentsAboveClinicianTarget:
          allowAdjustmentsAboveClinicianTarget ??
              this.allowAdjustmentsAboveClinicianTarget,
      wakeMinuteOfDay:
          clearWakeTime ? null : wakeMinuteOfDay ?? this.wakeMinuteOfDay,
      sleepMinuteOfDay:
          clearSleepTime ? null : sleepMinuteOfDay ?? this.sleepMinuteOfDay,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  HydrionBodyMetrics sanitized({
    required bool femaleProfile,
  }) {
    final safeReproductiveState = femaleProfile
        ? reproductiveState
        : HydrionReproductiveHydrationState.none;

    final pregnancyEligible =
        safeReproductiveState == HydrionReproductiveHydrationState.pregnant;

    final safePregnancyDays = pregnancyEligible &&
            HydrionBodyMetricsPolicy.validPregnancyDays(
              pregnancyGestationalDays,
            )
        ? pregnancyGestationalDays
        : null;

    return HydrionBodyMetrics(
      personalizationEnabled: personalizationEnabled,
      weightKg:
          HydrionBodyMetricsPolicy.validWeight(weightKg) ? weightKg : null,
      heightCm:
          HydrionBodyMetricsPolicy.validHeight(heightCm) ? heightCm : null,
      preferredWeightUnit: preferredWeightUnit,
      preferredHeightUnit: preferredHeightUnit,
      reproductiveState: safeReproductiveState,
      pregnancyGestationalDays: safePregnancyDays,
      preferredPregnancyDurationUnit: preferredPregnancyDurationUnit,
      fluidSafetyMode: fluidSafetyMode,
      clinicianTargetMl: _safeClinicianTarget(clinicianTargetMl),
      allowAdjustmentsAboveClinicianTarget:
          allowAdjustmentsAboveClinicianTarget,
      wakeMinuteOfDay: _safeMinute(wakeMinuteOfDay),
      sleepMinuteOfDay: _safeMinute(sleepMinuteOfDay),
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'personalizationEnabled': personalizationEnabled,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'preferredWeightUnit': preferredWeightUnit.name,
        'preferredHeightUnit': preferredHeightUnit.name,
        'reproductiveState': reproductiveState.name,
        'pregnancyGestationalDays': pregnancyGestationalDays,
        'preferredPregnancyDurationUnit': preferredPregnancyDurationUnit.name,
        'fluidSafetyMode': fluidSafetyMode.name,
        'clinicianTargetMl': clinicianTargetMl,
        'allowAdjustmentsAboveClinicianTarget':
            allowAdjustmentsAboveClinicianTarget,
        'wakeMinuteOfDay': wakeMinuteOfDay,
        'sleepMinuteOfDay': sleepMinuteOfDay,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static HydrionBodyMetrics fromJson(Object? value) {
    if (value is! Map) {
      return const HydrionBodyMetrics();
    }

    final weight = _safeDouble(value['weightKg']);
    final height = _safeDouble(value['heightCm']);

    final reproductiveState = _enumValue(
      HydrionReproductiveHydrationState.values,
      value['reproductiveState'],
      HydrionReproductiveHydrationState.none,
    );

    final storedPregnancyDays = _safePregnancyDays(
      value['pregnancyGestationalDays'],
    );

    // Supports an experimental or older value stored as weeks.
    final legacyPregnancyWeeks = _safeDouble(
      value['pregnancyGestationalWeeks'],
    );

    final migratedPregnancyDays =
        storedPregnancyDays ?? _pregnancyWeeksToSafeDays(legacyPregnancyWeeks);

    return HydrionBodyMetrics(
      personalizationEnabled: value['personalizationEnabled'] == true,
      weightKg: HydrionBodyMetricsPolicy.validWeight(weight) ? weight : null,
      heightCm: HydrionBodyMetricsPolicy.validHeight(height) ? height : null,
      preferredWeightUnit: _enumValue(
        HydrionWeightUnit.values,
        value['preferredWeightUnit'],
        HydrionWeightUnit.kilograms,
      ),
      preferredHeightUnit: _enumValue(
        HydrionHeightUnit.values,
        value['preferredHeightUnit'],
        HydrionHeightUnit.centimetres,
      ),
      reproductiveState: reproductiveState,
      pregnancyGestationalDays:
          reproductiveState == HydrionReproductiveHydrationState.pregnant
              ? migratedPregnancyDays
              : null,
      preferredPregnancyDurationUnit: _enumValue(
        HydrionPregnancyDurationUnit.values,
        value['preferredPregnancyDurationUnit'],
        HydrionPregnancyDurationUnit.weeks,
      ),
      fluidSafetyMode: _enumValue(
        HydrionFluidSafetyMode.values,
        value['fluidSafetyMode'],
        HydrionFluidSafetyMode.none,
      ),
      clinicianTargetMl: _safeClinicianTarget(value['clinicianTargetMl']),
      allowAdjustmentsAboveClinicianTarget:
          value['allowAdjustmentsAboveClinicianTarget'] == true,
      wakeMinuteOfDay: _safeMinute(value['wakeMinuteOfDay']),
      sleepMinuteOfDay: _safeMinute(value['sleepMinuteOfDay']),
      updatedAt: DateTime.tryParse(
        (value['updatedAt'] ?? '').toString(),
      ),
      schemaVersion: math.max(
        1,
        value['schemaVersion'] is num
            ? (value['schemaVersion'] as num).round()
            : 1,
      ),
    );
  }

  static double? _safeDouble(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;

  static int? _safePregnancyDays(Object? value) {
    if (value is! num || !value.isFinite) {
      return null;
    }

    final days = value.toInt();
    if (value != days) {
      return null;
    }

    return HydrionBodyMetricsPolicy.validPregnancyDays(
      days,
    )
        ? days
        : null;
  }

  static int? _pregnancyWeeksToSafeDays(
    double? weeks,
  ) {
    if (!HydrionBodyMetricsPolicy.validPregnancyWeeks(
      weeks,
    )) {
      return null;
    }

    final days = HydrionBodyMetricsPolicy.pregnancyWeeksToDays(
      weeks!,
    );

    return HydrionBodyMetricsPolicy.validPregnancyDays(
      days,
    )
        ? days
        : null;
  }

  static int? _safeMinute(Object? value) {
    if (value is! num || !value.isFinite) {
      return null;
    }

    final minute = value.round();

    return minute >= 0 && minute < 1440 ? minute : null;
  }

  static int? _safeClinicianTarget(Object? value) {
    if (value is! num || !value.isFinite) {
      return null;
    }

    final target = value.round();

    return target >= 500 && target <= 5000 ? target : null;
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    Object? raw,
    T fallback,
  ) {
    final name = raw?.toString();

    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return fallback;
  }
}

enum HydrionAdultBmiCategory {
  belowStandardRange,
  standardRange,
  aboveStandardRange,
  higherStandardRange,
}

HydrionAdultBmiCategory? adultBmiCategory({
  required int? age,
  required double? bmi,
}) {
  if (age == null || age < 20 || bmi == null || !bmi.isFinite || bmi <= 0) {
    return null;
  }

  if (bmi < 18.5) {
    return HydrionAdultBmiCategory.belowStandardRange;
  }

  if (bmi < 25) {
    return HydrionAdultBmiCategory.standardRange;
  }

  if (bmi < 30) {
    return HydrionAdultBmiCategory.aboveStandardRange;
  }

  return HydrionAdultBmiCategory.higherStandardRange;
}
