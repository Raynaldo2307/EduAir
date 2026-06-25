import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/timetable/presentation/widgets/timetable_bubble_week.dart';

/// Read-only weekly timetable for the logged-in teacher — HER OWN periods,
/// across every class she teaches, not one class's grid.
///
/// Pushed from the teacher Home "Time Table" tile. Uses the shared
/// [TimetableBubbleWeek] (the same Mon–Fri bubble view the student sees, so the
/// two can never drift) with the [TimetableLens.teacherView] lens — each period
/// shows WHICH CLASS it is, since her own name would be useless here. Data comes
/// from [teachingWeekProvider], scoped to the teacher server-side by the JWT, so
/// a roving subject teacher with no homeroom still sees her full week.
class TeacherTimetableScreen extends ConsumerWidget {
  const TeacherTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        title: const Text(
          'My Timetable',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: TimetableBubbleWeek(
        timetableAsync: ref.watch(teachingWeekProvider),
        lens: TimetableLens.teacherView,
      ),
    );
  }
}
