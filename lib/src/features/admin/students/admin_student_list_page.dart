import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'admin_student_edit_page.dart';

/// Maps a raw Node API student record to [AppUser].
AppUser _nodeStudentToAppUser(Map<String, dynamic> d) {
  return AppUser(
    uid: d['student_id'].toString(),
    firstName: d['first_name'] ?? '',
    lastName: d['last_name'] ?? '',
    email: d['email'] ?? '',
    phone: d['phone_number'] ?? '',
    role: 'student',
    studentId: d['student_code'],
    currentShift: d['current_shift_type'],
    sex: d['sex'],
    className: d['class_name'],
    gradeLevel: d['grade_level']?.toString(),
  );
}

/// Fetches all active students for the admin's school via the Node API.
final schoolStudentsProvider = FutureProvider<List<AppUser>>((ref) async {
  final studentsRepo = ref.read(studentsApiRepositoryProvider);
  final raw = await studentsRepo.getAll();
  return raw.map(_nodeStudentToAppUser).toList();
});

/// Admin/Principal page to view and manage students in their school.
class AdminStudentListPage extends ConsumerWidget {
  const AdminStudentListPage({super.key, this.onBackToHome});

  /// Callback to switch the shell back to the Home tab.
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(schoolStudentsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackToHome,
              )
            : null,
        title: const Text('Manage Students'),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load students: $err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (students) {
          if (students.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No students found in this school.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.grey),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final student = students[index];
              return _StudentTile(
                student: student,
                onTap: () => _openEditPage(context, ref, student),
              );
            },
          );
        },
      ),
    );
  }

  void _openEditPage(BuildContext context, WidgetRef ref, AppUser student) async {
    final result = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (_) => AdminStudentEditPage(student: student),
      ),
    );

    // Refresh the list if a student was updated
    if (result != null) {
      ref.invalidate(schoolStudentsProvider);
    }
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final AppUser student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shiftLabel = _shiftDisplayLabel(student.currentShift);

    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.35),
                child: Text(
                  student.initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student.className ?? 'No class'} • $shiftLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppTheme.textPrimary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shiftDisplayLabel(String? shift) {
    switch (shift) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'whole_day':
        return 'Whole Day';
      default:
        return 'Whole Day';
    }
  }
}
