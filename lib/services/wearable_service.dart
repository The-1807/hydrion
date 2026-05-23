class HydrationLog {
  final int volumeMl;
  final DateTime timestamp;
  final String source;

  HydrationLog({
    required this.volumeMl,
    required this.timestamp,
    required this.source,
  });
}

class WearableService {
  final List<HydrationLog> _logs = <HydrationLog>[];

  Future<bool> syncHydration(int volumeMl, DateTime timestamp) async {
    if (volumeMl <= 0) {
      return false;
    }

    _logs.add(
      HydrationLog(
        volumeMl: volumeMl,
        timestamp: timestamp,
        source: 'local',
      ),
    );
    return true;
  }

  Future<List<HydrationLog>> fetchHydrationData(
      DateTime start, DateTime end) async {
    final logs = _logs.where((log) {
      return !log.timestamp.isBefore(start) && !log.timestamp.isAfter(end);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return logs;
  }
}
