import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/admin/students/application/admin_students_provider.dart';
import 'package:edu_air/src/features/admin/students/admin_student_list_page.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

class AdminClassDetailPage extends ConsumerWidget {
  const AdminClassDetailPage({super.key, required this.classData});

  final Map<String, dynamic> classData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs           = Theme.of(context).colorScheme;
    final name         = classData['name']             as String? ?? '—';
    final gradeLevel   = classData['grade_level']      as String? ?? '';
    final teacher      = classData['homeroom_teacher']  as String?;
    final studentCount = int.tryParse(classData['student_count']?.toString() ?? '') ?? 0;
    final capacity     = int.tryParse(classData['capacity']?.toString() ?? '') ?? 40;
    final todayRate    = int.tryParse(classData['today_rate']?.toString() ?? '');
    final classId      = classData['id']?.toString();
    final isFull       = studentCount >= capacity;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        title: Text(name),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ───────────────────────────────────────────
            _HeaderCard(
              name: name,
              gradeLevel: gradeLevel,
              teacher: teacher,
              studentCount: studentCount,
              capacity: capacity,
              todayRate: todayRate,
              isFull: isFull,
              cs: cs,
            ),
            const SizedBox(height: 20),

            // ── Students section ──────────────────────────────────────
            _SectionLabel(label: 'Students', cs: cs),
            const SizedBox(height: 12),
            _StudentsPreview(
              classId: classId,
              className: name,
              studentCount: studentCount,
              ref: ref,
              cs: cs,
            ),
            const SizedBox(height: 20),

            // ── Subject teachers section ──────────────────────────────
            _SectionLabel(label: 'Subject Teachers', cs: cs),
            const SizedBox(height: 12),
            _SubjectTeachersPlaceholder(cs: cs),
          ],
        ),
      ),
    );
  }
}

// ─── Header card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.gradeLevel,
    required this.teacher,
    required this.studentCount,
    required this.capacity,
    required this.todayRate,
    required this.isFull,
    required this.cs,
  });

  final String   name;
  final String   gradeLevel;
  final String?  teacher;
  final int      studentCount;
  final int      capacity;
  final int?     todayRate;
  final bool     isFull;
  final ColorScheme cs;

  Color _gradeColor() {
    final colors = [
      Colors.indigo, Colors.teal, Colors.deepPurple,
      Colors.blue, Colors.green, Colors.orange,
    ];
    final code = gradeLevel.codeUnits.fold(0, (a, b) => a + b);
    return colors[code % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _gradeColor();
    final fillRatio = capacity > 0 ? studentCount / capacity : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? cs.surfaceContainerHighest
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class name + grade badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  gradeLevel.isNotEmpty ? gradeLevel : name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              if (todayRate != null) ...[
                const Spacer(),
                _RateBadge(rate: todayRate!),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Homeroom teacher
          Row(
            children: [
              Icon(Icons.person_outline, size: 15,
                  color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  teacher != null && teacher!.trim().isNotEmpty
                      ? teacher!
                      : 'No homeroom teacher assigned',
                  style: TextStyle(
                    fontSize: 13,
                    color: teacher != null && teacher!.trim().isNotEmpty
                        ? cs.onSurface.withValues(alpha: 0.75)
                        : cs.onSurface.withValues(alpha: 0.35),
                    fontStyle: teacher == null || teacher!.trim().isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Capacity
          Row(
            children: [
              Text(
                '$studentCount / $capacity enrolled',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isFull
                      ? Colors.red
                      : cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (isFull) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Full',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fillRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: cs.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(
                isFull ? Colors.red : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rate badge ───────────────────────────────────────────────────────────────

class _RateBadge extends StatelessWidget {
  const _RateBadge({required this.rate});
  final int rate;

  Color get _color {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.today_outlined, size: 13, color: _color),
            const SizedBox(width: 4),
            Text(
              '$rate% today',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ],
        ),
      );
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.cs});
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          color: cs.onSurface.withValues(alpha: 0.55),
        ),
      );
}

// ─── Students preview ─────────────────────────────────────────────────────────

class _StudentsPreview extends StatelessWidget {
  const _StudentsPreview({
    required this.classId,
    required this.className,
    required this.studentCount,
    required this.ref,
    required this.cs,
  });

  final String? classId;
  final String  className;
  final int     studentCount;
  final WidgetRef ref;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(schoolStudentsProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text(
        'Could not load students',
        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
      ),
      data: (all) {
        final inClass = classId != null
            ? all.where((s) => s.classId == classId).toList()
            : <AppUser>[];
        final preview = inClass.take(5).toList();
        final remaining = inClass.length - preview.length;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? cs.surfaceContainerHighest
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (inClass.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 40,
                          color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                      Text(
                        'No students enrolled yet',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                )
              else ...[
                for (int i = 0; i < preview.length; i++) ...[
                  _StudentRow(student: preview[i], cs: cs),
                  if (i < preview.length - 1)
                    Divider(
                        height: 1,
                        indent: 60,
                        color: cs.onSurface.withValues(alpha: 0.06)),
                ],
              ],

              // "View all" button
              if (inClass.isNotEmpty)
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminStudentListPage(
                        filterClassId: classId,
                        filterClassName: className,
                      ),
                    ),
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          remaining > 0
                              ? 'View all ${inClass.length} students  (+$remaining more)'
                              : 'View all ${inClass.length} students',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios,
                            size: 12, color: cs.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.cs});
  final AppUser student;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            UserAvatar(
              initials: student.initials,
              photoUrl: student.photoUrl,
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.displayName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                  ),
                  if (student.currentShift != null)
                    Text(
                      _shiftLabel(student.currentShift!),
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  String _shiftLabel(String shift) => switch (shift) {
        'morning'   => 'Morning shift',
        'afternoon' => 'Afternoon shift',
        _           => 'Whole day',
      };
}

// ─── Subject teachers placeholder ────────────────────────────────────────────

class _SubjectTeachersPlaceholder extends StatelessWidget {
  const _SubjectTeachersPlaceholder({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? cs.surfaceContainerHighest
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.menu_book_outlined, size: 36,
                color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 10),
            Text(
              'Subject teacher assignments',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coming soon — requires timetable',
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.35)),
            ),
          ],
        ),
      );
}
