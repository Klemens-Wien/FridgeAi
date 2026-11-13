import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../logic/recipe_ranking.dart';
import '../../models/meal_plan.dart';
import '../../models/pantry_item.dart' show dateOnly;
import '../../models/recipe.dart';
import '../../models/shopping_item.dart';
import '../../state/meal_plan_store.dart';
import '../../state/pantry_store.dart';
import '../../state/recipe_store.dart';
import '../../services/claude_client.dart';
import '../../services/fridge_ai_service.dart';
import '../../state/settings_store.dart';
import '../../state/shopping_store.dart';
import '../pro/pro_gate.dart';
import '../recipes/recipe_detail_screen.dart';
import '../widgets/common.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _weekStart = startOfWeek(DateTime.now());

  void _shiftWeek(int weeks) =>
      setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));

  bool _planning = false;

  /// Pro: lets the AI fill the empty dinner slots of the shown week (from
  /// today on) with recipes built around the pantry.
  Future<void> _autoPlan() async {
    final s = context.s;
    final plan = context.read<MealPlanStore>();
    final today = dateOnly(DateTime.now());
    final free = [
      for (var d = 0; d < 7; d++)
        if (!_weekStart.add(Duration(days: d)).isBefore(today) &&
            plan.entriesFor(_weekStart.add(Duration(days: d)), MealSlot.dinner).isEmpty)
          _weekStart.add(Duration(days: d)),
    ];
    if (free.isEmpty) {
      showSnack(context, s.autoPlanFull);
      return;
    }
    if (!await ensurePro(context) || !mounted) return;
    final settings = context.read<SettingsStore>();
    final recipes = context.read<RecipeStore>();
    final service = context.read<AiServiceFactory>()(settings.effectiveApiKey);
    final pantry = context.read<PantryStore>().items;
    setState(() => _planning = true);
    try {
      final result = await service.suggestRecipes(
        pantry: pantry,
        filters: settings.filters,
        languageCode: s.languageCode,
        servings: settings.defaultServings,
        prioritizeExpiring: settings.prioritizeExpiring,
        avoidIngredients: settings.avoidIngredients,
        likedTitles: recipes.likedTitles(),
        dislikedTitles: recipes.dislikedTitles(),
        note: FridgeAiService.weekPlanNote,
        count: free.length,
      );
      final usable = result
          .where(settings.filters.matches)
          .where((r) => !usesAvoidedIngredient(r, settings.avoidIngredients))
          .toList();
      var planned = 0;
      for (var i = 0; i < free.length && i < usable.length; i++) {
        await plan.add(free[i], MealSlot.dinner, usable[i]);
        planned++;
      }
      if (mounted) showSnack(context, s.autoPlanDone(planned));
    } on ClaudeException catch (e) {
      if (mounted) showSnack(context, s.errorMessage(e.kind));
    } catch (_) {
      if (mounted) showSnack(context, s.errorMessage(ClaudeErrorKind.badResponse));
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  Future<void> _addWeekToShopping() async {
    final s = context.s;
    final plan = context.read<MealPlanStore>();
    final shopping = context.read<ShoppingStore>();
    final ranker = RecipeRanker(context.read<PantryStore>().items);
    final items = <ShoppingItem>[];
    for (final e in plan.entriesInWeek(_weekStart)) {
      final missing = ranker
          .match(e.recipe)
          .missing
          .where((i) => !shopping.contains(i.name));
      items.addAll(shoppingItemsFor(e.recipe, missing, e.servings));
    }
    final n = await shopping.addAll(items);
    if (mounted) showSnack(context, s.addedToShopping(n));
  }

  Future<void> _pickRecipe(DateTime day, MealSlot slot) async {
    final recipe = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _RecipePicker(),
    );
    if (recipe != null && mounted) {
      await context.read<MealPlanStore>().add(day, slot, recipe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final plan = context.watch<MealPlanStore>();
    final weekEntries = plan.entriesInWeek(_weekStart);
    final fmtShort = DateFormat.MMMd(s.languageCode);
    final fmtDay = DateFormat.EEEE(s.languageCode);
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final today = dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(s.plannerTitle),
        actions: [
          IconButton(
            tooltip: s.autoPlanWeek,
            onPressed: _planning ? null : _autoPlan,
            icon: _planning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: s.addWeekToShopping,
            onPressed: weekEntries.isEmpty ? null : _addWeekToShopping,
            icon: const Icon(Icons.add_shopping_cart),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _shiftWeek(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      setState(() => _weekStart = startOfWeek(DateTime.now())),
                  child: Text(
                    s.weekLabel(
                      '${fmtShort.format(_weekStart)} – ${fmtShort.format(weekEnd)}',
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _shiftWeek(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (weekEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                s.weekEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          for (var d = 0; d < 7; d++) ...[
            Builder(builder: (context) {
              final day = _weekStart.add(Duration(days: d));
              final isToday = day == today;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isToday
                      ? BorderSide(color: theme.colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fmtDay.format(day)}, ${fmtShort.format(day)}'
                        '${isToday ? ' · ${s.today}' : ''}'
                        '${plan.plannedCalories(day) > 0 ? ' · ${s.plannedKcal(plan.plannedCalories(day).round())}' : ''}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isToday ? theme.colorScheme.primary : null,
                        ),
                      ),
                      for (final slot in MealSlot.values)
                        _SlotRow(
                          day: day,
                          slot: slot,
                          entries: plan.entriesFor(day, slot),
                          onAdd: () => _pickRecipe(day, slot),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.day,
    required this.slot,
    required this.entries,
    required this.onAdd,
  });

  final DateTime day;
  final MealSlot slot;
  final List<MealPlanEntry> entries;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final plan = context.read<MealPlanStore>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              s.slotName(slot),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in entries)
                InputChip(
                  label: Text(
                    '${e.recipe.title} (${e.servings})',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RecipeDetailScreen(recipe: e.recipe, servings: e.servings),
                    ),
                  ),
                  onDeleted: () {
                    plan.remove(e.id);
                    showSnack(
                      context,
                      s.itemDeleted(e.recipe.title),
                      actionLabel: s.undo,
                      onAction: () => plan.restore(e),
                    );
                  },
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: s.addMeal,
          visualDensity: VisualDensity.compact,
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _RecipePicker extends StatelessWidget {
  const _RecipePicker();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final store = context.watch<RecipeStore>();
    final tabs = <(String, List<Recipe>)>[
      (s.fromFavorites, store.favorites),
      (s.ownRecipes, store.own),
      (s.fromSuggestions, store.suggestions),
      (s.fromHistory, store.history.map((h) => h.recipe).toList()),
    ];

    return DefaultTabController(
      length: tabs.length,
      initialIndex: store.favorites.isEmpty && store.suggestions.isNotEmpty ? 2 : 0,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Text(s.pickRecipe, style: Theme.of(context).textTheme.titleLarge),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: [for (final t in tabs) Tab(text: t.$1)],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final t in tabs)
                    t.$2.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(s.noRecipesToPick, textAlign: TextAlign.center),
                          )
                        : ListView(
                            children: [
                              for (final r in t.$2)
                                ListTile(
                                  title: Text(r.title),
                                  subtitle: RecipeMetaChips(recipe: r, dense: true),
                                  onTap: () => Navigator.pop(context, r),
                                ),
                            ],
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
