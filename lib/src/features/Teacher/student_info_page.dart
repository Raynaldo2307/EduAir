import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

/// Loads students for a given class ID from the Node API.
final _classStudentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, classId) async {
  final repo = ref.read(studentsApiRepositoryProvider);
  return repo.getByClass(classId);
});

/// Loads attendance stats (last 30 records) for a given student.
final _studentAttendanceStatsProvider = FutureProvider.autoDispose
    .family<_AttendanceStats, int>((ref, studentId) async {
  final repo = ref.read(attendanceApiRepositoryProvider);
  final records = await repo.getStudentHistory(studentId: studentId, limit: 30);
  if (records.isEmpty) return const _AttendanceStats(percentage: null, total: 0);
  final attended = records.where((r) {
    final s = r['status'] as String? ?? '';
    return s == 'present' || s == 'early' || s == 'late';
  }).length;
  return _AttendanceStats(
    percentage: attended / records.length * 100,
    total: records.length,
  );
});

// ── Page ──────────────────────────────────────────────────────────────────────

class StudentInfoPage extends ConsumerStatefulWidget {
  const StudentInfoPage({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  ConsumerState<StudentInfoPage> createState() => _StudentInfoPageState();
}

class _StudentInfoPageState extends ConsumerState<StudentInfoPage> {
  _ClassOption? _selectedClass;

  /// Build class options from the teacher's profile.
  List<_ClassOption> _buildClassOptions(AppUser user) {
    final options = <String, _ClassOption>{};

    if (user.homeroomClassId != null &&
        user.homeroomClassId!.trim().isNotEmpty) {
      final id = int.tryParse(user.homeroomClassId!);
      if (id != null) {
        options[user.homeroomClassId!] = _ClassOption(
          classId: id,
          className: user.homeroomClassName?.trim().isNotEmpty == true
              ? user.homeroomClassName!
              : 'Class $id',
        );
      }
    }

    for (final assignment in user.subjectAssignments ?? []) {
      final id = int.tryParse(assignment.classId);
      if (id == null) continue;
      options.putIfAbsent(
        assignment.classId,
        () => _ClassOption(classId: id, className: assignment.className),
      );
    }

    return options.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(userProvider);
    final classOptions =
        user == null ? <_ClassOption>[] : _buildClassOptions(user);

    // Auto-select first class on first build
    if (_selectedClass == null && classOptions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedClass = classOptions.first);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text('Student Info'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              _buildClassDropdown(classOptions),
              const SizedBox(height: 16),
              Expanded(child: _buildStudentList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassDropdown(List<_ClassOption> options) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        ),
        child: Text(
          'No classes assigned',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      child: DropdownButton<_ClassOption>(
        value: _selectedClass,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(
          'Select Class',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
        ),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o.className)))
            .toList(),
        onChanged: (value) => setState(() => _selectedClass = value),
      ),
    );
  }

