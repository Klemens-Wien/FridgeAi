import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../logic/scaling.dart';
import '../../logic/share_text.dart';
import '../../models/pantry_item.dart';
import '../../models/shopping_item.dart';
import '../../state/pantry_store.dart';
import '../../state/shopping_store.dart';
import '../widgets/common.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _addTyped() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<ShoppingStore>().add(ShoppingItem(name: text));
    _input.clear();
  }

  Future<void> _moveCheckedToPantry() async {
    final s = context.s;
    final pantry = context.read<PantryStore>();
    final checked = await context.read<ShoppingStore>().takeChecked();
    await pantry.addAll(checked.map((i) => PantryItem(
          name: i.name,
          quantity: [formatAmount(i.amount, s.languageCode), i.unit]
              .where((p) => p.isNotEmpty)
              .join(' '),
        )));
    if (mounted) showSnack(context, s.movedToPantry(checked.length));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final store = context.watch<ShoppingStore>();
    final items = store.items;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.shoppingTitle),
        actions: [
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'copy':
                    await Clipboard.setData(ClipboardData(
                      text: shoppingShareText(store.items, s),
                    ));
                    if (context.mounted) showSnack(context, s.copied);
                  case 'pantry':
                    await _moveCheckedToPantry();
                  case 'clearChecked':
                    await store.takeChecked();
                  case 'clearAll':
                    if (await confirm(context, s.clearShoppingConfirm)) {
                      await store.clear();
                    }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'copy', child: Text(s.copyList)),
                PopupMenuItem(
                  value: 'pantry',
                  enabled: store.hasChecked,
                  child: Text(s.moveCheckedToPantry),
                ),
                PopupMenuItem(
                  value: 'clearChecked',
                  enabled: store.hasChecked,
                  child: Text(s.clearChecked),
                ),
                PopupMenuItem(value: 'clearAll', child: Text(s.delete)),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _input,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTyped(),
              decoration: InputDecoration(
                hintText: s.addShoppingHint,
                prefixIcon: const Icon(Icons.add),
                suffixIcon: IconButton(
                  tooltip: s.add,
                  icon: const Icon(Icons.send),
                  onPressed: _addTyped,
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: s.shoppingEmptyTitle,
                    body: s.shoppingEmptyBody,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    children: [
                      for (final item in items)
                        Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: scheme.errorContainer,
                            child: Icon(Icons.delete_outline,
                                color: scheme.onErrorContainer),
                          ),
                          onDismissed: (_) {
                            store.remove(item.id);
                            showSnack(
                              context,
                              s.itemDeleted(item.name),
                              actionLabel: s.undo,
                              onAction: () => store.restore(item),
                            );
                          },
                          child: CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            value: item.checked,
                            onChanged: (_) => store.toggle(item.id),
                            title: Text(
                              item.name,
                              style: item.checked
                                  ? TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: scheme.onSurfaceVariant,
                                    )
                                  : null,
                            ),
                            subtitle: item.recipeTitle.isEmpty
                                ? null
                                : Text(
                                    s.forRecipe(item.recipeTitle),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            secondary: Text(
                              [formatAmount(item.amount, s.languageCode), item.unit]
                                  .where((p) => p.isNotEmpty)
                                  .join(' '),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: store.hasChecked
          ? FloatingActionButton.extended(
              heroTag: 'toPantry',
              onPressed: _moveCheckedToPantry,
              icon: const Icon(Icons.kitchen),
              label: Text(s.moveCheckedToPantry),
            )
          : null,
    );
  }
}
