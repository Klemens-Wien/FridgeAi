import 'package:flutter/foundation.dart';

import '../models/pantry_item.dart' show dateOnly;
import '../services/storage.dart';

/// Free vs. Pro tier. Free users get a small number of AI requests per day;
/// Pro removes the limit and unlocks the Pro-only features.
///
/// Purchases are not wired up yet: [setPro] simply flips the flag. To sell
/// Pro, call it from the store's purchase/restore callbacks instead.
class ProStore extends ChangeNotifier {
  ProStore(this._store, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _isPro = _store.getBool(_kActive) ?? false;
    _usageDay = _store.getString(_kDay) ?? '';
    _usageCount = _store.getInt(_kCount) ?? 0;
  }

  final LocalStore _store;
  final DateTime Function() _clock;

  static const _kActive = 'pro.active';
  static const _kDay = 'pro.usageDay';
  static const _kCount = 'pro.usageCount';
  static const freeDailyAiRequests = 5;

  late bool _isPro;
  late String _usageDay;
  late int _usageCount;

  bool get isPro => _isPro;

  String get _today => dateOnly(_clock()).toIso8601String();

  /// AI requests already used today on the free tier.
  int get usedToday => _usageDay == _today ? _usageCount : 0;

  int get remainingToday =>
      (freeDailyAiRequests - usedToday).clamp(0, freeDailyAiRequests);

  /// Counts one AI request. Returns false (and counts nothing) when the
  /// free tier's daily allowance is used up. Always true for Pro.
  bool tryUseAi() {
    if (_isPro) return true;
    if (remainingToday <= 0) return false;
    _usageCount = usedToday + 1;
    _usageDay = _today;
    notifyListeners();
    _store.setString(_kDay, _usageDay);
    _store.setInt(_kCount, _usageCount);
    return true;
  }

  Future<void> setPro(bool value) async {
    _isPro = value;
    notifyListeners();
    await _store.setBool(_kActive, value);
  }
}