  Widget _buildStudentList() {
    final selected = _selectedClass;
    if (selected == null) {
      return const Center(child: Text('Select a class to view students.'));
    }

    final studentsAsync = ref.watch(_classStudentsProvider(selected.classId));

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 32),
            const SizedBox(height: 8),
            Text(
              'Could not load students.\nCheck your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ref.invalidate(_classStudentsProvider(selected.classId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Text(
              'No students found in ${selected.className}.',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final s = students[index];
            return _StudentTile(
              studentId: s['student_id'] as int,
              firstName: (s['first_name'] ?? '').toString(),
              lastName: (s['last_name'] ?? '').toString(),
              className: (s['class_name'] ?? selected.className).toString(),
              studentCode: s['student_code'] as String?,
              phone: s['phone_number'] as String?,
              sex: s['sex'] as String?,
              dateOfBirth: s['date_of_birth'] as String?,
            );
          },
        );
      },
    );
  }

}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.className,
    this.studentCode,
    this.phone,
    this.sex,
    this.dateOfBirth,
  });

  final int studentId;
  final String firstName;
  final String lastName;
  final String className;
  final String? studentCode;
  final String? phone;
  final String? sex;
  final String? dateOfBirth;

  String get _displayName => '$firstName $lastName'.trim();
  String get _initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppTheme.darkCard : AppTheme.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudentDetailPage(
                studentId: studentId,
                firstName: firstName,
                lastName: lastName,
                className: className,
                studentCode: studentCode,
                phone: phone,
                sex: sex,
                dateOfBirth: dateOfBirth,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              UserAvatar(initials: _initials, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    if (studentCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ID: $studentCode',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail Page ───────────────────────────────────────────────────────────────

class StudentDetailPage extends ConsumerWidget {
  const StudentDetailPage({
    super.key,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.className,
    this.studentCode,
    this.phone,
    this.sex,
    this.dateOfBirth,
  });

  final int studentId;
  final String firstName;
  final String lastName;
  final String className;
  final String? studentCode;
  final String? phone;
  final String? sex;
  final String? dateOfBirth;

  String get _displayName => '$firstName $lastName'.trim();
  String get _initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(_studentAttendanceStatsProvider(studentId));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Student Info'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  UserAvatar(initials: _initials, radius: 34),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (studentCode != null)
                          Text(
                            'Roll No: $studentCode',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        Text(
                          className,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Attendance stat card ────────────────────────────────────────
            statsAsync.when(
              loading: () => _AttendanceStatCard(stats: null, loading: true),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => _AttendanceStatCard(stats: stats, loading: false),
            ),

            const SizedBox(height: 16),

            // ── Info card ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Class', value: className),
                  _divider(cs),
                  if (studentCode != null) ...[
                    _InfoRow(label: 'Roll Number', value: studentCode!),
                    _divider(cs),
                  ],
                  if (sex != null) ...[
                    _InfoRow(
                      label: 'Gender',
                      value: sex == 'male' ? 'Male' : 'Female',
                    ),
                    _divider(cs),
                  ],
                  if (dateOfBirth != null) ...[
                    _InfoRow(label: 'Date of Birth', value: dateOfBirth!),
                    _divider(cs),
                  ],
                  _InfoRow(
                    label: 'Phone Number',
                    value: phone ?? '—',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ColorScheme cs) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: cs.outline.withValues(alpha: 0.12),
      );
}

// ── Attendance stat card ───────────────────────────────────────────────────────

class _AttendanceStatCard extends StatelessWidget {
  const _AttendanceStatCard({required this.stats, required this.loading});

  final _AttendanceStats? stats;
  final bool loading;

  Color _barColor(double pct) {
    if (pct >= 80) return const Color(0xFF22C55E); // green
    if (pct >= 60) return const Color(0xFFF59E0B); // amber
    return AppTheme.danger;
  }

  String _label(double pct) {
    if (pct >= 80) return 'Good attendance';
    if (pct >= 60) return 'Needs improvement';
    return 'Poor attendance';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final pct = stats?.percentage;
    final total = stats?.total ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: isDark ? 0.35 : 0.1),
            AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: loading
          ? Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading attendance…',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Attendance Rate',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      pct != null ? '${pct.toStringAsFixed(0)}%' : '—',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: pct != null
                            ? _barColor(pct)
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
                      minHeight: 6,
                      backgroundColor:
                          cs.onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_barColor(pct)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _label(pct),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _barColor(pct),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Based on $total record${total == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.45),
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
  }
}

// ── Info row ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.6),
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
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _AttendanceStats {
  const _AttendanceStats({required this.percentage, required this.total});

  final double? percentage;
  final int total;
}

class _ClassOption {
  const _ClassOption({required this.classId, required this.className});

  final int classId;
  final String className;

  @override
  bool operator ==(Object other) =>
      other is _ClassOption && other.classId == classId;

  @override
  int get hashCode => classId.hashCode;
}
