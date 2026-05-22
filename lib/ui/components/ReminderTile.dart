import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../hydrion/app/lib/services/notifications.dart';

/// ReminderTile — shows a one-tap scheduler. No side effects during build.
/// - Schedules on tap and gives user feedback
/// - Keeps last scheduled time visible
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
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final notif = context.read<NotificationService>();
      await notif.scheduleReminder(
        shortfallMl: widget.shortfallMl,
        lastDrinkHoursAgo: widget.lastDrinkHoursAgo,
        hydrationPercent: widget.hydrationPercent,
        isActiveTime: widget.isActiveTime,
      );
      if (!mounted) return;
      setState(() => _scheduledAt = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder scheduled')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule reminder')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(Icons.notifications, color: c.primary),
      title: Text(
        'Hydration Reminder',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        _scheduledAt == null
            ? 'Tap to schedule a reminder'
            : 'Scheduled at ${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
      ),
      trailing: _busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: _schedule,
              tooltip: 'Schedule',
            ),
      onTap: _schedule,
    );
  }
}
