import 'package:flutter/foundation.dart';

import '../logic/recipe_ranking.dart' show usesAvoidedIngredient;
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/recipe_filters.dart';
import '../services/claude_client.dart';
import '../services/fridge_ai_service.dart';
import '../services/storage.dart';

typedef AiServiceFactory = FridgeAiService Function(String apiKey);

class HistoryEntry {
  HistoryEntry(this.recipe, this.viewedAt);
  final Recipe recipe;
  final DateTime viewedAt;

  Map<String, dynamic> toJson() =>
      {'recipe': recipe.toJson(), 'viewedAt': viewedAt.toIso8601String()};

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
        DateTime.tryParse(json['viewedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Recipe suggestions, favourites and the "recently viewed/cooked" history.
class RecipeStore extends ChangeNotifier {
  RecipeStore(this._store, this._aiFactory) {
    _suggestions = _store.readList(_kSuggestions, Recipe.fromJson);
    _favorites = _store.readList(_kFavorites, Recipe.fromJson);
    _history = _store.readList(_kHistory, HistoryEntry.fromJson);
    _cookedCount = _store.getInt(_kCooked) ?? 0;
    _rescuedCount = _store.getInt(_kRescued) ?? 0;
  }

  final LocalStore _store;
  final AiServiceFactory _aiFactory;

  static const _kSuggestions = 'recipes.suggestions';
  static const _kFavorites = 'recipes.favorites';
  static const _kHistory = 'recipes.history';
  static const _kCooked = 'stats.cooked';
  static const _kRescued = 'stats.rescued';
  static const maxHistory = 50;

  late List<Recipe> _suggestions;
  late List<Recipe> _favorites;
  late List<HistoryEntry> _history;

  late int _cookedCount;
  late int _rescuedCount;
  bool _loading = false;
  ClaudeException? _error;

  List<Recipe> get suggestions => List.unmodifiable(_suggestions);
  List<Recipe> get favorites => List.unmodifiable(_favorites);
  List<HistoryEntry> get history => List.unmodifiable(_history);
  /// Free-text craving for the next suggestions (not persisted).
  String wish = '';

  bool get loading => _loading;

  /// How many recipes were finished in cooking mode.
  int get cookedCount => _cookedCount;

  /// How many soon-to-expire pantry items were used up by cooking.
  int get rescuedCount => _rescuedCount;

  Future<void> recordCooked({required int rescuedItems}) async {
    _cookedCount++;
    _rescuedCount += rescuedItems;
    notifyListeners();
    await _store.setInt(_kCooked, _cookedCount);
    await _store.setInt(_kRescued, _rescuedCount);
  }
  ClaudeException? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Asks Claude for new suggestions. With [append], the new recipes are added
  /// to the current list (and the model is told not to repeat them).
  Future<void> generate({
    required String apiKey,
    required List<PantryItem> pantry,
    required RecipeFilters filters,
    required String languageCode,
    required int servings,
    required bool prioritizeExpiring,
    List<String> avoidIngredients = const [],
    String wish = '',
    bool append = false,
  }) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final service = _aiFactory(apiKey);
      final recipes = await service.suggestRecipes(
        pantry: pantry,
        filters: filters,
        languageCode: languageCode,
        servings: servings,
        prioritizeExpiring: prioritizeExpiring,
        avoidTitles: append ? _suggestions.map((r) => r.title).toList() : const [],
        avoidIngredients: avoidIngredients,
        wish: wish,
      );
      // Safety net: never show recipes that break the user's diet filters
      // or contain something they must avoid.
      final valid = recipes
          .where(filters.matches)
          .where((r) => !usesAvoidedIngredient(r, avoidIngredients))
          .toList();
      _suggestions = append ? [..._suggestions, ...valid] : valid;
      await _store.writeList(_kSuggestions, _suggestions, (r) => r.toJson());
    } on ClaudeException catch (e) {
      _error = e;
    } catch (e) {
      _error = ClaudeException(ClaudeErrorKind.badResponse, e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Recipe? findById(String id) {
    for (final list in [_suggestions, _favorites, _history.map((h) => h.recipe)]) {
      for (final r in list) {
        if (r.id == id) return r;
      }
    }
    return null;
  }

  bool isFavorite(String id) => _favorites.any((r) => r.id == id);

  Future<void> toggleFavorite(Recipe recipe) async {
    if (isFavorite(recipe.id)) {
      _favorites.removeWhere((r) => r.id == recipe.id);
    } else {
      _favorites.insert(0, recipe);
    }
    notifyListeners();
    await _store.writeList(_kFavorites, _favorites, (r) => r.toJson());
  }

  Future<void> addToHistory(Recipe recipe) async {
    _history.removeWhere((h) => h.recipe.id == recipe.id);
    _history.insert(0, HistoryEntry(recipe, DateTime.now()));
    if (_history.length > maxHistory) {
      _history = _history.sublist(0, maxHistory);
    }
    notifyListeners();
    await _store.writeList(_kHistory, _history, (h) => h.toJson());
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    await _store.writeList(_kHistory, _history, (h) => h.toJson());
  }

  Future<void> clearSuggestions() async {
    _suggestions.clear();
    notifyListeners();
    await _store.writeList(_kSuggestions, _suggestions, (r) => r.toJson());
  }
}
