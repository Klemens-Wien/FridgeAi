import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../l10n/strings.dart';
import '../../models/food_log.dart';
import '../../models/pantry_item.dart' show dateOnly;
import '../../state/food_log_store.dart';
import '../widgets/common.dart';
import 'entry_sheet.dart';

/// Calorie diary: one day at a time with goal ring, macros, the day's
/// entries and a 7-day overview.
class CalorieScreen extends StatefulWidget {
  const CalorieScreen({super.key});

  @override
  State<CalorieScreen> createState() => _CalorieScreenState();
}

class _CalorieScreenState extends State<CalorieScreen> {
  DateTime _day = dateOnly(DateTime.now());

  bool get _isToday => _day == dateOnly(DateTime.now());

  void _shift(int days) => setState(() => _day = _day.add(Duration(days: days)));

  Future<void> _editGoal(FoodLogStore log) async {
    final s = context.s;
    var value = log.goal;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(s.dailyGoal),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value kcal', style: Theme.of(ctx).textTheme.headlineSmall),
              Slider(
                value: value.toDouble(),
                min: FoodLogStore.minGoal.toDouble(),
                max: 4000,
                divisions: (4000 - FoodLogStore.minGoal) ~/ 50,
                label: '$value',
                onChanged: (v) => setLocal(() => value = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, value),
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
    if (result != null) await log.setGoal(result);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final log = context.watch<FoodLogStore>();
    final entries = log.entriesFor(_day);
    final totals = DayTotals.of(entries);
    final fmtDay = DateFormat.MMMEd(s.languageCode);
    final time = DateFormat.Hm(s.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.calorieCounter),
        actions: [
          IconButton(
            tooltip: s.dailyGoal,
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => _editGoal(log),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addEntry',
        onPressed: () => showEntrySheet(context, day: _day),
        icon: const Icon(Icons.add),
        label: Text(s.addEntry),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      setState(() => _day = dateOnly(DateTime.now())),
                  child: Text(
                    _isToday ? s.today : fmtDay.format(_day),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isToday ? null : () => _shift(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _GoalRing(eaten: totals.calories, goal: log.goal),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _Macro(label: s.protein, grams: totals.proteinG),
                      _Macro(label: s.carbs, grams: totals.carbsG),
                      _Macro(label: s.fat, grams: totals.fatG),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                s.diaryEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                ),
                onDismissed: (_) {
                  log.remove(e.id);
                  showSnack(
                    context,
                    s.itemDeleted(e.name),
                    actionLabel: s.undo,
                    onAction: () => log.add(e),
                  );
                },
                child: Card(
                  child: ListTile(
                    title: Text(e.name),
                    subtitle: Text(
                      [
                        time.format(e.eatenAt),
                        if (e.estimated) s.estimatedValue,
                      ].join(' · '),
                    ),
                    trailing: Text(
                      '${e.estimated ? '≈ ' : ''}${e.calories.round()} kcal',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(s.last7Days, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _WeekChart(
            days: log.week(dateOnly(DateTime.now())),
            goal: log.goal,
            selected: _day,
            onSelect: (d) => setState(() => _day = d),
          ),
          const SizedBox(height: 16),
          Text(
            s.calorieDisclaimer,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.eaten, required this.goal});
  final double eaten;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final over = eaten > goal;
    final diff = (goal - eaten).abs().round();
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: goal == 0 ? 0 : (eaten / goal).clamp(0, 1).toDouble(),
            strokeWidth: 14,
            strokeCap: StrokeCap.round,
            backgroundColor: scheme.surfaceContainerHighest,
            color: over ? scheme.error : scheme.success,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${eaten.round()}', style: theme.textTheme.displaySmall),
                Text(
                  'kcal ${s.kcalEaten}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  '$diff ${over ? s.kcalOver : s.kcalLeft}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: over ? scheme.error : scheme.success,
                  ),
                ),
                Text(
                  '${s.dailyGoal}: $goal',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.grams});
  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text('${grams.round()} g', style: theme.textTheme.titleMedium),
          Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Seven bars, one per day; the goal is a line across. Tap a bar to jump to
/// that day.
class _WeekChart extends StatelessWidget {
  const _WeekChart({
    required this.days,
    required this.goal,
    required this.selected,
    required this.onSelect,
  });

  final List<(DateTime, double)> days;
  final int goal;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  static const _height = 110.0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = DateFormat.E(s.languageCode);
    final maxValue = [
      goal * 1.2,
      for (final (_, kcal) in days) kcal,
    ].reduce((a, b) => a > b ? a : b);
    final goalY = _height * (1 - goal / maxValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: Column(
          children: [
            SizedBox(
              height: _height,
              child: Stack(
                children: [
                  Positioned(
                    top: goalY,
                    left: 0,
                    right: 0,
                    child: Container(height: 1, color: scheme.outline),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (day, kcal) in days)
                        Expanded(
                          child: InkWell(
                            onTap: () => onSelect(day),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (kcal > 0)
                                  Text(
                                    '${kcal.round()}',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(fontSize: 9),
                                  ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  height: (_height - 16) * (kcal / maxValue),
                                  decoration: BoxDecoration(
                                    color: kcal > goal
                                        ? scheme.error
                                        : day == selected
                                            ? scheme.primary
                                            : scheme.primary.withValues(alpha: 0.45),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final (day, _) in days)
                  Expanded(
                    child: Text(
                      fmt.format(day),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight:
                            day == selected ? FontWeight.bold : FontWeight.normal,
                        color: day == selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
