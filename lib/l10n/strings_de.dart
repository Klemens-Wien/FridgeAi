import '../models/meal_plan.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../services/claude_client.dart';
import 'strings.dart';

class StringsDe extends S {
  const StringsDe();

  @override
  String get languageCode => 'de';

  @override
  String get appName => 'FridgeChef';
  @override
  String get save => 'Speichern';
  @override
  String get cancel => 'Abbrechen';
  @override
  String get delete => 'Löschen';
  @override
  String get undo => 'Rückgängig';
  @override
  String get retry => 'Erneut versuchen';
  @override
  String get apply => 'Anwenden';
  @override
  String get close => 'Schließen';
  @override
  String get add => 'Hinzufügen';
  @override
  String get edit => 'Bearbeiten';

  @override
  String get navPantry => 'Vorrat';
  @override
  String get navRecipes => 'Rezepte';
  @override
  String get navPlanner => 'Planer';
  @override
  String get navShopping => 'Einkauf';
  @override
  String get navMore => 'Mehr';

  @override
  String get pantryTitle => 'Mein Vorrat';
  @override
  String get pantryEmptyTitle => 'Dein Kühlschrank ist noch leer';
  @override
  String get pantryEmptyBody =>
      'Fotografiere Kühlschrank oder Vorratsschrank – die KI erkennt die Lebensmittel für dich. Oder füge sie von Hand hinzu.';
  @override
  String get scanFridge => 'Kühlschrank scannen';
  @override
  String get addManually => 'Manuell hinzufügen';
  @override
  String get findRecipes => 'Rezepte finden';
  @override
  String expiringBanner(int n) => n == 1
      ? '1 Lebensmittel läuft bald ab – Rezepte damit werden bevorzugt.'
      : '$n Lebensmittel laufen bald ab – Rezepte damit werden bevorzugt.';
  @override
  String get expiresToday => 'Läuft heute ab';
  @override
  String get expiresTomorrow => 'Läuft morgen ab';
  @override
  String expiresInDays(int n) => 'Noch $n Tage';
  @override
  String expiredDaysAgo(int n) =>
      n == 1 ? 'Seit 1 Tag abgelaufen' : 'Seit $n Tagen abgelaufen';
  @override
  String itemDeleted(String name) => '„$name“ entfernt';
  @override
  String get clearPantry => 'Vorrat leeren';
  @override
  String get clearPantryConfirm =>
      'Alle Lebensmittel aus dem Vorrat entfernen?';

  @override
  String get addItem => 'Lebensmittel hinzufügen';
  @override
  String get editItem => 'Lebensmittel bearbeiten';
  @override
  String get name => 'Name';
  @override
  String get quantity => 'Menge';
  @override
  String get quantityHint => 'z. B. 500 g, 2 Stück';
  @override
  String get category => 'Kategorie';
  @override
  String get expiryDate => 'Ablaufdatum';
  @override
  String get setExpiry => 'Ablaufdatum festlegen';
  @override
  String get noExpiry => 'Kein Ablaufdatum';
  @override
  String get nameRequired => 'Bitte einen Namen eingeben';
  @override
  String categoryName(FoodCategory c) => switch (c) {
        FoodCategory.produce => 'Obst & Gemüse',
        FoodCategory.dairy => 'Milchprodukte & Eier',
        FoodCategory.meat => 'Fleisch & Wurst',
        FoodCategory.fish => 'Fisch & Meeresfrüchte',
        FoodCategory.grains => 'Getreide, Nudeln & Reis',
        FoodCategory.bakery => 'Brot & Backwaren',
        FoodCategory.canned => 'Konserven',
        FoodCategory.frozen => 'Tiefkühl',
        FoodCategory.spices => 'Gewürze & Kräuter',
        FoodCategory.sauces => 'Saucen & Öle',
        FoodCategory.beverages => 'Getränke',
        FoodCategory.other => 'Sonstiges',
      };

