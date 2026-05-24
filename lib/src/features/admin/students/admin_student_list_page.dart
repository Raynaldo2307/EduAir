import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';
import 'package:edu_air/src/features/admin/students/application/admin_students_provider.dart';
import 'admin_student_edit_page.dart';

class AdminStudentListPage extends ConsumerStatefulWidget {
  const AdminStudentListPage({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  ConsumerState<AdminStudentListPage> createState() =>
      _AdminStudentListPageState();
}

class _AdminStudentListPageState extends ConsumerState<AdminStudentListPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _filter(List<AppUser> students) {
    if (_query.isEmpty) return students;
    final q = _query.toLowerCase();
    return students.where((s) {
      return s.displayName.toLowerCase().contains(q) ||
          (s.className?.toLowerCase().contains(q) ?? false) ||
          (s.gradeLevel?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _openEditPage(AppUser? student) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminStudentEditPage(student: student),
      ),
    );
    if (result == true) {
      ref.invalidate(schoolStudentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              student == null
                  ? 'Student added successfully'
                  : 'Student updated successfully',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final studentsAsync = ref.watch(schoolStudentsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBackToHome,
              )
            : null,
        title: Text(
          'Manage Students',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load students',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        ),
        data: (students) {
          final filtered = _filter(students);

          return Column(
            children: [
              // Search bar + count
              Container(
                color: cs.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search by name, class or grade…',
                        hintStyle:
                            TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                        prefixIcon:
                            Icon(Icons.search, color: cs.onSurfaceVariant),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: cs.onSurfaceVariant, size: 18),
                                onPressed: () => setState(() {
                                  _query = '';
                                  _searchController.clear();
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _query.isEmpty
                          ? '${students.length} students'
                          : '${filtered.length} of ${students.length} students',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(query: _query, cs: cs)
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final student = filtered[index];
                          return _StudentTile(
                            student: student,
                            onTap: () => _openEditPage(student),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditPage(null),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Student'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.cs});

  final String query;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final isSearch = query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch ? Icons.search_off : Icons.people_outline,
              size: 56,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'No results for "$query"' : 'No students yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSearch
                  ? 'Try searching by a different name or class'
                  : 'Tap the button below to add your first student',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final AppUser student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shift = student.currentShift;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        student.className ??
                            (student.gradeLevel != null
                                ? 'Grade ${student.gradeLevel}'
                                : '—'),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ShiftChip(shift: shift, cs: cs),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.shift, required this.cs});

  final String? shift;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (shift) {
      'morning'   => ('Morning', const Color(0xFF0059BA)),
      'afternoon' => ('Afternoon', const Color(0xFFB7791F)),
      _           => ('Whole Day', const Color(0xFF2E7D32)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
