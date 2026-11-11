import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../l10n/strings.dart';
import '../state/pantry_store.dart';
import '../state/shopping_store.dart';
import 'more/more_screen.dart';
import 'pantry/pantry_screen.dart';
import 'planner/planner_screen.dart';
import 'recipes/recipes_screen.dart';
import 'shopping/shopping_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tab = context.watch<TabNavigator>();
    final openShopping = context.select<ShoppingStore, int>((s) => s.openCount);
    final expiring =
        context.select<PantryStore, int>((p) => p.expiringSoon.length);

    return Scaffold(
      body: IndexedStack(
        index: tab.value,
        children: const [
          PantryScreen(),
          RecipesScreen(),
          PlannerScreen(),
          ShoppingScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.value,
        onDestinationSelected: tab.goTo,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: expiring > 0,
              label: Text('$expiring'),
              child: const Icon(Icons.kitchen_outlined),
            ),
            selectedIcon: const Icon(Icons.kitchen),
            label: s.navPantry,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu),
            label: s.navRecipes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: s.navPlanner,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: openShopping > 0,
              label: Text('$openShopping'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: s.navShopping,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: s.navMore,
          ),
        ],
      ),
    );
  }
}
