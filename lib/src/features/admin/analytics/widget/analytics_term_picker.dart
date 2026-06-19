import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/admin/analytics/application/admin_analytics_provider.dart';
import 'package:edu_air/src/features/academic_terms/application/academic_terms_provider.dart';

/// Shown ONLY when the 'Term' tab is active: lets the admin pick WHICH term to
/// scope analytics to (defaults to "Current term"). Picking one sets
/// [selectedAnalyticsTermProvider]; the wire-param provider folds it into
/// `term:<id>`, so every analytics card re-scopes to that term together.
///
/// Terms come from [schoolTermsProvider] (the academic-terms feature) — so the
/// moment an admin adds/edits a term, it appears here too.
class AnalyticsTermPicker extends ConsumerWidget {
  const AnalyticsTermPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only relevant under the Term tab — collapse otherwise.
    if (ref.watch(analyticsRangeProvider) != 'term') {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final termsAsync = ref.watch(schoolTermsProvider);
    final selected = ref.watch(selectedAnalyticsTermProvider);

    return termsAsync.maybeWhen(
      data: (terms) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              isExpanded: true,
              // Guard a stale id (e.g. a deleted term) → fall back to Current.
              value: terms.any((t) => t.id == selected) ? selected : null,
              icon: Icon(Icons.expand_more, color: cs.onSurfaceVariant),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Current term'),
                ),
                ...terms.map((t) => DropdownMenuItem<int?>(
                      value: t.id,
                      child: Text(t.name),
                    )),
              ],
              onChanged: (v) =>
                  ref.read(selectedAnalyticsTermProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
