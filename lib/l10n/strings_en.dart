import '../models/meal_plan.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../services/claude_client.dart';
import 'strings.dart';

class StringsEn extends S {
  const StringsEn();

  @override
  String get languageCode => 'en';

  @override
  String get appName => 'FridgeChef';
  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get undo => 'Undo';
  @override
  String get retry => 'Try again';
  @override
  String get apply => 'Apply';
  @override
  String get close => 'Close';
  @override
  String get add => 'Add';
  @override
  String get edit => 'Edit';

  @override
  String get navPantry => 'Pantry';
  @override
  String get navRecipes => 'Recipes';
  @override
  String get navPlanner => 'Planner';
  @override
  String get navShopping => 'Shopping';
  @override
  String get navMore => 'More';

  @override
  String get pantryTitle => 'My pantry';
  @override
  String get pantryEmptyTitle => 'Your fridge is still empty';
  @override
  String get pantryEmptyBody =>
      'Take a photo of your fridge or pantry – the AI will recognise the food for you. Or add items by hand.';
  @override
  String get scanFridge => 'Scan fridge';
  @override
  String get addManually => 'Add manually';
  @override
  String get findRecipes => 'Find recipes';
  @override
  String expiringBanner(int n) => n == 1
      ? '1 item expires soon – recipes using it are prioritised.'
      : '$n items expire soon – recipes using them are prioritised.';
  @override
  String get expiresToday => 'Expires today';
  @override
  String get expiresTomorrow => 'Expires tomorrow';
  @override
  String expiresInDays(int n) => '$n days left';
  @override
  String expiredDaysAgo(int n) =>
      n == 1 ? 'Expired 1 day ago' : 'Expired $n days ago';
  @override
  String itemDeleted(String name) => 'Removed “$name”';
  @override
  String get clearPantry => 'Clear pantry';
  @override
  String get clearPantryConfirm => 'Remove all items from your pantry?';

  @override
  String get addItem => 'Add item';
  @override
  String get editItem => 'Edit item';
  @override
  String get name => 'Name';
  @override
  String get quantity => 'Quantity';
  @override
  String get quantityHint => 'e.g. 500 g, 2 pieces';
  @override
  String get category => 'Category';
  @override
  String get expiryDate => 'Expiry date';
  @override
  String get setExpiry => 'Set expiry date';
  @override
  String get noExpiry => 'No expiry date';
  @override
  String get nameRequired => 'Please enter a name';
  @override
  String categoryName(FoodCategory c) => switch (c) {
        FoodCategory.produce => 'Fruit & vegetables',
        FoodCategory.dairy => 'Dairy & eggs',
        FoodCategory.meat => 'Meat',
        FoodCategory.fish => 'Fish & seafood',
        FoodCategory.grains => 'Grains, pasta & rice',
        FoodCategory.bakery => 'Bread & bakery',
        FoodCategory.canned => 'Canned goods',
        FoodCategory.frozen => 'Frozen',
        FoodCategory.spices => 'Spices & herbs',
        FoodCategory.sauces => 'Sauces & oils',
        FoodCategory.beverages => 'Drinks',
        FoodCategory.other => 'Other',
      };

  @override
  String get scanTitle => 'Scan pantry';
  @override
  String get scanHint =>
      'Take one or more photos of your fridge, freezer or cupboard. Good light and open doors help recognition.';
  @override
  String get takePhoto => 'Take photo';
  @override
  String get fromGallery => 'From gallery';
  @override
  String photosCount(int n, int max) => '$n of $max photos';
  @override
  String get analyze => 'Detect ingredients';
  @override
  String get analyzing => 'Detecting ingredients …';
  @override
  String get analyzingHint => 'This can take up to a minute.';
  @override
  String maxPhotosReached(int max) => 'At most $max photos per scan.';
  @override
  String get unsupportedImage =>
      'This image format is not supported. Please use JPEG or PNG.';
  @override
  String get cameraError => 'Could not open the camera or gallery.';

  @override
  String get reviewTitle => 'Detected ingredients';
  @override
  String get reviewHint =>
      'Check the list: tap to edit, remove anything wrong and add what is missing.';
  @override
  String get noItemsDetected =>
      'No food was detected in the photos. You can add items manually below.';
  @override
  String addSelected(int n) => n == 1 ? 'Add 1 item' : 'Add $n items';
  @override
  String get applyShelfLife => 'Use estimated shelf life as expiry date';
  @override
  String get confidenceLow => 'uncertain';
  @override
  String shelfLife(int days) => 'keeps approx. $days days';
  @override
  String itemsAdded(int n) => n == 1 ? '1 item added' : '$n items added';
  @override
  String get addRow => 'Add ingredient';

