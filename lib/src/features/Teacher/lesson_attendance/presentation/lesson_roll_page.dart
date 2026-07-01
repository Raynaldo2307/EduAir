import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/application/late_reason_provider.dart';
import 'package:edu_air/src/features/timetable/domain/timetable_entry.dart';
// lowercase `teacher/` on purpose — matches lessonRosterProvider's element type
// (see the note in lesson_attendance_providers.dart re: the Teacher/teacher artifact).
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';
import 'package:edu_air/src/features/Teacher/lesson_attendance/domain/lesson_attendance_models.dart';
import 'package:edu_air/src/features/Teacher/lesson_attendance/lesson_attendance_providers.dart';
// The shared marking body — the SAME row + columns the daily register uses, so
// the two screens cannot drift apart in layout, colour or dark/light theme.
import 'package:edu_air/src/shared/common/attendance/attendance_marking.dart';

/// The lesson roll — a subject teacher marks ONE timetable period.
///
/// Pre-scoped by the tapped [TimetableEntry]: the class, subject and shift are
/// fixed by the period, so there is NO class dropdown. Students default to
/// present (teacher flips only the exceptions — fastest for a Monday morning);
/// any existing marks pre-fill on open so she edits rather than re-enters. The
/// whole roll saves in a single batch request.
///
/// This is [AttendanceKind.lesson]: it shares the daily register's marking body
/// (the [AttendanceColumnHeader] + [AttendanceStatusRow]) and only differs in
/// its header (a fixed period, not a class/date picker) and where it saves.
class LessonRollPage extends ConsumerStatefulWidget {
  const LessonRollPage({super.key, required this.entry});

  final TimetableEntry entry;

  @override
  ConsumerState<LessonRollPage> createState() => _LessonRollPageState();
}

class _LessonRollPageState extends ConsumerState<LessonRollPage> {
  // Only the students the teacher actually touched. Displayed status is derived:
  // override ?? prefill ?? present — so we never fight an async seeding race.
  final Map<String, AttendanceStatus> _statusOverrides = {};
  final Map<String, String?> _reasonOverrides = {};
  bool _saving = false;

  String get _dateKey {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)}';
  }

  AttendanceStatus _statusFor(
    String uid,
    Map<String, ExistingLessonMark> prefill,
  ) {
    return _statusOverrides[uid] ??
        prefill[uid]?.status ??
        AttendanceStatus.present;
  }

  String? _reasonFor(String uid, Map<String, ExistingLessonMark> prefill) {
    if (_reasonOverrides.containsKey(uid)) return _reasonOverrides[uid];
    return prefill[uid]?.lateReasonCode;
  }

  Future<void> _save(List<TeacherAttendanceStudent> roster,
      Map<String, ExistingLessonMark> prefill) async {
    setState(() => _saving = true);
    final entries = roster.map((s) {
      final status = _statusFor(s.uid, prefill);
      final reason = status == AttendanceStatus.late
          ? _reasonFor(s.uid, prefill)
          : null;
      return LessonMarkEntry(
        studentId: int.tryParse(s.uid) ?? 0,
        status: status,
        lateReasonCode: reason,
      );
    }).toList();

    try {
      final result = await ref.read(lessonAttendanceApiRepositoryProvider).mark(
            timetableEntryId: widget.entry.id,
            dateKey: _dateKey,
            entries: entries,
          );
      // Refresh the prefill so a re-open shows what we just saved.
      ref.invalidate(lessonMarksForEntryProvider(LessonMarksQuery(
        timetableEntryId: widget.entry.id,
        dateKey: _dateKey,
      )));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved ${result.saved} — ${result.subject}'),
      ));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not save the roll. Check your connection and try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final cs = Theme.of(context).colorScheme;
    final rosterAsync = ref.watch(lessonRosterProvider(entry.classId));
    final prefillAsync = ref.watch(lessonMarksForEntryProvider(
      LessonMarksQuery(timetableEntryId: entry.id, dateKey: _dateKey),
    ));

    // The shared row expects code/label maps; adapt the MoEYI options provider.
    final reasonOptions = ref
        .watch(lateReasonOptionsProvider)
        .map((o) => {'code': o.code, 'label': o.label})
        .toList();

    return Scaffold(
      // Clean surface bar — matches the daily register, no coloured-bar clash.
      appBar: AppBar(
        title: Text(entry.subject),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      bottomNavigationBar: rosterAsync.maybeWhen(
        data: (roster) => roster.isEmpty
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () => _save(
                              roster,
                              prefillAsync.asData?.value ??
                                  const <String, ExistingLessonMark>{},
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save roll',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
        orElse: () => null,
      ),
      body: SafeArea(
        top: false,
        child: rosterAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _RetryBody(
            message: 'Could not load the class list.',
            onRetry: () => ref.invalidate(lessonRosterProvider(entry.classId)),
          ),
          data: (roster) {
            if (roster.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No students are registered to this class yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            // Prefill is best-effort: if it fails, mark from a clean
            // (all-present) slate rather than blocking the teacher.
            final prefill = prefillAsync.asData?.value ??
                const <String, ExistingLessonMark>{};

            // Live tally shown beneath each column label in the header — this
            // replaces the old separate count strip.
            final counts = <AttendanceStatus, int>{
              for (final st in const [
                AttendanceStatus.present,
                AttendanceStatus.absent,
                AttendanceStatus.late,
                AttendanceStatus.excused,
              ])
                st: roster
                    .where((r) => _statusFor(r.uid, prefill) == st)
                    .length,
            };

            return Column(
              children: [
                _LessonHeader(entry: entry),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: AttendanceColumnHeader(counts: counts),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: roster.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final s = roster[i];
                      return AttendanceStatusRow(
                        data: AttendanceRowData(
                          id: s.uid,
                          displayName: s.displayName,
                          initials: s.initials,
                          photoUrl: s.photoUrl,
                        ),
                        status: _statusFor(s.uid, prefill),
                        lateReason: _reasonFor(s.uid, prefill),
                        lateReasonOptions: reasonOptions,
                        onStatusSelected: (next) => setState(() {
                          _statusOverrides[s.uid] = next;
                          // Leaving 'late' clears any reason so none goes stale.
                          if (next != AttendanceStatus.late) {
                            _reasonOverrides[s.uid] = null;
                          }
                        }),
                        onLateReasonChanged: (code) =>
                            setState(() => _reasonOverrides[s.uid] = code),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The fixed period header — the lesson roll's equivalent of the daily
/// register's class/date picker, but read-only because the tapped card already
/// chose the class, subject and time. A lock badge makes that explicit.
class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.entry});

  final TimetableEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget box(IconData icon, String text) => Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              box(Icons.groups_outlined, entry.className ?? 'Class'),
              const SizedBox(width: 12),
              box(Icons.schedule_outlined, entry.timeRange),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 13, color: AppTheme.primaryColor),
                  SizedBox(width: 5),
                  Text(
                    'Period set from your timetable',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryBody extends StatelessWidget {
  const _RetryBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
