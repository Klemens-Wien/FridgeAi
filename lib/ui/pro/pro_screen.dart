import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../state/pro_store.dart';
import '../widgets/common.dart';
import 'pro_gate.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pro = context.watch<ProStore>();

    return Scaffold(
      appBar: AppBar(title: Text(s.proTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.tertiary, scheme.primary],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium, size: 40, color: scheme.onPrimary),
                const SizedBox(height: 12),
                Text(
                  pro.isPro ? s.proActive : s.freePlan,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: scheme.onPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  pro.isPro
                      ? s.proUnlimited
                      : s.freeRequestsLeft(
                          pro.remainingToday,
                          ProStore.freeDailyAiRequests,
                        ),
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: scheme.onPrimary),
                ),
                if (!pro.isPro) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: pro.usedToday / ProStore.freeDailyAiRequests,
                      color: scheme.onPrimary,
                      backgroundColor: scheme.onPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(s.proTagline, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const ProBenefitList(),
          const SizedBox(height: 20),
          if (pro.isPro)
            OutlinedButton(
              onPressed: () => pro.setPro(false),
              child: Text(s.proDeactivate),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.tertiary,
                foregroundColor: scheme.onTertiary,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () async {
                await pro.setPro(true);
                if (context.mounted) showSnack(context, s.proWelcome);
              },
              icon: const Icon(Icons.workspace_premium),
              label: Text(s.proUnlock),
            ),
          const SizedBox(height: 8),
          Text(
            s.proUnlockNote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