  @override
  String get scanTitle => 'Vorrat scannen';
  @override
  String get scanHint =>
      'Mach ein oder mehrere Fotos von Kühlschrank, Gefrierfach oder Vorratsschrank. Gutes Licht und geöffnete Türen helfen der Erkennung.';
  @override
  String get takePhoto => 'Foto aufnehmen';
  @override
  String get fromGallery => 'Aus Galerie';
  @override
  String photosCount(int n, int max) => '$n von $max Fotos';
  @override
  String get analyze => 'Lebensmittel erkennen';
  @override
  String get analyzing => 'Erkenne Lebensmittel …';
  @override
  String get analyzingHint => 'Das kann bis zu einer Minute dauern.';
  @override
  String maxPhotosReached(int max) => 'Maximal $max Fotos pro Scan.';
  @override
  String get unsupportedImage =>
      'Dieses Bildformat wird nicht unterstützt. Bitte JPEG oder PNG verwenden.';
  @override
  String get cameraError => 'Kamera oder Galerie konnte nicht geöffnet werden.';

  @override
  String get reviewTitle => 'Erkannte Lebensmittel';
  @override
  String get reviewHint =>
      'Prüfe die Liste: Tippe zum Bearbeiten, entferne Falsches und ergänze, was fehlt.';
  @override
  String get noItemsDetected =>
      'Auf den Fotos wurden keine Lebensmittel erkannt. Du kannst sie unten manuell ergänzen.';
  @override
  String addSelected(int n) =>
      n == 1 ? '1 Lebensmittel übernehmen' : '$n Lebensmittel übernehmen';
  @override
  String get applyShelfLife => 'Geschätzte Haltbarkeit als Ablaufdatum';
  @override
  String get confidenceLow => 'unsicher';
  @override
  String shelfLife(int days) => 'ca. $days Tage haltbar';
  @override
  String itemsAdded(int n) =>
      n == 1 ? '1 Lebensmittel hinzugefügt' : '$n Lebensmittel hinzugefügt';
  @override
  String get addRow => 'Lebensmittel ergänzen';

  @override
  String get recipesTitle => 'Rezeptvorschläge';
  @override
  String get generateRecipes => 'Rezepte vorschlagen';
  @override
  String get moreRecipes => 'Weitere Rezepte';
  @override
  String get generating => 'Suche passende Rezepte …';
  @override
  String get generatingHint =>
      'Die KI stellt Rezepte aus deinem Vorrat zusammen.';
  @override
  String get noSuggestionsTitle => 'Noch keine Vorschläge';
  @override
  String get noSuggestionsBody =>
      'Lass dir Rezepte vorschlagen, die möglichst viele deiner vorhandenen Zutaten nutzen.';
  @override
  String get noRecipesMatchFilters =>
      'Keine Vorschläge passen zu den aktuellen Filtern.';
  @override
  String get filters => 'Filter';
  @override
  String get resetFilters => 'Zurücksetzen';
  @override
  String get vegetarian => 'Vegetarisch';
  @override
  String get vegan => 'Vegan';
  @override
  String get glutenFree => 'Glutenfrei';
  @override
  String get lowCarb => 'Low Carb';
  @override
  String get maxTime => 'Max. Zeit';
  @override
  String get anyTime => 'Egal';
  @override
  String minutes(int n) => '$n Min.';
  @override
  String get difficulty => 'Schwierigkeit';
  @override
  String get anyDifficulty => 'Egal';
  @override
  String difficultyName(Difficulty d) => switch (d) {
        Difficulty.easy => 'Einfach',
        Difficulty.medium => 'Mittel',
        Difficulty.hard => 'Anspruchsvoll',
      };
  @override
  String get difficultyUpTo => 'Höchstens';
  @override
  String matchAvailable(int available, int total) =>
      '$available von $total Zutaten vorhanden';
  @override
  String missingCount(int n) => n == 1 ? '1 fehlt' : '$n fehlen';
  @override
  String get allAvailable => 'Alles da!';
  @override
  String usesExpiring(int n) => n == 1
      ? 'Verwertet 1 bald ablaufendes Lebensmittel'
      : 'Verwertet $n bald ablaufende Lebensmittel';
  @override
  String get prioritizeExpiring => 'Resteverwertung';
  @override
  String get prioritizeExpiringHint =>
      'Rezepte mit bald ablaufenden Lebensmitteln bevorzugen';
  @override
  String get pantryEmptyForRecipes =>
      'Dein Vorrat ist leer. Scanne zuerst deinen Kühlschrank für bessere Vorschläge.';

