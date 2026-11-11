import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../l10n/strings.dart';
import '../../logic/recipe_ranking.dart' show normalizeName;
import '../../models/pantry_item.dart';
import '../../state/pantry_store.dart';
import '../../state/settings_store.dart';
import '../recipes/recipes_screen.dart';
import '../scan/scan_screen.dart';
import '../widgets/common.dart';
import 'pantry_item_editor.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _query = '';

  /// The search field only earns its space once the list gets long.
  static const _searchThreshold = 6;

  Future<void> _addManually(BuildContext context) async {
    final pantry = context.read<PantryStore>();
    final item = await showPantryItemEditor(context);
    if (item != null) await pantry.addAll([item]);
  }

  void _scan(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final pantry = context.watch<PantryStore>();
    final hasKey = context.select<SettingsStore, bool>((s) => s.hasApiKey);
    final settings = context.watch<SettingsStore>();
    final items = pantry.items;
    final expiring = pantry.expiringSoon;
    final q = normalizeName(_query);
    final visible = q.isEmpty
        ? items
        : items.where((i) => normalizeName(i.name).contains(q)).toList();
    final grouped = <FoodCategory, List<PantryItem>>{};
    if (settings.groupPantry) {
      for (final c in FoodCategory.values) {
        final inCat = visible.where((i) => i.category == c).toList();
        if (inCat.isNotEmpty) grouped[c] = inCat;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.pantryTitle),
        actions: [
          IconButton(
            tooltip: s.addManually,
            icon: const Icon(Icons.add),
            onPressed: () => _addManually(context),
          ),
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'group') {
                  await settings.setGroupPantry(!settings.groupPantry);
                } else if (v == 'clear' &&
                    await confirm(context, s.clearPantryConfirm)) {
                  await pantry.clear();
                }
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'group',
                  checked: settings.groupPantry,
                  child: Text(s.groupByCategory),
                ),
                PopupMenuItem(value: 'clear', child: Text(s.clearPantry)),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'scan',
        onPressed: () => _scan(context),
        icon: const Icon(Icons.photo_camera_outlined),
        label: Text(s.scanFridge),
      ),
      body: Column(
        children: [
          if (!hasKey) const MissingApiKeyBanner(),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.kitchen_outlined,
                    title: s.pantryEmptyTitle,
                    body: s.pantryEmptyBody,
                    actions: [
                      FilledButton.icon(
                        onPressed: () => _scan(context),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(s.scanFridge),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addManually(context),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(s.addManually),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      if (expiring.isNotEmpty) ...[
                        _ExpiringCard(count: expiring.length),
                        const SizedBox(height: 12),
                      ],
                      FilledButton.icon(
                        onPressed: () {
                          context.read<TabNavigator>().goTo(TabNavigator.recipes);
                          generateRecipes(context);
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(s.findRecipes),
                      ),
                      const SizedBox(height: 12),
                      if (items.length > _searchThreshold) ...[
                        TextField(
                          onChanged: (v) => setState(() => _query = v),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: s.searchPantry,
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            s.noSearchResults,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (settings.groupPantry)
                        for (final entry in grouped.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                            child: Text(
                              '${s.categoryName(entry.key)} (${entry.value.length})',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          for (final item in entry.value)
                            _PantryTile(item: item),
                        ]
                      else
                        for (final item in visible) _PantryTile(item: item),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExpiringCard extends StatelessWidget {
  const _ExpiringCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.recycling, color: scheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.s.expiringBanner(count),
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PantryTile extends StatelessWidget {
  const _PantryTile({required this.item});
  final PantryItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final pantry = context.read<PantryStore>();
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      if (item.quantity.isNotEmpty) item.quantity,
      s.categoryName(item.category),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ),
        onDismissed: (_) {
          pantry.remove(item.id);
          showSnack(
            context,
            s.itemDeleted(item.name),
            actionLabel: s.undo,
            onAction: () => pantry.restore(item),
          );
        },
        child: Card(
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: CircleAvatar(
              backgroundColor: scheme.secondaryContainer,
              child: Icon(
                categoryIcon(item.category),
                color: scheme.onSecondaryContainer,
              ),
            ),
            title: Text(item.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.expiryDate != null) ...[
                  const SizedBox(height: 2),
                  ExpiryBadge(item: item),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final edited = await showPantryItemEditor(context, item: item);
              if (edited != null) await pantry.update(edited);
            },
          ),
        ),
      ),
    );
  }
}
