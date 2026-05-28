import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/admin/classes/application/admin_classes_provider.dart';
import 'package:edu_air/src/features/admin/students/admin_student_list_page.dart';

class AdminClassesScreen extends ConsumerWidget {
  const AdminClassesScreen({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs           = Theme.of(context).colorScheme;
    final classesAsync = ref.watch(adminClassesProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Classes'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: onBackToHome,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(adminClassesProvider),
          ),
        ],
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminClassesProvider),
        ),
        data: (classes) => classes.isEmpty
            ? const _EmptyView()
            : _ClassGrid(classes: classes),
      ),
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _ClassGrid extends StatelessWidget {
  const _ClassGrid({required this.classes});
  final List<Map<String, dynamic>> classes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${classes.length} class${classes.length == 1 ? '' : 'es'}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: classes.length,
              itemBuilder: (context, i) => _ClassCard(data: classes[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Class card ───────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.data});
  final Map<String, dynamic> data;

  void _openStudents(BuildContext context) {
    final classId   = data['id']?.toString();
    final className = data['name'] as String?;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminStudentListPage(
          filterClassId:   classId,
          filterClassName: className,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final name         = data['name']             as String? ?? '—';
    final gradeLevel   = data['grade_level']      as String? ?? '';
    final studentCount = (data['student_count'] as num?)?.toInt() ?? 0;
    final teacher      = data['homeroom_teacher']  as String?;

    return GestureDetector(
      onTap: () => _openStudents(context),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? cs.surfaceContainerHighest
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class name + grade
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _gradeColor(gradeLevel).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _classInitial(name),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _gradeColor(gradeLevel),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (gradeLevel.isNotEmpty)
                      Text(
                        gradeLevel,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Stats row
          Row(
            children: [
              _StatPill(
                icon: Icons.people_outline,
                label: '$studentCount ${studentCount == 1 ? 'student' : 'students'}',
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Teacher
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 13,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  teacher != null && teacher.trim().isNotEmpty
                      ? teacher
                      : 'No teacher assigned',
                  style: TextStyle(
                    fontSize: 12,
                    color: teacher != null && teacher.trim().isNotEmpty
                        ? cs.onSurface.withValues(alpha: 0.7)
                        : cs.onSurface.withValues(alpha: 0.35),
                    fontStyle: teacher == null || teacher.trim().isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    ),   // Container
    );   // GestureDetector
  }

  String _classInitial(String name) =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';

  Color _gradeColor(String grade) {
    final colors = [
      Colors.indigo, Colors.teal, Colors.deepPurple,
      Colors.blue,   Colors.green, Colors.orange,
    ];
    final code = grade.codeUnits.fold(0, (a, b) => a + b);
    return colors[code % colors.length];
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No classes found',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load classes:\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}
