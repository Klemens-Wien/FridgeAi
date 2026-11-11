import 'recipe.dart';

class RecipeFilters {
  const RecipeFilters({
    this.vegetarian = false,
    this.vegan = false,
    this.glutenFree = false,
    this.lowCarb = false,
    this.maxMinutes,
    this.difficulty,
  });

  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;
  final bool lowCarb;

  /// Maximum total time (prep + cook). Null = no limit.
  final int? maxMinutes;

  /// Maximum difficulty. Null = any.
  final Difficulty? difficulty;

  static const timeOptions = [15, 30, 45, 60];

  bool get isEmpty =>
      !vegetarian &&
      !vegan &&
      !glutenFree &&
      !lowCarb &&
      maxMinutes == null &&
      difficulty == null;

  int get activeCount =>
      [vegetarian, vegan, glutenFree, lowCarb].where((b) => b).length +
      (maxMinutes != null ? 1 : 0) +
      (difficulty != null ? 1 : 0);

  bool matches(Recipe r) {
    if (vegan && !r.vegan) return false;
    if (vegetarian && !r.vegetarian) return false;
    if (glutenFree && !r.glutenFree) return false;
    if (lowCarb && !r.lowCarb) return false;
    final max = maxMinutes;
    if (max != null && r.totalMinutes > max) return false;
    final diff = difficulty;
    if (diff != null && r.difficulty.index > diff.index) return false;
    return true;
  }

  RecipeFilters copyWith({
    bool? vegetarian,
    bool? vegan,
    bool? glutenFree,
    bool? lowCarb,
    int? maxMinutes,
    bool clearMaxMinutes = false,
    Difficulty? difficulty,
    bool clearDifficulty = false,
  }) =>
      RecipeFilters(
        vegetarian: vegetarian ?? this.vegetarian,
        vegan: vegan ?? this.vegan,
        glutenFree: glutenFree ?? this.glutenFree,
        lowCarb: lowCarb ?? this.lowCarb,
        maxMinutes: clearMaxMinutes ? null : (maxMinutes ?? this.maxMinutes),
        difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      );

  Map<String, dynamic> toJson() => {
        'vegetarian': vegetarian,
        'vegan': vegan,
        'glutenFree': glutenFree,
        'lowCarb': lowCarb,
        'maxMinutes': maxMinutes,
        'difficulty': difficulty?.name,
      };

  factory RecipeFilters.fromJson(Map<String, dynamic> json) => RecipeFilters(
        vegetarian: json['vegetarian'] as bool? ?? false,
        vegan: json['vegan'] as bool? ?? false,
        glutenFree: json['glutenFree'] as bool? ?? false,
        lowCarb: json['lowCarb'] as bool? ?? false,
        maxMinutes: (json['maxMinutes'] as num?)?.toInt(),
        difficulty: json['difficulty'] == null
            ? null
            : Difficulty.parse(json['difficulty'] as String),
      );
}
