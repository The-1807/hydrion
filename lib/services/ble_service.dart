class BottleConnection {
  final String id;
  final String name;

  const BottleConnection({
    required this.id,
    required this.name,
  });
}

class BLEService {
  bool get isAvailable => false;

  Future<List<BottleConnection>> scanForBottles() async {
    return const <BottleConnection>[];
  }

  Future<BottleConnection?> connectToBottle({
    Duration scanTimeout = const Duration(seconds: 10),
    String namePrefix = 'HydrionBottle',
  }) async {
    final matches = await scanForBottles();
    for (final connection in matches) {
      if (connection.name.contains(namePrefix)) {
        return connection;
      }
    }
    return null;
  }

  Future<int?> readWaterLevel(BottleConnection connection) async {
    return null;
  }

  Future<void> disconnect(BottleConnection connection) async {}

  Future<void> dispose() async {}
}
