import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/admin/analytics/application/admin_analytics_provider.dart';

/// Screen-level period control — the analytics "control panel".
///
/// Picking a segment sets [analyticsRangeProvider], which every analytics card
/// watches. One tap re-scopes the whole screen to the last 30 days, the last
/// 90 days, or the current term.
///
/// Three equal segments stretch to fill whatever width they're given, so the
/// same widget looks right on a phone, a tablet, and a desktop browser without
/// any breakpoint logic — there's no horizontal scroll to manage.
class AnalyticsRangeSelector extends ConsumerWidget {
  const AnalyticsRangeSelector({super.key});

  static const _options = [
    (key: '30',   label: '30D'),
    (key: '90',   label: '90D'),
    (key: 'term', label: 'Term'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs       = Theme.of(context).colorScheme;
    final selected = ref.watch(analyticsRangeProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: _options.map((o) {
          final active = o.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(analyticsRangeProvider.notifier).state = o.key,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  o.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
