import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../logic/recipe_ranking.dart';
import '../../state/pantry_store.dart';
import '../../state/recipe_store.dart';
import '../../state/settings_store.dart';
import '../pro/pro_gate.dart';
import '../widgets/common.dart';
import 'filter_sheet.dart';
import 'recipe_card.dart';

/// Requests recipe suggestions for the current pantry, filters and language.
Future<void> generateRecipes(
  BuildContext context, {
  bool append = false,
}) async {
  final store = context.read<RecipeStore>();
  if (store.loading) return;
  // Free tier: counts against the daily AI allowance.
  if (!await useAiQuota(context) || !context.mounted) return;
  final settings = context.read<SettingsStore>();
  return store.generate(
        apiKey: settings.effectiveApiKey,
        pantry: context.read<PantryStore>().items,
        filters: settings.filters,
        languageCode: context.s.languageCode,
        servings: settings.defaultServings,
        prioritizeExpiring: settings.prioritizeExpiring,
        avoidIngredients: settings.avoidIngredients,
        wish: store.wish,
        append: append,
      );
}

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final store = context.watch<RecipeStore>();
    final settings = context.watch<SettingsStore>();
    final pantry = context.watch<PantryStore>();
    final filters = settings.filters;

    final ranked = RecipeRanker(pantry.items)
        .rank(
          store.suggestions.where(filters.matches).where(
                (r) => !usesAvoidedIngredient(r, settings.avoidIngredients),
              ),
          prioritizeExpiring: settings.prioritizeExpiring,
        )
        .toList();

    Widget body;
    if (store.loading && store.suggestions.isEmpty) {
      body = Center(child: AiProgress(title: s.generating, subtitle: s.generatingHint));
    } else if (store.suggestions.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (store.error != null)
            AiErrorCard(error: store.error!, onRetry: () => generateRecipes(context)),
          EmptyState(
            icon: Icons.restaurant_menu,
            title: s.noSuggestionsTitle,
            body: pantry.isEmpty ? s.pantryEmptyForRecipes : s.noSuggestionsBody,
            actions: [
              FilledButton.icon(
                onPressed: () => generateRecipes(context),
                icon: const Icon(Icons.auto_awesome),
                label: Text(s.generateRecipes),
              ),
            ],
          ),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => generateRecipes(context),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (store.error != null) ...[
              AiErrorCard(error: store.error!, onRetry: () => generateRecipes(context)),
              const SizedBox(height: 12),
            ],
            if (ranked.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(s.noRecipesMatchFilters, textAlign: TextAlign.center),
              ),
            for (final match in ranked) ...[
              RecipeCard(match: match),
              const SizedBox(height: 12),
            ],
            if (store.loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              OutlinedButton.icon(
                onPressed: () => generateRecipes(context, append: true),
                icon: const Icon(Icons.add),
                label: Text(s.moreRecipes),
              ),
            const SizedBox(height: 16),
            Text(
              s.aiDisclaimer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.recipesTitle),
        actions: [
          if (store.suggestions.isNotEmpty)
            IconButton(
              tooltip: s.generateRecipes,
              icon: const Icon(Icons.refresh),
              onPressed: store.loading ? null : () => generateRecipes(context),
            ),
          IconButton(
            tooltip: s.filters,
            onPressed: () => showFilterSheet(context),
            icon: Badge(
              isLabelVisible: filters.activeCount > 0,
              label: Text('${filters.activeCount}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: QuickFilterBar(settings: settings),
        ),
      ),
      body: Column(
        children: [
          if (!settings.hasApiKey) const MissingApiKeyBanner(),
          const _WishField(),
          if (store.loading && store.suggestions.isNotEmpty)
            const LinearProgressIndicator(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// "What do you feel like?" – optional free text passed to the recipe prompt.
class _WishField extends StatefulWidget {
  const _WishField();

  @override
  State<_WishField> createState() => _WishFieldState();
}

class _WishFieldState extends State<_WishField> {
  late final _controller =
      TextEditingController(text: context.read<RecipeStore>().wish);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    generateRecipes(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final loading = context.select<RecipeStore, bool>((r) => r.loading);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.sentences,
        maxLength: 120,
        onChanged: (v) => context.read<RecipeStore>().wish = v,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          hintText: s.wishHint,
          prefixIcon: const Icon(Icons.lightbulb_outline),
          suffixIcon: IconButton(
            tooltip: s.generateRecipes,
            icon: const Icon(Icons.auto_awesome),
            onPressed: loading ? null : _submit,
          ),
        ),
      ),
    );
  }
}
