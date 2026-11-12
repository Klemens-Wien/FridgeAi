import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/logic/calorie_goal.dart';
import 'package:fridgechef/logic/quantity.dart';
import 'package:fridgechef/logic/recipe_ranking.dart';
import 'package:fridgechef/models/food_log.dart';
import 'package:fridgechef/models/meal_plan.dart';
import 'package:fridgechef/models/pantry_item.dart';
import 'package:fridgechef/models/recipe.dart';
import 'package:fridgechef/models/recipe_filters.dart';
import 'package:fridgechef/services/fridge_ai_service.dart';
import 'package:fridgechef/services/storage.dart';
import 'package:fridgechef/state/food_log_store.dart';
import 'package:fridgechef/state/meal_plan_store.dart';
import 'package:fridgechef/state/pantry_store.dart';
import 'package:fridgechef/state/recipe_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';
import 'widget_test.dart' show pumpApp;

void main() {
  group('Quantity', () {
    test('parses numbers, units and fractions', () {
      Quantity q(String s) => Quantity.parse(s)!;
      expect(q('500 g').value, 500);
      expect(q('500 g').dimension, 'g');
      expect(q('1,5 kg').value, 1500);
      expect(q('ca. 0.5 l').value, 500);
      expect(q('0.5 l').dimension, 'ml');
      expect(q('6 Stück').dimension, 'pc');
      expect(q('4').dimension, 'pc');
      expect(q('½ Bund').value, 0.5);
      expect(q('2 Dosen').dimension, 'other:dosen');
      expect(Quantity.parse('halbe Flasche'), isNull);
      expect(Quantity.parse(''), isNull);
    });
  });

  group('pantryUpdatesFor', () {
    Recipe recipe(List<RecipeIngredient> ings) =>
        Recipe(title: 'r', servings: 2, ingredients: ings);
    List<PantryUpdate> updates(
      List<PantryItem> pantry,
      Recipe r, {
      int servings = 2,
    }) => pantryUpdatesFor(RecipeRanker(pantry).match(r), servings, 'de');

    test('subtracts comparable amounts and converts units', () {
      final u = updates(
        [
          PantryItem(name: 'Nudeln', quantity: '500 g'),
          PantryItem(name: 'Mehl', quantity: '1 kg'),
          PantryItem(name: 'Milch', quantity: '1 l'),
          PantryItem(name: 'Eier', quantity: '6 Stück'),
        ],
        recipe(const [
          RecipeIngredient(name: 'Nudeln', amount: 200, unit: 'g'),
          RecipeIngredient(name: 'Mehl', amount: 250, unit: 'g'),
          RecipeIngredient(name: 'Milch', amount: 250, unit: 'ml'),
          RecipeIngredient(name: 'Eier', amount: 2, unit: ''),
        ]),
      );
      String q(String name) =>
          u.firstWhere((x) => x.item.name == name).newQuantity;
      expect(u.every((x) => x.change == PantryChange.reduced), isTrue);
      expect(q('Nudeln'), '300 g');
      expect(q('Mehl'), '750 g');
      expect(q('Milch'), '750 ml');
      expect(q('Eier'), '4 Stück');
    });

    test('scales with servings and detects used-up items', () {
      final u = updates(
        [
          PantryItem(name: 'Nudeln', quantity: '500 g'),
          PantryItem(name: 'Mehl', quantity: '2 kg'),
        ],
        recipe(const [
          RecipeIngredient(name: 'Nudeln', amount: 200, unit: 'g'),
          RecipeIngredient(name: 'Mehl', amount: 250, unit: 'g'),
        ]),
        servings: 6,
      );
      expect(u[0].change, PantryChange.usedUp); // needs 600 g of 500 g
      expect(u[1].newQuantity, '1¼ kg'); // 2000 - 750
    });

    test('unknown when units differ or no quantity is known', () {
      final u = updates(
        [
          PantryItem(name: 'Olivenöl', quantity: '500 ml'),
          PantryItem(name: 'Tomaten'),
          PantryItem(name: 'Salz', quantity: '500 g'),
        ],
        recipe(const [
          RecipeIngredient(name: 'Olivenöl', amount: 2, unit: 'EL'),
          RecipeIngredient(name: 'Tomaten', amount: 2, unit: ''),
          RecipeIngredient(name: 'Salz', amount: 0, unit: '', isStaple: true),
        ]),
      );
      expect(u.map((x) => x.change).toSet(), {PantryChange.unknown});
    });
  });

  test('calorieGoal follows Mifflin-St Jeor', () {
    // 10*70 + 6.25*175 - 5*30 + 5 = 1648.75; x1.55 = 2555.6 -> 2550
    expect(
      calorieGoal(
        sex: Sex.male,
        age: 30,
        heightCm: 175,
        weightKg: 70,
        activity: ActivityLevel.moderate,
        aim: WeightAim.maintain,
      ),
      2550,
    );
    // 10*60 + 6.25*165 - 5*40 - 161 = 1270.25; x1.2 = 1524.3; -500 -> floor 1200
    expect(
      calorieGoal(
        sex: Sex.female,
        age: 40,
        heightCm: 165,
        weightKg: 60,
        activity: ActivityLevel.sedentary,
        aim: WeightAim.lose,
      ),
      1200,
    );
    expect(
      calorieGoal(
        sex: Sex.female,
        age: 40,
        heightCm: 165,
        weightKg: 60,
        activity: ActivityLevel.light,
        aim: WeightAim.gain,
      ),
      2050, // 1746.6 + 300
    );
  });

  group('stores', () {
    late LocalStore store;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = await LocalStore.open();
    });

    test('ratings toggle, persist and feed liked/disliked titles', () async {
      final recipes = RecipeStore(store, FakeClaude().service);
      final a = Recipe(title: 'Curry'),
          b = Recipe(title: 'Eintopf'),
          c = Recipe(title: 'Salat');
      await recipes.rate(a, 5);
      await recipes.rate(b, 1);
      await recipes.rate(c, 3);
      expect(recipes.likedTitles(), ['Curry']);
      expect(recipes.dislikedTitles(), ['Eintopf']);
      await recipes.rate(a, 5); // same star again clears it
      expect(recipes.ratingOf(a.id), 0);
      final reloaded = RecipeStore(store, FakeClaude().service);
      expect(reloaded.ratingOf(b.id), 1);
      expect(reloaded.likedTitles(), isEmpty);
    });

    test('own recipes persist and are found by id', () async {
      final recipes = RecipeStore(store, FakeClaude().service);
      final r = Recipe(title: 'Omas Gulasch');
      await recipes.addOwn(r);
      final reloaded = RecipeStore(store, FakeClaude().service);
      expect(reloaded.own.single.title, 'Omas Gulasch');
      expect(reloaded.findById(r.id)?.title, 'Omas Gulasch');
      await reloaded.removeOwn(r.id);
      expect(reloaded.own, isEmpty);
    });

    test('frequent meals: most often first, latest values', () async {
      final log = FoodLogStore(store);
      final now = DateTime.now();
      FoodLogEntry e(String n, double k, int hoursAgo) => FoodLogEntry(
        name: n,
        calories: k,
        eatenAt: now.subtract(Duration(hours: hoursAgo)),
      );
      for (final x in [
        e('Müsli', 350, 50),
        e('müsli', 380, 2),
        e('Pizza', 900, 1),
        e('Apfel', 80, 30),
      ]) {
        await log.add(x);
      }
      final f = log.frequent();
      expect(f.map((x) => x.name), ['müsli', 'Pizza', 'Apfel']);
      expect(f.first.calories, 380);
    });

    test('planned calories per day', () async {
      final plan = MealPlanStore(store);
      final day = DateTime.now();
      await plan.add(
        day,
        MealSlot.dinner,
        Recipe(title: 'A', nutrition: const Nutrition(calories: 600)),
      );
      await plan.add(
        day,
        MealSlot.lunch,
        Recipe(title: 'B', nutrition: const Nutrition(calories: 450)),
      );
      expect(plan.plannedCalories(day), 1050);
      expect(plan.entriesOn(day).map((e) => e.recipe.title), ['B', 'A']);
      expect(plan.plannedCalories(day.add(const Duration(days: 1))), 0);
    });
  });

  group('AI service', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1]);

    test('receipt mode uses the receipt prompt', () async {
      final fake = FakeClaude();
      await fake
          .service('k')
          .detectIngredients([jpeg], languageCode: 'de', receipt: true);
      expect(fake.requests.single['system'], contains('supermarket receipt'));
      final content = fake.requests.single['messages'][0]['content'] as List;
      expect(
        content.last['text'],
        'List the food items bought on this receipt.',
      );
    });

    test('importRecipe returns the recipe or null', () async {
      final fake = FakeClaude();
      final r = await fake
          .service('k')
          .importRecipe(
            text: 'Omelett: 4 Eier ...',
            photos: [jpeg],
            pantry: [PantryItem(name: 'Eier')],
            languageCode: 'de',
          );
      expect(r!.title, 'Tomaten-Mozzarella-Omelett');
      final content = fake.requests.single['messages'][0]['content'] as List;
      expect(content.first['type'], 'image');
      expect(content.last['text'], contains('My recipe:\nOmelett: 4 Eier ...'));
      expect(content.last['text'], contains('My pantry: Eier'));
      expect(fake.requests.single['system'], contains('Transcribe faithfully'));

      fake.nextRecipes = {'recipes': []};
      expect(
        await fake
            .service('k')
            .importRecipe(text: 'hallo', pantry: [], languageCode: 'de'),
        isNull,
      );
    });

    test('recipe prompt mentions rated recipes', () {
      final prompt = FridgeAiService.recipeUserPrompt(
        pantry: [],
        filters: const RecipeFilters(),
        servings: 2,
        prioritizeExpiring: false,
        count: 6,
        likedTitles: ['Curry'],
        dislikedTitles: ['Eintopf'],
      );
      expect(prompt, contains('rated highly'));
      expect(prompt, contains('Curry'));
      expect(prompt, contains('did not like'));
      expect(prompt, contains('Eintopf'));
    });
  });

  testWidgets('cooking subtracts used amounts from the pantry', (tester) async {
    await pumpApp(
      tester,
      pantry: [
        PantryItem(name: 'Eier', quantity: '10 Stück'),
        PantryItem(name: 'Tomaten', quantity: '2'),
        PantryItem(name: 'Mozzarella'),
      ],
    );
    await tester.tap(find.text('Rezepte finden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomaten-Mozzarella-Omelett'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kochmodus starten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    expect(find.text('10 Stück → 6 Stück'), findsOneWidget);
    expect(find.text('aufgebraucht – wird entfernt'), findsOneWidget);
    expect(find.text('Menge unklar – entfernen?'), findsOneWidget);
    await tester.tap(find.text('Vorrat aktualisieren'));
    await tester.pumpAndSettle();

    final pantry = tester
        .element(find.byType(Scaffold).first)
        .read<PantryStore>();
    expect(
      {for (final p in pantry.items) p.name: p.quantity},
      {
        'Eier': '6 Stück',
        'Mozzarella': '', // unclear: kept unless ticked
      },
    );
  });

  testWidgets('rating, own recipe import and receipt mode', (tester) async {
    final (fake, _) = await pumpApp(tester, pantry: [PantryItem(name: 'Eier')]);

    // Import an own recipe from text.
    await tester.tap(find.text('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eigene Rezepte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rezept importieren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rezept importieren').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Gib einen Text ein oder füge ein Foto hinzu.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byType(TextField),
      'Omelett mit 4 Eiern und Tomaten',
    );
    await tester.tap(find.text('Rezept importieren').last);
    await tester.pumpAndSettle();
    expect(find.text('Rezept gespeichert'), findsOneWidget);
    expect(find.text('Tomaten-Mozzarella-Omelett'), findsOneWidget);

    // Rate it; the rating reaches the next suggestion prompt.
    await tester.tap(find.text('Tomaten-Mozzarella-Omelett'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Deine Bewertung: 5'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star), findsNWidgets(5));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rezepte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rezepte vorschlagen'));
    await tester.pumpAndSettle();
    final prompt =
        fake.requests.last['messages'][0]['content'][0]['text'] as String;
    expect(prompt, contains('rated highly'));
    expect(prompt, contains('Tomaten-Mozzarella-Omelett'));

    // Scan screen offers the receipt mode.
    await tester.tap(find.text('Vorrat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kühlschrank scannen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kassenbon'));
    await tester.pumpAndSettle();
    expect(find.text('Kassenbon auslesen'), findsOneWidget);
    expect(
      find.textContaining('Fotografiere deinen Kassenbon'),
      findsOneWidget,
    );
  });

  testWidgets(
    'calorie counter: planned meals, frequent meals, goal calculator',
    (tester) async {
      await pumpApp(tester);
      final ctx = tester.element(find.byType(Scaffold).first);
      await ctx.read<MealPlanStore>().add(
        DateTime.now(),
        MealSlot.dinner,
        Recipe(
          title: 'Linsencurry',
          nutrition: const Nutrition(calories: 640, proteinG: 30),
        ),
      );
      await ctx.read<FoodLogStore>().add(
        FoodLogEntry(
          name: 'Müsli',
          calories: 350,
          eatenAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      await tester.tap(find.text('Mehr'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kalorienzähler'));
      await tester.pumpAndSettle();

      // Planned meal → one tap logs it.
      expect(find.text('Linsencurry'), findsOneWidget);
      expect(find.text('Abendessen · ≈ 640 kcal'), findsOneWidget);
      await tester.tap(find.text('Gegessen'));
      await tester.pumpAndSettle();
      expect(find.text('1360 übrig'), findsOneWidget);

      // Frequent meal chip fills the form.
      await tester.tap(find.text('Eintrag'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Müsli · 350'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Müsli · 350'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('1010 übrig'), findsOneWidget);

      // Goal calculator.
      await tester.tap(find.byTooltip('Tagesziel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ziel berechnen'));
      await tester.pumpAndSettle();
      expect(find.text('Bitte alle Felder ausfüllen.'), findsOneWidget);
      await tester.tap(find.text('Männlich'));
      await tester.enterText(find.widgetWithText(TextField, 'Alter'), '30');
      await tester.enterText(
        find.widgetWithText(TextField, 'Größe (cm)'),
        '175',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Gewicht (kg)'),
        '70',
      );
      await tester.tap(find.text('Aktiv'));
      await tester.pumpAndSettle();
      expect(find.text('≈ 2550 kcal'), findsOneWidget);
      await tester.ensureVisible(find.text('Als Tagesziel übernehmen'));
      await tester.tap(find.text('Als Tagesziel übernehmen'));
      await tester.pumpAndSettle();
      expect(find.text('Tagesziel: 2550'), findsOneWidget);
    },
  );
}
