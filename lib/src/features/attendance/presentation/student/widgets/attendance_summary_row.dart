import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

/// Present / Absent / Event count row shown on the Attendance tab.
class AttendanceSummaryRow extends StatelessWidget {
  const AttendanceSummaryRow({
    super.key,
    required this.presentCount,
    required this.absentCount,
    required this.eventCount,
  });

  final int presentCount;
  final int absentCount;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        const SizedBox(width: 20),
        Expanded(
          child: _SummaryCard(
            label: 'Present',
            count: presentCount,
            background: isDark ? const Color(0xFF1A2E40) : const Color(0xFFE7F5FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            label: 'Absent',
            count: absentCount,
            background: isDark ? const Color(0xFF3A1E1E) : const Color(0xFFFFE9E9),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            label: 'Event',
            count: eventCount,
            background: isDark ? const Color(0xFF2A2040) : const Color(0xFFEDEDFF),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.background,
  });

  final String label;
  final int count;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_outline,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  count.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
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
