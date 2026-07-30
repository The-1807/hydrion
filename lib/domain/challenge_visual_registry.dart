import 'package:flutter/material.dart';

class ChallengeVisualIdentity {
  final String challengeId;
  final String assetPath;
  final Color primary;
  final Color secondary;
  final IconData icon;
  final Alignment imageAlignment;

  const ChallengeVisualIdentity({
    required this.challengeId,
    required this.assetPath,
    required this.primary,
    required this.secondary,
    required this.icon,
    required this.imageAlignment,
  });
}

class ChallengeVisualRegistry {
  const ChallengeVisualRegistry._();

  static const assetDirectory = 'assets/images/challenges';

  static const identities = <String, ChallengeVisualIdentity>{
    'around-the-world-infusion-week': ChallengeVisualIdentity(
      challengeId: 'around-the-world-infusion-week',
      assetPath: 'assets/UI_BETA/arounddworld-card.png',
      primary: Color(0xFF287C64),
      secondary: Color(0xFFE1A34A),
      icon: Icons.local_florist_outlined,
      imageAlignment: Alignment.centerRight,
    ),
    'temperature-roulette': ChallengeVisualIdentity(
      challengeId: 'temperature-roulette',
      assetPath: 'assets/UI_BETA/temp-roulette-card.png',
      primary: Color(0xFF2479A8),
      secondary: Color(0xFFE88A5A),
      icon: Icons.device_thermostat_outlined,
      imageAlignment: Alignment.centerRight,
    ),
    'eat-your-water-day': ChallengeVisualIdentity(
      challengeId: 'eat-your-water-day',
      assetPath: 'assets/UI_BETA/eatyourwater-card.png',
      primary: Color(0xFF3A8B58),
      secondary: Color(0xFFF0A65A),
      icon: Icons.restaurant_outlined,
      imageAlignment: Alignment.centerLeft,
    ),
    'pomodoro-sip': ChallengeVisualIdentity(
      challengeId: 'pomodoro-sip',
      assetPath: 'assets/UI_BETA/pomodoro-card.jpg',
      primary: Color(0xFFB64B55),
      secondary: Color(0xFFF1B658),
      icon: Icons.timer_outlined,
      imageAlignment: Alignment.centerRight,
    ),
    'plant-twin-challenge': ChallengeVisualIdentity(
      challengeId: 'plant-twin-challenge',
      assetPath: 'assets/UI_BETA/planttwin-card.png',
      primary: Color(0xFF468351),
      secondary: Color(0xFF84BDA0),
      icon: Icons.spa_outlined,
      imageAlignment: Alignment.centerLeft,
    ),
    'bottle-bingo': ChallengeVisualIdentity(
      challengeId: 'bottle-bingo',
      assetPath: 'assets/UI_BETA/ble_bottle.png',
      primary: Color(0xFF126E82),
      secondary: Color(0xFF67C9B8),
      icon: Icons.grid_view_rounded,
      imageAlignment: Alignment.centerRight,
    ),
    'lunch-break-refill': ChallengeVisualIdentity(
      challengeId: 'lunch-break-refill',
      assetPath: '$assetDirectory/lunch_break_refill.png',
      primary: Color(0xFF2C7A65),
      secondary: Color(0xFFF0B44D),
      icon: Icons.lunch_dining_outlined,
      imageAlignment: Alignment.centerRight,
    ),
    'homework-hydration': ChallengeVisualIdentity(
      challengeId: 'homework-hydration',
      assetPath: '$assetDirectory/homework_hydration.png',
      primary: Color(0xFF376A9A),
      secondary: Color(0xFF72C4B8),
      icon: Icons.menu_book_outlined,
      imageAlignment: Alignment.centerRight,
    ),
    'after-school-recharge': ChallengeVisualIdentity(
      challengeId: 'after-school-recharge',
      assetPath: '$assetDirectory/after_school_recharge.png',
      primary: Color(0xFF4C7656),
      secondary: Color(0xFFF09B67),
      icon: Icons.battery_charging_full_outlined,
      imageAlignment: Alignment.centerLeft,
    ),
    'backpack-bottle-check': ChallengeVisualIdentity(
      challengeId: 'backpack-bottle-check',
      assetPath: '$assetDirectory/backpack_bottle_check.png',
      primary: Color(0xFF33718A),
      secondary: Color(0xFFEDB95F),
      icon: Icons.backpack_outlined,
      imageAlignment: Alignment.centerRight,
    ),
    'desk-day-reset': ChallengeVisualIdentity(
      challengeId: 'desk-day-reset',
      assetPath: '$assetDirectory/desk_day_reset.png',
      primary: Color(0xFF3A6F78),
      secondary: Color(0xFF9CC9A7),
      icon: Icons.chair_outlined,
      imageAlignment: Alignment.centerLeft,
    ),
    'shift-hydration-check': ChallengeVisualIdentity(
      challengeId: 'shift-hydration-check',
      assetPath: '$assetDirectory/shift_hydration_check.png',
      primary: Color(0xFF355F8A),
      secondary: Color(0xFFF0B85B),
      icon: Icons.schedule_outlined,
      imageAlignment: Alignment.centerRight,
    ),
    'commute-cup': ChallengeVisualIdentity(
      challengeId: 'commute-cup',
      assetPath: '$assetDirectory/commute_cup.png',
      primary: Color(0xFF28756E),
      secondary: Color(0xFFE88C67),
      icon: Icons.directions_transit_outlined,
      imageAlignment: Alignment.centerRight,
    ),
    'evening-goal-review': ChallengeVisualIdentity(
      challengeId: 'evening-goal-review',
      assetPath: '$assetDirectory/evening_goal_review.png',
      primary: Color(0xFF4B6380),
      secondary: Color(0xFF8FC2A1),
      icon: Icons.nights_stay_outlined,
      imageAlignment: Alignment.centerRight,
    ),
  };

  static ChallengeVisualIdentity forId(String id) => identities[id]!;
}
