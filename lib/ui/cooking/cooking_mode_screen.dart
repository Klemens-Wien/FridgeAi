import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../l10n/strings.dart';
import '../../logic/recipe_ranking.dart';
import '../../logic/scaling.dart';
import '../../models/recipe.dart';
import '../../state/pantry_store.dart';
import '../../state/recipe_store.dart';
import '../widgets/common.dart';
import 'cooking_timer.dart';

/// Full-screen, step-by-step cooking view with timers. Keeps the screen on.
class CookingModeScreen extends StatefulWidget {
  const CookingModeScreen({super.key, required this.recipe, required this.servings});

  final Recipe recipe;
  final int servings;

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  final _pages = PageController();
  int _index = 0;

  /// Step timers by step index, plus custom timers (keyed from -1 downwards).
  final Map<int, CookingTimer> _timers = {};
  int _nextCustomKey = -1;

  Recipe get recipe => widget.recipe;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((_) {});
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    for (final t in _timers.values) {
      t.dispose();
    }
    _pages.dispose();
    super.dispose();
  }

  CookingTimer _timerForStep(int index) => _timers.putIfAbsent(
        index,
        () => _watch(CookingTimer(
          label: context.s.stepOf(index + 1, recipe.steps.length),
          stepNumber: index + 1,
          duration: Duration(seconds: recipe.steps[index].timerSeconds),
          onFinished: _onTimerFinished,
        )),
      );

  /// Rebuilds the screen (timer strip) whenever a timer changes state, but
  /// not on every tick.
  CookingTimer _watch(CookingTimer timer) {
    var last = timer.state;
    timer.addListener(() {
      if (timer.state != last) {
        last = timer.state;
        if (mounted) setState(() {});
      }
    });
    return timer;
  }

  void _onTimerFinished(CookingTimer timer) {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    if (!mounted) return;
    final s = context.s;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.alarm, size: 40),
        title: Text(s.timerDone),
        content: Text(
          timer.stepNumber != null ? s.timerDoneBody(timer.stepNumber!) : timer.label,
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(s.close)),
        ],
      ),
    );
  }

  Future<void> _addCustomTimer() async {
    final s = context.s;
    final minutes = await showDialog<int>(
      context: context,
      builder: (ctx) {
        var value = 5;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(s.customTimer),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: value > 1 ? () => setLocal(() => value--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(s.minutes(value), style: Theme.of(ctx).textTheme.headlineSmall),
                IconButton(
                  onPressed: () => setLocal(() => value++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, value),
                child: Text(s.startTimer),
              ),
            ],
          ),
        );
      },
    );
    if (minutes == null || !mounted) return;
    final t = _watch(CookingTimer(
      label: '${s.customTimer} · ${s.minutes(minutes)}',
      duration: Duration(minutes: minutes),
      onFinished: _onTimerFinished,
    ))
      ..start();
    setState(() => _timers[_nextCustomKey--] = t);
  }

  void _go(int delta) {
    final target = (_index + delta).clamp(0, recipe.steps.length - 1);
    _pages.animateToPage(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    final s = context.s;
    final pantry = context.read<PantryStore>();
    final match = RecipeRanker(pantry.items).match(recipe);
    final used = match.available.values.map((p) => p.name).toSet();
    await context
        .read<RecipeStore>()
        .recordCooked(rescuedItems: match.expiringUsed.length);
    if (!mounted) return;
    if (used.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restaurant, size: 40),
        title: Text(s.cookingDoneTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.cookingDoneBody),
            const SizedBox(height: 8),
            Text(used.join(', '), style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.keepPantry)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.removeUsedFromPantry),
          ),
        ],
      ),
    );
    if (remove == null || !mounted) return;
    if (remove) {
      await pantry.removeByNames(used);
      if (mounted) showSnack(context, s.removedFromPantry(used.length));
    }
    if (mounted) Navigator.pop(context);
  }

  void _showIngredients() {
    final s = context.s;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            '${s.ingredients} · ${s.servingsCount(widget.servings)}',
            style: Theme.of(ctx).textTheme.titleLarge,
          ),
          for (final ing in recipe.ingredients)
            ListTile(
              dense: true,
              title: Text(ing.name),
              trailing: Text(
                formatIngredient(ing, recipe.servings, widget.servings, s.languageCode),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final steps = recipe.steps;
    final activeTimers = _timers.entries
        .where((e) => e.value.state != TimerState.idle)
        .toList();
    final isLast = _index == steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: s.showIngredients,
            icon: const Icon(Icons.list_alt),
            onPressed: _showIngredients,
          ),
          IconButton(
            tooltip: s.customTimer,
            icon: const Icon(Icons.more_time),
            onPressed: _addCustomTimer,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_index + 1) / steps.length),
        ),
      ),
      body: Column(
        children: [
          if (activeTimers.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  for (final e in activeTimers)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TimerChip(
                        timer: e.value,
                        onTap: e.key >= 0 ? () => _pages.jumpToPage(e.key) : null,
                        onDelete: e.key < 0
                            ? () => setState(() => _timers.remove(e.key)?.dispose())
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: steps.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.stepOf(i + 1, steps.length),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      steps[i].text,
                      style: theme.textTheme.headlineSmall?.copyWith(height: 1.4),
                    ),
                    if (steps[i].timerSeconds > 0) ...[
                      const SizedBox(height: 32),
                      Center(child: _StepTimerPanel(timer: _timerForStep(i))),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _index == 0 ? null : () => _go(-1),
                    icon: const Icon(Icons.chevron_left),
                    label: Text(s.previous),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: isLast ? _finish : () => _go(1),
                    icon: Icon(isLast ? Icons.check : Icons.chevron_right),
                    label: Text(isLast ? s.finish : s.next),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTimerPanel extends StatelessWidget {
  const _StepTimerPanel({required this.timer});
  final CookingTimer timer;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) {
        final finished = timer.isFinished;
        return Column(
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: timer.state == TimerState.idle ? 0 : timer.progress,
                    strokeWidth: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: finished ? theme.colorScheme.error : null,
                  ),
                  Center(
                    child: Text(
                      formatDuration(timer.remaining.inSeconds +
                          (timer.remaining.inMilliseconds % 1000 > 0 ? 1 : 0)),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                if (timer.isRunning)
                  FilledButton.tonalIcon(
                    onPressed: timer.pause,
                    icon: const Icon(Icons.pause),
                    label: Text(s.pause),
                  )
                else
                  FilledButton.icon(
                    onPressed: timer.start,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      timer.state == TimerState.paused ? s.resume : s.startTimer,
                    ),
                  ),
                if (timer.state != TimerState.idle)
                  OutlinedButton.icon(
                    onPressed: timer.reset,
                    icon: const Icon(Icons.replay),
                    label: Text(s.reset),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.timer, this.onTap, this.onDelete});
  final CookingTimer timer;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        return InputChip(
          avatar: Icon(
            timer.isFinished
                ? Icons.alarm_on
                : timer.isRunning
                    ? Icons.timer
                    : Icons.pause,
            size: 18,
            color: timer.isFinished ? scheme.error : null,
          ),
          label: Text(
            '${timer.stepNumber != null ? '#${timer.stepNumber} ' : ''}'
            '${formatDuration(timer.remaining.inSeconds)}',
          ),
          onPressed: onTap ?? (timer.isRunning ? timer.pause : timer.start),
          onDeleted: onDelete,
        );
      },
    );
  }
}
