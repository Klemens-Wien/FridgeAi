import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/logic/recipe_ranking.dart';
import 'package:fridgechef/logic/scaling.dart';
import 'package:fridgechef/models/pantry_item.dart';
import 'package:fridgechef/models/recipe.dart';
import 'package:fridgechef/models/recipe_filters.dart';
import 'package:fridgechef/ui/cooking/cooking_timer.dart';
import 'package:intl/intl.dart';

Recipe recipe(String title, List<RecipeIngredient> ingredients, {int minutes = 20}) =>
    Recipe(title: title, ingredients: ingredients, cookMinutes: minutes);

void main() {
  final now = DateTime(2026, 11, 11, 12);

  group('PantryItem expiry', () {
    test('status by days left', () {
      PantryItem item(int days) =>
          PantryItem(name: 'x', expiryDate: now.add(Duration(days: days)));
      expect(PantryItem(name: 'x').expiryStatus(now), ExpiryStatus.none);
      expect(item(-1).expiryStatus(now), ExpiryStatus.expired);
      expect(item(0).expiryStatus(now), ExpiryStatus.soon);
      expect(item(2).expiryStatus(now), ExpiryStatus.soon);
      expect(item(3).expiryStatus(now), ExpiryStatus.ok);
    });

    test('json round trip', () {
      final p = PantryItem(
        name: 'Milch',
        quantity: '1 l',
        category: FoodCategory.dairy,
        expiryDate: DateTime(2026, 11, 13),
      );
      final back = PantryItem.fromJson(p.toJson());
      expect(back.id, p.id);
      expect(back.name, 'Milch');
      expect(back.category, FoodCategory.dairy);
      expect(back.expiryDate, DateTime(2026, 11, 13));
    });
  });

  group('RecipeRanker', () {
    final pantry = [
      PantryItem(name: 'Tomaten'),
      PantryItem(name: 'Mozzarella'),
      PantryItem(name: 'Spinat', expiryDate: now.add(const Duration(days: 1))),
      PantryItem(name: 'Eier'),
    ];
    final ranker = RecipeRanker(pantry, now: now);

    test('matches via pantryItem field, exact name and containment', () {
      final m = ranker.match(recipe('A', const [
        RecipeIngredient(name: 'Rispentomaten', pantryItem: 'Tomaten'),
        RecipeIngredient(name: 'mozzarella'),
        RecipeIngredient(name: 'Baby-Spinat'),
        RecipeIngredient(name: 'Basilikum'),
        RecipeIngredient(name: 'Salz', isStaple: true),
      ]));
      expect(m.availableCount, 3);
      expect(m.missing.map((i) => i.name), ['Basilikum']);
      expect(m.staples.map((i) => i.name), ['Salz']);
      expect(m.expiringUsed.map((p) => p.name), ['Spinat']);
      expect(m.coverage, closeTo(0.75, 1e-9));
    });

    test('a staple that is in the pantry counts as available', () {
      final r = RecipeRanker([PantryItem(name: 'Olivenöl')], now: now);
      final m = r.match(recipe('B', const [
        RecipeIngredient(name: 'Olivenöl', isStaple: true),
      ]));
      expect(m.availableCount, 1);
      expect(m.staples, isEmpty);
    });

    test('ranks by available ingredients, expiring items count double', () {
      final usesTwo = recipe('two', const [
        RecipeIngredient(name: 'Tomaten'),
        RecipeIngredient(name: 'Mozzarella'),
      ]);
      final usesSpinach = recipe('spinach', const [
        RecipeIngredient(name: 'Spinat'),
        RecipeIngredient(name: 'Nudeln'),
      ]);
      final usesNone = recipe('none', const [RecipeIngredient(name: 'Lachs')]);

      // Without leftovers priority: 2 available beats 1 available.
      expect(
        ranker
            .rank([usesNone, usesSpinach, usesTwo], prioritizeExpiring: false)
            .map((m) => m.recipe.title),
        ['two', 'spinach', 'none'],
      );
      // With leftovers priority: spinach scores 1 + 1 = 2, ties with "two",
      // which wins on fewer missing ingredients.
      expect(
        ranker.rank([usesSpinach, usesTwo]).map((m) => m.recipe.title),
        ['two', 'spinach'],
      );
      final usesSpinachAndEggs = recipe('spinach+eggs', const [
        RecipeIngredient(name: 'Spinat'),
        RecipeIngredient(name: 'Eier'),
      ]);
      expect(
        ranker.rank([usesTwo, usesSpinachAndEggs]).first.recipe.title,
        'spinach+eggs',
      );
    });

    test('ties are broken by shorter time', () {
      final slow = recipe('slow', const [RecipeIngredient(name: 'Eier')], minutes: 60);
      final fast = recipe('fast', const [RecipeIngredient(name: 'Eier')], minutes: 10);
      expect(ranker.rank([slow, fast]).first.recipe.title, 'fast');
    });
  });

  group('scaling', () {
    setUpAll(() => Intl.defaultLocale = 'en');

    test('scaleAmount', () {
      expect(scaleAmount(200, 2, 4), 400);
      expect(scaleAmount(1, 4, 2), 0.5);
      expect(scaleAmount(0, 2, 4), 0);
    });

    test('formatAmount uses fractions and locale decimals', () {
      expect(formatAmount(0.5, 'en'), '½');
      expect(formatAmount(1.5, 'de'), '1½');
      expect(formatAmount(2 / 3, 'en'), '⅔');
      expect(formatAmount(400, 'de'), '400');
      expect(formatAmount(12.5, 'de'), '12,5');
      expect(formatAmount(12.5, 'en'), '12.5');
      expect(formatAmount(0, 'en'), '');
    });

    test('formatIngredient', () {
      const ing = RecipeIngredient(name: 'Mehl', amount: 250, unit: 'g');
      expect(formatIngredient(ing, 2, 3, 'de'), '375 g');
      const toTaste = RecipeIngredient(name: 'Salz', unit: '');
      expect(formatIngredient(toTaste, 2, 3, 'de'), '');
    });

    test('formatDuration', () {
      expect(formatDuration(65), '01:05');
      expect(formatDuration(3725), '1:02:05');
    });
  });

  group('RecipeFilters', () {
    final r = Recipe(
      title: 'x',
      vegetarian: true,
      glutenFree: true,
      prepMinutes: 10,
      cookMinutes: 20,
      difficulty: Difficulty.medium,
    );

    test('matches diet, time and difficulty', () {
      expect(const RecipeFilters().matches(r), isTrue);
      expect(const RecipeFilters(vegetarian: true, glutenFree: true).matches(r), isTrue);
      expect(const RecipeFilters(vegan: true).matches(r), isFalse);
      expect(const RecipeFilters(lowCarb: true).matches(r), isFalse);
      expect(const RecipeFilters(maxMinutes: 30).matches(r), isTrue);
      expect(const RecipeFilters(maxMinutes: 15).matches(r), isFalse);
      expect(const RecipeFilters(difficulty: Difficulty.easy).matches(r), isFalse);
      expect(const RecipeFilters(difficulty: Difficulty.hard).matches(r), isTrue);
    });

    test('json round trip and counts', () {
      const f = RecipeFilters(vegan: true, maxMinutes: 30, difficulty: Difficulty.easy);
      final back = RecipeFilters.fromJson(f.toJson());
      expect(back.vegan, isTrue);
      expect(back.maxMinutes, 30);
      expect(back.difficulty, Difficulty.easy);
      expect(back.activeCount, 3);
      expect(back.copyWith(clearMaxMinutes: true).maxMinutes, isNull);
    });

    test('vegan recipes are always vegetarian', () {
      final v = Recipe.fromJson({'title': 'v', 'vegan': true, 'vegetarian': false});
      expect(v.vegetarian, isTrue);
    });
  });

  group('CookingTimer', () {
    test('counts down against the clock, pauses and finishes', () {
      var t = DateTime(2026);
      var finished = 0;
      final timer = CookingTimer(
        label: 't',
        duration: const Duration(seconds: 10),
        clock: () => t,
        onFinished: (_) => finished++,
      );
      timer.start();
      t = t.add(const Duration(seconds: 4));
      expect(timer.remaining, const Duration(seconds: 6));
      timer.pause();
      t = t.add(const Duration(seconds: 100));
      expect(timer.remaining, const Duration(seconds: 6));
      timer.start();
      t = t.add(const Duration(seconds: 7));
      timer.tick();
      expect(timer.isFinished, isTrue);
      expect(finished, 1);
      timer.reset();
      expect(timer.remaining, const Duration(seconds: 10));
      timer.dispose();
    });
  });
}
