import 'package:flutter/material.dart';

import '../../models/recipe.dart';

IconData recipeKindIcon(RecipeKind kind) => switch (kind) {
      RecipeKind.pasta => Icons.ramen_dining,
      RecipeKind.rice => Icons.rice_bowl,
      RecipeKind.soup => Icons.soup_kitchen,
      RecipeKind.salad => Icons.eco,
      RecipeKind.meat => Icons.kebab_dining,
      RecipeKind.fish => Icons.set_meal,
      RecipeKind.egg => Icons.egg_alt,
      RecipeKind.vegetable => Icons.local_florist,
      RecipeKind.bread => Icons.bakery_dining,
      RecipeKind.dessert => Icons.cake,
      RecipeKind.breakfast => Icons.breakfast_dining,
      RecipeKind.other => Icons.restaurant,
    };

/// Hue per dish type, so cards are told apart at a glance.
double _hue(RecipeKind kind) => switch (kind) {
      RecipeKind.pasta => 38,
      RecipeKind.rice => 48,
      RecipeKind.soup => 22,
      RecipeKind.salad => 120,
      RecipeKind.meat => 8,
      RecipeKind.fish => 200,
      RecipeKind.egg => 50,
      RecipeKind.vegetable => 95,
      RecipeKind.bread => 30,
      RecipeKind.dessert => 330,
      RecipeKind.breakfast => 28,
      RecipeKind.other => 150,
    };

/// Gradient tile with the dish-type icon; stands in for a recipe photo.
class RecipeArt extends StatelessWidget {
  const RecipeArt({
    super.key,
    required this.kind,
    this.size = 64,
    this.radius = 16,
  });

  final RecipeKind kind;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = _hue(kind);
    Color tone(double shift, double lightness) => HSLColor.fromAHSL(
          1,
          (hue + shift) % 360,
          dark ? 0.35 : 0.62,
          lightness,
        ).toColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [tone(0, 0.30), tone(25, 0.20)]
              : [tone(0, 0.86), tone(25, 0.74)],
        ),
      ),
      child: Icon(
        recipeKindIcon(kind),
        size: size * 0.5,
        color: HSLColor.fromAHSL(1, hue, 0.55, dark ? 0.82 : 0.28).toColor(),
      ),
    );
  }
}
