import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/timetable/domain/timetable_entry.dart';
import 'package:edu_air/src/features/timetable/presentation/widgets/timetable_week_view.dart';

/// Admin/principal timetable manager.
///
/// Pick a class → see its weekly periods (Mon–Fri) → add / edit / delete.
/// All writes go through TimetableApiRepository; the list re-fetches on change.
/// Teacher assignment is a planned follow-up — periods are created unassigned.
class AdminTimetableScreen extends ConsumerStatefulWidget {
  const AdminTimetableScreen({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  ConsumerState<AdminTimetableScreen> createState() =>
      _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends ConsumerState<AdminTimetableScreen> {
  int? _selectedClassId;

  // Day labels for the delete-confirmation dialog.
  static const _dayLabels = {
    'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday',
    'thu': 'Thursday', 'fri': 'Friday', 'sat': 'Saturday', 'sun': 'Sunday',
  };

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final classes   = ref.watch(schoolClassesProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Timetable',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        leading: widget.onBackToHome != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBackToHome)
            : null,
      ),
      floatingActionButton: _selectedClassId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(classId: _selectedClassId!),
              icon: const Icon(Icons.add),
              label: const Text('Add period'),
            ),
      body: Column(
        children: [
          // ── Class picker ─────────────────────────────────────────────
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: classes.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text('Could not load classes',
                  style: TextStyle(color: cs.error)),
              data: (list) => DropdownButtonFormField<int>(
                initialValue: _selectedClassId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Class',
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text('Select a class'),
                items: list.map((c) {
                  final id = (c['id'] as num).toInt();
                  final name = (c['name'] ?? '—').toString();
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedClassId = v),
              ),
            ),
          ),

          // ── Weekly list ──────────────────────────────────────────────
          Expanded(
            child: _selectedClassId == null
                ? _Hint(icon: Icons.event_note_outlined, text: 'Pick a class to see its timetable')
                : TimetableWeekView(
                    classId: _selectedClassId!,
                    onEdit: (entry) => _openForm(classId: _selectedClassId!, existing: entry),
                    onDelete: _confirmDelete,
                  ),
          ),
        ],
      ),
    );
  }

  // ── Add / edit form ────────────────────────────────────────────────────
  Future<void> _openForm({required int classId, TimetableEntry? existing}) async {
    final isShiftSchool = ref.read(userProvider)?.isShiftSchool ?? false;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _PeriodFormSheet(
          classId: classId,
          existing: existing,
          isShiftSchool: isShiftSchool,
        ),
      ),
    );
    if (saved == true) ref.invalidate(timetableByClassProvider(classId));
  }

  // ── Delete ───────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(TimetableEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete period?'),
        content: Text('${entry.subject} — ${_dayLabels[entry.dayOfWeek] ?? entry.dayOfWeek}, ${entry.timeRange}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(timetableApiRepositoryProvider).delete(entry.id);
      ref.invalidate(timetableByClassProvider(entry.classId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${_errMessage(e)}')),
        );
      }
    }
  }
}

// ─── Add / edit form sheet ────────────────────────────────────────────────────

class _PeriodFormSheet extends ConsumerStatefulWidget {
  const _PeriodFormSheet({
    required this.classId,
    required this.isShiftSchool,
    this.existing,
  });

  final int classId;
  final bool isShiftSchool;
  final TimetableEntry? existing;

  @override
  ConsumerState<_PeriodFormSheet> createState() => _PeriodFormSheetState();
}

class _PeriodFormSheetState extends ConsumerState<_PeriodFormSheet> {
  late final TextEditingController _subject;
  late final TextEditingController _room;
  late String _day;
  late String _shift;
  String? _start; // 'HH:mm'
  String? _end;
  bool _saving = false;
  String? _error;

  static const _days = [
    (v: 'mon', l: 'Monday'), (v: 'tue', l: 'Tuesday'), (v: 'wed', l: 'Wednesday'),
    (v: 'thu', l: 'Thursday'), (v: 'fri', l: 'Friday'),
  ];
  static const _shifts = [
    (v: 'morning', l: 'Morning'), (v: 'afternoon', l: 'Afternoon'), (v: 'whole_day', l: 'Whole Day'),
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _subject = TextEditingController(text: e?.subject ?? '');
    _room    = TextEditingController(text: e?.room ?? '');
    _day     = e?.dayOfWeek ?? 'mon';
    _shift   = e?.shiftType ?? 'whole_day';
    _start   = e?.startTime;
    _end     = e?.endTime;
  }

  @override
  void dispose() {
    _subject.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hhmm = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => isStart ? _start = hhmm : _end = hhmm);
    }
  }

  Future<void> _save() async {
    final subject = _subject.text.trim();
    if (subject.isEmpty || _start == null || _end == null) {
      setState(() => _error = 'Subject, start time and end time are required.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final repo = ref.read(timetableApiRepositoryProvider);
    final room = _room.text.trim();
    try {
      if (_isEdit) {
        await repo.update(
          id: widget.existing!.id, subject: subject, dayOfWeek: _day,
          startTime: _start!, endTime: _end!, shiftType: _shift,
          room: room.isEmpty ? null : room,
        );
      } else {
        await repo.create(
          classId: widget.classId, subject: subject, dayOfWeek: _day,
          startTime: _start!, endTime: _end!, shiftType: _shift,
          room: room.isEmpty ? null : room,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _saving = false; _error = _errMessage(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_isEdit ? 'Edit period' : 'Add period',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 16),

          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
            items: _days.map((d) => DropdownMenuItem(value: d.v, child: Text(d.l))).toList(),
            onChanged: (v) => setState(() => _day = v ?? _day),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _TimeField(label: 'Start', value: _start, onTap: () => _pickTime(isStart: true))),
              const SizedBox(width: 12),
              Expanded(child: _TimeField(label: 'End', value: _end, onTap: () => _pickTime(isStart: false))),
            ],
          ),
          const SizedBox(height: 12),

          // Shift only matters for shift schools; whole-day schools stay 'whole_day'.
          if (widget.isShiftSchool) ...[
            DropdownButtonFormField<String>(
              initialValue: _shift,
              decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
              items: _shifts.map((s) => DropdownMenuItem(value: s.v, child: Text(s.l))).toList(),
              onChanged: (v) => setState(() => _shift = v ?? _shift),
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _room,
            decoration: const InputDecoration(labelText: 'Room (optional)', border: OutlineInputBorder()),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save changes' : 'Add period'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.value, required this.onTap});

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(value ?? '--:--'),
      ),
    );
  }
}

// ─── Shared bits ──────────────────────────────────────────────────────────────

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// Pulls the server's {message} out of a Dio error, else a generic string.
String _errMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
  }
  return 'Something went wrong';
}
