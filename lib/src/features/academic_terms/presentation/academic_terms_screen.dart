import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/academic_terms/application/academic_terms_controller.dart';
import 'package:edu_air/src/features/academic_terms/application/academic_terms_provider.dart';
import 'package:edu_air/src/features/academic_terms/domain/academic_term.dart';

/// School Settings → Academic Terms. Admin/principal define the school's
/// reporting windows (Term 1, semesters...). These are the boundaries every
/// "this term" report and the student/teacher header read from.
class AcademicTermsScreen extends ConsumerWidget {
  const AcademicTermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final termsAsync = ref.watch(schoolTermsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Academic Terms',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTermForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add term'),
      ),
      body: termsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Hint(
            icon: Icons.error_outline,
            text: 'Could not load terms.',
            cs: cs),
        data: (terms) {
          if (terms.isEmpty) {
            return _Hint(
              icon: Icons.event_outlined,
              text: 'No terms set up yet.\nTap “Add term” to start your year.',
              cs: cs,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: terms.length,
            itemBuilder: (_, i) => _TermCard(
              term: terms[i],
              onTap: () => _showTermForm(context, existing: terms[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({required this.term, required this.onTap});
  final AcademicTerm term;
  final VoidCallback onTap;

  // Client-side hint only — the backend is the authority via currentTermProvider.
  bool get _isCurrent {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(term.startDate) && !today.isAfter(term.endDate);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(term.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface)),
                          ),
                          if (_isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Current',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onPrimaryContainer)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${_fmtDate(term.startDate)} – ${_fmtDate(term.endDate)}',
                          style: TextStyle(
                              fontSize: 12.5, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text, required this.cs});
  final IconData icon;
  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 52, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Add / edit a term ────────────────────────────────────────────────────────

Future<void> _showTermForm(BuildContext context, {AcademicTerm? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _TermFormSheet(existing: existing),
    ),
  );
}

class _TermFormSheet extends ConsumerStatefulWidget {
  const _TermFormSheet({this.existing});
  final AcademicTerm? existing;

  @override
  ConsumerState<_TermFormSheet> createState() => _TermFormSheetState();
}

class _TermFormSheetState extends ConsumerState<_TermFormSheet> {
  late final TextEditingController _name;
  DateTime? _start;
  DateTime? _end;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _start = widget.existing?.startDate;
    _end = widget.existing?.endDate;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final busy = ref.watch(academicTermsControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEditing ? 'Edit term' : 'Add term',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Term 1, Fall Semester',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _dateField('Start', _start, () => _pick(true))),
                const SizedBox(width: 12),
                Expanded(child: _dateField('End', _end, () => _pick(false))),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy ? null : _save,
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save changes' : 'Add term'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: busy ? null : _delete,
                icon: Icon(Icons.delete_outline, color: cs.error),
                label: Text('Delete term', style: TextStyle(color: cs.error)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(value == null ? 'Select' : _fmtDate(value)),
      ),
    );
  }

  Future<void> _pick(bool isStart) async {
    final init = (isStart ? _start : _end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  /// Mirror the backend's required-field + end>start rules for instant feedback.
  /// Overlap is checked server-side (a 409 surfaces its message) — the backend
  /// stays the source of truth.
  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return _snack('Enter a name for this term.');
    if (_start == null || _end == null) {
      return _snack('Pick a start and end date.');
    }
    if (!_end!.isAfter(_start!)) {
      return _snack('End date must be after start date.');
    }

    final controller = ref.read(academicTermsControllerProvider.notifier);
    final error = _isEditing
        ? await controller.editTerm(widget.existing!.id,
            name: name, startDate: _start, endDate: _end)
        : await controller.addTerm(
            name: name, startDate: _start!, endDate: _end!);

    if (!mounted) return;
    if (error != null) return _snack(error);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete term?'),
        content: Text('“${widget.existing!.name}” will be removed. Reports that '
            'reference it may be affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(academicTermsControllerProvider.notifier)
        .removeTerm(widget.existing!.id);

    if (!mounted) return;
    if (error != null) return _snack(error);
    Navigator.of(context).pop();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

// dd Mon yyyy, e.g. "1 Sep 2026".
const _months = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _fmtDate(DateTime d) => '${d.day} ${_months[d.month]} ${d.year}';
