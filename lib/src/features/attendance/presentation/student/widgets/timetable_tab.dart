import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/timetable/presentation/widgets/timetable_bubble_week.dart';

/// Time Table tab on the student Calendar screen.
///
/// Shows the student's class timetable for the whole week (Mon–Fri) as a
/// vertical-bubble timeline, with the school's bell events (devotion, break,
/// lunch…) woven in. The week view itself is the shared [TimetableBubbleWeek] so
/// the student and teacher see the exact same layout.
class TimetableTab extends ConsumerWidget {
  const TimetableTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs   = Theme.of(context).colorScheme;
    final user = ref.watch(userProvider);

    // The student's homeroom class id (the API sends it as a string).
    final classId  = int.tryParse(user?.classId ?? '');
    final className = user?.className;

    if (classId == null) {
      return _message(
        context,
        Icons.school_outlined,
        'No class assigned yet',
      );
    }

    return Column(
      children: [
        // ── Class header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Icon(Icons.class_outlined,
                  size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(
                (className != null && className.isNotEmpty)
                    ? className
                    : 'Your Class',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
              const Spacer(),
              Text(
                'This week',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
        Expanded(
          child: TimetableBubbleWeek(
            timetableAsync: ref.watch(timetableByClassProvider(classId)),
            lens: TimetableLens.classView,
          ),
        ),
      ],
    );
  }

  Widget _message(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(text,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
