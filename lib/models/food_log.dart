import 'package:uuid/uuid.dart';

import 'pantry_item.dart' show dateOnly;

const _uuid = Uuid();

/// One eaten meal or snack in the calorie diary.
class FoodLogEntry {
  FoodLogEntry({
    String? id,
    required this.name,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.estimated = false,
    DateTime? eatenAt,
  })  : id = id ?? _uuid.v4(),
        eatenAt = eatenAt ?? DateTime.now();

  final String id;
  final String name;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// True when the values come from an AI estimate (recipe or photo/text).
  final bool estimated;
  final DateTime eatenAt;

  DateTime get day => dateOnly(eatenAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'estimated': estimated,
        'eatenAt': eatenAt.toIso8601String(),
      };

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return FoodLogEntry(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      calories: d('calories'),
      proteinG: d('proteinG'),
      carbsG: d('carbsG'),
      fatG: d('fatG'),
      estimated: json['estimated'] as bool? ?? false,
      eatenAt: DateTime.tryParse(json['eatenAt'] as String? ?? ''),
    );
  }
}

/// Summed values of a day.
class DayTotals {
  const DayTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  factory DayTotals.of(Iterable<FoodLogEntry> entries) {
    var c = 0.0, p = 0.0, k = 0.0, f = 0.0;
    for (final e in entries) {
      c += e.calories;
      p += e.proteinG;
      k += e.carbsG;
      f += e.fatG;
    }
    return DayTotals(calories: c, proteinG: p, carbsG: k, fatG: f);
  }
}
