import 'package:shared_preferences/shared_preferences.dart';

abstract class HydrionLocalStore {
  Future<String?> readString(String key);

  /// Reports the underlying acknowledgement. Callers own rejection policy;
  /// cached readback cannot replace a true result. Native exceptions propagate.
  Future<bool> writeString(String key, String value);

  Future<void> remove(String key);
}

class SharedPreferencesHydrionStore implements HydrionLocalStore {
  final SharedPreferences _preferences;
  // All adapters over the singleton share ordering, not merely a generation
  // check after reload has already mutated its cache.
  static final _operations = Expando<_PreferenceOperations>();
  _PreferenceOperations get _coordination =>
      _operations[_preferences] ??= _PreferenceOperations();

  SharedPreferencesHydrionStore(this._preferences);

  static Future<SharedPreferencesHydrionStore> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesHydrionStore(preferences);
  }

  @override
  Future<String?> readString(String key) => _coordination.run(() async {
        if (_coordination.needsReload) {
          await _preferences.reload();
          _coordination.needsReload = false;
        }
        return _preferences.getString(key);
      });

  @override
  Future<bool> writeString(String key, String value) =>
      _coordination.run(() async {
        try {
          final acknowledged = await _preferences.setString(key, value);
          if (!acknowledged) _coordination.needsReload = true;
          return acknowledged;
        } catch (_) {
          _coordination.needsReload = true;
          rethrow;
        }
      });

  @override
  Future<void> remove(String key) => _coordination.run(() async {
        // Ordering only: deletion acknowledgement policy remains unchanged.
        await _preferences.remove(key);
      });
}

class _PreferenceOperations {
  Future<void> _tail = Future.value();
  bool needsReload = false;

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    // A failed operation must not strand later recovery attempts in the queue.
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

class MemoryHydrionStore implements HydrionLocalStore {
  final Map<String, String> _values;

  MemoryHydrionStore([Map<String, String>? initialValues])
      : _values = Map<String, String>.from(initialValues ?? const {});

  Map<String, String> get snapshot => Map<String, String>.unmodifiable(_values);

  @override
  Future<String?> readString(String key) async {
    return _values[key];
  }

  @override
  Future<bool> writeString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}
