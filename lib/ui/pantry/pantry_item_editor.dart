import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/strings.dart';
import '../../models/pantry_item.dart';
import '../widgets/common.dart';

/// Bottom sheet to create or edit a pantry item. Returns the edited item, or
/// null if cancelled.
Future<PantryItem?> showPantryItemEditor(
  BuildContext context, {
  PantryItem? item,
}) =>
    showModalBottomSheet<PantryItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _PantryItemEditor(item: item),
    );

class _PantryItemEditor extends StatefulWidget {
  const _PantryItemEditor({this.item});
  final PantryItem? item;

  @override
  State<_PantryItemEditor> createState() => _PantryItemEditorState();
}

class _PantryItemEditorState extends State<_PantryItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.item?.name ?? '');
  late final TextEditingController _quantity =
      TextEditingController(text: widget.item?.quantity ?? '');
  late FoodCategory _category = widget.item?.category ?? FoodCategory.other;
  late DateTime? _expiry = widget.item?.expiryDate;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now.add(const Duration(days: 3)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.item;
    final result = base == null
        ? PantryItem(
            name: _name.text.trim(),
            quantity: _quantity.text.trim(),
            category: _category,
            expiryDate: _expiry,
          )
        : base.copyWith(
            name: _name.text.trim(),
            quantity: _quantity.text.trim(),
            category: _category,
            expiryDate: _expiry,
            clearExpiry: _expiry == null,
          );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final locale = s.languageCode;
    final now = DateTime.now();
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.item == null ? s.addItem : s.editItem,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: widget.item == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: s.name),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.nameRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantity,
                decoration: InputDecoration(
                  labelText: s.quantity,
                  hintText: s.quantityHint,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FoodCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.category),
                items: [
                  for (final c in FoodCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(categoryIcon(c), size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              s.categoryName(c),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (c) => setState(() => _category = c ?? _category),
              ),
              const SizedBox(height: 16),
              Text(s.expiryDate, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(s.noExpiry),
                    selected: _expiry == null,
                    onSelected: (_) => setState(() => _expiry = null),
                  ),
                  for (final days in [1, 3, 7, 14])
                    ChoiceChip(
                      label: Text('+$days'),
                      selected: _expiry != null &&
                          dateOnly(_expiry!) ==
                              dateOnly(now.add(Duration(days: days))),
                      onSelected: (_) => setState(
                        () => _expiry = dateOnly(now.add(Duration(days: days))),
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _expiry == null
                          ? s.setExpiry
                          : DateFormat.yMMMd(locale).format(_expiry!),
                    ),
                    onPressed: _pickDate,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _submit, child: Text(s.save)),
            ],
          ),
        ),
      ),
    );
  }
}
