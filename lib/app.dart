import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/strings.dart';
import 'services/claude_client.dart';
import 'services/fridge_ai_service.dart';
import 'services/storage.dart';
import 'state/food_log_store.dart';
import 'state/meal_plan_store.dart';
import 'state/pantry_store.dart';
import 'state/pro_store.dart';
import 'state/recipe_store.dart';
import 'state/settings_store.dart';
import 'state/shopping_store.dart';
import 'ui/home_shell.dart';
import 'ui/onboarding/onboarding_screen.dart';

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
        ChangeNotifierProvider(create: (_) => FoodLogStore(store)),
        ChangeNotifierProvider(create: (_) => ProStore(store)),
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
          home: settings.onboardingDone
              ? const HomeShell()
              : OnboardingScreen(onDone: settings.completeOnboarding),
        ),
      ),
    );
  }
}

const _seed = Color(0xFF2F7D4F);
const _accent = Color(0xFFE8833A);

ThemeData buildTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    tertiary: _accent,
    brightness: brightness,
  ).copyWith(
    // Slightly warm paper tone instead of the default cool grey-green.
    surface: light ? const Color(0xFFFBFAF5) : const Color(0xFF12140F),
    surfaceContainerLow:
        light ? const Color(0xFFF4F3EC) : const Color(0xFF1A1D17),
    surfaceContainer: light ? const Color(0xFFEFEEE6) : const Color(0xFF1F221C),
    surfaceContainerHigh:
        light ? const Color(0xFFE9E8DF) : const Color(0xFF292C25),
    surfaceContainerHighest:
        light ? const Color(0xFFE3E2D8) : const Color(0xFF33372F),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: 'Roboto',
  );
  final text = base.textTheme;
  TextStyle? bold(TextStyle? s, [double spacing = -0.2]) =>
      s?.copyWith(fontWeight: FontWeight.w700, letterSpacing: spacing);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      displaySmall: bold(text.displaySmall, -0.5),
      headlineMedium: bold(text.headlineMedium, -0.4),
      headlineSmall: bold(text.headlineSmall, -0.3),
      titleLarge: bold(text.titleLarge),
      titleMedium: bold(text.titleMedium, 0),
      titleSmall: bold(text.titleSmall, 0),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      extendedTextStyle:
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      showCheckmark: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
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
