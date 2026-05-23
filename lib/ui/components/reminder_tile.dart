import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/reminder_repository.dart';
import '../../services/notifications.dart';

class ReminderTile extends StatefulWidget {
  final int shortfallMl;
  final double lastDrinkHoursAgo;
  final double hydrationPercent;
  final bool isActiveTime;

  const ReminderTile({
    super.key,
    required this.shortfallMl,
    required this.lastDrinkHoursAgo,
    required this.hydrationPercent,
    required this.isActiveTime,
  });

  @override
  State<ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<ReminderTile> {
  bool _busy = false;

  Future<void> _schedule() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final notifications = context.read<NotificationService>();
      final reminder = await notifications.scheduleReminder(
        shortfallMl: widget.shortfallMl,
        lastDrinkHoursAgo: widget.lastDrinkHoursAgo,
        hydrationPercent: widget.hydrationPercent,
        isActiveTime: widget.isActiveTime,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reminder == null
                ? 'No local reminder was needed'
                : 'Local reminder saved',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule reminder')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reminders = context.watch<ReminderRepository>().reminders;
    final nextReminder = reminders.isEmpty ? null : reminders.first;
    final scheduledAt = nextReminder?.triggerTime;

    return ListTile(
      leading: Icon(Icons.notifications, color: scheme.primary),
      title: Text(
        'Local Reminder',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        scheduledAt == null
            ? 'No reminders saved. OS notifications are not enabled yet.'
            : '${reminders.length} saved locally. Next: ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: _schedule,
              tooltip: 'Save local reminder',
            ),
      onTap: _schedule,
    );
  }
}
