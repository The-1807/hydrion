import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  DateTime? _scheduledAt;
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
      setState(() => _scheduledAt = reminder?.triggerTime ?? DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder scheduled')),
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
    final scheduledAt = _scheduledAt;

    return ListTile(
      leading: Icon(Icons.notifications, color: scheme.primary),
      title: Text(
        'Hydration Reminder',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        scheduledAt == null
            ? 'Tap to schedule a reminder'
            : 'Scheduled for ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
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
              tooltip: 'Schedule',
            ),
      onTap: _schedule,
    );
  }
}
