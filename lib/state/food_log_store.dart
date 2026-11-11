import 'package:flutter/foundation.dart';

import '../models/food_log.dart';
import '../models/pantry_item.dart' show dateOnly;
import '../services/storage.dart';

/// The calorie diary: what was eaten on which day, plus the daily goal.
class FoodLogStore extends ChangeNotifier {
  FoodLogStore(this._store) {
    _entries = _store.readList(_kEntries, FoodLogEntry.fromJson);
    _goal = _store.getInt(_kGoal) ?? defaultGoal;
    // Keep roughly three months so storage does not grow forever.
    final cutoff = dateOnly(DateTime.now()).subtract(const Duration(days: 92));
    _entries.removeWhere((e) => e.day.isBefore(cutoff));
  }

  final LocalStore _store;
  static const _kEntries = 'foodlog.entries';
  static const _kGoal = 'foodlog.goal';
  static const defaultGoal = 2000;
  static const minGoal = 800;
  static const maxGoal = 6000;

  late List<FoodLogEntry> _entries;
  late int _goal;

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