  @override
  String get servings => 'Portionen';
  @override
  String servingsCount(int n) => n == 1 ? '1 Portion' : '$n Portionen';
  @override
  String get ingredients => 'Zutaten';
  @override
  String get steps => 'Zubereitung';
  @override
  String get nutrition => 'Nährwerte';
  @override
  String get nutritionEstimate => 'Schätzung';
  @override
  String get nutritionEstimateNote =>
      'KI-Schätzung, keine Laborwerte. Tatsächliche Werte hängen von Produkten und Mengen ab.';
  @override
  String get perServing => 'pro Portion';
  @override
  String totalFor(int servings) => 'gesamt ($servings P.)';
  @override
  String get calories => 'Kalorien';
  @override
  String get protein => 'Eiweiß';
  @override
  String get carbs => 'Kohlenhydrate';
  @override
  String get fat => 'Fett';
  @override
  String get fiber => 'Ballaststoffe';
  @override
  String get startCooking => 'Kochmodus starten';
  @override
  String addMissingToList(int n) => n == 1
      ? '1 fehlende Zutat auf die Einkaufsliste'
      : '$n fehlende Zutaten auf die Einkaufsliste';
  @override
  String addedToShopping(int n) => n == 1
      ? '1 Zutat zur Einkaufsliste hinzugefügt'
      : '$n Zutaten zur Einkaufsliste hinzugefügt';
  @override
  String get addedOneToShopping => 'Zur Einkaufsliste hinzugefügt';
  @override
  String get onShoppingList => 'Auf der Einkaufsliste';
  @override
  String get inPantry => 'Vorhanden';
  @override
  String get missing => 'Fehlt';
  @override
  String get staple => 'Grundzutat';
  @override
  String get addToPlan => 'Zum Wochenplan';
  @override
  String get favoriteAdded => 'Zu Favoriten hinzugefügt';
  @override
  String get favoriteRemoved => 'Aus Favoriten entfernt';
  @override
  String get prepTime => 'Vorbereitung';
  @override
  String get cookTime => 'Kochen';
  @override
  String get totalTime => 'Gesamt';

  @override
  String get cookingMode => 'Kochmodus';
  @override
  String stepOf(int i, int n) => 'Schritt $i von $n';
  @override
  String get previous => 'Zurück';
  @override
  String get next => 'Weiter';
  @override
  String get finish => 'Fertig';
  @override
  String get startTimer => 'Timer starten';
  @override
  String get pause => 'Pause';
  @override
  String get resume => 'Weiter';
  @override
  String get reset => 'Zurücksetzen';
  @override
  String get timerDone => 'Timer abgelaufen!';
  @override
  String timerDoneBody(int step) => 'Der Timer für Schritt $step ist fertig.';
  @override
  String get customTimer => 'Eigener Timer';
  @override
  String get setTimer => 'Timer stellen';
  @override
  String get cookingDoneTitle => 'Guten Appetit!';
  @override
  String get cookingDoneBody =>
      'Sollen die verwendeten Zutaten aus deinem Vorrat entfernt werden?';
  @override
  String get removeUsedFromPantry => 'Vorrat aktualisieren';
  @override
  String get keepPantry => 'Nichts ändern';
  @override
  String removedFromPantry(int n) => n == 1
      ? '1 Lebensmittel aus dem Vorrat entfernt'
      : '$n Lebensmittel aus dem Vorrat entfernt';
  @override
  String get showIngredients => 'Zutaten anzeigen';

