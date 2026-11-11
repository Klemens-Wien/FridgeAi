import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ShoppingItem {
  ShoppingItem({
    String? id,
    required this.name,
    this.amount = 0,
    this.unit = '',
    this.recipeTitle = '',
    this.checked = false,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final double amount;
  final String unit;

  /// Title of the recipe this item was added for ("" if added manually).
  final String recipeTitle;
  final bool checked;

  ShoppingItem copyWith({
    String? name,
    double? amount,
    String? unit,
    String? recipeTitle,
    bool? checked,
  }) =>
      ShoppingItem(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        unit: unit ?? this.unit,
        recipeTitle: recipeTitle ?? this.recipeTitle,
        checked: checked ?? this.checked,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'unit': unit,
        'recipeTitle': recipeTitle,
        'checked': checked,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? '',
        recipeTitle: json['recipeTitle'] as String? ?? '',
        checked: json['checked'] as bool? ?? false,
      );
}
