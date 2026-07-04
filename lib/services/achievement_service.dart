import '../repositories/hydration_repository.dart';

enum AchievementRuleScope {
  currentDay,
  permanent,
}

class AchievementState {
  final String id;
  final AchievementRuleScope scope;
  final bool unlocked;

  const AchievementState({
    required this.id,
    required this.scope,
    required this.unlocked,
  });
}

class AchievementSnapshot {
  final AchievementState dailyGoal;
  final AchievementState threeLogsToday;
  final AchievementState sevenDayStreak;

  const AchievementSnapshot({
    required this.dailyGoal,
    required this.threeLogsToday,
    required this.sevenDayStreak,
  });
}

class AchievementService {
  static const dailyGoalId = 'daily-goal';
  static const threeLogsTodayId = 'three-logs-today';
  static const sevenDayStreakId = 'seven-day-streak';

  const AchievementService();

  AchievementSnapshot evaluate({
    required HydrationRepository hydrationRepository,
    required DateTime now,
    required int activeGoalMl,
  }) {
    final dayStart = DateTime(now.year, now.month, now.day);
    final todayLogs = hydrationRepository.fetch(
      dayStart,
      dayStart.add(const Duration(days: 1)),
    );

    return AchievementSnapshot(
      dailyGoal: AchievementState(
        id: dailyGoalId,
        scope: AchievementRuleScope.currentDay,
        unlocked: hydrationRepository.totalForDay(now) >= activeGoalMl,
      ),
      threeLogsToday: AchievementState(
        id: threeLogsTodayId,
        scope: AchievementRuleScope.currentDay,
        unlocked: todayLogs.length >= 3,
      ),
      sevenDayStreak: AchievementState(
        id: sevenDayStreakId,
        scope: AchievementRuleScope.currentDay,
        unlocked: _streakDays(hydrationRepository, now, activeGoalMl) >= 7,
      ),
    );
  }

  int _streakDays(
    HydrationRepository repository,
    DateTime now,
    int targetMl,
  ) {
    var streak = 0;

    for (var offset = 0; offset < 30; offset += 1) {
      final day = DateTime(now.year, now.month, now.day - offset);
      if (repository.totalForDay(day) >= targetMl) {
        streak += 1;
      } else {
        break;
      }
    }

    return streak;
  }
}