  @override
  String get plannerTitle => 'Wochenplan';
  @override
  String get today => 'Heute';
  @override
  String slotName(MealSlot s) => switch (s) {
        MealSlot.breakfast => 'Frühstück',
        MealSlot.lunch => 'Mittagessen',
        MealSlot.dinner => 'Abendessen',
      };
  @override
  String get addMeal => 'Gericht hinzufügen';
  @override
  String get pickRecipe => 'Rezept auswählen';
  @override
  String get noRecipesToPick =>
      'Noch keine Rezepte vorhanden. Lass dir zuerst Rezepte vorschlagen oder speichere Favoriten.';
  @override
  String get fromFavorites => 'Favoriten';
  @override
  String get fromSuggestions => 'Vorschläge';
  @override
  String get fromHistory => 'Verlauf';
  @override
  String get addWeekToShopping => 'Fehlende Zutaten der Woche einkaufen';
  @override
  String get weekEmpty => 'Für diese Woche ist noch nichts geplant.';
  @override
  String plannedFor(String day, String slot) => 'Geplant: $day, $slot';
  @override
  String get chooseDay => 'Tag wählen';
  @override
  String get chooseSlot => 'Mahlzeit wählen';
  @override
  String weekLabel(String range) => 'Woche $range';

  @override
  String get shoppingTitle => 'Einkaufsliste';
  @override
  String get shoppingEmptyTitle => 'Einkaufsliste ist leer';
  @override
  String get shoppingEmptyBody =>
      'Füge fehlende Zutaten direkt aus einem Rezept hinzu – mit einem Tipp.';
  @override
  String get addShoppingHint => 'Artikel hinzufügen …';
  @override
  String get clearChecked => 'Erledigte entfernen';
  @override
  String get moveCheckedToPantry => 'Erledigte in den Vorrat';
  @override
  String movedToPantry(int n) => n == 1
      ? '1 Artikel in den Vorrat übernommen'
      : '$n Artikel in den Vorrat übernommen';
  @override
  String forRecipe(String title) => 'Für: $title';
  @override
  String get clearShoppingConfirm => 'Gesamte Einkaufsliste löschen?';

  @override
  String get moreTitle => 'Mehr';
  @override
  String get favorites => 'Favoriten';
  @override
  String get history => 'Verlauf';
  @override
  String get settings => 'Einstellungen';
  @override
  String get favoritesEmpty =>
      'Noch keine Favoriten. Tippe im Rezept auf das Herz, um es zu speichern.';
  @override
  String get historyEmpty => 'Noch keine angesehenen Rezepte.';
  @override
  String get clearHistory => 'Verlauf löschen';
  @override
  String get about => 'Über FridgeChef';
  @override
  String get aboutBody =>
      'FridgeChef erkennt Lebensmittel auf deinen Fotos und schlägt Rezepte vor, die möglichst viel von dem nutzen, was du schon hast – damit weniger im Müll landet.';

  @override
  String get appearance => 'Darstellung';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Hell';
  @override
  String get themeDark => 'Dunkel';
  @override
  String get language => 'Sprache';
  @override
  String get languageSystem => 'Systemsprache';
  @override
  String get defaultServings => 'Standard-Portionen';
  @override
  String get apiKeySection => 'KI-Zugang (Claude API)';
  @override
  String get apiKey => 'API-Schlüssel';
  @override
  String get apiKeyHint => 'sk-ant-…';
  @override
  String get apiKeyUser => 'Eigener Schlüssel ist gespeichert';
  @override
  String get apiKeyBuiltIn => 'Integrierter Schlüssel wird verwendet';
  @override
  String get apiKeyNotSet => 'Kein Schlüssel hinterlegt';
  @override
  String get apiKeySaved => 'API-Schlüssel gespeichert';
  @override
  String get apiKeyRemoved => 'API-Schlüssel entfernt';
  @override
  String get apiKeyInfo =>
      'Der Schlüssel wird verschlüsselt auf diesem Gerät gespeichert und nur für Anfragen an die Claude API verwendet. Fotos und dein Vorrat werden zur Analyse an Anthropic gesendet.';
  @override
  String get removeApiKey => 'Schlüssel entfernen';
  @override
  String get aiDisclaimer =>
      'Rezepte und Nährwerte werden von einer KI erstellt und können Fehler enthalten. Prüfe bei Allergien immer die Zutaten.';
  @override
  String get missingApiKeyBanner =>
      'Für Erkennung und Rezepte wird ein Claude-API-Schlüssel benötigt.';

  @override
  String get builtInAiActive => 'Claude über dein claude.ai-Konto – kein Schlüssel nötig';
  @override
  String get builtInAiInfo =>
      'In dieser Web-Vorschau fragt die App Claude über dein eigenes claude.ai-Konto. Beim ersten Scan wirst du um Erlaubnis gefragt. Fotos und dein Vorrat werden dafür an Claude gesendet.';

