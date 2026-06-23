import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/timetable/presentation/widgets/timetable_bubble_week.dart';

/// Read-only weekly timetable for the teacher's homeroom class.
/// Pushed from the teacher Home "Time Table" tile. Uses the shared
/// [TimetableBubbleWeek] — the same Mon–Fri bubble view the student sees, so the
/// two can never drift, with the school's bell events (lunch, break…) woven in.
class TeacherTimetableScreen extends ConsumerWidget {
  const TeacherTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs        = Theme.of(context).colorScheme;
    final user      = ref.watch(userProvider);
    final classId   = int.tryParse(user?.homeroomClassId ?? '');
    final className  = user?.homeroomClassName;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        title: Text(
          (className != null && className.isNotEmpty)
              ? 'Timetable · $className'
              : 'Timetable',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: classId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No homeroom class assigned yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            )
          : TimetableBubbleWeek(classId: classId),
    );
  }
}
