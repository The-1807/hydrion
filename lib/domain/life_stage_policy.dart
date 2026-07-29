enum HydrionProductAccessStage {
  unsupportedIndependentChild,
  teen,
  adult,
  unresolved,
  invalid,
}

enum HydrionBodyReferenceStage {
  adolescent,
  adult,
  unresolved,
  invalid,
}

class HydrionLifeStagePolicy {
  static const minimumIndependentAge = 13;
  static const adultProductAge = 18;
  static const adultBodyReferenceAge = 20;
  static const maximumPlausibleAge = 120;

  const HydrionLifeStagePolicy._();

  static HydrionProductAccessStage productAccessStage(int? age) {
    if (age == null) return HydrionProductAccessStage.unresolved;
    if (age < 0 || age > maximumPlausibleAge) {
      return HydrionProductAccessStage.invalid;
    }
    if (age < minimumIndependentAge) {
      return HydrionProductAccessStage.unsupportedIndependentChild;
    }
    if (age < adultProductAge) return HydrionProductAccessStage.teen;
    return HydrionProductAccessStage.adult;
  }

  static HydrionBodyReferenceStage bodyReferenceStage(int? age) {
    if (age == null) return HydrionBodyReferenceStage.unresolved;
    if (age < 0 || age > maximumPlausibleAge) {
      return HydrionBodyReferenceStage.invalid;
    }
    if (age < minimumIndependentAge) {
      return HydrionBodyReferenceStage.invalid;
    }
    if (age < adultBodyReferenceAge) {
      return HydrionBodyReferenceStage.adolescent;
    }
    return HydrionBodyReferenceStage.adult;
  }

  static bool canCreateIndependentProfile(int? age) {
    final stage = productAccessStage(age);
    return stage == HydrionProductAccessStage.teen ||
        stage == HydrionProductAccessStage.adult;
  }
}
