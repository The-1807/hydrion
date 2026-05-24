import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/reminder_repository.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ReminderRepository>();
    final reminders = repository.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.notifications_off_outlined),
              title: Text('OS notifications disabled'),
              subtitle: Text(
                'Standalone mode stores reminder definitions locally only. No platform notification will fire.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (reminders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No local reminders saved',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use the Home reminder card to save a local reminder definition for later review.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            ...reminders.map((reminder) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(reminder.message),
                  subtitle: Text(
                    '${_formatTimestamp(reminder.triggerTime)} - priority ${reminder.priority}',
                  ),
                  trailing: IconButton(
                    key: Key('delete-reminder-${reminder.id}'),
                    tooltip: 'Delete local reminder',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await repository.delete(reminder.id);
                      if (!context.mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Local reminder definition deleted'),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime time) {
    final date =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }
}
