import 'package:flutter/material.dart';

import '../../app.dart';
import '../../l10n/strings.dart';
import '../../logic/recipe_ranking.dart';
import '../widgets/common.dart';
import '../widgets/recipe_art.dart';
import 'recipe_detail_screen.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.match});
  final RecipeMatch match;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = match.recipe;
    final total = match.availableCount + match.missingCount;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecipeArt(kind: r.kind),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: theme.textTheme.titleMedium),
                        if (r.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            r.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RecipeMetaChips(recipe: r, dense: true),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: match.coverage,
                  minHeight: 6,
                  color: scheme.success,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.matchAvailable(match.availableCount, total),
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  Text(
                    match.missingCount == 0
                        ? s.allAvailable
                        : s.missingCount(match.missingCount),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: match.missingCount == 0 ? scheme.success : scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (match.expiringUsed.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.recycling, size: 16, color: scheme.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${s.usesExpiring(match.expiringUsed.length)}: '
                        '${match.expiringUsed.map((p) => p.name).join(', ')}',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: scheme.warning),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
