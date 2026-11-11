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
