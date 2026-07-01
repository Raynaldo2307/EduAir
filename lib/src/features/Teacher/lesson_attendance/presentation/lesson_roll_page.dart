import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/application/late_reason_provider.dart';
import 'package:edu_air/src/features/timetable/domain/timetable_entry.dart';
// lowercase `teacher/` on purpose — matches lessonRosterProvider's element type
// (see the note in lesson_attendance_providers.dart re: the Teacher/teacher artifact).
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';
import 'package:edu_air/src/features/Teacher/lesson_attendance/domain/lesson_attendance_models.dart';
import 'package:edu_air/src/features/Teacher/lesson_attendance/lesson_attendance_providers.dart';

/// The lesson roll — a subject teacher marks ONE timetable period.
///
/// Pre-scoped by the tapped [TimetableEntry]: the class, subject and shift are
/// fixed by the period, so there is NO class dropdown. Students default to
/// present (teacher flips only the exceptions — fastest for a Monday morning);
/// any existing marks pre-fill on open so she edits rather than re-enters. The
/// whole roll saves in a single batch request.
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
    final rosterAsync = ref.watch(lessonRosterProvider(entry.classId));
    final prefillAsync = ref.watch(lessonMarksForEntryProvider(
      LessonMarksQuery(timetableEntryId: entry.id, dateKey: _dateKey),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.subject),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${entry.className ?? 'Class'} • ${entry.timeRange}',
              // Match the AppBar's white foreground (not the default dark body
              // colour) so the subtitle reads cleanly on the coloured bar.
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: (Theme.of(context).appBarTheme.foregroundColor ??
                            Colors.white)
                        .withValues(alpha: 0.85),
                  ),
            ),
          ),
        ),
      ),
      body: rosterAsync.when(
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
          // Prefill is best-effort: if it fails, mark from a clean (all-present)
          // slate rather than blocking the teacher from taking the roll.
          final prefill = prefillAsync.asData?.value ??
              const <String, ExistingLessonMark>{};

          return Column(
            children: [
              _SummaryBar(
                roster: roster,
                statusOf: (uid) => _statusFor(uid, prefill),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  itemCount: roster.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = roster[i];
                    final status = _statusFor(s.uid, prefill);
                    return _StudentRollTile(
                      name: s.displayName,
                      status: status,
                      reasonCode: _reasonFor(s.uid, prefill),
                      reasonOptions: ref.watch(lateReasonOptionsProvider),
                      onStatus: (next) => setState(() {
                        _statusOverrides[s.uid] = next;
                        // Leaving 'late' clears any reason so none goes stale.
                        if (next != AttendanceStatus.late) {
                          _reasonOverrides[s.uid] = null;
                        }
                      }),
                      onReason: (code) =>
                          setState(() => _reasonOverrides[s.uid] = code),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: rosterAsync.maybeWhen(
        data: (roster) => roster.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving
                        ? null
                        : () => _save(
                              roster,
                              prefillAsync.asData?.value ??
                                  const <String, ExistingLessonMark>{},
                            ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save roll'),
                  ),
                ),
              ),
        orElse: () => null,
      ),
    );
  }
}

/// A compact count of the four statuses across the class.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.roster, required this.statusOf});

  final List<TeacherAttendanceStudent> roster;
  final AttendanceStatus Function(String uid) statusOf;

  @override
  Widget build(BuildContext context) {
    int count(AttendanceStatus s) =>
        roster.where((r) => statusOf(r.uid) == s).length;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: cs.surfaceContainerHighest,
      child: Text(
        'Present ${count(AttendanceStatus.present)}   '
        'Late ${count(AttendanceStatus.late)}   '
        'Absent ${count(AttendanceStatus.absent)}   '
        'Excused ${count(AttendanceStatus.excused)}',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _StudentRollTile extends StatelessWidget {
  const _StudentRollTile({
    required this.name,
    required this.status,
    required this.reasonCode,
    required this.reasonOptions,
    required this.onStatus,
    required this.onReason,
  });

  final String name;
  final AttendanceStatus status;
  final String? reasonCode;
  final List<LateReasonOption> reasonOptions;
  final ValueChanged<AttendanceStatus> onStatus;
  final ValueChanged<String?> onReason;

  // Only the four statuses a lesson can use — never `early`.
  static const _choices = [
    AttendanceStatus.present,
    AttendanceStatus.late,
    AttendanceStatus.absent,
    AttendanceStatus.excused,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _choices.map((s) {
                return ChoiceChip(
                  label: Text(s.label),
                  selected: status == s,
                  onSelected: (_) => onStatus(s),
                );
              }).toList(),
            ),
            if (status == AttendanceStatus.late) ...[
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Reason for lateness'),
                value: reasonCode,
                items: reasonOptions
                    .map((o) => DropdownMenuItem(
                          value: o.code,
                          child: Text(o.label),
                        ))
                    .toList(),
                onChanged: onReason,
                dropdownColor: cs.surface,
              ),
            ],
          ],
        ),
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
