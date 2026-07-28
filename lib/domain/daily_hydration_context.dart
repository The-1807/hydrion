enum HydrionActivityIntensity { rest, light, moderate, vigorous }

enum HydrionEnvironmentExposure {
  mostlyIndoors,
  mixed,
  mostlyOutdoors,
}

enum HydrionSweatLevel { low, moderate, high, unknown }

enum HydrionTemporaryCondition {
  none,
  fever,
  vomitingOrDiarrhea,
  recovering,
  preferNotToSay,
}

class DailyHydrationContext {
  final String localDateKey;
  final HydrionActivityIntensity activityIntensity;
  final int activityMinutes;
  final HydrionEnvironmentExposure environment;
  final HydrionSweatLevel sweatLevel;
  final HydrionTemporaryCondition temporaryCondition;
  final int userAdjustmentMl;
  final DateTime updatedAt;

  const DailyHydrationContext({
    required this.localDateKey,
    this.activityIntensity = HydrionActivityIntensity.rest,
    this.activityMinutes = 0,
    this.environment = HydrionEnvironmentExposure.mostlyIndoors,
    this.sweatLevel = HydrionSweatLevel.unknown,
    this.temporaryCondition = HydrionTemporaryCondition.none,
    this.userAdjustmentMl = 0,
    required this.updatedAt,
  });

  Map<String, Object?> toJson() => {
        'localDateKey': localDateKey,
        'activityIntensity': activityIntensity.name,
        'activityMinutes': activityMinutes,
        'environment': environment.name,
        'sweatLevel': sweatLevel.name,
        'temporaryCondition': temporaryCondition.name,
        'userAdjustmentMl': userAdjustmentMl,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static DailyHydrationContext? fromJson(Object? value) {
    if (value is! Map) return null;
    final key = value['localDateKey']?.toString() ?? '';
    final updatedAt = DateTime.tryParse((value['updatedAt'] ?? '').toString());
    final minutes = value['activityMinutes'];
    final adjustment = value['userAdjustmentMl'];
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key) ||
        updatedAt == null ||
        minutes is! num ||
        !minutes.isFinite ||
        minutes < 0 ||
        minutes > 1440) {
      return null;
    }
    return DailyHydrationContext(
      localDateKey: key,
      activityIntensity: _value(
        HydrionActivityIntensity.values,
        value['activityIntensity'],
        HydrionActivityIntensity.rest,
      ),
      activityMinutes: minutes.round(),
      environment: _value(
        HydrionEnvironmentExposure.values,
        value['environment'],
        HydrionEnvironmentExposure.mostlyIndoors,
      ),
      sweatLevel: _value(
        HydrionSweatLevel.values,
        value['sweatLevel'],
        HydrionSweatLevel.unknown,
      ),
      temporaryCondition: _value(
        HydrionTemporaryCondition.values,
        value['temporaryCondition'],
        HydrionTemporaryCondition.none,
      ),
      userAdjustmentMl: adjustment is num && adjustment.isFinite
          ? adjustment.round().clamp(-500, 500)
          : 0,
      updatedAt: updatedAt,
    );
  }

  static T _value<T extends Enum>(List<T> values, Object? raw, T fallback) {
    for (final value in values) {
      if (value.name == raw?.toString()) return value;
    }
    return fallback;
  }
}

String hydrionLocalDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