  @override
  String get wishHint =>
      'Worauf hast du Lust? (optional)';
  @override
  String get avoidSection =>
      'Allergien & Abneigungen';
  @override
  String get avoidHint =>
      'z. B. Nüsse, Pilze';
  @override
  String get avoidInfo =>
      'Diese Zutaten kommen in Vorschlägen nicht vor. Die KI kann sich irren – prüfe bei Allergien immer die Zutatenliste.';
  @override
  String get searchPantry =>
      'Vorrat durchsuchen';
  @override
  String get groupByCategory =>
      'Nach Kategorie gruppieren';
  @override
  String get noSearchResults =>
      'Nichts gefunden.';
  @override
  String get copyRecipe =>
      'Rezept kopieren';
  @override
  String get copyList =>
      'Liste kopieren';
  @override
  String get copied =>
      'In die Zwischenablage kopiert';
  @override
  String get statsTitle =>
      'Deine Bilanz';
  @override
  String get statsCooked =>
      'Gerichte gekocht';
  @override
  String get statsRescued =>
      'Lebensmittel gerettet';
  @override
  String get findSubstitute =>
      'Ersatz finden';
  @override
  String get substituteLoading =>
      'Suche Alternativen …';
  @override
  String get noSubstitutes =>
      'Dafür gibt es leider keinen guten Ersatz.';
  @override
  String get addToShopping =>
      'Auf die Einkaufsliste';

  @override
  String get calorieCounter =>
      'Kalorienzähler';
  @override
  String get dailyGoal =>
      'Tagesziel';
  @override
  String get kcalEaten =>
      'gegessen';
  @override
  String get kcalLeft =>
      'übrig';
  @override
  String get kcalOver =>
      'über dem Ziel';
  @override
  String get addEntry =>
      'Eintrag';
  @override
  String get newEntry =>
      'Mahlzeit eintragen';
  @override
  String get entryName =>
      'Was hast du gegessen?';
  @override
  String get entryNameHint =>
      'z. B. Käsebrot und ein Apfel';
  @override
  String get kcalRequired =>
      'Bitte Kalorien eingeben';
  @override
  String get estimateWithAi =>
      'Mit KI schätzen';
  @override
  String get estimating =>
      'Schätze Nährwerte …';
  @override
  String get estimateFailed =>
      'Das konnte die KI nicht erkennen. Beschreibe die Mahlzeit etwas genauer.';
  @override
  String get estimateNeedsInput =>
      'Beschreibe die Mahlzeit oder füge ein Foto hinzu.';
  @override
  String get addPhoto =>
      'Foto';
  @override
  String get photoAdded =>
      'Foto hinzugefügt';
  @override
  String get diaryEmpty =>
      'Für diesen Tag ist noch nichts eingetragen.';
  @override
  String get last7Days =>
      'Letzte 7 Tage';
  @override
  String get logAsEaten =>
      'Als gegessen eintragen';
  @override
  String get portionsEaten =>
      'Wie viele Portionen hast du gegessen?';
  @override
  String get loggedToDiary =>
      'Im Kalorienzähler eingetragen';
  @override
  String get estimatedValue =>
      'geschätzt';
  @override
  String get calorieDisclaimer =>
      'Die Werte sind Schätzungen und ersetzen keine Ernährungsberatung.';

