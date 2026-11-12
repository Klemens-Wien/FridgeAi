import '../models/pantry_item.dart';
import 'recipe_ranking.dart';
import 'scaling.dart';

/// A parsed free-text quantity such as "500 g", "1,5 kg" or "6 Stück".
class Quantity {
  const Quantity(this.value, this.dimension, this.unitText);

  /// Value in the base unit of [dimension] (g, ml, pieces, or the raw unit).
  final double value;

  /// 'g', 'ml', 'pc', or `other:unit` for units like "Dose" or "Bund".
  final String dimension;

  /// Unit as the user wrote it (used when writing the quantity back).
  final String unitText;

  static const _fractions = {'½': 0.5, '¼': 0.25, '¾': 0.75};
  static final _pattern = RegExp(
    r'^\s*(?:ca\.?|circa|about|approx\.?|etwa|~|≈)?\s*(\d+(?:[.,]\d+)?|[½¼¾])\s*(.*?)\s*$',
    caseSensitive: false,
  );

  static Quantity? parse(String text) {
    final m = _pattern.firstMatch(text);
    if (m == null) return null;
    final raw = m.group(1)!;
    final value = _fractions[raw] ?? double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    return of(value, m.group(2)!);
  }

  static Quantity of(double value, String unit) {
    final u = unit.toLowerCase().replaceAll('.', '').trim();
    switch (u) {
      case 'g' || 'gr' || 'gramm' || 'gram' || 'grams':
        return Quantity(value, 'g', unit);
      case 'kg' || 'kilo' || 'kilogramm':
        return Quantity(value * 1000, 'g', unit);
      case 'ml':
        return Quantity(value, 'ml', unit);
      case 'l' || 'liter' || 'litre' || 'liters' || 'litres':
        return Quantity(value * 1000, 'ml', unit);
      case '' ||
            'stück' ||
            'stueck' ||
            'stk' ||
            'st' ||
            'x' ||
            'piece' ||
            'pieces' ||
            'pcs' ||
            'pc':
        return Quantity(value, 'pc', unit);
      default:
        return Quantity(value, 'other:$u', unit);
    }
  }
}

enum PantryChange {
  /// Amount could be subtracted; some is left.
  reduced,

  /// Amount could be subtracted; nothing is left.
  usedUp,

  /// Units don't match or no quantity is known: the app cannot tell.
  unknown,
}

class PantryUpdate {
  const PantryUpdate(this.item, this.change, [this.newQuantity = '']);

  final PantryItem item;
  final PantryChange change;

  /// Quantity text after cooking (only for [PantryChange.reduced]).
  final String newQuantity;
}

String _format(double base, Quantity original, String locale) {
  final big = original.dimension == 'g' || original.dimension == 'ml';
  final wasLarge = big && Quantity.of(1, original.unitText).value == 1000;
  if (wasLarge && base >= 1000) {
    return '${formatAmount(base / 1000, locale)} ${original.unitText}';
  }
  final unit = big ? original.dimension : original.unitText;
  return [formatAmount(base, locale), unit].where((p) => p.isNotEmpty).join(' ');
}

/// Works out how the pantry changes after cooking [match]'s recipe for
/// [servings]: subtracts what was used where units are comparable
/// (g/kg, ml/l, pieces, or the same custom unit), otherwise marks the item
/// as unknown so the user can decide.
List<PantryUpdate> pantryUpdatesFor(
  RecipeMatch match,
  int servings,
  String locale,
) {
  final remaining = <String, double>{};
  final unknown = <String>{};
  final parsed = <String, Quantity?>{};
  final items = <String, PantryItem>{};

  match.available.forEach((ingredient, item) {
    items[item.id] = item;
    final have = parsed.putIfAbsent(item.id, () => Quantity.parse(item.quantity));
    final amount =
        scaleAmount(ingredient.amount, match.recipe.servings, servings);
    if (have == null || amount <= 0) {
      unknown.add(item.id);
      return;
    }
    final used = Quantity.of(amount, ingredient.unit);
    if (used.dimension != have.dimension) {
      unknown.add(item.id);
      return;
    }
    remaining[item.id] = (remaining[item.id] ?? have.value) - used.value;
  });

  return [
    for (final item in items.values)
      if (unknown.contains(item.id) && !remaining.containsKey(item.id))
        PantryUpdate(item, PantryChange.unknown)
      else if ((remaining[item.id] ?? 0) <= 0.001)
        PantryUpdate(item, PantryChange.usedUp)
      else
        PantryUpdate(
          item,
          PantryChange.reduced,
          _format(remaining[item.id]!, parsed[item.id]!, locale),
        ),
  ];
}
