import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../state/pro_store.dart';
import '../widgets/common.dart';

/// The Pro benefits, shared by the paywall sheet and the Pro screen.
List<(IconData, String, String)> proBenefits(S s) => [
      (Icons.all_inclusive, s.proUnlimited, s.proUnlimitedSub),
      (Icons.auto_awesome, s.proWeekPlan, s.proWeekPlanSub),
      (Icons.receipt_long_outlined, s.proReceipt, s.proReceiptSub),
      (Icons.menu_book_outlined, s.proImport, s.proImportSub),
      (Icons.local_fire_department_outlined, s.proEstimate, s.proEstimateSub),
      (Icons.swap_horiz, s.proSubstitutes, s.proSubstitutesSub),
    ];

/// Returns true if the user has Pro. Otherwise shows the paywall and returns
/// whether they unlocked it there.
Future<bool> ensurePro(BuildContext context) async {
  final pro = context.read<ProStore>();
  if (pro.isPro) return true;
  await showPaywall(context, reason: context.s.proFeatureLocked);
  return pro.isPro;
}

/// Counts one AI request against the free allowance. Returns false if the
/// allowance is used up and the user did not unlock Pro in the paywall.
Future<bool> useAiQuota(BuildContext context) async {
  final pro = context.read<ProStore>();
  if (pro.tryUseAi()) return true;
  await showPaywall(context, reason: context.s.proLimitReached);
  return pro.isPro;
}

Future<void> showPaywall(BuildContext context, {String? reason}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _Paywall(reason: reason),
    );

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.tertiary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: scheme.onTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class ProBenefitList extends StatelessWidget {
  const ProBenefitList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (icon, title, sub) in proBenefits(context.s))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      Text(
                        sub,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Paywall extends StatelessWidget {
  const _Paywall({this.reason});
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  s.proTitle,
                  style: theme.textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reason ?? s.proTagline,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          const ProBenefitList(),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.tertiary,
              foregroundColor: theme.colorScheme.onTertiary,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () async {
              await context.read<ProStore>().setPro(true);
              if (!context.mounted) return;
              Navigator.pop(context);
              showSnack(context, s.proWelcome);
            },
            icon: const Icon(Icons.workspace_premium),
            label: Text(s.proUnlock),
          ),
          const SizedBox(height: 8),
          Text(
            s.proUnlockNote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
