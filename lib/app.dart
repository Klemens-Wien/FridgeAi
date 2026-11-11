import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/strings.dart';
import 'services/claude_client.dart';
import 'services/fridge_ai_service.dart';
import 'services/storage.dart';
import 'state/meal_plan_store.dart';
import 'state/pantry_store.dart';
import 'state/recipe_store.dart';
import 'state/settings_store.dart';
import 'state/shopping_store.dart';
import 'ui/home_shell.dart';

FridgeAiService _defaultAiFactory(String apiKey) =>
    FridgeAiService(ClaudeClient(apiKey: apiKey));

/// Which bottom-navigation tab is selected; lets screens jump between tabs.
class TabNavigator extends ValueNotifier<int> {
  TabNavigator() : super(0);

  static const pantry = 0;
  static const recipes = 1;
  static const planner = 2;
  static const shopping = 3;
  static const more = 4;

  void goTo(int tab) => value = tab;
}

class FridgeChefApp extends StatelessWidget {
  const FridgeChefApp({
    super.key,
    required this.store,
    required this.settings,
    this.aiFactory = _defaultAiFactory,
  });

  final LocalStore store;
  final SettingsStore settings;
  final AiServiceFactory aiFactory;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => PantryStore(store)),
        ChangeNotifierProvider(create: (_) => RecipeStore(store, aiFactory)),
        ChangeNotifierProvider(create: (_) => ShoppingStore(store)),
        ChangeNotifierProvider(create: (_) => MealPlanStore(store)),
        ChangeNotifierProvider(create: (_) => TabNavigator()),
        Provider<AiServiceFactory>.value(value: aiFactory),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, settings, _) => MaterialApp(
          title: 'FridgeChef',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (device, supported) {
            final code = device?.languageCode;
            return supported.firstWhere(
              (l) => l.languageCode == code,
              orElse: () => const Locale('en'),
            );
          },
          home: const HomeShell(),
        ),
      ),
    );
  }
}

const _seed = Color(0xFF2E7D32);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    chipTheme: const ChipThemeData(showCheckmark: true),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Semantic colours for expiry states that work in light and dark mode.
extension ExpiryColors on ColorScheme {
  Color get warning => brightness == Brightness.light
      ? const Color(0xFFB26A00)
      : const Color(0xFFFFB74D);
  Color get success => brightness == Brightness.light
      ? const Color(0xFF2E7D32)
      : const Color(0xFF81C784);
}
