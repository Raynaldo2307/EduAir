import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

// ── Attendance stats provider ─────────────────────────────────────────────────
// Fetches last 30 attendance records for a student and computes the rate.
// studentId here is the database integer (AppUser.uid parsed as int).

final _studentStatsProvider = FutureProvider.autoDispose
    .family<_Stats, int>((ref, studentId) async {
  final repo = ref.read(attendanceApiRepositoryProvider);
  final records = await repo.getStudentHistory(studentId: studentId, limit: 30);
  if (records.isEmpty) return const _Stats(percentage: null, total: 0);
  final attended = records.where((r) {
    final s = r['status'] as String? ?? '';
    return s == 'present' || s == 'early' || s == 'late';
  }).length;
  return _Stats(
    percentage: attended / records.length * 100,
    total: records.length,
  );
});

// ── Public entry point ────────────────────────────────────────────────────────

/// Shows student detail as a bottom sheet on mobile, side panel on desktop.
/// Pass [onEdit] from the calling screen to handle navigation to the edit page —
/// the shared widget stays decoupled from any specific edit screen.
void showStudentDetail(
  BuildContext context,
  AppUser student, {
  required bool isAdmin,
  VoidCallback? onEdit,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 700;

  if (isDesktop) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (dialogCtx) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: _SidePanel(
            student: student,
            isAdmin: isAdmin,
            onEdit: onEdit,
            onClose: () => Navigator.of(dialogCtx).pop(),
          ),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.93,
        expand: false,
        builder: (_, scrollController) => _BottomSheetContainer(
          student: student,
          isAdmin: isAdmin,
          onEdit: onEdit,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

// ── Desktop side panel container ──────────────────────────────────────────────

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.student,
    required this.isAdmin,
    this.onEdit,
    this.onClose,
  });

  final AppUser student;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 360,
      height: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Close button row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    'Student Detail',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _StudentDetailContent(
                student: student,
                isAdmin: isAdmin,
                onEdit: onEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile bottom sheet container ─────────────────────────────────────────────

class _BottomSheetContainer extends StatelessWidget {
  const _BottomSheetContainer({
    required this.student,
    required this.isAdmin,
    this.onEdit,
    this.scrollController,
  });

  final AppUser student;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _StudentDetailContent(
              student: student,
              isAdmin: isAdmin,
              onEdit: onEdit,
              scrollController: scrollController,
            ),
          ),
        ],
      ),
    );
  }
}

// ── The actual content — shared between bottom sheet and side panel ───────────

class _StudentDetailContent extends ConsumerWidget {
  const _StudentDetailContent({
    required this.student,
    required this.isAdmin,
    this.onEdit,
    this.scrollController,
  });

  final AppUser student;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final ScrollController? scrollController;

  Color _attendanceColor(double pct, ColorScheme cs) {
    if (pct >= 80) return const Color(0xFF22C55E);
    if (pct >= 60) return const Color(0xFFF59E0B);
    return cs.error;
  }

  String _attendanceLabel(double pct) {
    if (pct >= 80) return 'Good attendance';
    if (pct >= 60) return 'Needs improvement';
    return 'Poor attendance';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numericId = int.tryParse(student.uid) ?? 0;
    final statsAsync = ref.watch(_studentStatsProvider(numericId));

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Profile header ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: AppTheme.cardShadow(isDark: isDark, primary: cs.primary),
          ),
          child: Row(
            children: [
              UserAvatar(
                initials: student.initials,
                photoUrl: student.photoUrl,
                radius: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.displayName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (student.studentId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${student.studentId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (student.className?.isNotEmpty == true)
                          _InfoChip(
                            label: student.className!,
                            color: cs.primary,
                          ),
                        if (student.currentShift != null) ...[
                          const SizedBox(width: 6),
                          _ShiftChip(shift: student.currentShift!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Attendance stats ─────────────────────────────────────────────
        statsAsync.when(
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.2 : 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Loading attendance…',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (stats) {
            final pct = stats.percentage;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: isDark ? 0.2 : 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Attendance Rate',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        pct != null ? '${pct.toStringAsFixed(0)}%' : '—',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: pct != null
                              ? _attendanceColor(pct, cs)
                              : cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  if (pct != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 7,
                        backgroundColor:
                            cs.onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _attendanceColor(pct, cs),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _attendanceLabel(pct),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _attendanceColor(pct, cs),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Last ${stats.total} records',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      'No attendance records yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // ── Details table ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: AppTheme.cardShadow(isDark: isDark, primary: cs.primary),
          ),
          child: Column(
            children: [
              if (student.className?.isNotEmpty == true)
                _DetailRow(label: 'Class', value: student.className!, cs: cs),
              if (student.gradeLevel?.isNotEmpty == true)
                _DetailRow(label: 'Grade Level', value: student.gradeLevel!, cs: cs),
              if (student.sex?.isNotEmpty == true)
                _DetailRow(
                  label: 'Gender',
                  value: student.sex == 'M' || student.sex == 'male' ? 'Male' : 'Female',
                  cs: cs,
                ),
              if (student.studentId?.isNotEmpty == true)
                _DetailRow(label: 'Student ID', value: student.studentId!, cs: cs),
              _DetailRow(
                label: 'Phone',
                value: student.phone.isNotEmpty ? student.phone : '—',
                cs: cs,
                isLast: true,
              ),
            ],
          ),
        ),

        // ── Admin actions ────────────────────────────────────────────────
        if (isAdmin && onEdit != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onEdit,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.cs,
    this.isLast = false,
  });

  final String label;
  final String value;
  final ColorScheme cs;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.shift});

  final String shift;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (shift) {
      'morning'   => ('Morning', const Color(0xFF0059BA)),
      'afternoon' => ('Afternoon', const Color(0xFFB7791F)),
      _           => ('Whole Day', const Color(0xFF2E7D32)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _Stats {
  const _Stats({required this.percentage, required this.total});

  final double? percentage;
  final int total;
}
