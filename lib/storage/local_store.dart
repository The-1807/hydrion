import 'package:shared_preferences/shared_preferences.dart';

abstract class HydrionLocalStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> remove(String key);
}

class SharedPreferencesHydrionStore implements HydrionLocalStore {
  final SharedPreferences _preferences;

  SharedPreferencesHydrionStore(this._preferences);

  static Future<SharedPreferencesHydrionStore> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesHydrionStore(preferences);
  }

  @override
  Future<String?> readString(String key) async {
    return _preferences.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
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
