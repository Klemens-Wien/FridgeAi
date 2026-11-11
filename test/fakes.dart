import 'dart:convert';

import 'package:fridgechef/services/claude_client.dart';
import 'package:fridgechef/services/fridge_ai_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Wraps [payload] the way the Messages API returns structured output.
http.Response messageResponse(Object payload, {String stopReason = 'end_turn'}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode({
        'id': 'msg_test',
        'type': 'message',
        'role': 'assistant',
        'model': 'claude-opus-5-5',
        'stop_reason': stopReason,
        'content': [
          {'type': 'thinking', 'thinking': '', 'signature': 'sig'},
          {'type': 'text', 'text': jsonEncode(payload)},
        ],
        'usage': {'input_tokens': 10, 'output_tokens': 10},
      })),
      200,
      headers: {'content-type': 'application/json'},
    );

final sampleRecipes = {
  'recipes': [
    {
      'title': 'Tomaten-Mozzarella-Omelett',
      'description': 'Schnelles Omelett mit Resten.',
      'servings': 2,
      'prepMinutes': 5,
      'cookMinutes': 10,
      'difficulty': 'easy',
      'vegetarian': true,
      'vegan': false,
      'glutenFree': true,
      'lowCarb': true,
      'ingredients': [
        {'name': 'Eier', 'amount': 4, 'unit': '', 'pantryItem': 'Eier', 'isStaple': false},
        {'name': 'Tomaten', 'amount': 2, 'unit': '', 'pantryItem': 'Tomaten', 'isStaple': false},
        {'name': 'Mozzarella', 'amount': 125, 'unit': 'g', 'pantryItem': '', 'isStaple': false},
        {'name': 'Basilikum', 'amount': 0, 'unit': '', 'pantryItem': '', 'isStaple': false},
        {'name': 'Salz', 'amount': 0, 'unit': '', 'pantryItem': '', 'isStaple': true},
      ],
      'steps': [
        {'text': 'Eier verquirlen.', 'timerSeconds': 0},
        {'text': 'In der Pfanne 5 Minuten stocken lassen.', 'timerSeconds': 300},
      ],
      'nutrition': {
        'calories': 380,
        'proteinG': 26,
        'carbsG': 5,
        'fatG': 28,
        'fiberG': 1,
      },
    },
    {
      'title': 'Steak mit Pommes',
      'description': 'Fleischgericht, das den Vegetarisch-Filter nicht erfüllt.',
      'servings': 2,
      'prepMinutes': 10,
      'cookMinutes': 30,
      'difficulty': 'medium',
      'vegetarian': false,
      'vegan': false,
      'glutenFree': true,
      'lowCarb': false,
      'ingredients': [
        {'name': 'Rindersteak', 'amount': 400, 'unit': 'g', 'pantryItem': '', 'isStaple': false},
      ],
      'steps': [
        {'text': 'Braten.', 'timerSeconds': 0},
      ],
      'nutrition': {
        'calories': 700,
        'proteinG': 50,
        'carbsG': 40,
        'fatG': 35,
        'fiberG': 3,
      },
    },
  ],
};

final sampleIngredients = {
  'items': [
    {
      'name': 'Eier',
      'quantity': '6 Stück',
      'category': 'dairy',
      'confidence': 'high',
      'shelfLifeDays': 14,
    },
    {
      'name': 'Tomaten',
      'quantity': '3',
      'category': 'produce',
      'confidence': 'high',
      'shelfLifeDays': 5,
    },
    {
      'name': 'Unklares Glas',
      'quantity': '',
      'category': 'other',
      'confidence': 'low',
      'shelfLifeDays': 0,
    },
  ],
};

final sampleMealEstimate = {
  'name': 'Käsebrot mit Apfel',
  'calories': 420,
  'proteinG': 16,
  'carbsG': 48,
  'fatG': 17,
};

final sampleSubstitutes = {
  'substitutes': [
    {'name': 'Eier', 'note': 'Macht das Omelett fester.', 'pantryItem': 'Eier'},
    {'name': 'Feta', 'note': 'Etwas salziger.', 'pantryItem': ''},
    {'name': 'Gouda', 'note': 'Angeblich im Vorrat.', 'pantryItem': 'Gouda'},
  ],
};

/// A Claude client backed by [MockClient] that answers recipe and ingredient
/// requests with the samples above and records every request body.
class FakeClaude {
  final List<Map<String, dynamic>> requests = [];

  late final MockClient http = MockClient((req) async {
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    requests.add(body);
    final schema = body['output_config']['format']['schema'] as Map;
    final props = schema['properties'] as Map;
    if (props.containsKey('substitutes')) return messageResponse(sampleSubstitutes);
    if (props.containsKey('calories')) return messageResponse(sampleMealEstimate);
    return messageResponse(
      props.containsKey('recipes') ? sampleRecipes : sampleIngredients,
    );
  });

  FridgeAiService service(String apiKey) =>
      FridgeAiService(ClaudeClient(apiKey: apiKey, httpClient: http));
}
