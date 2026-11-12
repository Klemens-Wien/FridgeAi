import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../logic/calorie_goal.dart';
import '../../state/food_log_store.dart';

/// Works out a personal daily calorie goal. The inputs are only used for
/// the calculation and are not stored.
Future<void> showGoalCalculator(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _GoalSheet(),
    );

class _GoalSheet extends StatefulWidget {
  const _GoalSheet();

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  Sex _sex = Sex.female;
  ActivityLevel _activity = ActivityLevel.light;
  WeightAim _aim = WeightAim.maintain;

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  static double _num(String t) =>
      double.tryParse(t.trim().replaceAll(',', '.')) ?? 0;

  /// The goal for the current inputs, or null while they are incomplete or
  /// implausible.
  int? get _result {
    final age = _num(_age.text), h = _num(_height.text), w = _num(_weight.text);
    if (age < 14 || age > 110 || h < 120 || h > 230 || w < 30 || w > 300) {
      return null;
    }
    return calorieGoal(
      sex: _sex,
      age: age.round(),
      heightCm: h,
      weightKg: w,
      activity: _activity,
      aim: _aim,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final result = _result;
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

    Widget field(TextEditingController c, String label) => Expanded(
          child: TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: numbers,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(isDense: true, labelText: label),
          ),
        );

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(text, style: theme.textTheme.titleSmall),
        );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.calculateGoal, style: theme.textTheme.titleLarge),
            label(s.sex),
            SegmentedButton<Sex>(
              segments: [
                ButtonSegment(value: Sex.female, label: Text(s.female)),
                ButtonSegment(value: Sex.male, label: Text(s.male)),
              ],
              selected: {_sex},
              onSelectionChanged: (v) => setState(() => _sex = v.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                field(_age, s.age),
                const SizedBox(width: 8),
                field(_height, s.heightCm),
                const SizedBox(width: 8),
                field(_weight, s.weightKg),
              ],
            ),
            label(s.activity),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (level, text) in [
                  (ActivityLevel.sedentary, s.activitySedentary),
                  (ActivityLevel.light, s.activityLight),
                  (ActivityLevel.moderate, s.activityModerate),
                  (ActivityLevel.active, s.activityActive),
                ])
                  ChoiceChip(
                    label: Text(text),
                    selected: _activity == level,
                    onSelected: (_) => setState(() => _activity = level),
                  ),
              ],
            ),
            label(s.aim),
            SegmentedButton<WeightAim>(
              segments: [
                ButtonSegment(value: WeightAim.lose, label: Text(s.aimLose)),
                ButtonSegment(
                  value: WeightAim.maintain,
                  label: Text(s.aimMaintain),
                ),
                ButtonSegment(value: WeightAim.gain, label: Text(s.aimGain)),
              ],
              selected: {_aim},
              onSelectionChanged: (v) => setState(() => _aim = v.first),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                result == null ? s.fillAllFields : '≈ $result kcal',
                style: result == null
                    ? theme.textTheme.bodyMedium
                    : theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: result == null
                  ? null
                  : () async {
                      await context.read<FoodLogStore>().setGoal(result);
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(s.useThisGoal),
            ),
            const SizedBox(height: 12),
            Text(
              s.goalFormulaNote,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
