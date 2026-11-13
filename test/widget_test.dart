import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/app.dart';
import 'package:fridgechef/models/pantry_item.dart';
import 'package:fridgechef/services/storage.dart';
import 'package:fridgechef/state/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<(FakeClaude, SettingsStore)> pumpApp(
  WidgetTester tester, {
  List<PantryItem> pantry = const [],
  String language = 'de',
  bool pro = true,
  bool onboarded = true,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final store = await LocalStore.open();
  await store.writeList('pantry.items', pantry, (p) => p.toJson());
  await store.setBool('pro.active', pro);
  await store.setBool('settings.onboardingDone', onboarded);
  final settings = SettingsStore(store, MemorySecretStore('sk-test'));
  await settings.loadSecrets();
  await settings.setLocaleCode(language);

  final fake = FakeClaude();
  await tester.pumpWidget(FridgeChefApp(
    store: store,
    settings: settings,
    aiFactory: fake.service,
  ));
  await tester.pumpAndSettle();
  return (fake, settings);
}

void main() {
  testWidgets('empty pantry shows onboarding actions', (tester) async {
    await pumpApp(tester);
    expect(find.text('Dein Kühlschrank ist noch leer'), findsOneWidget);
    expect(find.text('Kühlschrank scannen'), findsWidgets);
    expect(find.text('Manuell hinzufügen'), findsOneWidget);
  });

  testWidgets('add a pantry item manually', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Manuell hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Karotten');
    await tester.tap(find.text('+3'));
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Karotten'), findsOneWidget);
    expect(find.text('Noch 3 Tage'), findsOneWidget);
  });

  testWidgets('pantry → recipes → detail → shopping list → cooking mode',
      (tester) async {
    final (fake, _) = await pumpApp(tester, pantry: [
      PantryItem(name: 'Eier', category: FoodCategory.dairy),
      PantryItem(
        name: 'Tomaten',
        category: FoodCategory.produce,
        expiryDate: DateTime.now().add(const Duration(days: 1)),
      ),
    ]);

    expect(find.text('Mein Vorrat'), findsOneWidget);
    expect(find.text('laufen bald ab'), findsOneWidget);

    // Generate suggestions.
    await tester.tap(find.text('Rezepte finden'));
    await tester.pumpAndSettle();
    expect(fake.requests, hasLength(1));
    final prompt = fake.requests.single['messages'][0]['content'][0]['text'] as String;
    expect(prompt, contains('Tomaten'));
    expect(prompt, contains('EXPIRES IN 1 DAY'));

    expect(find.text('Tomaten-Mozzarella-Omelett'), findsOneWidget);
    expect(find.text('Steak mit Pommes'), findsOneWidget);
    expect(find.text('2 von 4 Zutaten vorhanden'), findsOneWidget);
    expect(find.textContaining('Verwertet 1 bald ablaufendes'), findsOneWidget);

    // Vegetarian filter hides the steak.
    await tester.tap(find.widgetWithText(FilterChip, 'Vegetarisch'));
    await tester.pumpAndSettle();
    expect(find.text('Steak mit Pommes'), findsNothing);

    // Recipe detail with portion calculator.
    await tester.tap(find.text('Tomaten-Mozzarella-Omelett'));
    await tester.pumpAndSettle();
    expect(find.text('2 Portionen'), findsOneWidget);
    expect(find.text('125 g'), findsOneWidget);
    await tester.tap(find.byTooltip('+'));
    await tester.pumpAndSettle();
    expect(find.text('3 Portionen'), findsOneWidget);
    expect(find.text('6'), findsOneWidget); // 4 eggs × 3/2
    expect(find.text('187,5 g'), findsOneWidget);

    // One tap: missing ingredients onto the shopping list.
    final addMissing = find.text('2 fehlende Zutaten auf die Einkaufsliste');
    await tester.scrollUntilVisible(
      addMissing,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(addMissing);
    await tester.pumpAndSettle();
    expect(find.text('2 Zutaten zur Einkaufsliste hinzugefügt'), findsOneWidget);
    expect(addMissing, findsNothing);

    // Nutrition is labelled as an estimate.
    await tester.scrollUntilVisible(
      find.text('Schätzung'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('≈ 380 kcal'), findsOneWidget);
    await tester.tap(find.text('gesamt (3 P.)'));
    await tester.pumpAndSettle();
    expect(find.text('≈ 1140 kcal'), findsOneWidget);

    // Cooking mode (after the snack bar has gone).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kochmodus starten'));
    await tester.pumpAndSettle();
    expect(find.text('Schritt 1 von 2'), findsOneWidget);
    expect(find.text('Eier verquirlen.'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('Timer starten'), findsOneWidget);
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    expect(find.text('Guten Appetit!'), findsOneWidget);
    await tester.tap(find.text('Nichts ändern'));
    await tester.pumpAndSettle();

    // Back on the detail screen → back to the list → shopping tab.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einkauf'));
    await tester.pumpAndSettle();
    expect(find.text('Mozzarella'), findsOneWidget);
    expect(find.text('Basilikum'), findsOneWidget);
    expect(find.text('Für: Tomaten-Mozzarella-Omelett'), findsNWidgets(2));

    // History recorded the viewed recipe.
    await tester.tap(find.text('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verlauf'));
    await tester.pumpAndSettle();
    expect(find.text('Tomaten-Mozzarella-Omelett'), findsOneWidget);
  });

  testWidgets('settings switch language and theme', (tester) async {
    final (_, settings) = await pumpApp(tester);
    await tester.tap(find.text('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dunkel'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.dark);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Pantry'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
  });
}
