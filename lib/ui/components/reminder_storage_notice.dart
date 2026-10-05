import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/reminder_repository.dart';

/// Unknown reminder storage is shown as unavailable, never as "no reminders".
class ReminderStorageNotice extends StatefulWidget {
  const ReminderStorageNotice({super.key});

  static String message(AppLocalizations l10n, ReminderStorageStatus status) =>
      switch (status) {
        ReminderStorageStatus.cleanupPending => l10n.dailyContextCleanupPending,
        ReminderStorageStatus.deletionPending => l10n.reminderDeletionPending,
        _ => l10n.reminderStorageUnavailable,
      };

  @override
  State<ReminderStorageNotice> createState() => _ReminderStorageNoticeState();
}

class _ReminderStorageNoticeState extends State<ReminderStorageNotice> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ReminderRepository>();
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const Key('reminder-storage-notice'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            ReminderStorageNotice.message(l10n, repository.storageStatus),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('reminder-storage-retry'),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
            onPressed: _retrying
                ? null
                : () async {
                    setState(() => _retrying = true);
                    try {
                      await repository.refreshFromStore();
                    } on ReminderStorageUnavailable {
                      // Repository state remains the authority; no raw error.
                    } finally {
                      if (mounted) setState(() => _retrying = false);
                    }
                  },
          ),
        ]),
      ),
    );
  }
}
