import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/timetable/domain/timetable_entry.dart';

/// One class's weekly timetable, grouped Mon–Fri and sorted by start time.
///
/// Shared by the admin manager and the teacher's read-only view so the two can
/// never drift. Pass [onEdit]/[onDelete] to show per-period action buttons
/// (admin); leave them null for a read-only view (teacher/student).
class TimetableWeekView extends ConsumerWidget {
  const TimetableWeekView({
    super.key,
    required this.classId,
    this.onEdit,
    this.onDelete,
  });

  final int classId;
  final void Function(TimetableEntry)? onEdit;
  final void Function(TimetableEntry)? onDelete;

  static const _dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri'];
  static const _dayLabels = {
    'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday',
    'thu': 'Thursday', 'fri': 'Friday', 'sat': 'Saturday', 'sun': 'Sunday',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs    = Theme.of(context).colorScheme;
    final async = ref.watch(timetableByClassProvider(classId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const _Hint(icon: Icons.error_outline, text: 'Could not load timetable'),
      data: (entries) {
        if (entries.isEmpty) {
          return const _Hint(
              icon: Icons.event_busy_outlined, text: 'No periods scheduled yet.');
        }
        final sections = <Widget>[];
        for (final day in _dayOrder) {
          final dayEntries = entries.where((e) => e.dayOfWeek == day).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          if (dayEntries.isEmpty) continue;
          sections.add(Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              _dayLabels[day] ?? day,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ));
          sections.addAll(dayEntries.map(
              (e) => _PeriodCard(entry: e, onEdit: onEdit, onDelete: onDelete)));
        }
        return ListView(padding: const EdgeInsets.only(bottom: 100), children: sections);
      },
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.entry, this.onEdit, this.onDelete});

  final TimetableEntry entry;
  final void Function(TimetableEntry)? onEdit;
  final void Function(TimetableEntry)? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(entry.timeRange,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subject,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(
                  [
                    entry.teacherName ?? 'Unassigned',
                    if (entry.room != null && entry.room!.isNotEmpty) 'Room ${entry.room}',
                  ].join('  ·  '),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Action buttons only render when callbacks are supplied (admin).
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: cs.onSurfaceVariant),
              onPressed: () => onEdit!(entry),
            ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
              onPressed: () => onDelete!(entry),
            ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
