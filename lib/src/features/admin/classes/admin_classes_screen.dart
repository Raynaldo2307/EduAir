import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/admin/classes/admin_class_detail_page.dart';
import 'package:edu_air/src/features/admin/classes/admin_class_edit_page.dart';
import 'package:edu_air/src/features/admin/classes/application/admin_classes_provider.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_class_fab',
        onPressed: () => _openEdit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New Class'),
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminClassesProvider),
        ),
        data: (classes) => classes.isEmpty
            ? _EmptyView(onAdd: () => _openEdit(context, ref, null))
            : _ClassGrid(
                classes: classes,
                onEdit: (data) => _openEdit(context, ref, data),
              ),
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? classData,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminClassEditPage(classData: classData)),
    );
    if (result == true) ref.invalidate(adminClassesProvider);
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _ClassGrid extends StatefulWidget {
  const _ClassGrid({required this.classes, required this.onEdit});
  final List<Map<String, dynamic>> classes;
  final void Function(Map<String, dynamic>) onEdit;

  @override
  State<_ClassGrid> createState() => _ClassGridState();
}

class _ClassGridState extends State<_ClassGrid> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return widget.classes;
    final q = _query.toLowerCase();
    return widget.classes.where((c) {
      final name  = (c['name']        as String? ?? '').toLowerCase();
      final grade = (c['grade_level'] as String? ?? '').toLowerCase();
      final teacher = (c['homeroom_teacher'] as String? ?? '').toLowerCase();
      return name.contains(q) || grade.contains(q) || teacher.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final total    = widget.classes.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ────────────────────────────────────────────
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search by class name, grade or teacher…',
              hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
              prefixIcon: Icon(Icons.search, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                      onPressed: () { _search.clear(); setState(() => _query = ''); },
                    )
                  : null,
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Count label ───────────────────────────────────────────
          Text(
            _query.isEmpty
                ? '$total class${total == 1 ? '' : 'es'}'
                : '${filtered.length} of $total class${total == 1 ? '' : 'es'}',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),

          // ── Grid ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No classes match "$_query"',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _ClassCard(
                      data: filtered[i],
                      onEdit: () => widget.onEdit(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Class card ───────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.data, required this.onEdit});
  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminClassDetailPage(classData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final name         = data['name']             as String? ?? '—';
    final gradeLevel   = data['grade_level']      as String? ?? '';
    final studentCount = int.tryParse(data['student_count']?.toString() ?? '') ?? 0;
    final capacity     = int.tryParse(data['capacity']?.toString() ?? '') ?? 40;
    final teacher      = data['homeroom_teacher'] as String?;
    final todayRate    = int.tryParse(data['today_rate']?.toString() ?? '');
    final isFull       = studentCount >= capacity;

    return GestureDetector(
      onTap:      () => _openDetail(context),
      onLongPress: onEdit,
      child: Container(
        padding: const EdgeInsets.all(14),
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
            // ── Header row ────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _gradeColor(gradeLevel).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _avatarLabel(gradeLevel, name),
                      style: TextStyle(
                        fontSize: _avatarLabel(gradeLevel, name).length > 2 ? 12 : 15,
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
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (gradeLevel.isNotEmpty)
                        Text(
                          gradeLevel,
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                    ],
                  ),
                ),
                // Edit hint icon
                Icon(Icons.more_vert, size: 16, color: cs.onSurface.withValues(alpha: 0.25)),
              ],
            ),
            const Spacer(),

            // ── Capacity bar ──────────────────────────────────────
            Row(
              children: [
                Text(
                  '$studentCount / $capacity',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isFull ? Colors.red : cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: capacity > 0 ? studentCount / capacity : 0,
                      minHeight: 4,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(
                        isFull ? Colors.red : _gradeColor(gradeLevel),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Bottom row: teacher + today rate ──────────────────
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    teacher != null && teacher.trim().isNotEmpty ? teacher : 'No teacher',
                    style: TextStyle(
                      fontSize: 11,
                      color: teacher != null && teacher.trim().isNotEmpty
                          ? cs.onSurface.withValues(alpha: 0.65)
                          : cs.onSurface.withValues(alpha: 0.3),
                      fontStyle: teacher == null || teacher.trim().isEmpty
                          ? FontStyle.italic : FontStyle.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (todayRate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _rateColor(todayRate).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$todayRate%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _rateColor(todayRate),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Extracts the grade number from grade_level ("Grade 10" → "10", "Grade 9" → "9").
  // Falls back to the class name if no number found ("Form 1A" → "1A" stripped).
  String _avatarLabel(String gradeLevel, String className) {
    final nums = RegExp(r'\d+').allMatches(gradeLevel).map((m) => m.group(0)!).toList();
    if (nums.isNotEmpty) return nums.last;
    final classNums = RegExp(r'\d+').allMatches(className).map((m) => m.group(0)!).toList();
    if (classNums.isNotEmpty) return classNums.first;
    return className.isNotEmpty ? className[0].toUpperCase() : '?';
  }

  Color _gradeColor(String grade) {
    final colors = [
      Colors.indigo, Colors.teal, Colors.deepPurple,
      Colors.blue, Colors.green, Colors.orange,
    ];
    final code = grade.codeUnits.fold(0, (a, b) => a + b);
    return colors[code % colors.length];
  }

  Color _rateColor(int rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No classes yet', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create First Class'),
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
              Text('Failed to load classes:\n$message',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
