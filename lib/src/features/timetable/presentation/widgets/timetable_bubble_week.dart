import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/bell_schedule/application/bell_schedule_provider.dart';
import 'package:edu_air/src/features/bell_schedule/domain/bell_period.dart';
import 'package:edu_air/src/features/bell_schedule/domain/shift.dart';
import 'package:edu_air/src/features/timetable/domain/timetable_entry.dart';

/// Which lens the week is rendered through — decides what a period's subtitle
/// says. A student/admin viewing a class wants the TEACHER's name on each
/// period; a teacher viewing her own week wants WHICH CLASS each period is (her
/// own name would be useless on her own dashboard).
enum TimetableLens { classView, teacherView }

/// Read-only weekly timetable as a vertical-bubble timeline, Monday→Friday.
///
/// Shared by the student and teacher views so the two can never drift. The day's
/// teaching periods come from the class timetable; the school's NON-teaching bell
/// events (devotion, break, lunch, assembly, dismissal) are woven in by start
/// time so a reader sees the whole day in order — class, break, class, lunch…
///
/// Composition happens at read time: nothing merged is persisted. The timetable
/// and the bell schedule are configured independently per school, so this view
/// works for any school — and a no-bell school (HEART) simply shows its classes.
///
/// Bell merge currently covers single-shift / whole-day schools (one shift → use
/// its bells). Multi-shift schools need a `shifts.shift_type` column to map a
/// class's shift to the right bell set; until that migration lands they show
/// classes only (never the wrong shift's bells).
class TimetableBubbleWeek extends ConsumerWidget {
  const TimetableBubbleWeek({
    super.key,
    required this.timetableAsync,
    required this.lens,
  });

  /// The week's periods. Watched by the CALLER (each screen does its own
  /// `ref.watch`) so this widget stays purely presentational — student, teacher
  /// and admin all feed it through here and can never drift onto different
  /// layouts. One source, three lenses; the layout is the one source.
  final AsyncValue<List<TimetableEntry>> timetableAsync;

  /// Whose-eyes lens — drives the per-period subtitle (see [TimetableLens]).
  final TimetableLens lens;

