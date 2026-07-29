import 'life_stage_policy.dart';

enum HydrionChallengeAudience { universal, teen, adult }

class HydrionChallengeEligibility {
  final bool eligible;
  final String? reason;

  const HydrionChallengeEligibility._(this.eligible, this.reason);

  const HydrionChallengeEligibility.allowed() : this._(true, null);

  const HydrionChallengeEligibility.blocked(String reason)
      : this._(false, reason);
}

class HydrionChallengeEligibilityPolicy {
  static const teenChallengeIds = <String>{
    'lunch-break-refill',
    'homework-hydration',
    'after-school-recharge',
    'backpack-bottle-check',
  };

  static const adultChallengeIds = <String>{
    'desk-day-reset',
    'shift-hydration-check',
    'commute-cup',
    'evening-goal-review',
  };

  const HydrionChallengeEligibilityPolicy._();

  static HydrionChallengeAudience audienceFor(String challengeId) {
    if (teenChallengeIds.contains(challengeId)) {
      return HydrionChallengeAudience.teen;
    }
    if (adultChallengeIds.contains(challengeId)) {
      return HydrionChallengeAudience.adult;
    }
    return HydrionChallengeAudience.universal;
  }

  static HydrionChallengeEligibility evaluate({
    required String challengeId,
    required int? age,
  }) {
    final stage = HydrionLifeStagePolicy.productAccessStage(age);
    if (stage == HydrionProductAccessStage.unsupportedIndependentChild) {
      return const HydrionChallengeEligibility.blocked(
        'Challenges require a supported independent profile aged 13 or older.',
      );
    }
    if (stage == HydrionProductAccessStage.invalid) {
      return const HydrionChallengeEligibility.blocked(
        'Review the saved age before joining a challenge.',
      );
    }

    return switch (audienceFor(challengeId)) {
      HydrionChallengeAudience.universal =>
        const HydrionChallengeEligibility.allowed(),
      HydrionChallengeAudience.teen => stage == HydrionProductAccessStage.teen
          ? const HydrionChallengeEligibility.allowed()
          : const HydrionChallengeEligibility.blocked(
              'This challenge is available to teen profiles.',
            ),
      HydrionChallengeAudience.adult => stage == HydrionProductAccessStage.adult
          ? const HydrionChallengeEligibility.allowed()
          : const HydrionChallengeEligibility.blocked(
              'This challenge is available to adult profiles.',
            ),
    };
  }
}
