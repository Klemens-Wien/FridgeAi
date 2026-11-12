import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/l10n/strings.dart';
import 'package:fridgechef/logic/recipe_ranking.dart';
import 'package:fridgechef/logic/share_text.dart';
import 'package:fridgechef/models/pantry_item.dart';
import 'package:fridgechef/models/recipe.dart';
import 'package:fridgechef/models/recipe_filters.dart';
import 'package:fridgechef/models/shopping_item.dart';
import 'package:fridgechef/services/fridge_ai_service.dart';

import 'package:fridgechef/state/recipe_store.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';
import 'widget_test.dart' show pumpApp;

void main() {
  final omelette = Recipe.fromJson(
    (sampleRecipes['recipes'] as List).first as Map<String, dynamic>,
  );

  test('usesAvoidedIngredient matches by containment', () {
    final r = Recipe(
      title: 'x',
      ingredients: const [
        RecipeIngredient(name: 'Walnüsse'),
        RecipeIngredient(name: 'Ei'),
      ],
    );
    expect(usesAvoidedIngredient(r, ['Nüsse']), isTrue);
    expect(usesAvoidedIngredient(r, ['Pilze']), isFalse);
    expect(usesAvoidedIngredient(r, []), isFalse);
    // Too-short terms never match everything.
    expect(usesAvoidedIngredient(r, ['e']), isFalse);
  });

  test('recipe prompt carries wish and ingredients to avoid', () {
    final prompt = FridgeAiService.recipeUserPrompt(
      pantry: [PantryItem(name: 'Reis')],
      filters: const RecipeFilters(),
      servings: 2,
      prioritizeExpiring: false,
      count: 6,
      avoidIngredients: ['Nüsse', 'Pilze'],
      wish: ' etwas Asiatisches ',
    );
    expect(prompt, contains('Never use these ingredients'));
    expect(prompt, contains('Nüsse, Pilze'));
    expect(prompt, contains('What I feel like today'));
    expect(prompt, contains('etwas Asiatisches'));
    expect(prompt, isNot(contains('Prioritise using')));
  });

  test('share texts', () {
    final s = S.forLanguage('de');
    final text = recipeShareText(omelette, 4, s);
    expect(
      text,
      startsWith('Tomaten-Mozzarella-Omelett\n4 Portionen · 15 Min. · Einfach'),
    );
    expect(text, contains('- 8 Eier')); // scaled from 2 to 4 servings
    expect(text, contains('- 250 g Mozzarella'));
    expect(text, contains('- Salz'));
    expect(text, contains('2. In der Pfanne 5 Minuten stocken lassen.'));
    expect(text, contains('≈ 380 kcal pro Portion (Schätzung)'));

    final list = shoppingShareText([
      ShoppingItem(name: 'Mozzarella', amount: 125, unit: 'g'),
      ShoppingItem(name: 'Basilikum'),
      ShoppingItem(name: 'Milch', checked: true),
    ], s);
    expect(list, 'Einkaufsliste:\n- 125 g Mozzarella\n- Basilikum');
  });

  test('suggestSubstitutes parses the answer', () async {
    final fake = FakeClaude();
    final subs = await fake
        .service('k')
        .suggestSubstitutes(
          recipe: omelette,
          ingredient: omelette.ingredients[2],
          pantry: [PantryItem(name: 'Eier')],
          languageCode: 'de',
          avoidIngredients: ['Nüsse'],
        );
    expect(subs.map((s) => s.name), ['Eier', 'Feta', 'Gouda']);
    final prompt =
        fake.requests.single['messages'][0]['content'][0]['text'] as String;
    expect(prompt, contains('Missing ingredient: Mozzarella (125.0 g)'));
    expect(prompt, contains('My pantry: Eier'));
    expect(prompt, contains('Ingredients to avoid: Nüsse'));
  });

  testWidgets('substitutes, copy, avoid list, wish and stats', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );

    final (fake, settings) = await pumpApp(
      tester,
      pantry: [
        PantryItem(name: 'Eier'),
        PantryItem(
          name: 'Tomaten',
          expiryDate: DateTime.now().add(const Duration(days: 1)),
        ),
      ],
    );
    await settings.addAvoidIngredient('Nüsse');

    // Wish field feeds the prompt.
    await tester.tap(find.text('Rezepte'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Worauf hast du Lust? (optional)'),
      'etwas Schnelles',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    final prompt =
        fake.requests.last['messages'][0]['content'][0]['text'] as String;
    expect(prompt, contains('etwas Schnelles'));
    expect(prompt, contains('Nüsse'));
    expect(find.text('Steak mit Pommes'), findsOneWidget);

    // Adding an ingredient to avoid hides matching recipes at once.
    await settings.addAvoidIngredient('Rindersteak');
    await tester.pumpAndSettle();
    expect(find.text('Steak mit Pommes'), findsNothing);

    // Detail: copy and substitutes.
    await tester.tap(find.text('Tomaten-Mozzarella-Omelett'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rezept kopieren'));
    await tester.pumpAndSettle();
    expect(copied.single, contains('- 125 g Mozzarella'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mozzarella'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ersatz finden'));
    await tester.pumpAndSettle();
    expect(find.text('Feta'), findsOneWidget);
    // Only the substitute that really is in the pantry is marked as such.
    expect(find.text('Vorhanden · Macht das Omelett fester.'), findsOneWidget);
    expect(find.text('Angeblich im Vorrat.'), findsOneWidget);
    await tester.tap(find.text('Auf die Einkaufsliste'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Cook it: stats count the meal and the rescued tomato.
    await tester.tap(find.text('Kochmodus starten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vorrat aktualisieren'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mehr'));
    await tester.pumpAndSettle();
    expect(find.text('Deine Bilanz'), findsOneWidget);
    expect(find.text('Gerichte gekocht'), findsOneWidget);
    final stats = tester.element(find.text('Deine Bilanz')).read<RecipeStore>();
    expect(stats.cookedCount, 1);
    expect(stats.rescuedCount, 1); // the tomato that expired tomorrow

    // Shopping list can be copied.
    await tester.tap(find.text('Einkauf'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liste kopieren'));
    await tester.pumpAndSettle();
    expect(copied.last, 'Einkaufsliste:\n- 125 g Mozzarella');
  });

  testWidgets('pantry search and grouping', (tester) async {
    final (_, settings) = await pumpApp(
      tester,
      pantry: [
        for (final n in [
          'Apfel',
          'Birne',
          'Karotte',
          'Lauch',
          'Paprika',
          'Zucchini',
        ])
          PantryItem(name: n, category: FoodCategory.produce),
        PantryItem(name: 'Milch', category: FoodCategory.dairy),
      ],
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Vorrat durchsuchen'),
      'mil',
    );
    await tester.pumpAndSettle();
    expect(find.text('Milch'), findsOneWidget);
    expect(find.text('Apfel'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Vorrat durchsuchen'),
      '',
    );
    await settings.setGroupPantry(true);
    await tester.pumpAndSettle();
    expect(find.text('Obst & Gemüse (6)'), findsOneWidget);
    expect(find.text('Milchprodukte & Eier (1)'), findsOneWidget);
  });
}
