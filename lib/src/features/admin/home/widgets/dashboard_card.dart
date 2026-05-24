import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppTheme.cardShadow(isDark: isDark, primary: cs.primary),
      ),
      child: child,
    );
  }
}
