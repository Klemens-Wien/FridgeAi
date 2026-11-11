import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../models/meal_plan.dart';
import '../../models/pantry_item.dart' show dateOnly;
import '../../models/recipe.dart';
import '../../state/meal_plan_store.dart';
import '../widgets/common.dart';

/// Lets the user pick a day (next 14 days) and a meal slot for [recipe].
Future<void> showAddToPlanSheet(
  BuildContext context,
  Recipe recipe, {
  int? servings,
  DateTime? initialDay,
  MealSlot? initialSlot,
}) async {
  final result = await showModalBottomSheet<(DateTime, MealSlot)>(
    context: context,
    showDragHandle: true,
    builder: (_) => _AddToPlanSheet(
      initialDay: initialDay ?? DateTime.now(),
      initialSlot: initialSlot ?? MealSlot.dinner,
    ),
  );
  if (result == null || !context.mounted) return;
  final (day, slot) = result;
  await context.read<MealPlanStore>().add(day, slot, recipe, servings: servings);
  if (!context.mounted) return;
  final s = context.s;
  showSnack(
    context,
    s.plannedFor(DateFormat.MMMEd(s.languageCode).format(day), s.slotName(slot)),
  );
}

class _AddToPlanSheet extends StatefulWidget {
  const _AddToPlanSheet({required this.initialDay, required this.initialSlot});
  final DateTime initialDay;
  final MealSlot initialSlot;

  @override
  State<_AddToPlanSheet> createState() => _AddToPlanSheetState();
}

class _AddToPlanSheetState extends State<_AddToPlanSheet> {
  late DateTime _day = dateOnly(widget.initialDay);
  late MealSlot _slot = widget.initialSlot;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final today = dateOnly(DateTime.now());
    final days = List.generate(14, (i) => today.add(Duration(days: i)));
    final fmt = DateFormat.MMMEd(s.languageCode);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.addToPlan, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(s.chooseDay, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text(i == 0 ? s.today : fmt.format(days[i])),
                  selected: _day == days[i],
                  onSelected: (_) => setState(() => _day = days[i]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(s.chooseSlot, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MealSlot>(
                segments: [
                  for (final slot in MealSlot.values)
                    ButtonSegment(value: slot, label: Text(s.slotName(slot))),
                ],
                selected: {_slot},
                onSelectionChanged: (v) => setState(() => _slot = v.first),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, (_day, _slot)),
                child: Text(s.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
