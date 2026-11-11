import 'package:flutter/foundation.dart';

import '../logic/recipe_ranking.dart' show normalizeName;
import '../models/pantry_item.dart';
import '../services/storage.dart';

class PantryStore extends ChangeNotifier {
  PantryStore(this._store) {
    _items = _store.readList(_key, PantryItem.fromJson);
  }

  final LocalStore _store;
  static const _key = 'pantry.items';
  late List<PantryItem> _items;

  /// Items sorted so that the ones expiring first are on top, then by name.
  List<PantryItem> get items {
    final list = [..._items];
    list.sort((a, b) {
      final da = a.expiryDate, db = b.expiryDate;
      if (da != null && db != null) {
        final c = da.compareTo(db);
        if (c != 0) return c;
      } else if (da != null) {
        return -1;
      } else if (db != null) {
        return 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;

  List<PantryItem> get expiringSoon =>
      items.where((i) => i.isExpiringSoon()).toList();

  bool contains(String name) {
    final n = normalizeName(name);
    return _items.any((i) => normalizeName(i.name) == n);
  }

  Future<void> _save() => _store.writeList(_key, _items, (i) => i.toJson());

  Future<void> add(PantryItem item) async {
    _items.add(item);
    notifyListeners();
    await _save();
  }

  /// Adds [newItems], merging with existing items of the same name: the
  /// newer quantity wins and the earlier expiry date is kept.
  /// Returns the number of items that were genuinely new.
  Future<int> addAll(Iterable<PantryItem> newItems) async {
    var added = 0;
    for (final item in newItems) {
      if (item.name.trim().isEmpty) continue;
      final n = normalizeName(item.name);
      final idx = _items.indexWhere((i) => normalizeName(i.name) == n);
      if (idx < 0) {
        _items.add(item);
        added++;
      } else {
        final old = _items[idx];
        DateTime? expiry = old.expiryDate;
        final ne = item.expiryDate;
        if (ne != null && (expiry == null || ne.isBefore(expiry))) expiry = ne;
        _items[idx] = old.copyWith(
          quantity: item.quantity.isNotEmpty ? item.quantity : old.quantity,
          category: item.category,
          expiryDate: expiry,
        );
      }
    }
    notifyListeners();
    await _save();
    return added;
  }

  Future<void> update(PantryItem item) async {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx < 0) return;
    _items[idx] = item;
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> removeByNames(Iterable<String> names) async {
    final set = names.map(normalizeName).toSet();
    _items.removeWhere((i) => set.contains(normalizeName(i.name)));
    notifyListeners();
    await _save();
  }

  Future<void> restore(PantryItem item) => add(item);

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _save();
  }
}
