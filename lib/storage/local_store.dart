import 'package:shared_preferences/shared_preferences.dart';

abstract class HydrionLocalStore {
  Future<String?> readString(String key);

  /// Completes only when the underlying store acknowledges the write.
  /// Rejection must throw; cached readback is not a substitute for that result.
  Future<void> writeString(String key, String value);

  Future<void> remove(String key);
}

final class LocalStoreWriteFailure implements Exception {
  const LocalStoreWriteFailure();
  @override
  String toString() => 'LocalStoreWriteFailure';
}

class SharedPreferencesHydrionStore implements HydrionLocalStore {
  final SharedPreferences _preferences;
  // SharedPreferences is a singleton: a new adapter must not trust a failed
  // write's optimistic cache either. No keys or values are retained here.
  static final _unconfirmedCache = Expando<Object>();

  SharedPreferencesHydrionStore(this._preferences);

  static Future<SharedPreferencesHydrionStore> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesHydrionStore(preferences);
  }

  @override
  Future<String?> readString(String key) async {
    while (_unconfirmedCache[_preferences] != null) {
      final generation = _unconfirmedCache[_preferences];
      await _preferences.reload();
      if (identical(_unconfirmedCache[_preferences], generation)) {
        _unconfirmedCache[_preferences] = null;
      }
    }
    return _preferences.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    try {
      if (await _preferences.setString(key, value)) return;
    } catch (_) {
      // Native exceptions and false acknowledgements have the same contract.
    }
    _unconfirmedCache[_preferences] = Object();
    throw const LocalStoreWriteFailure();
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
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
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}