  static const _dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri'];
  static const _dayLabels = {
    'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday',
    'thu': 'Thursday', 'fri': 'Friday',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs    = Theme.of(context).colorScheme;
    final bells = _resolveNonTeachingBells(ref);

    return timetableAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _Message(
          icon: Icons.error_outline, text: 'Could not load timetable'),
      data: (entries) {
        final sections = <Widget>[];

        for (final day in _dayOrder) {
          // The day's class periods.
          final slots = <_Slot>[
            for (final e in entries.where((e) => e.dayOfWeek == day))
              _Slot(
                start: e.startTime,
                end: e.endTime,
                title: e.subject,
                subtitle: _subtitleFor(e),
                isBell: false,
              ),
          ];

          // Skip a weekday with no classes — don't render a day of bells alone.
          if (slots.isEmpty) continue;

          // Weave in the daily bell events (same every weekday).
          for (final b in bells) {
            slots.add(_Slot(
              start: b.startTime,
              end: b.endTime,
              title: b.label,
              isBell: true,
              icon: _bellIcon(b.kind),
            ));
          }
          slots.sort((a, b) => a.start.compareTo(b.start));

          sections.add(Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              _dayLabels[day] ?? day,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ));
          for (var i = 0; i < slots.length; i++) {
            sections.add(_SlotRow(slot: slots[i], isLast: i == slots.length - 1));
          }
        }

        if (sections.isEmpty) {
          return _Message(
              icon: Icons.event_busy_outlined, text: 'No periods scheduled yet.');
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 24), children: sections);
      },
    );
  }

  /// A period's secondary line, chosen by lens: the teacher's name when a class
  /// is being viewed, the class name when a teacher views her own week. Room is
  /// appended when present.
  String _subtitleFor(TimetableEntry e) {
    final lead = switch (lens) {
      TimetableLens.classView   => e.teacherName ?? 'Unassigned',
      TimetableLens.teacherView => e.className ?? 'Class',
    };
    final hasRoom = e.room != null && e.room!.isNotEmpty;
    return [lead, if (hasRoom) 'Room ${e.room}'].join('  ·  ');
  }

  /// The school's non-teaching bell events for the viewer's shift, or empty when
  /// none apply.
  ///
  /// Bells are supplementary: any loading/error/no-match case resolves to an
  /// empty list so the timetable still renders. A single-shift school uses its
  /// one shift; a multi-shift school matches the viewer's [AppUser.currentShift]
  /// to the shift of that type (by stable type, never the display name). If no
  /// shift matches — or a shift isn't typed yet — show classes only, never the
  /// wrong shift's bells. Teaching slots are dropped (the timetable supplies
  /// those).
  List<BellPeriod> _resolveNonTeachingBells(WidgetRef ref) {
    final shifts = ref.watch(schoolShiftsProvider).valueOrNull;
    if (shifts == null || shifts.isEmpty) return const [];

    Shift? shift;
    if (shifts.length == 1) {
      shift = shifts.first;
    } else {
      final userShift = ref.watch(userProvider)?.currentShift;
      for (final s in shifts) {
        if (s.type != null && s.type == userShift) {
          shift = s;
          break;
        }
      }
    }
    if (shift == null) return const [];

    final bells = ref.watch(bellPeriodsByShiftProvider(shift.id)).valueOrNull;
    if (bells == null) return const [];
    return bells.where((b) => !b.kind.holdsSubject).toList();
  }

  static IconData _bellIcon(BellSlotType kind) => switch (kind) {
        BellSlotType.lunch => Icons.restaurant_outlined,
        BellSlotType.breakTime => Icons.local_cafe_outlined,
        BellSlotType.devotion => Icons.volunteer_activism_outlined,
        BellSlotType.assembly => Icons.groups_outlined,
        BellSlotType.dismissal => Icons.logout_outlined,
        BellSlotType.teaching => Icons.menu_book_outlined,
      };
}

/// One merged row in the week — a class period or a bell event.
class _Slot {
  const _Slot({
    required this.start,
    required this.end,
    required this.title,
    required this.isBell,
    this.subtitle,
    this.icon,
  });

  final String start; // 'HH:mm'
  final String end;
  final String title;
  final String? subtitle;
  final bool isBell;
  final IconData? icon;
}

/// A bubble-timeline row: time on the left, a connecting line + dot, then the
/// title. Bell events get a muted hollow dot + icon so they read as breaks, not
/// classes.
class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.isLast});

  final _Slot slot;
  final bool isLast;

  static const _dotSize = 10.0;
  static const _lineWidth = 2.0;
  static const _timeWidth = 48.0;
  static const _rowMinHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dotColor = slot.isBell ? cs.onSurfaceVariant : cs.primary;
    final lineColor = cs.primary.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Time ──────────────────────────────────
            SizedBox(
              width: _timeWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  slot.start,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.55)),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Vertical timeline ──────────────────────
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(width: _lineWidth, height: 18, color: lineColor),
                  Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      // Bell events read as hollow dots; classes are filled.
                      color: slot.isBell ? cs.surface : dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: dotColor, width: 2),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: _lineWidth,
                      color: isLast ? Colors.transparent : lineColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Title + subtitle ───────────────────────
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: _rowMinHeight),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (slot.icon != null) ...[
                          Icon(slot.icon,
                              size: 15, color: cs.onSurface.withValues(alpha: 0.6)),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            slot.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  slot.isBell ? FontWeight.w500 : FontWeight.w600,
                              color: slot.isBell
                                  ? cs.onSurface.withValues(alpha: 0.7)
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (slot.subtitle != null && slot.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        slot.subtitle!,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
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
