import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:health/health.dart';

import '../../../hydrion/app/lib/services/wearable_service.dart';
import '../../utils/i18n_resolver.dart';

/// LogScreen — hydration history (wearables + manual)
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late Future<List<HealthDataPoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<HealthDataPoint>> _load() async {
    final wearable = context.read<WearableService>();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return wearable.fetchHydrationData(start, now);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.read<I18nResolver>();
    final dir = Directionality.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.getText('log_title', 'Hydration Log'), textDirection: dir),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<HealthDataPoint>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  i18n.getText('logs_error', 'Failed to load hydration logs'),
                  textDirection: dir,
                ),
              );
            }
            final data = (snap.data ?? const []);
            if (data.isEmpty) {
              return Center(
                child: Text(
                  i18n.getText('no_logs', 'No hydration logs found'),
                  textDirection: dir,
                ),
              );
            }

            // Sort newest first
            data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final log = data[i];
                final ml = log.value is HealthDataValueNumeric
                    ? (log.value as HealthDataValueNumeric).numericValue.toInt()
                    : 0;
                final t = log.dateFrom;
                final ts = '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  leading: const Icon(Icons.local_drink),
                  title: Text(
                    '$ml ml',
                    textDirection: dir,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    i18n.getText('log_time', ts),
                    textDirection: dir,
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
}
