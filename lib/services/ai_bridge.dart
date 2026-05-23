class HydrationSummary {
  final double hydrationPercent;
  final int activityMinutes;
  final int consumedMl;
  final int targetMl;

  const HydrationSummary({
    required this.hydrationPercent,
    required this.activityMinutes,
    required this.consumedMl,
    required this.targetMl,
  });
}

class HydrationChallenge {
  final String name;
  final String description;
  final int targetMl;
  final int durationDays;

  const HydrationChallenge({
    required this.name,
    required this.description,
    required this.targetMl,
    required this.durationDays,
  });
}

class AIBridge {
  Future<HydrationSummary> getHydrationSummary() async {
    const consumedMl = 1500;
    const targetMl = 2200;
    return const HydrationSummary(
      hydrationPercent: consumedMl / targetMl * 100,
      activityMinutes: 30,
      consumedMl: consumedMl,
      targetMl: targetMl,
    );
  }

  Future<HydrationChallenge> createChallenge(
      {required String userLevel}) async {
    final targetMl = switch (userLevel.toLowerCase()) {
      'advanced' => 2600,
      'intermediate' => 2300,
      _ => 2000,
    };

    return HydrationChallenge(
      name: 'Seven Day Steady Sip',
      description: 'Reach your daily hydration goal for one week.',
      targetMl: targetMl,
      durationDays: 7,
    );
  }
}
