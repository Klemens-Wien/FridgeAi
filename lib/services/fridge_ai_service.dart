import 'dart:convert';
import 'dart:typed_data';

import '../config.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/recipe_filters.dart';
import 'ai_backend.dart';
import 'claude_client.dart';
import 'image_utils.dart';

/// FridgeChef's two AI tasks: recognising food in photos and suggesting
/// recipes for what is at hand.
class FridgeAiService {
  FridgeAiService(this.client);

  final AiBackend client;

  static String _languageName(String code) =>
      code == 'de' ? 'German' : 'English';

  // ---------------------------------------------------------------------------
  // Ingredient recognition
  // ---------------------------------------------------------------------------

  static final Map<String, dynamic> ingredientSchema = {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'quantity': {'type': 'string'},
            'category': {
              'type': 'string',
              'enum': FoodCategory.values.map((c) => c.name).toList(),
            },
            'confidence': {
              'type': 'string',
              'enum': DetectionConfidence.values.map((c) => c.name).toList(),
            },
            'shelfLifeDays': {'type': 'integer'},
          },
          'required': [
            'name',
            'quantity',
            'category',
            'confidence',
            'shelfLifeDays',
          ],
          'additionalProperties': false,
        },
      },
    },
    'required': ['items'],
    'additionalProperties': false,
  };

  static String ingredientSystemPrompt(String languageCode) => '''
You are the food-recognition component of FridgeChef, a cooking app. The user
photographs the inside of their fridge, freezer or pantry - sometimes several
photos of the same shelves from different angles.

Your job is to list the distinct food items that are visible, so the app can
suggest recipes. The list is shown to the user for review and editing.

Guidelines:
- Merge duplicates across photos: the same carton seen in two photos is one item.
- Use short, generic grocery names a shopper would write on a list
  ("Milk", "Cherry tomatoes", "Cheddar"), not brand names. Write every name and
  quantity in ${_languageName(languageCode)}.
- Estimate quantity loosely when you can ("2 pieces", "about 500 g", "half a
  bottle"); use an empty string if you cannot tell.
- Only include food and drink ingredients. Skip non-food items, empty
  containers and things you cannot identify at all.
- Packaged items whose contents you cannot read: include them only if the
  packaging makes the product clear, and mark confidence "low" if you are
  guessing.
- shelfLifeDays: a typical remaining shelf life in days for this kind of item
  once it is in a home fridge or pantry (e.g. fresh herbs 4, milk 5,
  hard cheese 21, canned goods 365). Use 0 if it does not make sense.
- If no food is visible, return an empty list.
''';

  Future<List<DetectedIngredient>> detectIngredients(
    List<Uint8List> photos, {
    required String languageCode,
  }) async {
    final content = <Map<String, dynamic>>[];
    for (var i = 0; i < photos.length; i++) {
      final bytes = photos[i];
      content
        ..add(ClaudeClient.textBlock('Photo ${i + 1}:'))
        ..add(ClaudeClient.imageBlock(detectImageMediaType(bytes), base64Encode(bytes)));
    }
    content.add(ClaudeClient.textBlock(
      'List the food items visible in ${photos.length == 1 ? 'this photo' : 'these ${photos.length} photos'}.',
    ));

    final json = await client.createJson(
      system: ingredientSystemPrompt(languageCode),
      content: content,
      schema: ingredientSchema,
      effort: 'medium',
    );
    return parseDetectedIngredients(json);
  }

  static List<DetectedIngredient> parseDetectedIngredients(
    Map<String, dynamic> json,
  ) {
    final seen = <String>{};
    final items = <DetectedIngredient>[];
    for (final raw in (json['items'] as List? ?? const [])) {
      if (raw is! Map<String, dynamic>) continue;
      final item = DetectedIngredient.fromJson(raw);
      if (item.name.isEmpty) continue;
      if (!seen.add(item.name.toLowerCase())) continue;
      item.selected = item.confidence != DetectionConfidence.low;
      items.add(item);
    }
    return items;
  }

  // ---------------------------------------------------------------------------
  // Recipe suggestions
  // ---------------------------------------------------------------------------

  static final Map<String, dynamic> recipeSchema = {
    'type': 'object',
    'properties': {
      'recipes': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'description': {'type': 'string'},
            'servings': {'type': 'integer'},
            'prepMinutes': {'type': 'integer'},
            'cookMinutes': {'type': 'integer'},
            'difficulty': {
              'type': 'string',
              'enum': Difficulty.values.map((d) => d.name).toList(),
            },
            'vegetarian': {'type': 'boolean'},
            'vegan': {'type': 'boolean'},
            'glutenFree': {'type': 'boolean'},
            'lowCarb': {'type': 'boolean'},
            'ingredients': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                  'amount': {'type': 'number'},
                  'unit': {'type': 'string'},
                  'pantryItem': {'type': 'string'},
                  'isStaple': {'type': 'boolean'},
                },
                'required': ['name', 'amount', 'unit', 'pantryItem', 'isStaple'],
                'additionalProperties': false,
              },
            },
            'steps': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'text': {'type': 'string'},
                  'timerSeconds': {'type': 'integer'},
                },
                'required': ['text', 'timerSeconds'],
                'additionalProperties': false,
              },
            },
            'nutrition': {
              'type': 'object',
              'properties': {
                'calories': {'type': 'number'},
                'proteinG': {'type': 'number'},
                'carbsG': {'type': 'number'},
                'fatG': {'type': 'number'},
                'fiberG': {'type': 'number'},
              },
              'required': ['calories', 'proteinG', 'carbsG', 'fatG', 'fiberG'],
              'additionalProperties': false,
            },
          },
          'required': [
            'title',
            'description',
            'servings',
            'prepMinutes',
            'cookMinutes',
            'difficulty',
            'vegetarian',
            'vegan',
            'glutenFree',
            'lowCarb',
            'ingredients',
            'steps',
            'nutrition',
          ],
          'additionalProperties': false,
        },
      },
    },
    'required': ['recipes'],
    'additionalProperties': false,
  };

  static String recipeSystemPrompt(String languageCode) => '''
You are the recipe engine of FridgeChef, a cooking app that helps people cook
with what they already have and waste less food. Write realistic, tested-style
home recipes that a normal home cook can follow.

How the app uses your output:
- Recipes are ranked by how many of the user's pantry items they use, so build
  each recipe around the pantry and keep extra shopping to a minimum (ideally
  0-3 missing ingredients, never more than 5).
- For every ingredient, set "pantryItem" to the exact name of the pantry item
  it uses, copied verbatim from the pantry list, or "" if it is not in the
  pantry. The app matches on this field.
- Set "isStaple" to true only for basics almost every kitchen has: salt,
  pepper, cooking oil, water, sugar, flour, vinegar, common dried spices.
  Staples are not counted as missing.
- "amount" is a number for the given servings (0 means "to taste"); "unit" is
  a short unit such as g, ml, EL/TL (German) or tbsp/tsp (English), "piece",
  or "" for countable items.
- Steps: one action per step, in order. If a step involves waiting for a fixed
  time (simmering, baking, resting), set "timerSeconds" to that duration;
  otherwise 0.
- nutrition: your best estimate PER SERVING (kcal and grams). The app labels
  it as an estimate.
- Diet flags must be accurate for the recipe as written: vegan implies
  vegetarian; glutenFree only if no ingredient normally contains gluten;
  lowCarb if roughly under 20 g carbohydrates per serving.
- Respect every dietary filter and limit the user sets. Recipes that violate
  them are discarded by the app.
- Make the recipes clearly different from each other (cuisine, dish type,
  technique).
- Write all text (titles, descriptions, ingredient names, units, steps) in
  ${_languageName(languageCode)}.
''';

  static String recipeUserPrompt({
    required List<PantryItem> pantry,
    required RecipeFilters filters,
    required int servings,
    required bool prioritizeExpiring,
    required int count,
    List<String> avoidTitles = const [],
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final lines = pantry.map((p) {
      final parts = <String>[p.name];
      if (p.quantity.isNotEmpty) parts.add('(${p.quantity})');
      final days = p.daysUntilExpiry(today);
      if (days != null) {
        if (days < 0) {
          parts.add('[past its date by ${-days} day(s) - only if still usable]');
        } else if (days <= expirySoonThresholdDays) {
          parts.add('[EXPIRES IN $days DAY(S) - use up]');
        } else {
          parts.add('[expires in $days days]');
        }
      }
      return '- ${parts.join(' ')}';
    }).join('\n');

    final constraints = <String>[
      'Servings per recipe: $servings',
      if (filters.vegan) 'Vegan (no animal products at all)',
      if (filters.vegetarian && !filters.vegan) 'Vegetarian (no meat or fish)',
      if (filters.glutenFree) 'Gluten-free',
      if (filters.lowCarb) 'Low carb (under ~20 g carbohydrates per serving)',
      if (filters.maxMinutes != null)
        'Total time (prep + cook) at most ${filters.maxMinutes} minutes',
      if (filters.difficulty != null)
        'Difficulty at most "${filters.difficulty!.name}"',
    ];

    return [
      'My pantry:',
      lines.isEmpty ? '(empty - suggest recipes with few, common ingredients)' : lines,
      '',
      'Requirements:',
      ...constraints.map((c) => '- $c'),
      if (prioritizeExpiring)
        '- Prioritise using the items marked as expiring soon; at least half '
            'of the recipes should use one or more of them if possible.',
      if (avoidTitles.isNotEmpty)
        '- Do not repeat these recipes I have already seen: ${avoidTitles.join('; ')}',
      '',
      'Suggest $count recipes.',
    ].join('\n');
  }

  Future<List<Recipe>> suggestRecipes({
    required List<PantryItem> pantry,
    required RecipeFilters filters,
    required String languageCode,
    required int servings,
    bool prioritizeExpiring = true,
    List<String> avoidTitles = const [],
    int count = AppConfig.recipesPerRequest,
  }) async {
    final json = await client.createJson(
      system: recipeSystemPrompt(languageCode),
      content: [
        ClaudeClient.textBlock(recipeUserPrompt(
          pantry: pantry,
          filters: filters,
          servings: servings,
          prioritizeExpiring: prioritizeExpiring,
          count: count,
          avoidTitles: avoidTitles,
        )),
      ],
      schema: recipeSchema,
      effort: 'medium',
    );
    return parseRecipes(json, languageCode: languageCode);
  }

  static List<Recipe> parseRecipes(
    Map<String, dynamic> json, {
    required String languageCode,
  }) =>
      (json['recipes'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((r) => Recipe.fromJson(r, languageCode: languageCode))
          .where((r) => r.title.isNotEmpty && r.ingredients.isNotEmpty)
          .toList();
}
