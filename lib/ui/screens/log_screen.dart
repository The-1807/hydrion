import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/hydration_repository.dart';
import '../../utils/i18n_resolver.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  Future<void> _editLog(HydrationLog log) async {
    final repository = context.read<HydrationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: log.volumeMl.toString());

    final volumeMl = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit hydration log'),
          content: TextField(
            key: const Key('edit-log-volume-field'),
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount in ml',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('save-log-edit-button'),
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.of(context).pop(parsed == null || parsed <= 0
                    ? null
                    : parsed.clamp(1, 5000).toInt());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

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
          content: Text(updated ? 'Hydration log updated' : 'Log not found')),
    );
  }

  Future<void> _deleteLog(HydrationLog log) async {
    final repository = context.read<HydrationRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await repository.deleteLog(log.id);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
          content: Text(deleted ? 'Hydration log deleted' : 'Log not found')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.watch<I18nResolver>();
    final repository = context.watch<HydrationRepository>();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final data = repository.fetch(start, now);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('log_title', 'Hydration Log')),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
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
                    i18n.getText('no_logs', 'No hydration logs found'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use Home to add a local hydration entry. Logs are saved on this device.',
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
                  final timestamp = _formatTimestamp(log.timestamp);

                  return ListTile(
                    leading: const Icon(Icons.local_drink),
                    title: Text(
                      '${log.volumeMl} ml',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${_sourceLabel(log.source)} - $timestamp',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          key: Key('edit-log-${log.id}'),
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit log',
                          onPressed: () => _editLog(log),
                        ),
                        IconButton(
                          key: Key('delete-log-${log.id}'),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete log',
                          onPressed: () => _deleteLog(log),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final date =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  String _sourceLabel(String source) {
    return switch (source) {
      'local' => 'Local entry',
      _ => source,
    };
  }
}
