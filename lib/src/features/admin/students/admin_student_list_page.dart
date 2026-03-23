import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';
import 'package:edu_air/src/features/admin/students/application/admin_students_provider.dart';
import 'admin_student_edit_page.dart';

/// Admin/Principal page to view and manage students in their school.
class AdminStudentListPage extends ConsumerWidget {
  const AdminStudentListPage({super.key, this.onBackToHome});

  /// Callback to switch the shell back to the Home tab.
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(schoolStudentsProvider);

    final cs = Theme.of(context).colorScheme;
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
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const AdminStudentEditPage(),
            ),
          );
          if (added == true) ref.invalidate(schoolStudentsProvider);
        },
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Student'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
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
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminStudentEditPage(student: student),
      ),
    );

    if (result == true) {
      ref.invalidate(schoolStudentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully')),
        );
      }
    }
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final AppUser student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shiftLabel = _shiftDisplayLabel(student.currentShift);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatar(
              initials: student.initials,
              photoUrl: student.photoUrl,
              radius: 22,
            ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student.className ?? (student.gradeLevel != null ? 'Grade ${student.gradeLevel}' : '—')} • $shiftLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ],
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
