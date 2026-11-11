import 'package:flutter/foundation.dart';

import '../logic/recipe_ranking.dart' show normalizeName;
import '../models/shopping_item.dart';
import '../services/storage.dart';

class ShoppingStore extends ChangeNotifier {
  ShoppingStore(this._store) {
    _items = _store.readList(_key, ShoppingItem.fromJson);
  }

  final LocalStore _store;
  static const _key = 'shopping.items';
  late List<ShoppingItem> _items;

  /// Unchecked items first, in insertion order.
  List<ShoppingItem> get items => [
        ..._items.where((i) => !i.checked),
        ..._items.where((i) => i.checked),
      ];

  int get openCount => _items.where((i) => !i.checked).length;
  bool get hasChecked => _items.any((i) => i.checked);

  bool contains(String name) {
    final n = normalizeName(name);
    return _items.any((i) => !i.checked && normalizeName(i.name) == n);
  }

  Future<void> _save() => _store.writeList(_key, _items, (i) => i.toJson());

  /// Adds items; an open item with the same name and unit gets its amount
  /// summed instead of being duplicated. Returns how many were added/merged.
  Future<int> addAll(Iterable<ShoppingItem> newItems) async {
    var count = 0;
    for (final item in newItems) {
      if (item.name.trim().isEmpty) continue;
      final n = normalizeName(item.name);
      final idx = _items.indexWhere((i) =>
          !i.checked &&
          normalizeName(i.name) == n &&
          i.unit.toLowerCase() == item.unit.toLowerCase());
      if (idx >= 0) {
        final old = _items[idx];
        final titles = {
          ...old.recipeTitle.split(', ').where((t) => t.isNotEmpty),
          if (item.recipeTitle.isNotEmpty) item.recipeTitle,
        };
        _items[idx] = old.copyWith(
          amount: (old.amount > 0 && item.amount > 0)
              ? old.amount + item.amount
              : (old.amount > 0 ? old.amount : item.amount),
          recipeTitle: titles.join(', '),
        );
      } else {
        _items.add(item);
      }
      count++;
    }
    notifyListeners();
    await _save();
    return count;
  }

  Future<void> add(ShoppingItem item) => addAll([item]);

  Future<void> toggle(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    _items[idx] = _items[idx].copyWith(checked: !_items[idx].checked);
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> restore(ShoppingItem item) async {
    _items.add(item);
    notifyListeners();
    await _save();
  }

  /// Removes and returns all checked items.
  Future<List<ShoppingItem>> takeChecked() async {
    final checked = _items.where((i) => i.checked).toList();
    _items.removeWhere((i) => i.checked);
    notifyListeners();
    await _save();
    return checked;
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _save();
  }
}
