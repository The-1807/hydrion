import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../repositories/hydration_repository.dart';
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
  int _selectedVolumeMl = 250;

  Future<void> _logWater(int volumeMl) async {
    final repository = context.read<HydrationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    await repository.addLog(
      volumeMl: volumeMl,
      timestamp: now,
      source: 'local',
    );
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Logged $volumeMl ml')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();
    context.watch<HydrationRepository>();

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
        future: context.read<HydrationSummaryService>().getHydrationSummary(),
        builder: (context, snapshot) {
          final summary = snapshot.data ??
              const HydrationSummary(
                hydrationPercent: 0,
                entryCount: 0,
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
                entryCount: summary.entryCount,
                temperatureC: 24,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log hydration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              key: const Key('volume-picker'),
                              initialValue: _selectedVolumeMl,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [150, 250, 350, 500, 750, 1000]
                                  .map(
                                    (amount) => DropdownMenuItem<int>(
                                      value: amount,
                                      child: Text('$amount ml'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedVolumeMl = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            key: const Key('log-water-button'),
                            onPressed: () => _logWater(_selectedVolumeMl),
                            icon: const Icon(Icons.local_drink),
                            label: Text('Log $_selectedVolumeMl ml'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Saved locally on this device. BLE and Health sync are disabled.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
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
                      label: 'Reminders',
                      icon: Icons.notifications_none,
                      route: '/reminders'),
                  _RouteButton(
                      label: 'AR disabled',
                      icon: Icons.view_in_ar,
                      route: '/ar'),
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
      key: Key('route-$route'),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => Navigator.of(context).pushNamed(route),
    );
  }
}
