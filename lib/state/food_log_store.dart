import 'package:flutter/foundation.dart';

import '../models/food_log.dart';
import '../models/pantry_item.dart' show dateOnly;
import '../services/storage.dart';

/// The calorie diary: what was eaten on which day, plus the daily goal.
class FoodLogStore extends ChangeNotifier {
  FoodLogStore(this._store) {
    _entries = _store.readList(_kEntries, FoodLogEntry.fromJson);
    _goal = _store.getInt(_kGoal) ?? defaultGoal;
    final water = _store.readMap(_kWater) ?? const {};
    _water = {
      for (final e in water.entries)
        if (e.value is num) e.key: (e.value as num).toInt(),
    };
    // Keep roughly three months so storage does not grow forever.
    final cutoff = dateOnly(DateTime.now()).subtract(const Duration(days: 92));
    _entries.removeWhere((e) => e.day.isBefore(cutoff));
  }

  final LocalStore _store;
  static const _kEntries = 'foodlog.entries';
  static const _kGoal = 'foodlog.goal';
  static const _kWater = 'foodlog.water';

  /// Glasses (à 250 ml) to aim for per day.
  static const waterGoal = 8;
  static const defaultGoal = 2000;
  static const minGoal = 800;
  static const maxGoal = 6000;

  late List<FoodLogEntry> _entries;
  late int _goal;
  late Map<String, int> _water;

  /// Daily calorie goal in kcal.
  int get goal => _goal;

  Future<void> _save() =>
      _store.writeList(_kEntries, _entries, (e) => e.toJson());

  /// Entries of [day], earliest first.
  List<FoodLogEntry> entriesFor(DateTime day) {
    final d = dateOnly(day);
    return _entries.where((e) => e.day == d).toList()
      ..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));
  }

  DayTotals totalsFor(DateTime day) => DayTotals.of(entriesFor(day));

  /// Calories of the 7 days ending on [lastDay], oldest first.
  List<(DateTime, double)> week(DateTime lastDay) {
    final end = dateOnly(lastDay);
    return [
      for (var i = 6; i >= 0; i--)
        (
          end.subtract(Duration(days: i)),
          totalsFor(end.subtract(Duration(days: i))).calories,
        ),
    ];
  }

  /// The meals logged most often (by name), most frequent first; ties go
  /// to the more recent one. Each is represented by its latest entry.
  List<FoodLogEntry> frequent({int max = 6}) {
    final count = <String, int>{};
    final latest = <String, FoodLogEntry>{};
    for (final e in _entries) {
      final key = e.name.trim().toLowerCase();
      if (key.isEmpty) continue;
      count[key] = (count[key] ?? 0) + 1;
      final l = latest[key];
      if (l == null || e.eatenAt.isAfter(l.eatenAt)) latest[key] = e;
    }
    final keys = count.keys.toList()
      ..sort((a, b) {
        final c = count[b]!.compareTo(count[a]!);
        return c != 0 ? c : latest[b]!.eatenAt.compareTo(latest[a]!.eatenAt);
      });
    return keys.take(max).map((k) => latest[k]!).toList();
  }

  static String _dayKey(DateTime day) =>
      dateOnly(day).toIso8601String().substring(0, 10);

  /// Glasses of water logged on [day].
  int waterOn(DateTime day) => _water[_dayKey(day)] ?? 0;

  Future<void> setWater(DateTime day, int glasses) async {
    final key = _dayKey(day);
    final value = glasses.clamp(0, 30);
    if (value == 0) {
      _water.remove(key);
    } else {
      _water[key] = value;
    }
    // Same retention as the entries.
    final cutoff = _dayKey(DateTime.now().subtract(const Duration(days: 92)));
    _water.removeWhere((k, _) => k.compareTo(cutoff) < 0);
    notifyListeners();
    await _store.writeMap(_kWater, _water);
  }

  Future<void> add(FoodLogEntry entry) async {
    _entries.add(entry);
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> setGoal(int kcal) async {
    _goal = kcal.clamp(minGoal, maxGoal);
    notifyListeners();
    await _store.setInt(_kGoal, _goal);
  }
}
