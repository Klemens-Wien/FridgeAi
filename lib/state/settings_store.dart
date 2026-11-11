import 'package:flutter/material.dart';

import '../config.dart';
import '../models/recipe_filters.dart';
import '../services/storage.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._store, this._secrets) {
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _store.getString(_kTheme),
      orElse: () => ThemeMode.system,
    );
    _localeCode = _store.getString(_kLocale);
    _defaultServings = _store.getInt(_kServings) ?? 2;
    _prioritizeExpiring = _store.getBool(_kExpiring) ?? true;
    final f = _store.readMap(_kFilters);
    _filters = f == null ? const RecipeFilters() : RecipeFilters.fromJson(f);
  }

  final LocalStore _store;
  final SecretStore _secrets;

  static const _kTheme = 'settings.theme';
  static const _kLocale = 'settings.locale';
  static const _kServings = 'settings.servings';
  static const _kExpiring = 'settings.prioritizeExpiring';
  static const _kFilters = 'settings.filters';
  static const supportedLanguages = ['de', 'en'];

  late ThemeMode _themeMode;
  String? _localeCode;
  late int _defaultServings;
  late bool _prioritizeExpiring;
  late RecipeFilters _filters;
  String? _userApiKey;

  ThemeMode get themeMode => _themeMode;

  /// Explicit language choice, or null to follow the device language.
  String? get localeCode => _localeCode;
  Locale? get locale => _localeCode == null ? null : Locale(_localeCode!);
  int get defaultServings => _defaultServings;
  bool get prioritizeExpiring => _prioritizeExpiring;
  RecipeFilters get filters => _filters;

  bool get hasUserApiKey => (_userApiKey ?? '').isNotEmpty;

  /// The key used for API calls: the user's own key, else a build-time key.
  String get effectiveApiKey =>
      hasUserApiKey ? _userApiKey! : AppConfig.apiKeyFromEnvironment;
  bool get hasApiKey => effectiveApiKey.isNotEmpty;

  Future<void> loadSecrets() async {
    _userApiKey = await _secrets.readApiKey();
    notifyListeners();
  }

  Future<void> setApiKey(String? key) async {
    final trimmed = key?.trim();
    _userApiKey = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    notifyListeners();
    await _secrets.writeApiKey(_userApiKey);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _store.setString(_kTheme, mode.name);
  }

  Future<void> setLocaleCode(String? code) async {
    _localeCode = code;
    notifyListeners();
    if (code == null) {
      await _store.remove(_kLocale);
    } else {
      await _store.setString(_kLocale, code);
    }
  }

  Future<void> setDefaultServings(int servings) async {
    _defaultServings = servings.clamp(1, 12);
    notifyListeners();
    await _store.setInt(_kServings, _defaultServings);
  }

  Future<void> setPrioritizeExpiring(bool value) async {
    _prioritizeExpiring = value;
    notifyListeners();
    await _store.setBool(_kExpiring, value);
  }

  Future<void> setFilters(RecipeFilters filters) async {
    _filters = filters;
    notifyListeners();
    await _store.writeMap(_kFilters, filters.toJson());
  }
}
