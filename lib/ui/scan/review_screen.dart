import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../models/pantry_item.dart';
import '../../state/pantry_store.dart';
import '../pantry/pantry_item_editor.dart';
import '../widgets/common.dart';

/// Editable list of what the AI detected, before it goes into the pantry.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.initial});
  final List<DetectedIngredient> initial;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<DetectedIngredient> _items = [...widget.initial];
  bool _applyShelfLife = true;

  int get _selectedCount => _items.where((i) => i.selected).length;

  Future<void> _edit(int index) async {
    final d = _items[index];
    final edited = await showPantryItemEditor(
      context,
      item: PantryItem(
        name: d.name,
        quantity: d.quantity,
        category: d.category,
        expiryDate: d.expiryDate,
      ),
    );
    if (edited == null) return;
    setState(() {
      d
        ..name = edited.name
        ..quantity = edited.quantity
        ..category = edited.category
        ..expiryDate = edited.expiryDate
        // A manually set date wins over the shelf-life estimate.
        ..shelfLifeDays = edited.expiryDate != null ? 0 : d.shelfLifeDays
        ..selected = true;
    });
  }

  Future<void> _addRow() async {
    final item = await showPantryItemEditor(context);
    if (item == null) return;
    setState(() => _items.add(DetectedIngredient(
          name: item.name,
          quantity: item.quantity,
          category: item.category,
          expiryDate: item.expiryDate,
        )));
  }

  Future<void> _save() async {
    final s = context.s;
    final pantry = context.read<PantryStore>();
    final today = dateOnly(DateTime.now());
    final toAdd = _items.where((i) => i.selected).map((d) {
      final item = d.toPantryItem();
      if (item.expiryDate == null && _applyShelfLife && d.shelfLifeDays > 0) {
        return item.copyWith(
          expiryDate: today.add(Duration(days: d.shelfLifeDays)),
        );
      }
      return item;
    }).toList();
    await pantry.addAll(toAdd);
    if (!mounted) return;
    showSnack(context, s.itemsAdded(toAdd.length));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pantry = context.watch<PantryStore>();

    return Scaffold(
      appBar: AppBar(title: Text(s.reviewTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Text(
                  _items.isEmpty ? s.noItemsDetected : s.reviewHint,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (_items.any((i) => i.shelfLifeDays > 0))
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.applyShelfLife),
                    value: _applyShelfLife,
                    onChanged: (v) => setState(() => _applyShelfLife = v),
                  ),
                for (var i = 0; i < _items.length; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      value: _items[i].selected,
                      onChanged: (v) =>
                          setState(() => _items[i].selected = v ?? false),
                      secondary: IconButton(
                        tooltip: s.edit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(i),
                      ),
                      title: Row(
                        children: [
                          Icon(categoryIcon(_items[i].category), size: 18),
                          const SizedBox(width: 8),
                          Flexible(child: Text(_items[i].name)),
                          if (_items[i].confidence == DetectionConfidence.low) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${s.confidenceLow})',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: scheme.error),
                            ),
                          ],
                          if (pantry.contains(_items[i].name)) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle, size: 16, color: successColor(context)),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        [
                          if (_items[i].quantity.isNotEmpty) _items[i].quantity,
                          if (_items[i].expiryDate != null)
                            MaterialLocalizations.of(context)
                                .formatShortDate(_items[i].expiryDate!)
                          else if (_items[i].shelfLifeDays > 0)
                            s.shelfLife(_items[i].shelfLifeDays),
                        ].join(' · '),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: Text(s.addRow),
                ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedCount == 0 ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(s.addSelected(_selectedCount)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
