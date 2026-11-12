import 'package:flutter/foundation.dart';

import '../models/meal_plan.dart';
import '../models/pantry_item.dart' show dateOnly;
import '../models/recipe.dart';
import '../services/storage.dart';

class MealPlanStore extends ChangeNotifier {
  MealPlanStore(this._store) {
    _entries = _store.readList(_key, MealPlanEntry.fromJson);
    _pruneOld();
  }

  final LocalStore _store;
  static const _key = 'mealplan.entries';
  late List<MealPlanEntry> _entries;

  /// Drops entries older than four weeks so storage doesn't grow forever.
  void _pruneOld() {
    final cutoff = dateOnly(DateTime.now()).subtract(const Duration(days: 28));
    _entries.removeWhere((e) => e.date.isBefore(cutoff));
  }

  Future<void> _save() => _store.writeList(_key, _entries, (e) => e.toJson());

  List<MealPlanEntry> entriesFor(DateTime day, MealSlot slot) => _entries
      .where((e) => e.date == dateOnly(day) && e.slot == slot)
      .toList();

  /// All meals planned for [day], in slot order.
  List<MealPlanEntry> entriesOn(DateTime day) => [
        for (final slot in MealSlot.values) ...entriesFor(day, slot),
      ];

  /// Estimated calories of [day]'s plan, counting one serving per meal.
  double plannedCalories(DateTime day) => entriesOn(day)
      .fold(0, (sum, e) => sum + e.recipe.nutrition.calories);

  List<MealPlanEntry> entriesInWeek(DateTime weekStart) {
    final start = dateOnly(weekStart);
    final end = start.add(const Duration(days: 7));
    return _entries
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .toList()
      ..sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.slot.index.compareTo(b.slot.index);
      });
  }

  Future<void> add(DateTime day, MealSlot slot, Recipe recipe, {int? servings}) async {
    _entries.add(MealPlanEntry(
      date: day,
      slot: slot,
      recipe: recipe,
      servings: servings,
    ));
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> restore(MealPlanEntry entry) async {
    _entries.add(entry);
    notifyListeners();
    await _save();
  }
}
