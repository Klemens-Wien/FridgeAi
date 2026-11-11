import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/models/pantry_item.dart';
import 'package:fridgechef/models/recipe_filters.dart';
import 'package:fridgechef/services/claude_client.dart';
import 'package:fridgechef/services/fridge_ai_service.dart';
import 'package:fridgechef/services/image_utils.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fakes.dart';

void main() {
  group('ClaudeClient', () {
    test('sends the expected headers and body', () async {
      late http.Request captured;
      final client = ClaudeClient(
        apiKey: ' sk-test ',
        baseUrl: 'https://api.example.com',
        model: 'claude-opus-5-5',
        httpClient: MockClient((req) async {
          captured = req;
          return messageResponse({'ok': true});
        }),
      );
      final result = await client.createJson(
        system: 'sys',
        content: [ClaudeClient.textBlock('hi')],
        schema: {'type': 'object'},
        effort: 'low',
      );
      expect(result, {'ok': true});
      expect(captured.url.toString(), 'https://api.example.com/v1/messages');
      expect(captured.headers['x-api-key'], 'sk-test');
      expect(captured.headers['anthropic-version'], '2026-10-21');
      expect(captured.headers['anthropic-beta'], 'server-side-fallback-2026-07-01');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'claude-opus-5-5');
      expect(body['system'], 'sys');
      expect(body['fallbacks'], 'default');
      expect(body['output_config']['effort'], 'low');
      expect(body['output_config']['format']['type'], 'json_schema');
      expect(body.containsKey('thinking'), isFalse);
      expect(body.containsKey('temperature'), isFalse);
    });

    test('missing key fails fast without a request', () async {
      var called = false;
      final client = ClaudeClient(
        apiKey: '',
        httpClient: MockClient((_) async {
          called = true;
          return http.Response('', 200);
        }),
      );
      await expectLater(
        client.createJson(system: '', content: [], schema: {}),
        throwsA(isA<ClaudeException>()
            .having((e) => e.kind, 'kind', ClaudeErrorKind.missingApiKey)),
      );
      expect(called, isFalse);
    });

    test('maps HTTP errors', () async {
      Future<ClaudeErrorKind> kindFor(int status) async {
        final client = ClaudeClient(
          apiKey: 'k',
          maxRetries: 0,
          httpClient: MockClient((_) async => http.Response(
                jsonEncode({
                  'type': 'error',
                  'error': {'type': 'x', 'message': 'nope'},
                }),
                status,
              )),
        );
        try {
          await client.createJson(system: '', content: [], schema: {});
        } on ClaudeException catch (e) {
          return e.kind;
        }
        fail('expected an exception');
      }

      expect(await kindFor(401), ClaudeErrorKind.invalidApiKey);
      expect(await kindFor(429), ClaudeErrorKind.rateLimited);
      expect(await kindFor(400), ClaudeErrorKind.badRequest);
      expect(await kindFor(529), ClaudeErrorKind.overloaded);
    });

    test('retries overloaded responses, then succeeds', () async {
      var calls = 0;
      final client = ClaudeClient(
        apiKey: 'k',
        httpClient: MockClient((_) async {
          calls++;
          if (calls == 1) {
            return http.Response('{}', 529, headers: {'retry-after': '0'});
          }
          return messageResponse({'ok': 1});
        }),
      );
      expect(await client.createJson(system: '', content: [], schema: {}), {'ok': 1});
      expect(calls, 2);
    });

    test('refusal and max_tokens are reported, not parsed', () {
      expect(
        () => ClaudeClient.parseJsonResponse({
          'stop_reason': 'refusal',
          'stop_details': {'type': 'refusal', 'category': null, 'explanation': 'x'},
          'content': [],
        }),
        throwsA(isA<ClaudeException>()
            .having((e) => e.kind, 'kind', ClaudeErrorKind.refused)),
      );
      expect(
        () => ClaudeClient.parseJsonResponse({
          'stop_reason': 'max_tokens',
          'content': [
            {'type': 'text', 'text': '{"a":'},
          ],
        }),
        throwsA(isA<ClaudeException>()
            .having((e) => e.kind, 'kind', ClaudeErrorKind.truncated)),
      );
    });

    test('skips thinking and fallback blocks', () {
      final json = ClaudeClient.parseJsonResponse({
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'thinking', 'thinking': ''},
          {'type': 'fallback', 'from': {}, 'to': {}},
          {'type': 'text', 'text': '{"x": 1}'},
        ],
      });
      expect(json, {'x': 1});
    });
  });

  group('FridgeAiService', () {
    test('detectIngredients sends every photo and parses items', () async {
      final fake = FakeClaude();
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);
      final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
      final items = await fake
          .service('k')
          .detectIngredients([jpeg, png], languageCode: 'de');

      final content = fake.requests.single['messages'][0]['content'] as List;
      final images = content.where((b) => b['type'] == 'image').toList();
      expect(images, hasLength(2));
      expect(images[0]['source']['media_type'], 'image/jpeg');
      expect(images[1]['source']['media_type'], 'image/png');
      expect(fake.requests.single['system'], contains('German'));

      expect(items.map((i) => i.name), ['Eier', 'Tomaten', 'Unklares Glas']);
      // Low-confidence items start unselected.
      expect(items.map((i) => i.selected), [true, true, false]);
      expect(items[1].shelfLifeDays, 5);
    });

    test('recipe prompt lists pantry, expiry markers and filters', () {
      final now = DateTime(2026, 11, 11);
      final prompt = FridgeAiService.recipeUserPrompt(
        pantry: [
          PantryItem(name: 'Spinat', quantity: '200 g', expiryDate: DateTime(2026, 11, 12)),
          PantryItem(name: 'Reis'),
        ],
        filters: const RecipeFilters(vegan: true, maxMinutes: 30),
        servings: 3,
        prioritizeExpiring: true,
        count: 6,
        avoidTitles: ['Risotto'],
        now: now,
      );
      expect(prompt, contains('- Spinat (200 g) [EXPIRES IN 1 DAY(S) - use up]'));
      expect(prompt, contains('- Reis'));
      expect(prompt, contains('Servings per recipe: 3'));
      expect(prompt, contains('Vegan'));
      expect(prompt, isNot(contains('Vegetarian (no meat')));
      expect(prompt, contains('at most 30 minutes'));
      expect(prompt, contains('Prioritise using the items marked as expiring'));
      expect(prompt, contains('Risotto'));
      expect(prompt, contains('Suggest 6 recipes.'));
    });

    test('suggestRecipes parses the structured output', () async {
      final fake = FakeClaude();
      final recipes = await fake.service('k').suggestRecipes(
            pantry: [PantryItem(name: 'Eier')],
            filters: const RecipeFilters(),
            languageCode: 'en',
            servings: 2,
          );
      expect(recipes, hasLength(2));
      final r = recipes.first;
      expect(r.languageCode, 'en');
      expect(r.ingredients, hasLength(5));
      expect(r.steps[1].timerSeconds, 300);
      expect(r.nutrition.calories, 380);
      expect(fake.requests.single['system'], contains('English'));
    });

    test('schemas satisfy structured-output rules', () {
      void check(Object? node) {
        if (node is Map) {
          if (node['type'] == 'object') {
            expect(node['additionalProperties'], isFalse);
            final props = (node['properties'] as Map).keys.toSet();
            expect((node['required'] as List).toSet(), props);
          }
          node.values.forEach(check);
        } else if (node is List) {
          node.forEach(check);
        }
      }

      check(FridgeAiService.recipeSchema);
      check(FridgeAiService.ingredientSchema);
    });
  });

  test('detectImageMediaType', () {
    expect(detectImageMediaType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0])), 'image/jpeg');
    expect(
      detectImageMediaType(Uint8List.fromList(
        [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50],
      )),
      'image/webp',
    );
    expect(
      () => detectImageMediaType(Uint8List.fromList([0, 0, 0, 0x18, 0x66, 0x74])),
      throwsA(isA<UnsupportedImageException>()),
    );
  });
}
