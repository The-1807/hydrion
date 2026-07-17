import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/hydration_repository.dart';
import '../../services/app_refresh_controller.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final Set<String> _deletingLogIds = <String>{};

  Future<void> _editLog(HydrationLog log) async {
    final repository = context.read<HydrationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final volumeMl = await showDialog<int>(
      context: context,
      builder: (context) => _EditLogDialog(initialVolumeMl: log.volumeMl),
    );

    if (volumeMl == null) {
      return;
    }

    final updated = await repository.updateLog(
      id: log.id,
      volumeMl: volumeMl,
    );
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(updated ? l10n.hydrationLogUpdated : l10n.logNotFound),
      ),
    );
  }

  Future<void> _deleteLog(HydrationLog log) async {
    if (_deletingLogIds.contains(log.id)) {
      return;
    }
    setState(() {
      _deletingLogIds.add(log.id);
    });
    final repository = context.read<HydrationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final deleted = await repository.deleteLog(log.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _deletingLogIds.remove(log.id);
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(deleted ? l10n.hydrationLogDeleted : l10n.logNotFound),
        action: deleted
            ? SnackBarAction(
                label: l10n.undo,
                onPressed: () async {
                  final restored = await repository.restoreLog(log);
                  if (!mounted) {
                    return;
                  }
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        restored ? l10n.hydrationLogRestored : l10n.logNotFound,
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = context.watch<HydrationRepository>();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final data = repository.fetch(start, now);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logTitle),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        key: const Key('history-refresh-indicator'),
        onRefresh: () => refreshHydrionData(context),
        child: data.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 96),
                  Icon(
                    Icons.local_drink_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noLogs,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.logEmptyDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: data.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = data[index];
                  final timestamp = _formatTimestamp(context, log.timestamp);
                  final deleting = _deletingLogIds.contains(log.id);

                  return ListTile(
                    leading: const Icon(Icons.local_drink),
                    title: Text(
                      '${log.volumeMl} ml',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      l10n.logSourceTimestamp(
                        source: _sourceLabel(log.source, l10n),
                        timestamp: timestamp,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          key: Key('edit-log-${log.id}'),
                          icon: const Icon(Icons.edit),
                          tooltip: l10n.editLogTooltip,
                          onPressed: () => _editLog(log),
                        ),
                        IconButton(
                          key: Key('delete-log-${log.id}'),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.deleteLogTooltip,
                          onPressed: deleting ? null : () => _deleteLog(log),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final dayLabel = day == today
        ? l10n.today
        : day == today.subtract(const Duration(days: 1))
            ? l10n.yesterday
            : material.formatMediumDate(local);
    final timeLabel = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return l10n.relativeDateTime(date: dayLabel, time: timeLabel);
  }

  String _sourceLabel(String source, AppLocalizations l10n) {
    return switch (source) {
      'local' => l10n.localEntry,
      _ => source,
    };
  }
}

class _EditLogDialog extends StatefulWidget {
  final int initialVolumeMl;

  const _EditLogDialog({required this.initialVolumeMl});

  @override
  State<_EditLogDialog> createState() => _EditLogDialogState();
}

class _EditLogDialogState extends State<_EditLogDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialVolumeMl.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.editHydrationLog),
      content: TextField(
        key: const Key('edit-log-volume-field'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.amountInMl,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('save-log-edit-button'),
          onPressed: () {
            final parsed = int.tryParse(_controller.text.trim());
            Navigator.of(context).pop(parsed == null || parsed <= 0
                ? null
                : parsed.clamp(1, 5000).toInt());
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
