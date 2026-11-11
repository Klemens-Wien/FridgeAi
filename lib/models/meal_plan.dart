import 'package:uuid/uuid.dart';

import 'pantry_item.dart' show dateOnly;
import 'recipe.dart';

const _uuid = Uuid();

enum MealSlot { breakfast, lunch, dinner }

class MealPlanEntry {
  MealPlanEntry({
    String? id,
    required DateTime date,
    required this.slot,
    required this.recipe,
    int? servings,
  })  : id = id ?? _uuid.v4(),
        date = dateOnly(date),
        servings = servings ?? recipe.servings;

  final String id;
  final DateTime date;
  final MealSlot slot;

  /// Snapshot of the recipe, so the plan survives even if the recipe is
  /// removed from favourites or history.
  final Recipe recipe;
  final int servings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'slot': slot.name,
        'recipe': recipe.toJson(),
        'servings': servings,
      };

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'] as String?,
        date: DateTime.parse(json['date'] as String),
        slot: MealSlot.values.firstWhere(
          (s) => s.name == json['slot'],
          orElse: () => MealSlot.dinner,
        ),
        recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
        servings: (json['servings'] as num?)?.toInt(),
      );
}

/// Monday of the week containing [d].
DateTime startOfWeek(DateTime d) {
  final day = dateOnly(d);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}
