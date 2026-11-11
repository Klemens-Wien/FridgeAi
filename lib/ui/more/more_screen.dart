import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../state/recipe_store.dart';
import 'recipe_list_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final store = context.watch<RecipeStore>();
    void push(Widget w) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      appBar: AppBar(title: Text(s.moreTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.statsTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Stat(
                          icon: Icons.restaurant,
                          value: store.cookedCount,
                          label: s.statsCooked,
                        ),
                        _Stat(
                          icon: Icons.recycling,
                          value: store.rescuedCount,
                          label: s.statsRescued,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: Text(s.favorites),
            trailing: Text('${store.favorites.length}'),
            onTap: () => push(const FavoritesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(s.history),
            trailing: Text('${store.history.length}'),
            onTap: () => push(const HistoryScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(s.settings),
            onTap: () => push(const SettingsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.about),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: s.appName,
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.kitchen, size: 40),
              children: [Text(s.aboutBody), const SizedBox(height: 12), Text(s.aiDisclaimer)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer;
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
