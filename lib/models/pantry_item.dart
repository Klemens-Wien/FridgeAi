import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Broad food categories used to group the pantry list and to tell the
/// vision model which labels it may return.
enum FoodCategory {
  produce,
  dairy,
  meat,
  fish,
  grains,
  bakery,
  canned,
  frozen,
  spices,
  sauces,
  beverages,
  other;

  static FoodCategory parse(String? value) => FoodCategory.values.firstWhere(
        (c) => c.name == value,
        orElse: () => FoodCategory.other,
      );
}

enum ExpiryStatus { none, ok, soon, expired }

/// Days before the expiry date at which an item counts as "expiring soon".
const int expirySoonThresholdDays = 2;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class PantryItem {
  PantryItem({
    String? id,
    required this.name,
    this.quantity = '',
    this.category = FoodCategory.other,
    this.expiryDate,
    DateTime? addedAt,
  })  : id = id ?? _uuid.v4(),
        addedAt = addedAt ?? DateTime.now();

  final String id;
  final String name;
  final String quantity;
  final FoodCategory category;
  final DateTime? expiryDate;
  final DateTime addedAt;

  /// Whole days until the expiry date (negative when already expired),
  /// or null if no date is set.
  int? daysUntilExpiry([DateTime? now]) {
    final e = expiryDate;
    if (e == null) return null;
    return dateOnly(e).difference(dateOnly(now ?? DateTime.now())).inDays;
  }

  ExpiryStatus expiryStatus([DateTime? now]) {
    final days = daysUntilExpiry(now);
    if (days == null) return ExpiryStatus.none;
    if (days < 0) return ExpiryStatus.expired;
    if (days <= expirySoonThresholdDays) return ExpiryStatus.soon;
    return ExpiryStatus.ok;
  }

  bool isExpiringSoon([DateTime? now]) {
    final s = expiryStatus(now);
    return s == ExpiryStatus.soon || s == ExpiryStatus.expired;
  }

  PantryItem copyWith({
    String? name,
    String? quantity,
    FoodCategory? category,
    DateTime? expiryDate,
    bool clearExpiry = false,
  }) =>
      PantryItem(
        id: id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        category: category ?? this.category,
        expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'category': category.name,
        'expiryDate': expiryDate?.toIso8601String(),
        'addedAt': addedAt.toIso8601String(),
      };

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as String? ?? '',
        category: FoodCategory.parse(json['category'] as String?),
        expiryDate: json['expiryDate'] == null
            ? null
            : DateTime.tryParse(json['expiryDate'] as String),
        addedAt: json['addedAt'] == null
            ? null
            : DateTime.tryParse(json['addedAt'] as String),
      );
}

/// An ingredient as returned by the vision model, before the user confirms it.
class DetectedIngredient {
  DetectedIngredient({
    required this.name,
    this.quantity = '',
    this.category = FoodCategory.other,
    this.confidence = DetectionConfidence.high,
    this.shelfLifeDays = 0,
    this.selected = true,
    this.expiryDate,
  });

  String name;
  String quantity;
  FoodCategory category;
  DetectionConfidence confidence;

  /// Rough shelf-life estimate from the model; 0 means "no estimate".
  int shelfLifeDays;
  bool selected;
  DateTime? expiryDate;

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) =>
      DetectedIngredient(
        name: (json['name'] as String? ?? '').trim(),
        quantity: (json['quantity'] as String? ?? '').trim(),
        category: FoodCategory.parse(json['category'] as String?),
        confidence: DetectionConfidence.parse(json['confidence'] as String?),
        shelfLifeDays: (json['shelfLifeDays'] as num?)?.toInt() ?? 0,
      );

  PantryItem toPantryItem() => PantryItem(
        name: name.trim(),
        quantity: quantity.trim(),
        category: category,
        expiryDate: expiryDate,
      );
}

enum DetectionConfidence {
  high,
  medium,
  low;

  static DetectionConfidence parse(String? v) =>
      DetectionConfidence.values.firstWhere(
        (c) => c.name == v,
        orElse: () => DetectionConfidence.medium,
      );
}
