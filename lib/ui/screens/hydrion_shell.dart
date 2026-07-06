import 'package:flutter/material.dart';

import '../theme/hydrion_design.dart';
import 'analytics_screen.dart';
import 'chat_coach_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'social_challenges_screen.dart';

class HydrionShell extends StatefulWidget {
  const HydrionShell({super.key});

  @override
  State<HydrionShell> createState() => _HydrionShellState();
}

class _HydrionShellState extends State<HydrionShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: HydrionGradients.lagoon),
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            HomeScreen(showRouteShortcuts: false),
            SocialChallengesScreen(embedded: true),
            AnalyticsScreen(embedded: true),
            ChatCoachScreen(embedded: true),
            ProfileScreen(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          key: const Key('hydrion-bottom-nav'),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              key: Key('nav-home'),
              icon: Icon(Icons.water_drop_outlined),
              selectedIcon: Icon(Icons.water_drop),
              label: 'Home',
            ),
            NavigationDestination(
              key: Key('nav-challenges'),
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events),
              label: 'Challenges',
            ),
            NavigationDestination(
              key: Key('nav-progress'),
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Progress',
            ),
            NavigationDestination(
              key: Key('nav-coach'),
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Coach',
            ),
            NavigationDestination(
              key: Key('nav-profile'),
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
