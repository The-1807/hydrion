import '../repositories/hydration_repository.dart';

class HydrationSummary {
  final double hydrationPercent;
  final int entryCount;
  final int consumedMl;
  final int targetMl;

  const HydrationSummary({
    required this.hydrationPercent,
    int? entryCount,
    int? activityMinutes,
    required this.consumedMl,
    required this.targetMl,
  }) : entryCount = entryCount ?? activityMinutes ?? 0;

  @Deprecated('Use entryCount; Hydrion does not read platform activity data.')
  int get activityMinutes => entryCount;
}

class HydrationChallenge {
  final String id;
  final String name;
  final String description;
  final int targetMl;
  final int durationDays;

  const HydrationChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.targetMl,
    required this.durationDays,
  });
}

class AIBridge {
  final HydrationRepository _hydrationRepository;

  AIBridge({HydrationRepository? hydrationRepository})
      : _hydrationRepository =
            hydrationRepository ?? HydrationRepository.memory();

  Future<HydrationSummary> getHydrationSummary() async {
    final today = DateTime.now();
    final consumedMl = _hydrationRepository.totalForDay(today);
    final logsToday = _hydrationRepository.fetch(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day + 1),
    );
    const targetMl = 2200;
    final hydrationPercent = (consumedMl / targetMl * 100).clamp(0.0, 100.0);

    return HydrationSummary(
      hydrationPercent: hydrationPercent,
      entryCount: logsToday.length,
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
      id: 'steady-sip-7-day-${userLevel.toLowerCase()}',
      name: 'Seven Day Steady Sip',
      description: 'Reach your daily hydration goal for one week.',
      targetMl: targetMl,
      durationDays: 7,
    );
  }
}
