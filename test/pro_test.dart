import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/models/meal_plan.dart';
import 'package:fridgechef/models/pantry_item.dart';
import 'package:fridgechef/models/recipe.dart';
import 'package:fridgechef/services/storage.dart';
import 'package:fridgechef/state/food_log_store.dart';
import 'package:fridgechef/state/meal_plan_store.dart';
import 'package:fridgechef/state/pro_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show pumpApp;

void main() {
  group('ProStore', () {
    late LocalStore store;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = await LocalStore.open();
    });

    test('free tier: five AI requests per day, reset the next day', () {
      var now = DateTime(2026, 11, 12, 9);
      final pro = ProStore(store, clock: () => now);
      expect(pro.isPro, isFalse);
      for (var i = 0; i < 5; i++) {
        expect(pro.tryUseAi(), isTrue);
      }
      expect(pro.remainingToday, 0);
      expect(pro.tryUseAi(), isFalse);
      expect(pro.usedToday, 5);
      now = DateTime(2026, 11, 13, 0, 5);
      expect(pro.remainingToday, 5);
      expect(pro.tryUseAi(), isTrue);
      expect(pro.usedToday, 1);
    });

    test('pro is unlimited and persists', () async {
      final pro = ProStore(store);
      await pro.setPro(true);
      for (var i = 0; i < 20; i++) {
        expect(pro.tryUseAi(), isTrue);
      }
      expect(pro.usedToday, 0);
      expect(ProStore(store).isPro, isTrue);
    });

    test('usage survives a restart on the same day', () {
      final now = DateTime(2026, 11, 12, 9);
      ProStore(store, clock: () => now)
        ..tryUseAi()
        ..tryUseAi();
      expect(ProStore(store, clock: () => now).usedToday, 2);
    });
  });

  test('water per day', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    final log = FoodLogStore(store);
    final today = DateTime.now();
    await log.setWater(today, 3);
    await log.setWater(today.subtract(const Duration(days: 1)), 6);
    expect(log.waterOn(today), 3);
    expect(
      FoodLogStore(store).waterOn(today.subtract(const Duration(days: 1))),
      6,
    );
    await log.setWater(today, -2);
    expect(log.waterOn(today), 0);
  });

  test('recipe kind round trip and fallback', () {
    final r = Recipe.fromJson({'title': 'x', 'kind': 'soup'});
    expect(r.kind, RecipeKind.soup);
    expect(Recipe.fromJson(r.toJson()).kind, RecipeKind.soup);
    expect(
      Recipe.fromJson({'title': 'x', 'kind': 'nonsense'}).kind,
      RecipeKind.other,
    );
    expect(Recipe.fromJson({'title': 'x'}).kind, RecipeKind.other);
  });

  testWidgets('onboarding shows once', (tester) async {
    final (_, settings) = await pumpApp(tester, onboarded: false);
    expect(find.text('Kühlschrank fotografieren'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Planen und im Blick behalten'), findsOneWidget);
    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();
    expect(settings.onboardingDone, isTrue);
    expect(find.text('Dein Kühlschrank ist noch leer'), findsOneWidget);
  });

  testWidgets('free tier: quota, paywall and unlocking Pro', (tester) async {
    final (fake, _) = await pumpApp(
      tester,
      pro: false,
      pantry: [PantryItem(name: 'Eier')],
    );
    final pro = tester.element(find.byType(Scaffold).first).read<ProStore>();
    await tester.tap(find.text('Rezepte'));
    await tester.pumpAndSettle();

    // Five free requests go through.
    await tester.tap(find.text('Rezepte vorschlagen'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('Rezepte vorschlagen').first);
      await tester.pumpAndSettle();
    }
    expect(fake.requests, hasLength(5));
    expect(pro.remainingToday, 0);

    // The sixth opens the paywall and sends nothing.
    await tester.tap(find.byTooltip('Rezepte vorschlagen').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Dein Tageslimit an kostenlosen KI-Anfragen ist erreicht.'),
      findsOneWidget,
    );
    expect(fake.requests, hasLength(5));

    // Unlocking in the paywall lets the request through.
    await tester.tap(find.text('Pro freischalten'));
    await tester.pumpAndSettle();
    expect(pro.isPro, isTrue);
    expect(fake.requests, hasLength(6));
  });

  testWidgets('pro-only features are locked on the free tier', (tester) async {
    final (fake, _) = await pumpApp(tester, pro: false);
    await tester.tap(find.text('Mehr'));
    await tester.pumpAndSettle();
    expect(find.text('Heute noch 5 von 5 KI-Anfragen frei'), findsOneWidget);

    // AI calorie estimate.
    await tester.tap(find.text('Kalorienzähler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eintrag'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Was hast du gegessen?'),
      'Käsebrot',
    );
    await tester.tap(find.text('Mit KI schätzen'));
    await tester.pumpAndSettle();
    expect(find.text('Das ist eine Pro-Funktion.'), findsOneWidget);
    expect(fake.requests, isEmpty);
  });

  testWidgets('pro screen toggles the plan', (tester) async {
    await pumpApp(tester, pro: false);
    await tester.tap(find.text('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FridgeChef Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Kostenlose Version'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pro freischalten'), 200);
    await tester.tap(find.text('Pro freischalten'));
    await tester.pumpAndSettle();
    expect(find.text('Pro ist aktiv'), findsOneWidget);
  });

  testWidgets('automatic week plan fills free dinners', (tester) async {
    final (fake, _) = await pumpApp(tester, pantry: [PantryItem(name: 'Eier')]);
    final plan = tester
        .element(find.byType(Scaffold).first)
        .read<MealPlanStore>();
    await tester.tap(find.text('Planer'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Woche automatisch planen'));
    await tester.pumpAndSettle();

    final prompt =
        fake.requests.single['messages'][0]['content'][0]['text'] as String;
    expect(prompt, contains('dinners for the coming days'));
    final today = DateTime.now();
    final daysLeft = 8 - today.weekday; // today through Sunday
    expect(prompt, contains('Suggest $daysLeft recipes.'));
    // The fake returns two recipes; they land on the first free dinners.
    final planned = plan.entriesInWeek(startOfWeek(today));
    expect(planned, hasLength(daysLeft < 2 ? daysLeft : 2));
    expect(planned.first.slot, MealSlot.dinner);
    expect(planned.first.recipe.title, 'Tomaten-Mozzarella-Omelett');
  });

  testWidgets('water counter and today header', (tester) async {
    await pumpApp(tester, pantry: [PantryItem(name: 'Eier')]);
    expect(find.text('im Vorrat'), findsOneWidget);
    expect(find.text('kcal heute'), findsOneWidget);
    await tester.tap(find.text('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalorienzähler'));
    await tester.pumpAndSettle();
    expect(find.text('0 von 8 Gläsern'), findsOneWidget);
    await tester.tap(find.byTooltip('Wasser +'));
    await tester.tap(find.byTooltip('Wasser +'));
    await tester.pumpAndSettle();
    expect(find.text('2 von 8 Gläsern'), findsOneWidget);
    await tester.tap(find.byTooltip('Wasser −'));
    await tester.pumpAndSettle();
    expect(find.text('1 von 8 Gläsern'), findsOneWidget);
  });
}
