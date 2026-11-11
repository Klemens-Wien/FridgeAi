import '../l10n/strings.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';
import 'scaling.dart';

/// Plain-text version of a recipe for sharing via messenger or notes.
String recipeShareText(Recipe recipe, int servings, S s) {
  final b = StringBuffer()
    ..writeln(recipe.title)
    ..writeln(
      '${s.servingsCount(servings)} · ${s.minutes(recipe.totalMinutes)} · '
      '${s.difficultyName(recipe.difficulty)}',
    );
  if (recipe.description.isNotEmpty) b.writeln(recipe.description);
  b
    ..writeln()
    ..writeln('${s.ingredients}:');
  for (final i in recipe.ingredients) {
    final amount = formatIngredient(i, recipe.servings, servings, s.languageCode);
    b.writeln('- ${[amount, i.name].where((p) => p.isNotEmpty).join(' ')}');
  }
  b
    ..writeln()
    ..writeln('${s.steps}:');
  for (var n = 0; n < recipe.steps.length; n++) {
    b.writeln('${n + 1}. ${recipe.steps[n].text}');
  }
  final kcal = recipe.nutrition.calories.round();
  if (kcal > 0) {
    b
      ..writeln()
      ..writeln('≈ $kcal kcal ${s.perServing} (${s.nutritionEstimate})');
  }
  return b.toString().trimRight();
}

/// Plain-text shopping list; only open (unchecked) items.
String shoppingShareText(Iterable<ShoppingItem> items, S s) {
  final b = StringBuffer()..writeln('${s.shoppingTitle}:');
  for (final i in items.where((i) => !i.checked)) {
    final amount = [formatAmount(i.amount, s.languageCode), i.unit]
        .where((p) => p.isNotEmpty)
        .join(' ');
    b.writeln('- ${[amount, i.name].where((p) => p.isNotEmpty).join(' ')}');
  }
  return b.toString().trimRight();
}
