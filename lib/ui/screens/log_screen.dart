import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/wearable_service.dart';
import '../../utils/i18n_resolver.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late Future<List<HydrationLog>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<HydrationLog>> _load() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return context.read<WearableService>().fetchHydrationData(start, now);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('log_title', 'Hydration Log')),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = _load();
          });
        },
        child: FutureBuilder<List<HydrationLog>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(i18n.getText(
                    'logs_error', 'Failed to load hydration logs')),
              );
            }

            final data = snapshot.data ?? const <HydrationLog>[];
            if (data.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Center(
                      child: Text(
                          i18n.getText('no_logs', 'No hydration logs found'))),
                ],
              );
            }

            return ListView.separated(
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
                    '${log.source} - $timestamp',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
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
}
