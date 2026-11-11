import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../l10n/strings.dart';
import '../../logic/recipe_ranking.dart';
import '../../logic/scaling.dart';
import '../../models/recipe.dart';
import '../../models/shopping_item.dart';
import '../../state/pantry_store.dart';
import '../../state/recipe_store.dart';
import '../../state/shopping_store.dart';
import '../cooking/cooking_mode_screen.dart';
import '../planner/add_to_plan_sheet.dart';
import '../widgets/common.dart';

/// Builds shopping-list entries for [ingredients], scaled to [servings].
List<ShoppingItem> shoppingItemsFor(
  Recipe recipe,
  Iterable<RecipeIngredient> ingredients,
  int servings,
) =>
    ingredients
        .map((i) => ShoppingItem(
              name: i.name,
              amount: scaleAmount(i.amount, recipe.servings, servings),
              unit: i.unit,
              recipeTitle: recipe.title,
            ))
        .toList();

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe, this.servings});

  final Recipe recipe;

  /// Initial servings (e.g. from the meal plan); defaults to the recipe's own.
  final int? servings;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late int _servings = widget.servings ?? widget.recipe.servings;
  bool _showTotalNutrition = false;

  Recipe get recipe => widget.recipe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecipeStore>().addToHistory(recipe);
    });
  }

  Future<void> _addMissing(RecipeMatch match) async {
    final s = context.s;
    final shopping = context.read<ShoppingStore>();
    final missing = match.missing.where((i) => !shopping.contains(i.name));
    final n = await shopping.addAll(shoppingItemsFor(recipe, missing, _servings));
    if (mounted) showSnack(context, s.addedToShopping(n));
  }

  Future<void> _addOne(RecipeIngredient ing) async {
    final s = context.s;
    await context
        .read<ShoppingStore>()
        .addAll(shoppingItemsFor(recipe, [ing], _servings));
    if (mounted) showSnack(context, s.addedOneToShopping);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pantry = context.watch<PantryStore>();
    final shopping = context.watch<ShoppingStore>();
    final recipes = context.watch<RecipeStore>();
    final isFav = recipes.isFavorite(recipe.id);
    final match = RecipeRanker(pantry.items).match(recipe);
    final missingNotOnList =
        match.missing.where((i) => !shopping.contains(i.name)).toList();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: s.addToPlan,
            icon: const Icon(Icons.event_available_outlined),
            onPressed: () => showAddToPlanSheet(context, recipe, servings: _servings),
          ),
          IconButton(
            tooltip: s.favorites,
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            color: isFav ? scheme.error : null,
            onPressed: () async {
              await recipes.toggleFavorite(recipe);
              if (context.mounted) {
                showSnack(context, isFav ? s.favoriteRemoved : s.favoriteAdded);
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: recipe.steps.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CookingModeScreen(recipe: recipe, servings: _servings),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text(s.startCooking),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(recipe.title, style: theme.textTheme.headlineSmall),
          if (recipe.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              recipe.description,
              style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          RecipeMetaChips(recipe: recipe),
          const SizedBox(height: 16),
          _TimesRow(recipe: recipe),
          const SizedBox(height: 24),

          // Ingredients + portion calculator
          Row(
            children: [
              Expanded(child: Text(s.ingredients, style: theme.textTheme.titleLarge)),
              _ServingsStepper(
                value: _servings,
                onChanged: (v) => setState(() => _servings = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final ing in recipe.ingredients)
                  _IngredientRow(
                    ingredient: ing,
                    amountText: formatIngredient(
                      ing,
                      recipe.servings,
                      _servings,
                      s.languageCode,
                    ),
                    available: match.available.containsKey(ing),
                    onList: shopping.contains(ing.name),
                    onAdd: () => _addOne(ing),
                  ),
              ],
            ),
          ),
          if (missingNotOnList.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _addMissing(match),
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(s.addMissingToList(missingNotOnList.length)),
            ),
          ],
          const SizedBox(height: 24),

          // Nutrition
          _NutritionCard(
            nutrition: recipe.nutrition,
            servings: _servings,
            showTotal: _showTotalNutrition,
            onToggle: (v) => setState(() => _showTotalNutrition = v),
          ),
          const SizedBox(height: 24),

          // Steps
          Text(s.steps, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (var i = 0; i < recipe.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.steps[i].text, style: theme.textTheme.bodyLarge),
                        if (recipe.steps[i].timerSeconds > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 16, color: scheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  formatDuration(recipe.steps[i].timerSeconds),
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(color: scheme.primary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            s.aiDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TimesRow extends StatelessWidget {
  const _TimesRow({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    Widget cell(String label, int minutes) => Expanded(
          child: Column(
            children: [
              Text(s.minutes(minutes), style: theme.textTheme.titleMedium),
              Text(
                label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            cell(s.prepTime, recipe.prepMinutes),
            cell(s.cookTime, recipe.cookMinutes),
            cell(s.totalTime, recipe.totalMinutes),
          ],
        ),
      ),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '−',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Semantics(
            label: s.servings,
            child: Text(
              s.servingsCount(value),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '+',
            onPressed: value < 24 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.amountText,
    required this.available,
    required this.onList,
    required this.onAdd,
  });

  final RecipeIngredient ingredient;
  final String amountText;
  final bool available;
  final bool onList;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color, String status) = available
        ? (Icons.check_circle, scheme.success, s.inPantry)
        : ingredient.isStaple
            ? (Icons.radio_button_unchecked, scheme.onSurfaceVariant, s.staple)
            : (Icons.cancel_outlined, scheme.error, s.missing);

    return ListTile(
      dense: true,
      leading: Tooltip(message: status, child: Icon(icon, color: color)),
      title: Text(ingredient.name),
      subtitle: Text(status, style: TextStyle(color: color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (amountText.isNotEmpty)
            Text(amountText, style: Theme.of(context).textTheme.bodyMedium),
          if (!available && !ingredient.isStaple)
            onList
                ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Tooltip(
                      message: s.onShoppingList,
                      child: Icon(Icons.shopping_cart, color: scheme.primary, size: 20),
                    ),
                  )
                : IconButton(
                    tooltip: s.addedOneToShopping,
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: onAdd,
                  ),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({
    required this.nutrition,
    required this.servings,
    required this.showTotal,
    required this.onToggle,
  });

  final Nutrition nutrition;
  final int servings;
  final bool showTotal;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final n = showTotal ? nutrition * servings : nutrition;
    final fmt = NumberFormat('0', s.languageCode);

    Widget macro(String label, double grams, Color color) => Expanded(
          child: Column(
            children: [
              Text('${fmt.format(grams)} g', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Container(height: 3, width: 28, color: color),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(s.nutrition, style: theme.textTheme.titleLarge),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.nutritionEstimate,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(s.perServing)),
                ButtonSegment(value: true, label: Text(s.totalFor(servings))),
              ],
              selected: {showTotal},
              onSelectionChanged: (v) => onToggle(v.first),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '≈ ${fmt.format(n.calories)} kcal',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                macro(s.protein, n.proteinG, Colors.redAccent),
                macro(s.carbs, n.carbsG, Colors.amber),
                macro(s.fat, n.fatG, Colors.blueAccent),
                macro(s.fiber, n.fiberG, Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.nutritionEstimateNote,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
