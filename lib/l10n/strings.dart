import 'package:flutter/widgets.dart';

import '../models/meal_plan.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../services/claude_client.dart';
import 'strings_de.dart';
import 'strings_en.dart';

/// All user-facing strings. Every language implements this class, so a
/// missing translation is a compile-time error.
abstract class S {
  const S();

  static const supportedLocales = [Locale('de'), Locale('en')];
  static const delegate = _SDelegate();

  static S of(BuildContext context) =>
      Localizations.of<S>(context, S) ?? const StringsEn();

  static S forLanguage(String code) =>
      code == 'de' ? const StringsDe() : const StringsEn();

  String get languageCode;

  // General
  String get appName;
  String get save;
  String get cancel;
  String get delete;
  String get undo;
  String get retry;
  String get apply;
  String get close;
  String get add;
  String get edit;

  // Navigation
  String get navPantry;
  String get navRecipes;
  String get navPlanner;
  String get navShopping;
  String get navMore;

  // Pantry
  String get pantryTitle;
  String get pantryEmptyTitle;
  String get pantryEmptyBody;
  String get scanFridge;
  String get addManually;
  String get findRecipes;
  String expiringBanner(int n);
  String get expiresToday;
  String get expiresTomorrow;
  String expiresInDays(int n);
  String expiredDaysAgo(int n);
  String itemDeleted(String name);
  String get clearPantry;
  String get clearPantryConfirm;

  // Item editor
  String get addItem;
  String get editItem;
  String get name;
  String get quantity;
  String get quantityHint;
  String get category;
  String get expiryDate;
  String get setExpiry;
  String get noExpiry;
  String get nameRequired;
  String categoryName(FoodCategory c);

  // Scan
  String get scanTitle;
  String get scanHint;
  String get takePhoto;
  String get fromGallery;
  String photosCount(int n, int max);
  String get analyze;
  String get analyzing;
  String get analyzingHint;
  String maxPhotosReached(int max);
  String get unsupportedImage;
  String get cameraError;

  // Review
  String get reviewTitle;
  String get reviewHint;
  String get noItemsDetected;
  String addSelected(int n);
  String get applyShelfLife;
  String get confidenceLow;
  String shelfLife(int days);
  String itemsAdded(int n);
  String get addRow;

  // Recipes
  String get recipesTitle;
  String get generateRecipes;
  String get moreRecipes;
  String get generating;
  String get generatingHint;
  String get noSuggestionsTitle;
  String get noSuggestionsBody;
  String get noRecipesMatchFilters;
  String get filters;
  String get resetFilters;
  String get vegetarian;
  String get vegan;
  String get glutenFree;
  String get lowCarb;
  String get maxTime;
  String get anyTime;
  String minutes(int n);
  String get difficulty;
  String get anyDifficulty;
  String difficultyName(Difficulty d);
  String get difficultyUpTo;
  String matchAvailable(int available, int total);
  String missingCount(int n);
  String get allAvailable;
  String usesExpiring(int n);
  String get prioritizeExpiring;
  String get prioritizeExpiringHint;
  String get pantryEmptyForRecipes;

  // Recipe detail
  String get servings;
  String servingsCount(int n);
  String get ingredients;
  String get steps;
  String get nutrition;
  String get nutritionEstimate;
  String get nutritionEstimateNote;
  String get perServing;
  String totalFor(int servings);
  String get calories;
  String get protein;
  String get carbs;
  String get fat;
  String get fiber;
  String get startCooking;
  String addMissingToList(int n);
  String addedToShopping(int n);
  String get addedOneToShopping;
  String get onShoppingList;
  String get inPantry;
  String get missing;
  String get staple;
  String get addToPlan;
  String get favoriteAdded;
  String get favoriteRemoved;
  String get prepTime;
  String get cookTime;
  String get totalTime;

  // Cooking mode
  String get cookingMode;
  String stepOf(int i, int n);
  String get previous;
  String get next;
  String get finish;
  String get startTimer;
  String get pause;
  String get resume;
  String get reset;
  String get timerDone;
  String timerDoneBody(int step);
  String get customTimer;
  String get setTimer;
  String get cookingDoneTitle;
  String get cookingDoneBody;
  String get removeUsedFromPantry;
  String get keepPantry;
  String removedFromPantry(int n);
  String get showIngredients;

  // Planner
  String get plannerTitle;
  String get today;
  String slotName(MealSlot s);
  String get addMeal;
  String get pickRecipe;
  String get noRecipesToPick;
  String get fromFavorites;
  String get fromSuggestions;
  String get fromHistory;
  String get addWeekToShopping;
  String get weekEmpty;
  String plannedFor(String day, String slot);
  String get chooseDay;
  String get chooseSlot;
  String weekLabel(String range);

  // Shopping list
  String get shoppingTitle;
  String get shoppingEmptyTitle;
  String get shoppingEmptyBody;
  String get addShoppingHint;
  String get clearChecked;
  String get moveCheckedToPantry;
  String movedToPantry(int n);
  String forRecipe(String title);
  String get clearShoppingConfirm;

  // More / favourites / history
  String get moreTitle;
  String get favorites;
  String get history;
  String get settings;
  String get favoritesEmpty;
  String get historyEmpty;
  String get clearHistory;
  String get about;
  String get aboutBody;

  // Settings
  String get appearance;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get language;
  String get languageSystem;
  String get defaultServings;
  String get apiKeySection;
  String get apiKey;
  String get apiKeyHint;
  String get apiKeyUser;
  String get apiKeyBuiltIn;
  String get apiKeyNotSet;
  String get apiKeySaved;
  String get apiKeyRemoved;
  String get apiKeyInfo;
  String get removeApiKey;
  String get aiDisclaimer;
  String get missingApiKeyBanner;
  String get builtInAiActive;
  String get builtInAiInfo;

  // Extras
  String get wishHint;
  String get avoidSection;
  String get avoidHint;
  String get avoidInfo;
  String get searchPantry;
  String get groupByCategory;
  String get noSearchResults;
  String get copyRecipe;
  String get copyList;
  String get copied;
  String get statsTitle;
  String get statsCooked;
  String get statsRescued;
  String get findSubstitute;
  String get substituteLoading;
  String get noSubstitutes;
  String get addToShopping;

  // Calorie counter
  String get calorieCounter;
  String get dailyGoal;
  String get kcalEaten;
  String get kcalLeft;
  String get kcalOver;
  String get addEntry;
  String get newEntry;
  String get entryName;
  String get entryNameHint;
  String get kcalRequired;
  String get estimateWithAi;
  String get estimating;
  String get estimateFailed;
  String get estimateNeedsInput;
  String get addPhoto;
  String get photoAdded;
  String get diaryEmpty;
  String get last7Days;
  String get logAsEaten;
  String get portionsEaten;
  String get loggedToDiary;
  String get estimatedValue;
  String get calorieDisclaimer;

  // Errors
  String get errorTitle;
  String errorMessage(ClaudeErrorKind kind);
  String get goToSettings;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['de', 'en'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async => S.forLanguage(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

extension SContext on BuildContext {
  S get s => S.of(this);
}
