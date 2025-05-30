import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ConfigKey {
  otpUrl('otp_url', String, 'https://maps.bhasher.com'),
  otpUsername('otp_username', String, ''),
  otpPassword('otp_password', String, ''),
  otpCountry('otp_country', String, 'be'),
  sortStopsByDistance('sort_stops_by_distance', bool, false),
  useContactsLocation('use_contacts_location', bool, false),
  useCalendarsLocation('use_calendars_location', bool, false),
  defaultProfileId('default_profile_id', int, 0);

  final String key;
  final Type type;
  final Object defaultValue;

  const ConfigKey(this.key, this.type, this.defaultValue);
}

class Config {
  static final Config _instance = Config._internal();
  final Map<ConfigKey, Object> _values = {};

  factory Config() {
    return _instance;
  }

  Config._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    for (final k in ConfigKey.values) {
      _values[k] = prefs.get(k.key) ?? k.defaultValue;
    }
  }

  T get<T>(ConfigKey key) => _values[key] as T;

  Future<bool> setValue<T>(ConfigKey key, T value) async {
    if (value.runtimeType != key.type) {
      debugPrint(
        'Type mismatch for config key: ${key.key}. Expected ${key.type}, got ${value.runtimeType}',
      );
      return false;
    }
    final prefs = await SharedPreferences.getInstance();

    Type type = T == Object ? key.type : T;

    bool result;
    if (type == String) {
      result = await prefs.setString(key.key, value as String);
    } else if (type == int) {
      result = await prefs.setInt(key.key, value as int);
    } else if (type == bool) {
      result = await prefs.setBool(key.key, value as bool);
    } else if (type == double) {
      result = await prefs.setDouble(key.key, value as double);
    } else if (type == List<String>) {
      result = await prefs.setStringList(key.key, value as List<String>);
    } else {
      debugPrint('Unsupported type for config key: ${key.key} with type $T');
      return false;
    }
    if (result) _values[key] = value as Object;
    return result;
  }

  Future<bool> setValues(Map<ConfigKey, Object> values) async {
    if ((await Future.wait(
      values.entries.map((entry) => setValue(entry.key, entry.value)),
    )).any((result) => !result)) {
      return false;
    }

    return true;
  }

  String get otpUrl => get<String>(ConfigKey.otpUrl);
  String get otpUsername => get<String>(ConfigKey.otpUsername);
  String get otpPassword => get<String>(ConfigKey.otpPassword);
  String get otpCountry => get<String>(ConfigKey.otpCountry);
  bool get sortStopsByDistance => get<bool>(ConfigKey.sortStopsByDistance);
  bool get useContactsLocation => get<bool>(ConfigKey.useContactsLocation);
  bool get useCalendarsLocation => get<bool>(ConfigKey.useCalendarsLocation);
  int get defaultProfileId => get<int>(ConfigKey.defaultProfileId);
}
