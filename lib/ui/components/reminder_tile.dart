import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hydration_contracts.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
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
      final capabilities = context.read<AppCapabilityReporter>().capabilities;
      final notificationStatus = capabilities.osNotifications
          ? l10n.osNotificationsAvailableSentence
          : l10n.osNotificationsDisabledSentence;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reminder == null
                ? l10n.noLocalReminderNeeded
                : l10n.localReminderSaved(
                    notificationStatus: notificationStatus,
                  ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToScheduleReminder)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final reminders = context.watch<ReminderRepository>().reminders;
    final capabilities = context.watch<AppCapabilityReporter>().capabilities;
    final nextReminder = reminders.isEmpty ? null : reminders.first;
    final scheduledAt = nextReminder?.triggerTime;
    final notificationStatus = capabilities.osNotifications
        ? l10n.osNotificationsAvailableSentence
        : l10n.osNotificationsDisabledSentence;

    return ListTile(
      leading: Icon(Icons.notifications, color: scheme.primary),
      title: Text(
        l10n.localReminderDefinition,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        scheduledAt == null
            ? l10n.reminderTileNoSaved(
                notificationStatus: notificationStatus,
              )
            : l10n.reminderTileSaved(
                count: reminders.length,
                time:
                    '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                notificationStatus: notificationStatus,
              ),
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
              tooltip: l10n.saveLocalReminderDefinitionTooltip,
            ),
      onTap: _schedule,
    );
  }
}
