import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum Difficulty {
  easy,
  medium,
  hard;

  static Difficulty parse(String? v) => Difficulty.values.firstWhere(
        (d) => d.name == v,
        orElse: () => Difficulty.medium,
      );
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    this.amount = 0,
    this.unit = '',
    this.pantryItem = '',
    this.isStaple = false,
  });

  final String name;

  /// Amount for the recipe's base servings. 0 means "to taste / unspecified".
  final double amount;
  final String unit;

  /// Name of the pantry item the model mapped this ingredient to ("" if none).
  final String pantryItem;

  /// Basic staples (salt, pepper, oil, water) that are assumed to be at hand
  /// and never count as missing.
  final bool isStaple;

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'unit': unit,
        'pantryItem': pantryItem,
        'isStaple': isStaple,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: (json['name'] as String? ?? '').trim(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        unit: (json['unit'] as String? ?? '').trim(),
        pantryItem: (json['pantryItem'] as String? ?? '').trim(),
        isStaple: json['isStaple'] as bool? ?? false,
      );
}

class RecipeStep {
  const RecipeStep({required this.text, this.timerSeconds = 0});

  final String text;

  /// Suggested timer for this step; 0 means no timer.
  final int timerSeconds;

  Map<String, dynamic> toJson() => {'text': text, 'timerSeconds': timerSeconds};

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        text: (json['text'] as String? ?? '').trim(),
        timerSeconds: (json['timerSeconds'] as num?)?.toInt() ?? 0,
      );
}

/// Nutrition values **per serving**. These are always model estimates.
class Nutrition {
  const Nutrition({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
  });

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  Nutrition operator *(num factor) => Nutrition(
        calories: calories * factor,
        proteinG: proteinG * factor,
        carbsG: carbsG * factor,
        fatG: fatG * factor,
        fiberG: fiberG * factor,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'fiberG': fiberG,
      };

  factory Nutrition.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Nutrition();
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return Nutrition(
      calories: d('calories'),
      proteinG: d('proteinG'),
      carbsG: d('carbsG'),
      fatG: d('fatG'),
      fiberG: d('fiberG'),
    );
  }
}

class Recipe {
  Recipe({
    String? id,
    required this.title,
    this.description = '',
    this.servings = 2,
    this.prepMinutes = 0,
    this.cookMinutes = 0,
    this.difficulty = Difficulty.medium,
    this.vegetarian = false,
    this.vegan = false,
    this.glutenFree = false,
    this.lowCarb = false,
    this.ingredients = const [],
    this.steps = const [],
    this.nutrition = const Nutrition(),
    this.languageCode = 'de',
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String description;
  final int servings;
  final int prepMinutes;
  final int cookMinutes;
  final Difficulty difficulty;
  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;
  final bool lowCarb;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final Nutrition nutrition;
  final String languageCode;
  final DateTime createdAt;

  int get totalMinutes => prepMinutes + cookMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'servings': servings,
        'prepMinutes': prepMinutes,
        'cookMinutes': cookMinutes,
        'difficulty': difficulty.name,
        'vegetarian': vegetarian,
        'vegan': vegan,
        'glutenFree': glutenFree,
        'lowCarb': lowCarb,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'nutrition': nutrition.toJson(),
        'languageCode': languageCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Recipe.fromJson(Map<String, dynamic> json, {String? languageCode}) {
    final vegan = json['vegan'] as bool? ?? false;
    final servings = (json['servings'] as num?)?.toInt() ?? 2;
    return Recipe(
      id: json['id'] as String?,
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      servings: servings < 1 ? 1 : servings,
      prepMinutes: (json['prepMinutes'] as num?)?.toInt() ?? 0,
      cookMinutes: (json['cookMinutes'] as num?)?.toInt() ?? 0,
      difficulty: Difficulty.parse(json['difficulty'] as String?),
      // Vegan implies vegetarian, regardless of what the model said.
      vegetarian: vegan || (json['vegetarian'] as bool? ?? false),
      vegan: vegan,
      glutenFree: json['glutenFree'] as bool? ?? false,
      lowCarb: json['lowCarb'] as bool? ?? false,
      ingredients: ((json['ingredients'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RecipeIngredient.fromJson)
          .where((i) => i.name.isNotEmpty)
          .toList(),
      steps: ((json['steps'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RecipeStep.fromJson)
          .where((s) => s.text.isNotEmpty)
          .toList(),
      nutrition: Nutrition.fromJson(json['nutrition'] as Map<String, dynamic>?),
      languageCode: languageCode ?? json['languageCode'] as String? ?? 'de',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }
}
