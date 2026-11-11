import '../models/pantry_item.dart';
import '../models/recipe.dart';

/// Lower-cases and strips punctuation/diacritics-insensitive noise so that
/// "Tomaten", "tomaten " and "Tomaten," compare equal.
String normalizeName(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Result of matching a recipe's ingredients against the pantry.
class RecipeMatch {
  RecipeMatch({
    required this.recipe,
    required this.available,
    required this.missing,
    required this.staples,
    required this.expiringUsed,
  });

  final Recipe recipe;

  /// Recipe ingredient → pantry item it is covered by.
  final Map<RecipeIngredient, PantryItem> available;
  final List<RecipeIngredient> missing;
  final List<RecipeIngredient> staples;

  /// Pantry items that expire soon (or already expired) and are used here.
  final List<PantryItem> expiringUsed;

  int get availableCount => available.length;
  int get missingCount => missing.length;

  /// Share of the non-staple ingredients that are already at home (0..1).
  double get coverage {
    final total = availableCount + missingCount;
    return total == 0 ? 1 : availableCount / total;
  }

  bool isAvailable(RecipeIngredient i) => i.isStaple || available.containsKey(i);
}

class RecipeRanker {
  RecipeRanker(this.pantry, {DateTime? now}) : _now = now ?? DateTime.now() {
    for (final p in pantry) {
      _byName[normalizeName(p.name)] = p;
    }
  }

  final List<PantryItem> pantry;
  final DateTime _now;
  final Map<String, PantryItem> _byName = {};

  /// Finds the pantry item covering [ingredient]: first via the model's
  /// explicit mapping, then by exact name, then by word containment
  /// ("Cherrytomaten" ↔ "Tomaten", "red onion" ↔ "onion").
  PantryItem? findPantryItem(RecipeIngredient ingredient) {
    if (ingredient.pantryItem.isNotEmpty) {
      final hit = _byName[normalizeName(ingredient.pantryItem)];
      if (hit != null) return hit;
    }
    final name = normalizeName(ingredient.name);
    if (name.isEmpty) return null;
    final exact = _byName[name];
    if (exact != null) return exact;
    for (final entry in _byName.entries) {
      final p = entry.key;
      if (p.length < 3 || name.length < 3) continue;
      if (name.contains(p) || p.contains(name)) return entry.value;
    }
    return null;
  }

  RecipeMatch match(Recipe recipe) {
    final available = <RecipeIngredient, PantryItem>{};
    final missing = <RecipeIngredient>[];
    final staples = <RecipeIngredient>[];
    final expiring = <String, PantryItem>{};
    for (final ing in recipe.ingredients) {
      final p = findPantryItem(ing);
      if (p != null) {
        available[ing] = p;
        if (p.isExpiringSoon(_now)) expiring[p.id] = p;
      } else if (ing.isStaple) {
        staples.add(ing);
      } else {
        missing.add(ing);
      }
    }
    return RecipeMatch(
      recipe: recipe,
      available: available,
      missing: missing,
      staples: staples,
      expiringUsed: expiring.values.toList(),
    );
  }

  /// Sorts recipes so that those using the most pantry ingredients come first.
  ///
  /// With [prioritizeExpiring], every soon-to-expire item a recipe uses counts
  /// twice, so leftovers get used up first. Ties are broken by fewer missing
  /// ingredients, then by shorter total time.
  List<RecipeMatch> rank(
    Iterable<Recipe> recipes, {
    bool prioritizeExpiring = true,
  }) {
    final matches = recipes.map(match).toList();
    int score(RecipeMatch m) =>
        m.availableCount + (prioritizeExpiring ? m.expiringUsed.length : 0);
    matches.sort((a, b) {
      final s = score(b).compareTo(score(a));
      if (s != 0) return s;
      final miss = a.missingCount.compareTo(b.missingCount);
      if (miss != 0) return miss;
      return a.recipe.totalMinutes.compareTo(b.recipe.totalMinutes);
    });
    return matches;
  }
}
