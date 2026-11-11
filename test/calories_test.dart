import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/models/food_log.dart';
import 'package:fridgechef/models/pantry_item.dart';
import 'package:fridgechef/services/storage.dart';
import 'package:fridgechef/state/food_log_store.dart';
import 'package:fridgechef/ui/calories/entry_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';
import 'widget_test.dart' show pumpApp;

void main() {
  group('FoodLogStore', () {
    late FoodLogStore log;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      log = FoodLogStore(await LocalStore.open());
    });

    test('totals per day, week overview and goal', () async {
      expect(log.goal, 2000);
      await log.add(
        FoodLogEntry(
          name: 'A',
          calories: 300,
          proteinG: 10,
          carbsG: 30,
          fatG: 5,
        ),
      );
      await log.add(FoodLogEntry(name: 'B', calories: 450.5, proteinG: 20));
      await log.add(FoodLogEntry(name: 'C', calories: 800, eatenAt: yesterday));

      final t = log.totalsFor(today);
      expect(t.calories, 750.5);
      expect(t.proteinG, 30);
      expect(t.carbsG, 30);
      expect(log.entriesFor(yesterday).single.name, 'C');

      final week = log.week(today);
      expect(week, hasLength(7));
      expect(week.last.$2, 750.5);
      expect(week[5].$2, 800);
      expect(week.first.$2, 0);

      await log.setGoal(100000);
      expect(log.goal, FoodLogStore.maxGoal);
      await log.setGoal(1800);
      expect(log.goal, 1800);
    });

    test('persists and drops entries older than three months', () async {
      final store = await LocalStore.open();
      await store.writeList('foodlog.entries', [
        FoodLogEntry(
          name: 'alt',
          calories: 1,
          eatenAt: today.subtract(const Duration(days: 200)),
        ),
        FoodLogEntry(name: 'neu', calories: 2, estimated: true),
      ], (e) => e.toJson());
      final reloaded = FoodLogStore(store);
      expect(reloaded.entriesFor(today).single.name, 'neu');
      expect(reloaded.entriesFor(today).single.estimated, isTrue);
      expect(
        reloaded.entriesFor(today.subtract(const Duration(days: 200))),
        isEmpty,
      );
    });
  });

  test('entryTimeFor uses now for today and noon for other days', () {
    final now = DateTime(2026, 11, 11, 18, 30);
    expect(entryTimeFor(DateTime(2026, 11, 11), now), now);
    expect(entryTimeFor(DateTime(2026, 11, 9), now), DateTime(2026, 11, 9, 12));
  });

  test('estimateMeal sends text and photo, parses the estimate', () async {
    final fake = FakeClaude();
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1]);
    final e = await fake
        .service('k')
        .estimateMeal(
          description: 'Käsebrot und ein Apfel',
          photo: jpeg,
          languageCode: 'de',
        );
    expect(e!.name, 'Käsebrot mit Apfel');
    expect(e.calories, 420);
    final content = fake.requests.single['messages'][0]['content'] as List;
    expect(content.first['type'], 'image');
    expect(content.last['text'], 'What I ate: Käsebrot und ein Apfel');
    expect(fake.requests.single['output_config']['effort'], 'low');
  });

  testWidgets('diary: AI estimate, manual entry, goal ring, delete', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Mehr'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 2000 kcal'), findsOneWidget);
    await tester.tap(find.text('Kalorienzähler'));
    await tester.pumpAndSettle();
    expect(
      find.text('Für diesen Tag ist noch nichts eingetragen.'),
      findsOneWidget,
    );
    expect(find.text('2000 übrig'), findsOneWidget);

    // AI estimate from a description fills the form.
    await tester.tap(find.text('Eintrag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mit KI schätzen'));
    await tester.pumpAndSettle();
    expect(
      find.text('Beschreibe die Mahlzeit oder füge ein Foto hinzu.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Was hast du gegessen?'),
      'Käsebrot und ein Apfel',
    );
    await tester.tap(find.text('Mit KI schätzen'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '420'), findsOneWidget);
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('≈ 420 kcal'), findsOneWidget);
    expect(find.text('1580 übrig'), findsOneWidget);

    // Manual entry; validation needs calories.
    await tester.tap(find.text('Eintrag'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Was hast du gegessen?'),
      'Pizza',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Bitte Kalorien eingeben'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kalorien'),
      '1700,5',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('1701 kcal'), findsOneWidget);
    expect(find.text('121 über dem Ziel'), findsOneWidget);

    // Swipe to delete.
    await tester.drag(find.text('Pizza'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('1580 übrig'), findsOneWidget);
  });

  testWidgets('log a recipe as eaten', (tester) async {
    await pumpApp(tester, pantry: [PantryItem(name: 'Eier')]);
    await tester.tap(find.text('Rezepte finden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomaten-Mozzarella-Omelett'));
    await tester.pumpAndSettle();
    final button = find.text('Als gegessen eintragen');
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('≈ 380 kcal'), findsNWidgets(2)); // card + dialog
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    expect(find.text('≈ 570 kcal'), findsOneWidget); // 1½ servings
    await tester.tap(find.text('Hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.text('Im Kalorienzähler eingetragen'), findsOneWidget);

    final log = tester.element(button).read<FoodLogStore>();
    final entry = log.entriesFor(DateTime.now()).single;
    expect(entry.name, 'Tomaten-Mozzarella-Omelett');
    expect(entry.calories, 570);
    expect(entry.proteinG, 39);
    expect(entry.estimated, isTrue);
  });
}
