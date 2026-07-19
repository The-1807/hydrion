import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/hydration_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/app_refresh_controller.dart';
import '../components/intake_ring.dart';

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

    final settings = context.read<UserSettingsRepository>().settings;
    final result = await showDialog<_EditLogResult>(
      context: context,
      builder: (context) => _EditLogDialog(
        log: log,
        unit: settings.volumeUnit,
      ),
    );

    if (result == null) {
      return;
    }

    final updated = await repository.updateLog(
      id: log.id,
      volumeMl: result.volumeMl,
      timestamp: result.timestamp,
      metadata: result.metadata,
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
    final settings = context.watch<UserSettingsRepository>().settings;
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
                      HydrationVolumeFormatter.format(
                        log.volumeMl,
                        settings.volumeUnit,
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${l10n.logSourceTimestamp(
                        source: _sourceLabel(log.source, l10n),
                        timestamp: timestamp,
                      )}${_metadataSummary(log.metadata)}',
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
    if (source.startsWith('challenge:')) {
      final id = source.split(':').elementAtOrNull(1);
      return switch (id) {
        'temperature-roulette' => 'Temperature Roulette',
        'around-the-world-infusion-week' => 'Infusion Week',
        'pomodoro-sip' => 'Pomodoro Sip',
        'bottle-bingo' => 'Bottle Bingo',
        _ => 'Challenge drink',
      };
    }
    return switch (source) {
      'local' => l10n.localEntry,
      'quick-add' => 'Quick log',
      'wearable' => 'Wearable log',
      'voice' => 'Voice log',
      _ => 'Hydration entry',
    };
  }

  String _metadataSummary(HydrationMetadata metadata) {
    final details = <String>[
      if (metadata.temperatureStyle != null) metadata.temperatureStyle!,
      if (metadata.infusionTheme != null) metadata.infusionTheme!,
      if (metadata.noAddedSugar == true) 'No added sugar',
      if (metadata.mealContext != null) metadata.mealContext!,
    ];
    return details.isEmpty ? '' : '\n${details.join(' \u00b7 ')}';
  }
}

class _EditLogDialog extends StatefulWidget {
  final HydrationLog log;
  final HydrionVolumeUnit unit;

  const _EditLogDialog({required this.log, required this.unit});

  @override
  State<_EditLogDialog> createState() => _EditLogDialogState();
}

class _EditLogDialogState extends State<_EditLogDialog> {
  late final TextEditingController _controller;
  late final TextEditingController _infusionController;
  late DateTime _timestamp;
  String? _temperatureStyle;
  bool _noAddedSugar = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: HydrationVolumeFormatter.fromMilliliters(
        widget.log.volumeMl,
        widget.unit,
      ).toStringAsFixed(widget.unit == HydrionVolumeUnit.ounces ? 1 : 0),
    );
    _infusionController =
        TextEditingController(text: widget.log.metadata.infusionTheme);
    _timestamp = widget.log.timestamp;
    _temperatureStyle = widget.log.metadata.temperatureStyle;
    _noAddedSugar = widget.log.metadata.noAddedSugar ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _infusionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.editHydrationLog),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('edit-log-volume-field'),
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: widget.unit == HydrionVolumeUnit.ounces
                    ? 'Amount in fluid ounces'
                    : l10n.amountInMl,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('edit-log-timestamp'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Date and time'),
              subtitle: Text(MaterialLocalizations.of(context)
                  .formatFullDate(_timestamp.toLocal())),
              onTap: _chooseTimestamp,
            ),
            DropdownButtonFormField<String?>(
              key: const Key('edit-log-temperature'),
              initialValue: _temperatureStyle,
              decoration: const InputDecoration(labelText: 'Temperature style'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Not specified')),
                DropdownMenuItem(value: 'Cool', child: Text('Cool')),
                DropdownMenuItem(
                  value: 'Room temperature',
                  child: Text('Room temperature'),
                ),
                DropdownMenuItem(
                  value: 'Comfortably warm',
                  child: Text('Comfortably warm'),
                ),
              ],
              onChanged: (value) => setState(() => _temperatureStyle = value),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('edit-log-infusion'),
              controller: _infusionController,
              decoration: const InputDecoration(labelText: 'Infusion theme'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _noAddedSugar,
              title: const Text('No added sugar'),
              onChanged: (value) =>
                  setState(() => _noAddedSugar = value ?? false),
            ),
          ],
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
            final parsed = double.tryParse(_controller.text.trim());
            if (parsed == null || parsed <= 0) {
              Navigator.of(context).pop();
              return;
            }
            final volumeMl = HydrationVolumeFormatter.toMilliliters(
              parsed,
              widget.unit,
            ).clamp(1, 5000);
            final infusion = _infusionController.text.trim();
            Navigator.of(context).pop(
              _EditLogResult(
                volumeMl: volumeMl,
                timestamp: _timestamp,
                metadata: widget.log.metadata.copyWith(
                  temperatureStyle: _temperatureStyle,
                  clearTemperatureStyle: _temperatureStyle == null,
                  infusionTheme: infusion.isEmpty ? null : infusion,
                  clearInfusionTheme: infusion.isEmpty,
                  noAddedSugar: infusion.isEmpty ? null : _noAddedSugar,
                  clearNoAddedSugar: infusion.isEmpty,
                ),
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _chooseTimestamp() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null) return;
    setState(() {
      _timestamp = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }
}

class _EditLogResult {
  final int volumeMl;
  final DateTime timestamp;
  final HydrationMetadata metadata;

  const _EditLogResult({
    required this.volumeMl,
    required this.timestamp,
    required this.metadata,
  });
}
