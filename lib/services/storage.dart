import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin JSON persistence layer on top of SharedPreferences.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  List<T> readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    } catch (e) {
      debugPrint('LocalStore: could not read "$key": $e');
      return [];
    }
  }

  Future<void> writeList<T>(
    String key,
    Iterable<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) =>
      _prefs.setString(key, jsonEncode(items.map(toJson).toList()));

  Map<String, dynamic>? readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  List<String> getStringList(String key) => _prefs.getStringList(key) ?? [];
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
}

/// Stores the user's Claude API key in the Keychain / Android Keystore.
abstract class SecretStore {
  Future<String?> readApiKey();
  Future<void> writeApiKey(String? key);
}

class SecureSecretStore implements SecretStore {
  SecureSecretStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'anthropic_api_key';

  @override
  Future<String?> readApiKey() async {
    try {
      return await _storage.read(key: _key);
    } catch (e) {
      debugPrint('SecureSecretStore: read failed: $e');
      return null;
    }
  }

  @override
  Future<void> writeApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(key: _key, value: key.trim());
    }
  }
}

/// In-memory implementation for tests.
class MemorySecretStore implements SecretStore {
  MemorySecretStore([this._value]);
  String? _value;

  @override
  Future<String?> readApiKey() async => _value;

  @override
  Future<void> writeApiKey(String? key) async => _value = key;
}