  @override
  String get recipesTitle => 'Recipe ideas';
  @override
  String get generateRecipes => 'Suggest recipes';
  @override
  String get moreRecipes => 'More recipes';
  @override
  String get generating => 'Finding matching recipes …';
  @override
  String get generatingHint =>
      'The AI is putting together recipes from your pantry.';
  @override
  String get noSuggestionsTitle => 'No suggestions yet';
  @override
  String get noSuggestionsBody =>
      'Get recipe ideas that use as many of your ingredients as possible.';
  @override
  String get noRecipesMatchFilters =>
      'No suggestions match the current filters.';
  @override
  String get filters => 'Filters';
  @override
  String get resetFilters => 'Reset';
  @override
  String get vegetarian => 'Vegetarian';
  @override
  String get vegan => 'Vegan';
  @override
  String get glutenFree => 'Gluten-free';
  @override
  String get lowCarb => 'Low carb';
  @override
  String get maxTime => 'Max. time';
  @override
  String get anyTime => 'Any';
  @override
  String minutes(int n) => '$n min';
  @override
  String get difficulty => 'Difficulty';
  @override
  String get anyDifficulty => 'Any';
  @override
  String difficultyName(Difficulty d) => switch (d) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Challenging',
      };
  @override
  String get difficultyUpTo => 'At most';
  @override
  String matchAvailable(int available, int total) =>
      '$available of $total ingredients at home';
  @override
  String missingCount(int n) => '$n missing';
  @override
  String get allAvailable => 'You have everything!';
  @override
  String usesExpiring(int n) => n == 1
      ? 'Uses up 1 item that expires soon'
      : 'Uses up $n items that expire soon';
  @override
  String get prioritizeExpiring => 'Use up leftovers';
  @override
  String get prioritizeExpiringHint =>
      'Prefer recipes with items that expire soon';
  @override
  String get pantryEmptyForRecipes =>
      'Your pantry is empty. Scan your fridge first for better suggestions.';

  @override
  String get servings => 'Servings';
  @override
  String servingsCount(int n) => n == 1 ? '1 serving' : '$n servings';
  @override
  String get ingredients => 'Ingredients';
  @override
  String get steps => 'Method';
  @override
  String get nutrition => 'Nutrition';
  @override
  String get nutritionEstimate => 'Estimate';
  @override
  String get nutritionEstimateNote =>
      'AI estimate, not lab values. Actual values depend on products and amounts.';
  @override
  String get perServing => 'per serving';
  @override
  String totalFor(int servings) => 'total ($servings serv.)';
  @override
  String get calories => 'Calories';
  @override
  String get protein => 'Protein';
  @override
  String get carbs => 'Carbs';
  @override
  String get fat => 'Fat';
  @override
  String get fiber => 'Fibre';
  @override
  String get startCooking => 'Start cooking mode';
  @override
  String addMissingToList(int n) => n == 1
      ? 'Add 1 missing ingredient to shopping list'
      : 'Add $n missing ingredients to shopping list';
  @override
  String addedToShopping(int n) => n == 1
      ? '1 ingredient added to shopping list'
      : '$n ingredients added to shopping list';
  @override
  String get addedOneToShopping => 'Added to shopping list';
  @override
  String get onShoppingList => 'On shopping list';
  @override
  String get inPantry => 'At home';
  @override
  String get missing => 'Missing';
  @override
  String get staple => 'Staple';
  @override
  String get addToPlan => 'Add to meal plan';
  @override
  String get favoriteAdded => 'Added to favourites';
  @override
  String get favoriteRemoved => 'Removed from favourites';
  @override
  String get prepTime => 'Prep';
  @override
  String get cookTime => 'Cook';
  @override
  String get totalTime => 'Total';

  @override
  String get cookingMode => 'Cooking mode';
  @override
  String stepOf(int i, int n) => 'Step $i of $n';
  @override
  String get previous => 'Back';
  @override
  String get next => 'Next';
  @override
  String get finish => 'Done';
  @override
  String get startTimer => 'Start timer';
  @override
  String get pause => 'Pause';
  @override
  String get resume => 'Resume';
  @override
  String get reset => 'Reset';
  @override
  String get timerDone => 'Time is up!';
  @override
  String timerDoneBody(int step) => 'The timer for step $step has finished.';
  @override
  String get customTimer => 'Custom timer';
  @override
  String get setTimer => 'Set timer';
  @override
  String get cookingDoneTitle => 'Enjoy your meal!';
  @override
  String get cookingDoneBody =>
      'Remove the ingredients you used from your pantry?';
  @override
  String get removeUsedFromPantry => 'Remove from pantry';
  @override
  String get keepPantry => 'Keep';
  @override
  String removedFromPantry(int n) => n == 1
      ? '1 item removed from pantry'
      : '$n items removed from pantry';
  @override
  String get showIngredients => 'Show ingredients';

  @override
  String get plannerTitle => 'Meal plan';
  @override
  String get today => 'Today';
  @override
  String slotName(MealSlot s) => switch (s) {
        MealSlot.breakfast => 'Breakfast',
        MealSlot.lunch => 'Lunch',
        MealSlot.dinner => 'Dinner',
      };
  @override
  String get addMeal => 'Add meal';
  @override
  String get pickRecipe => 'Choose a recipe';
  @override
  String get noRecipesToPick =>
      'No recipes yet. Get some suggestions first or save favourites.';
  @override
  String get fromFavorites => 'Favourites';
  @override
  String get fromSuggestions => 'Suggestions';
  @override
  String get fromHistory => 'History';
  @override
  String get addWeekToShopping => 'Shop for this week\'s missing ingredients';
  @override
  String get weekEmpty => 'Nothing planned for this week yet.';
  @override
  String plannedFor(String day, String slot) => 'Planned: $day, $slot';
  @override
  String get chooseDay => 'Choose day';
  @override
  String get chooseSlot => 'Choose meal';
  @override
  String weekLabel(String range) => 'Week $range';

  @override
  String get shoppingTitle => 'Shopping list';
  @override
  String get shoppingEmptyTitle => 'Shopping list is empty';
  @override
  String get shoppingEmptyBody =>
      'Add missing ingredients straight from a recipe – with a single tap.';
  @override
  String get addShoppingHint => 'Add item …';
  @override
  String get clearChecked => 'Remove checked';
  @override
  String get moveCheckedToPantry => 'Move checked to pantry';
  @override
  String movedToPantry(int n) =>
      n == 1 ? '1 item moved to pantry' : '$n items moved to pantry';
  @override
  String forRecipe(String title) => 'For: $title';
  @override
  String get clearShoppingConfirm => 'Delete the whole shopping list?';

  @override
  String get moreTitle => 'More';
  @override
  String get favorites => 'Favourites';
  @override
  String get history => 'History';
  @override
  String get settings => 'Settings';
  @override
  String get favoritesEmpty =>
      'No favourites yet. Tap the heart on a recipe to save it.';
  @override
  String get historyEmpty => 'No recipes viewed yet.';
  @override
  String get clearHistory => 'Clear history';
  @override
  String get about => 'About FridgeChef';
  @override
  String get aboutBody =>
      'FridgeChef recognises the food in your photos and suggests recipes that use as much of what you already have as possible – so less ends up in the bin.';

  @override
  String get appearance => 'Appearance';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get language => 'Language';
  @override
  String get languageSystem => 'System language';
  @override
  String get defaultServings => 'Default servings';
  @override
  String get apiKeySection => 'AI access (Claude API)';
  @override
  String get apiKey => 'API key';
  @override
  String get apiKeyHint => 'sk-ant-…';
  @override
  String get apiKeyUser => 'Your own key is saved';
  @override
  String get apiKeyBuiltIn => 'Using the built-in key';
  @override
  String get apiKeyNotSet => 'No key set';
  @override
  String get apiKeySaved => 'API key saved';
  @override
  String get apiKeyRemoved => 'API key removed';
  @override
  String get apiKeyInfo =>
      'The key is stored encrypted on this device and only used for requests to the Claude API. Photos and your pantry are sent to Anthropic for analysis.';
  @override
  String get removeApiKey => 'Remove key';
  @override
  String get aiDisclaimer =>
      'Recipes and nutrition values are generated by AI and may contain mistakes. Always check ingredients if you have allergies.';
  @override
  String get missingApiKeyBanner =>
      'A Claude API key is needed for recognition and recipes.';

  @override
  String get builtInAiActive => 'Claude via your claude.ai account – no key needed';
  @override
  String get builtInAiInfo =>
      'In this web preview the app asks Claude through your own claude.ai account. You will be asked for permission on the first scan. Photos and your pantry are sent to Claude for this.';

  @override
  String get wishHint =>
      'What do you feel like? (optional)';
  @override
  String get avoidSection =>
      'Allergies & dislikes';
  @override
  String get avoidHint =>
      'e.g. nuts, mushrooms';
  @override
  String get avoidInfo =>
      'These ingredients are kept out of suggestions. The AI can make mistakes – always check the ingredient list if you have allergies.';
  @override
  String get searchPantry =>
      'Search pantry';
  @override
  String get groupByCategory =>
      'Group by category';
  @override
  String get noSearchResults =>
      'Nothing found.';
  @override
  String get copyRecipe =>
      'Copy recipe';
  @override
  String get copyList =>
      'Copy list';
  @override
  String get copied =>
      'Copied to clipboard';
  @override
  String get statsTitle =>
      'Your record';
  @override
  String get statsCooked =>
      'meals cooked';
  @override
  String get statsRescued =>
      'foods rescued';
  @override
  String get findSubstitute =>
      'Find a substitute';
  @override
  String get substituteLoading =>
      'Looking for alternatives …';
  @override
  String get noSubstitutes =>
      'There is no good substitute for this.';
  @override
  String get addToShopping =>
      'Add to shopping list';

  @override
  String get calorieCounter =>
      'Calorie counter';
  @override
  String get dailyGoal =>
      'Daily goal';
  @override
  String get kcalEaten =>
      'eaten';
  @override
  String get kcalLeft =>
      'left';
  @override
  String get kcalOver =>
      'over goal';
  @override
  String get addEntry =>
      'Add entry';
  @override
  String get newEntry =>
      'Log a meal';
  @override
  String get entryName =>
      'What did you eat?';
  @override
  String get entryNameHint =>
      'e.g. cheese sandwich and an apple';
  @override
  String get kcalRequired =>
      'Please enter calories';
  @override
  String get estimateWithAi =>
      'Estimate with AI';
  @override
  String get estimating =>
      'Estimating nutrition …';
  @override
  String get estimateFailed =>
      'The AI could not tell what this is. Please describe the meal in more detail.';
  @override
  String get estimateNeedsInput =>
      'Describe the meal or add a photo.';
  @override
  String get addPhoto =>
      'Photo';
  @override
  String get photoAdded =>
      'Photo added';
  @override
  String get diaryEmpty =>
      'Nothing logged for this day yet.';
  @override
  String get last7Days =>
      'Last 7 days';
  @override
  String get logAsEaten =>
      'Log as eaten';
  @override
  String get portionsEaten =>
      'How many servings did you eat?';
  @override
  String get loggedToDiary =>
      'Added to the calorie counter';
  @override
  String get estimatedValue =>
      'estimated';
  @override
  String get calorieDisclaimer =>
      'Values are estimates and do not replace nutritional advice.';

  @override
  String get errorTitle => 'Something went wrong';
  @override
  String errorMessage(ClaudeErrorKind kind) => switch (kind) {
        ClaudeErrorKind.missingApiKey =>
          'No API key set. Please add one in Settings.',
        ClaudeErrorKind.invalidApiKey =>
          'The API key is invalid or lacks permission.',
        ClaudeErrorKind.rateLimited =>
          'Too many requests. Please wait a moment and try again.',
        ClaudeErrorKind.overloaded =>
          'The AI service is busy right now. Please try again shortly.',
        ClaudeErrorKind.network =>
          'No connection. Please check your internet connection.',
        ClaudeErrorKind.timeout => 'The request took too long. Please try again.',
        ClaudeErrorKind.refused => 'The AI could not handle this request.',
        ClaudeErrorKind.truncated =>
          'The response was incomplete. Please try again.',
        ClaudeErrorKind.badResponse =>
          'Unexpected response from the AI service. Please try again.',
        ClaudeErrorKind.notAllowed =>
          'Access to Claude was not allowed. Reload the page to allow it again.',
        ClaudeErrorKind.badRequest =>
          'The request was rejected (e.g. photos too large).',
      };
  @override
  String get goToSettings => 'Open settings';
}
