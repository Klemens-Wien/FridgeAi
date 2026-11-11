import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../models/recipe.dart';
import '../../models/recipe_filters.dart';
import '../../state/settings_store.dart';

/// Horizontally scrolling row of the most-used filters.
class QuickFilterBar extends StatelessWidget {
  const QuickFilterBar({super.key, required this.settings});
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = settings.filters;
    void set(RecipeFilters nf) => settings.setFilters(nf);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            avatar: const Icon(Icons.recycling, size: 18),
            label: Text(s.prioritizeExpiring),
            selected: settings.prioritizeExpiring,
            onSelected: settings.setPrioritizeExpiring,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(s.vegetarian),
            selected: f.vegetarian,
            onSelected: (v) => set(f.copyWith(vegetarian: v)),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(s.vegan),
            selected: f.vegan,
            onSelected: (v) => set(f.copyWith(vegan: v)),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(s.glutenFree),
            selected: f.glutenFree,
            onSelected: (v) => set(f.copyWith(glutenFree: v)),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(s.lowCarb),
            selected: f.lowCarb,
            onSelected: (v) => set(f.copyWith(lowCarb: v)),
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: const Icon(Icons.schedule, size: 18),
            label: Text(f.maxMinutes == null
                ? s.maxTime
                : '≤ ${s.minutes(f.maxMinutes!)}'),
            selected: f.maxMinutes != null,
            onSelected: (_) => showFilterSheet(context),
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: const Icon(Icons.signal_cellular_alt, size: 18),
            label: Text(f.difficulty == null
                ? s.difficulty
                : '≤ ${s.difficultyName(f.difficulty!)}'),
            selected: f.difficulty != null,
            onSelected: (_) => showFilterSheet(context),
          ),
        ],
      ),
    );
  }
}

Future<void> showFilterSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsStore>();
    final f = settings.filters;
    final theme = Theme.of(context);
    void set(RecipeFilters nf) => settings.setFilters(nf);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(title, style: theme.textTheme.titleSmall),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(s.filters, style: theme.textTheme.titleLarge)),
                TextButton(
                  onPressed: f.isEmpty ? null : () => set(const RecipeFilters()),
                  child: Text(s.resetFilters),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.recycling),
              title: Text(s.prioritizeExpiring),
              subtitle: Text(s.prioritizeExpiringHint),
              value: settings.prioritizeExpiring,
              onChanged: settings.setPrioritizeExpiring,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(s.vegetarian),
                  selected: f.vegetarian,
                  onSelected: (v) => set(f.copyWith(vegetarian: v)),
                ),
                FilterChip(
                  label: Text(s.vegan),
                  selected: f.vegan,
                  onSelected: (v) => set(f.copyWith(vegan: v)),
                ),
                FilterChip(
                  label: Text(s.glutenFree),
                  selected: f.glutenFree,
                  onSelected: (v) => set(f.copyWith(glutenFree: v)),
                ),
                FilterChip(
                  label: Text(s.lowCarb),
                  selected: f.lowCarb,
                  onSelected: (v) => set(f.copyWith(lowCarb: v)),
                ),
              ],
            ),
            section(s.maxTime),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(s.anyTime),
                  selected: f.maxMinutes == null,
                  onSelected: (_) => set(f.copyWith(clearMaxMinutes: true)),
                ),
                for (final m in RecipeFilters.timeOptions)
                  ChoiceChip(
                    label: Text('≤ ${s.minutes(m)}'),
                    selected: f.maxMinutes == m,
                    onSelected: (_) => set(f.copyWith(maxMinutes: m)),
                  ),
              ],
            ),
            section('${s.difficulty} (${s.difficultyUpTo})'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(s.anyDifficulty),
                  selected: f.difficulty == null,
                  onSelected: (_) => set(f.copyWith(clearDifficulty: true)),
                ),
                for (final d in Difficulty.values)
                  ChoiceChip(
                    label: Text(s.difficultyName(d)),
                    selected: f.difficulty == d,
                    onSelected: (_) => set(f.copyWith(difficulty: d)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.apply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