  @override
  String get scanModeFridge =>
      'Kühlschrank';
  @override
  String get scanModeReceipt =>
      'Kassenbon';
  @override
  String get receiptHint =>
      'Fotografiere deinen Kassenbon. Bei langen Bons einfach mehrere Fotos machen. Die gekauften Lebensmittel landen in deinem Vorrat.';
  @override
  String get analyzeReceipt =>
      'Kassenbon auslesen';
  @override
  String get pantryUpdateBody =>
      'So ändert sich dein Vorrat:';
  @override
  String get pantryUsedUp =>
      'aufgebraucht – wird entfernt';
  @override
  String get pantryUnknown =>
      'Menge unklar – entfernen?';
  @override
  String get pantryUpdated =>
      'Vorrat aktualisiert';
  @override
  String get calculateGoal =>
      'Ziel berechnen';
  @override
  String get sex =>
      'Geschlecht';
  @override
  String get female =>
      'Weiblich';
  @override
  String get male =>
      'Männlich';
  @override
  String get age =>
      'Alter';
  @override
  String get heightCm =>
      'Größe (cm)';
  @override
  String get weightKg =>
      'Gewicht (kg)';
  @override
  String get activity =>
      'Aktivität';
  @override
  String get activitySedentary =>
      'Kaum Bewegung';
  @override
  String get activityLight =>
      'Leicht aktiv';
  @override
  String get activityModerate =>
      'Aktiv';
  @override
  String get activityActive =>
      'Sehr aktiv';
  @override
  String get aim =>
      'Ziel';
  @override
  String get aimLose =>
      'Abnehmen';
  @override
  String get aimMaintain =>
      'Halten';
  @override
  String get aimGain =>
      'Zunehmen';
  @override
  String get goalFormulaNote =>
      'Richtwert nach Mifflin-St-Jeor. Deine Angaben werden nicht gespeichert. Bei gesundheitlichen Fragen bitte ärztlich beraten lassen.';
  @override
  String get useThisGoal =>
      'Als Tagesziel übernehmen';
  @override
  String get fillAllFields =>
      'Bitte alle Felder ausfüllen.';
  @override
  String get plannedToday =>
      'Geplant';
  @override
  String get eaten =>
      'Gegessen';
  @override
  String get frequentMeals =>
      'Häufig gegessen';
  @override
  String get ownRecipes =>
      'Eigene Rezepte';
  @override
  String get ownRecipesEmpty =>
      'Noch keine eigenen Rezepte. Tippe ein Rezept ein oder fotografiere es aus einem Kochbuch.';
  @override
  String get importRecipe =>
      'Rezept importieren';
  @override
  String get importHint =>
      'Rezept hier eintippen oder einfügen – so, wie du es aufschreiben würdest …';
  @override
  String get importing =>
      'Lese Rezept ein …';
  @override
  String get importFailed =>
      'Darin wurde kein Rezept erkannt.';
  @override
  String get importNeedsInput =>
      'Gib einen Text ein oder füge ein Foto hinzu.';
  @override
  String get recipeImported =>
      'Rezept gespeichert';
  @override
  String get yourRating =>
      'Deine Bewertung';
  @override
  String get ratingHint =>
      'Bewertungen fließen in künftige Vorschläge ein.';
  @override
  String plannedKcal(int kcal) => 'geplant: ≈ $kcal kcal';
  @override
  String photosAdded(int n) => n == 1 ? '1 Foto' : '$n Fotos';

  @override
  String get carbsShort => 'Kohlenh.';

