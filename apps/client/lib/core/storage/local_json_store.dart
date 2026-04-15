import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalJsonStore {
  LocalJsonStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<void> writeList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final encoded = jsonEncode(items);
    await _preferences.setString(key, encoded);
  }
}
