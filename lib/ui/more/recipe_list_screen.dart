import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../logic/recipe_ranking.dart';
import '../../models/recipe.dart';
import '../../state/pantry_store.dart';
import '../../state/recipe_store.dart';
import '../recipes/recipe_card.dart';
import '../widgets/common.dart';

class _RecipeList extends StatelessWidget {
  const _RecipeList({required this.recipes, required this.emptyText, this.subtitles});

  final List<Recipe> recipes;
  final String emptyText;
  final List<String>? subtitles;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return EmptyState(icon: Icons.menu_book_outlined, title: emptyText);
    }
    final ranker = RecipeRanker(context.watch<PantryStore>().items);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitles != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(subtitles![i], style: Theme.of(context).textTheme.labelSmall),
            ),
          RecipeCard(match: ranker.match(recipes[i])),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final store = context.watch<RecipeStore>();
    return Scaffold(
      appBar: AppBar(title: Text(s.favorites)),
      body: _RecipeList(recipes: store.favorites, emptyText: s.favoritesEmpty),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final store = context.watch<RecipeStore>();
    final loc = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.history),
        actions: [
          if (store.history.isNotEmpty)
            IconButton(
              tooltip: s.clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                if (await confirm(context, '${s.clearHistory}?')) {
                  await store.clearHistory();
                }
              },
            ),
        ],
      ),
      body: _RecipeList(
        recipes: store.history.map((h) => h.recipe).toList(),
        subtitles: store.history
            .map((h) =>
                '${loc.formatMediumDate(h.viewedAt)} · ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(h.viewedAt))}')
            .toList(),
        emptyText: s.historyEmpty,
      ),
    );
  }
}
