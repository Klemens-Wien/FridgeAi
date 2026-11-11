import 'package:flutter/material.dart';

import '../../app.dart';
import '../../l10n/strings.dart';
import '../../models/pantry_item.dart';
import '../../models/recipe.dart';
import '../../services/claude_client.dart';
import '../more/settings_screen.dart';

void showSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    action: actionLabel == null
        ? null
        : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
  ));
}

Future<bool> confirm(BuildContext context, String message) async {
  final s = context.s;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, size: 44, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error panel for failed AI calls, with retry and a shortcut to Settings
/// when the API key is the problem.
class AiErrorCard extends StatelessWidget {
  const AiErrorCard({super.key, required this.error, this.onRetry});

  final ClaudeException error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final keyProblem = error.kind == ClaudeErrorKind.missingApiKey ||
        error.kind == ClaudeErrorKind.invalidApiKey;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  s.errorTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.errorMessage(error.kind),
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (keyProblem)
                  FilledButton.tonal(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Text(s.goToSettings),
                  ),
                if (onRetry != null && !keyProblem)
                  FilledButton.tonal(onPressed: onRetry, child: Text(s.retry)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner shown when no API key is configured.
class MissingApiKeyBanner extends StatelessWidget {
  const MissingApiKeyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return MaterialBanner(
      leading: const Icon(Icons.key_outlined),
      content: Text(s.missingApiKeyBanner),
      actions: [
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          child: Text(s.goToSettings),
        ),
      ],
    );
  }
}

String expiryLabel(S s, PantryItem item) {
  final d = item.daysUntilExpiry();
  if (d == null) return s.noExpiry;
  if (d < 0) return s.expiredDaysAgo(-d);
  if (d == 0) return s.expiresToday;
  if (d == 1) return s.expiresTomorrow;
  return s.expiresInDays(d);
}

class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({super.key, required this.item});
  final PantryItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = item.expiryStatus();
    if (status == ExpiryStatus.none) return const SizedBox.shrink();
    final color = switch (status) {
      ExpiryStatus.expired => scheme.error,
      ExpiryStatus.soon => scheme.warning,
      _ => scheme.onSurfaceVariant,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          status == ExpiryStatus.ok ? Icons.event_outlined : Icons.warning_amber_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          expiryLabel(context.s, item),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

IconData categoryIcon(FoodCategory c) => switch (c) {
      FoodCategory.produce => Icons.eco_outlined,
      FoodCategory.dairy => Icons.egg_outlined,
      FoodCategory.meat => Icons.set_meal_outlined,
      FoodCategory.fish => Icons.phishing_outlined,
      FoodCategory.grains => Icons.rice_bowl_outlined,
      FoodCategory.bakery => Icons.bakery_dining_outlined,
      FoodCategory.canned => Icons.inventory_2_outlined,
      FoodCategory.frozen => Icons.ac_unit,
      FoodCategory.spices => Icons.grass_outlined,
      FoodCategory.sauces => Icons.water_drop_outlined,
      FoodCategory.beverages => Icons.local_drink_outlined,
      FoodCategory.other => Icons.category_outlined,
    };

/// Small chips with the recipe's diet flags, time and difficulty.
class RecipeMetaChips extends StatelessWidget {
  const RecipeMetaChips({super.key, required this.recipe, this.dense = false});

  final Recipe recipe;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final items = <(IconData, String)>[
      (Icons.schedule, s.minutes(recipe.totalMinutes)),
      (Icons.signal_cellular_alt, s.difficultyName(recipe.difficulty)),
      if (recipe.vegan)
        (Icons.spa_outlined, s.vegan)
      else if (recipe.vegetarian)
        (Icons.eco_outlined, s.vegetarian),
      if (recipe.glutenFree) (Icons.grain, s.glutenFree),
      if (recipe.lowCarb) (Icons.trending_down, s.lowCarb),
    ];
    final theme = Theme.of(context);
    return Wrap(
      spacing: dense ? 10 : 8,
      runSpacing: 6,
      children: [
        for (final (icon, label) in items)
          dense
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : Chip(
                  avatar: Icon(icon, size: 16),
                  label: Text(label),
                  visualDensity: VisualDensity.compact,
                ),
      ],
    );
  }
}

/// Loading panel used while the AI works.
class AiProgress extends StatelessWidget {
  const AiProgress({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// Brand-coloured "success" text style helper.
Color successColor(BuildContext context) => Theme.of(context).colorScheme.success;