  @override
  String get proTitle =>
      'FridgeChef Pro';
  @override
  String get proActive =>
      'Pro ist aktiv';
  @override
  String get proTagline =>
      'Mehr aus deinem Kühlschrank holen';
  @override
  String get proUnlimited =>
      'Unbegrenzte KI-Anfragen';
  @override
  String get proUnlimitedSub =>
      'Scannen und Rezepte vorschlagen, so oft du willst';
  @override
  String get proWeekPlan =>
      'Automatischer Wochenplan';
  @override
  String get proWeekPlanSub =>
      'Die KI plant deine Abendessen aus dem Vorrat';
  @override
  String get proReceipt =>
      'Kassenbon-Scan';
  @override
  String get proReceiptSub =>
      'Einkäufe per Foto in den Vorrat';
  @override
  String get proImport =>
      'Eigene Rezepte importieren';
  @override
  String get proImportSub =>
      'Aus Text oder Kochbuch-Foto';
  @override
  String get proEstimate =>
      'KI-Kalorienschätzung';
  @override
  String get proEstimateSub =>
      'Mahlzeit beschreiben oder fotografieren';
  @override
  String get proSubstitutes =>
      'Ersatz für fehlende Zutaten';
  @override
  String get proSubstitutesSub =>
      'Alternativen aus deinem Vorrat';
  @override
  String get proUnlock =>
      'Pro freischalten';
  @override
  String get proUnlockNote =>
      'In dieser Vorschau kostenlos – es wird nichts abgebucht. Der Kauf über den App Store folgt.';
  @override
  String get proDeactivate =>
      'Zur kostenlosen Version wechseln';
  @override
  String get proFeatureLocked =>
      'Das ist eine Pro-Funktion.';
  @override
  String get proLimitReached =>
      'Dein Tageslimit an kostenlosen KI-Anfragen ist erreicht.';
  @override
  String get proWelcome =>
      'Willkommen bei Pro!';
  @override
  String get freePlan =>
      'Kostenlose Version';
  @override
  String get autoPlanWeek =>
      'Woche automatisch planen';
  @override
  String get autoPlanning =>
      'Plane deine Woche …';
  @override
  String get autoPlanFull =>
      'In dieser Woche sind alle Abendessen schon geplant.';
  @override
  String get water =>
      'Wasser';
  @override
  String get onboardingSkip =>
      'Überspringen';
  @override
  String get onboardingStart =>
      "Los geht's";
  @override
  String get onb1Title =>
      'Kühlschrank fotografieren';
  @override
  String get onb1Body =>
      'Die KI erkennt deine Lebensmittel – oder du scannst einfach den Kassenbon.';
  @override
  String get onb2Title =>
      'Kochen, was da ist';
  @override
  String get onb2Body =>
      'Rezepte, die möglichst viel aus deinem Vorrat nutzen und bald Ablaufendes zuerst verwerten.';
  @override
  String get onb3Title =>
      'Planen und im Blick behalten';
  @override
  String get onb3Body =>
      'Wochenplan, Einkaufsliste und Kalorienzähler arbeiten zusammen.';
  @override
  String get todayTitle =>
      'Heute';
  @override
  String get statInPantry =>
      'im Vorrat';
  @override
  String get statExpiring =>
      'laufen bald ab';
  @override
  String get statKcalToday =>
      'kcal heute';
  @override
  String get goodMorning =>
      'Guten Morgen';
  @override
  String get goodDay =>
      'Hallo';
  @override
  String get goodEvening =>
      'Guten Abend';
  @override
  String freeRequestsLeft(int left, int total) =>
      'Heute noch $left von $total KI-Anfragen frei';
  @override
  String autoPlanDone(int n) =>
      n == 1 ? '1 Abendessen geplant' : '$n Abendessen geplant';
  @override
  String waterGlasses(int n, int goal) => '$n von $goal Gläsern';
  @override
  String tonight(String title) => 'Heute geplant: $title';

  @override
  String get errorTitle => 'Das hat nicht geklappt';
  @override
  String errorMessage(ClaudeErrorKind kind) => switch (kind) {
        ClaudeErrorKind.missingApiKey =>
          'Kein API-Schlüssel hinterlegt. Bitte in den Einstellungen eintragen.',
        ClaudeErrorKind.invalidApiKey =>
          'Der API-Schlüssel ist ungültig oder hat keine Berechtigung.',
        ClaudeErrorKind.rateLimited =>
          'Zu viele Anfragen. Bitte warte kurz und versuche es erneut.',
        ClaudeErrorKind.overloaded =>
          'Der KI-Dienst ist gerade überlastet. Bitte versuche es gleich noch einmal.',
        ClaudeErrorKind.network =>
          'Keine Verbindung. Bitte prüfe deine Internetverbindung.',
        ClaudeErrorKind.timeout =>
          'Die Anfrage hat zu lange gedauert. Bitte erneut versuchen.',
        ClaudeErrorKind.refused =>
          'Die KI konnte diese Anfrage nicht bearbeiten.',
        ClaudeErrorKind.truncated =>
          'Die Antwort war unvollständig. Bitte erneut versuchen.',
        ClaudeErrorKind.badResponse =>
          'Unerwartete Antwort vom KI-Dienst. Bitte erneut versuchen.',
        ClaudeErrorKind.notAllowed =>
          'Der Zugriff auf Claude wurde nicht erlaubt. Lade die Seite neu, um es erneut zu erlauben.',
        ClaudeErrorKind.badRequest =>
          'Die Anfrage wurde abgelehnt (z. B. Fotos zu groß).',
      };
  @override
  String get goToSettings => 'Zu den Einstellungen';
}
