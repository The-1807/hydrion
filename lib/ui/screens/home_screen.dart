import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_bridge.dart';
import '../../services/eco_tracker.dart';
import '../../services/wearable_service.dart';
import '../../utils/i18n_resolver.dart';
import '../components/intake_ring.dart';
import '../components/llm_advice_card.dart';
import '../components/reminder_tile.dart';
import '../components/voice_input_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HydrationSummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = context.read<AIBridge>().getHydrationSummary();
  }

  Future<void> _logWater(int volumeMl) async {
    final wearables = context.read<WearableService>();
    final ecoTracker = context.read<EcoTracker>();
    final aiBridge = context.read<AIBridge>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    await wearables.syncHydration(volumeMl, now);
    await ecoTracker.logHydration(volumeMl);
    if (!mounted) {
      return;
    }
    setState(() {
      _summary = aiBridge.getHydrationSummary();
    });
    messenger.showSnackBar(
      SnackBar(content: Text('Logged $volumeMl ml')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('app_title', 'Hydrion')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: FutureBuilder<HydrationSummary>(
        future: _summary,
        builder: (context, snapshot) {
          final summary = snapshot.data ??
              const HydrationSummary(
                hydrationPercent: 0,
                activityMinutes: 0,
                consumedMl: 0,
                targetMl: 2200,
              );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: IntakeRing(
                  consumedMl: summary.consumedMl.toDouble(),
                  targetMl: summary.targetMl.toDouble(),
                ),
              ),
              const SizedBox(height: 16),
              LLMAdviceCard(
                hydrationPercent: summary.hydrationPercent,
                activityMinutes: summary.activityMinutes,
                temperatureC: 24,
              ),
              const SizedBox(height: 12),
              Card(
                child: ReminderTile(
                  shortfallMl: (summary.targetMl - summary.consumedMl)
                      .clamp(0, summary.targetMl),
                  lastDrinkHoursAgo: 1.5,
                  hydrationPercent: summary.hydrationPercent,
                  isActiveTime: true,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _logWater(250),
                icon: const Icon(Icons.local_drink),
                label: const Text('Log 250 ml'),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RouteButton(
                      label: 'Analytics',
                      icon: Icons.insights,
                      route: '/analytics'),
                  _RouteButton(
                      label: 'Log', icon: Icons.list_alt, route: '/log'),
                  _RouteButton(
                      label: 'Coach',
                      icon: Icons.chat_bubble_outline,
                      route: '/chat'),
                  _RouteButton(
                      label: 'Challenges',
                      icon: Icons.emoji_events,
                      route: '/challenges'),
                  _RouteButton(
                      label: 'AR', icon: Icons.view_in_ar, route: '/ar'),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: VoiceInputWidget(
        onCommandParsed: (command) {
          final intent = command['intent'] ?? 'unknown_command';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice intent: $intent')),
          );
        },
      ),
    );
  }
}

class _RouteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _RouteButton({
    required this.label,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => Navigator.of(context).pushNamed(route),
    );
  }
}
