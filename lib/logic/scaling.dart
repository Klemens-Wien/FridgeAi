import 'package:intl/intl.dart';

import '../models/recipe.dart';

/// Scales an ingredient amount from the recipe's base servings to [servings].
double scaleAmount(double amount, int baseServings, int servings) {
  if (amount <= 0 || baseServings <= 0) return amount;
  return amount * servings / baseServings;
}

/// Formats an amount for display: integers without decimals, common
/// fractions as ½ ¼ ¾ ⅓ ⅔, otherwise up to one (or two for small values)
/// decimals in the given locale.
String formatAmount(double amount, String locale) {
  if (amount <= 0) return '';
  final whole = amount.floor();
  final frac = amount - whole;
  const fractions = [(0.25, '¼'), (0.5, '½'), (0.75, '¾'), (1 / 3, '⅓'), (2 / 3, '⅔')];
  if (amount < 10) {
    for (final (value, glyph) in fractions) {
      if ((frac - value).abs() < 0.02) {
        return whole == 0 ? glyph : '$whole$glyph';
      }
    }
  }
  if (frac < 0.01 || frac > 0.99) {
    return NumberFormat('0', locale).format(amount.round());
  }
  final pattern = amount < 1 ? '0.##' : '0.#';
  return NumberFormat(pattern, locale).format(amount);
}

String formatIngredient(
  RecipeIngredient ing,
  int baseServings,
  int servings,
  String locale,
) {
  final amount = formatAmount(
    scaleAmount(ing.amount, baseServings, servings),
    locale,
  );
  return [amount, ing.unit].where((s) => s.isNotEmpty).join(' ');
}

String formatDuration(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
}
