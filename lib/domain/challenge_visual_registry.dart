import 'package:flutter/material.dart';

import 'profile_art_registry.dart';

class ChallengeVisualIdentity {
  final Color primary;
  final Color secondary;
  final IconData icon;
  final String? cardAsset;
  final String neutralAsset;
  final String? maleAsset;
  final String? femaleAsset;
  final String? intersexAsset;
  final Alignment imageAlignment;

  const ChallengeVisualIdentity({
    required this.primary,
    required this.secondary,
    required this.icon,
    required this.imageAlignment,
    required this.neutralAsset,
    this.cardAsset,
    this.maleAsset,
    this.femaleAsset,
    this.intersexAsset,
  });

  String dashboardAssetFor(Object? profileValue) =>
      HydrionProfileArtResolver.resolve(
        profileValue: profileValue,
        slot: HydrionProfileArtSlot(
          neutralAsset: neutralAsset,
          maleAsset: maleAsset,
          femaleAsset: femaleAsset,
          intersexAsset: intersexAsset,
        ),
      );
}

class ChallengeVisualRegistry {
  const ChallengeVisualRegistry._();

  static const aliases = <String, String>{
    'arounddworld': 'around-the-world-infusion-week',
    'infusion': 'around-the-world-infusion-week',
    'temp-roulette': 'temperature-roulette',
    'temp_roulette': 'temperature-roulette',
    'temp-roullete': 'temperature-roulette',
    'temp_roullete': 'temperature-roulette',
    'eat-water': 'eat-your-water-day',
    'water-food': 'eat-your-water-day',
    'pomodoro': 'pomodoro-sip',
    'pomo': 'pomodoro-sip',
    'planttwin': 'plant-twin-challenge',
    'bingo': 'bottle-bingo',
    'bottle-bingo': 'bottle-bingo',
  };

  static const identities = <String, ChallengeVisualIdentity>{
    'around-the-world-infusion-week': ChallengeVisualIdentity(
      primary: Color(0xFF287C64),
      secondary: Color(0xFFE1A34A),
      icon: Icons.local_florist_outlined,
      cardAsset: 'assets/UI_BETA/arounddworld-card.png',
      neutralAsset: 'assets/UI_BETA/arounddworld.png',
      imageAlignment: Alignment.centerRight,
    ),
    'temperature-roulette': ChallengeVisualIdentity(
      primary: Color(0xFF2479A8),
      secondary: Color(0xFFE88A5A),
      icon: Icons.device_thermostat_outlined,
      cardAsset: 'assets/UI_BETA/temp-roulette-card.png',
      neutralAsset: 'assets/UI_BETA/temp-roulette.png',
      maleAsset: 'assets/UI_BETA/temp-roulette-man.png',
      femaleAsset: 'assets/UI_BETA/temp-roulette-lady.png',
      imageAlignment: Alignment.centerRight,
    ),
    'eat-your-water-day': ChallengeVisualIdentity(
      primary: Color(0xFF3A8B58),
      secondary: Color(0xFFF0A65A),
      icon: Icons.restaurant_outlined,
      cardAsset: 'assets/UI_BETA/eatyourwater-card.png',
      neutralAsset: 'assets/UI_BETA/eatyourwater.png',
      maleAsset: 'assets/UI_BETA/eatyourwater-man.png',
      femaleAsset: 'assets/UI_BETA/eatyourwater-lady.png',
      intersexAsset: 'assets/UI_BETA/pride/eat-your-water.png',
      imageAlignment: Alignment.centerLeft,
    ),
    'pomodoro-sip': ChallengeVisualIdentity(
      primary: Color(0xFFB64B55),
      secondary: Color(0xFFF1B658),
      icon: Icons.timer_outlined,
      cardAsset: 'assets/UI_BETA/pomodoro-card.jpg',
      neutralAsset: 'assets/UI_BETA/pomodoro-technique.jpg',
      imageAlignment: Alignment.centerRight,
    ),
    'plant-twin-challenge': ChallengeVisualIdentity(
      primary: Color(0xFF468351),
      secondary: Color(0xFF84BDA0),
      icon: Icons.spa_outlined,
      cardAsset: 'assets/UI_BETA/planttwin-card.png',
      neutralAsset: 'assets/UI_BETA/planttwin-card.png',
      maleAsset: 'assets/UI_BETA/planttwin-man.png',
      femaleAsset: 'assets/UI_BETA/planttwin-lady.png',
      imageAlignment: Alignment.centerLeft,
    ),
    'bottle-bingo': ChallengeVisualIdentity(
      primary: Color(0xFF126E82),
      secondary: Color(0xFF67C9B8),
      icon: Icons.grid_view_rounded,
      cardAsset: 'assets/UI_BETA/ble_bottle.png',
      neutralAsset: 'assets/UI_BETA/ble_bottle.png',
      imageAlignment: Alignment.centerRight,
    ),
    'lunch-break-refill': ChallengeVisualIdentity(
      primary: Color(0xFF2C7A65),
      secondary: Color(0xFFF0B44D),
      icon: Icons.lunch_dining_outlined,
      neutralAsset: 'assets/UI_BETA/challenge.png',
      imageAlignment: Alignment.centerRight,
    ),
    'homework-hydration': ChallengeVisualIdentity(
      primary: Color(0xFF376A9A),
      secondary: Color(0xFF72C4B8),
      icon: Icons.menu_book_outlined,
      neutralAsset: 'assets/UI_BETA/community-run.png',
      imageAlignment: Alignment.centerRight,
    ),
    'after-school-recharge': ChallengeVisualIdentity(
      primary: Color(0xFF4C7656),
      secondary: Color(0xFFF09B67),
      icon: Icons.battery_charging_full_outlined,
      neutralAsset: 'assets/UI_BETA/tracked_intake.png',
      imageAlignment: Alignment.centerLeft,
    ),
    'backpack-bottle-check': ChallengeVisualIdentity(
      primary: Color(0xFF33718A),
      secondary: Color(0xFFEDB95F),
      icon: Icons.backpack_outlined,
      neutralAsset: 'assets/UI_BETA/pride/pride-bottle.png',
      imageAlignment: Alignment.centerRight,
    ),
    'desk-day-reset': ChallengeVisualIdentity(
      primary: Color(0xFF3A6F78),
      secondary: Color(0xFF9CC9A7),
      icon: Icons.chair_outlined,
      neutralAsset: 'assets/UI_BETA/goals.png',
      imageAlignment: Alignment.centerLeft,
    ),
    'shift-hydration-check': ChallengeVisualIdentity(
      primary: Color(0xFF355F8A),
      secondary: Color(0xFFF0B85B),
      icon: Icons.schedule_outlined,
      neutralAsset: 'assets/UI_BETA/green-check.png',
      imageAlignment: Alignment.centerRight,
    ),
    'commute-cup': ChallengeVisualIdentity(
      primary: Color(0xFF28756E),
      secondary: Color(0xFFE88C67),
      icon: Icons.directions_transit_outlined,
      neutralAsset: 'assets/UI_BETA/weather.png',
      imageAlignment: Alignment.centerRight,
    ),
    'evening-goal-review': ChallengeVisualIdentity(
      primary: Color(0xFF4B6380),
      secondary: Color(0xFF8FC2A1),
      icon: Icons.nights_stay_outlined,
      neutralAsset: 'assets/UI_BETA/hot-summer.png',
      imageAlignment: Alignment.centerRight,
    ),
  };

  static ChallengeVisualIdentity forId(String id) => identities[id]!;
}
