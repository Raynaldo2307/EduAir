import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';
import 'package:edu_air/src/features/admin/attendance/application/admin_attendance_provider.dart';
import 'package:edu_air/src/features/attendance/application/late_reason_provider.dart';

// Valid statuses the admin can set
const _kStatuses = ['early', 'present', 'late', 'excused', 'absent'];

// ─── Page ────────────────────────────────────────────────────────────────────

/// Admin/Principal screen — shows school-wide attendance from Node API + MySQL.
/// Demonstrates: Flutter → Dio → Node.js → MySQL end-to-end.
class AdminAttendancePage extends ConsumerWidget {
  const AdminAttendancePage({super.key , required this.onBackToHome});

  final VoidCallback onBackToHome;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(attendanceDateProvider);
    final selectedShift = ref.watch(attendanceShiftProvider);
    final attendanceAsync = ref.watch(adminAttendanceResultProvider);

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Attendance Report'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: onBackToHome,
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            selectedDate: selectedDate,
            selectedShift: selectedShift,
            onDateChanged: (d) =>
                ref.read(attendanceDateProvider.notifier).state = d,
            onRefresh: () => ref.invalidate(adminAttendanceResultProvider),
          ),
          const Divider(height: 1),
          Expanded(
            child: attendanceAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorView(error: err.toString()),
              data: (records) => records.isEmpty
                  ? const _EmptyView()
                  : _AttendanceList(records: records),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedDate,
    required this.selectedShift,
    required this.onDateChanged,
    required this.onRefresh,
  });

  final DateTime selectedDate;
  final String selectedShift;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onRefresh;

  String get _formattedDate =>
      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

  String get _shiftLabel {
    switch (selectedShift) {
      case 'morning':
        return 'Morning Shift';
      case 'afternoon':
        return 'Afternoon Shift';
      default:
        return 'Whole Day';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Date picker
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(_formattedDate),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );
                if (picked != null) onDateChanged(picked);
              },
            ),
          ),
          const SizedBox(width: 10),

          // Locked shift badge — school config, not user-selectable
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  _shiftLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Refresh
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'Reload',
          ),
        ],
      ),
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _AttendanceList extends ConsumerWidget {
  const _AttendanceList({required this.records});

  final List<Map<String, dynamic>> records;

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> record,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _AttendanceEditSheet(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _AttendanceTile(
        record: records[i],
        onEdit: () => _showEditSheet(context, ref, records[i]),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.record, required this.onEdit});

  final Map<String, dynamic> record;
  final VoidCallback onEdit;


  String get _studentName =>
      '${record['student_first_name'] ?? ''} ${record['student_last_name'] ?? ''}'
          .trim();

  String get _initials {
    final first = (record['student_first_name'] as String? ?? '');
    final last = (record['student_last_name'] as String? ?? '');
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
        .toUpperCase();
  }

  String _formatTime(dynamic t) {
    if (t == null) return '--:--';
    try {
      final dt = DateTime.parse(t.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  String get _clockIn  => _formatTime(record['clock_in']);
  String get _clockOut => _formatTime(record['clock_out']);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = record['status'] as String? ?? 'absent';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          // Avatar — shared UserAvatar widget (deterministic colour from initials)
          UserAvatar(initials: _initials, radius: 20),
          const SizedBox(width: 12),

          // Name + times
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _studentName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'In: $_clockIn   Out: $_clockOut',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),

          // Status chip
          _StatusChip(status: status),
          const SizedBox(width: 14),

          // Edit button — pushed clear of the chip
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, bg, fg) = switch (status) {
      'early' => ('Early', const Color(0xFFD3F9D8), const Color(0xFF2F9E44)),
      'late' => ('Late', const Color(0xFFFFE8CC), const Color(0xFFE8590C)),
      'present' => ('Present', const Color(0xFFD0EBFF), const Color(0xFF1971C2)),
      'excused' => ('Excused', const Color(0xFFEDEDFF), const Color(0xFF5C5FC6)),
      _ => ('Absent', const Color(0xFFFFE3E3), const Color(0xFFC92A2A)),
    };
    final chipBg = isDark ? fg.withValues(alpha: 0.2) : bg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No attendance records for this date and shift.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load attendance.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

// ─── Edit Sheet ───────────────────────────────────────────────────────────────

/// Bottom sheet that lets admin/principal change a student's attendance status.
/// Architecture: UI → AdminAttendanceNotifier → AttendanceApiRepository → Node API
class _AttendanceEditSheet extends ConsumerStatefulWidget {
  const _AttendanceEditSheet({required this.record});

  final Map<String, dynamic> record;

  @override
  ConsumerState<_AttendanceEditSheet> createState() =>
      _AttendanceEditSheetState();
}

class _AttendanceEditSheetState extends ConsumerState<_AttendanceEditSheet> {
  late String _selectedStatus;
  String? _selectedLateReason;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.record['status'] as String? ?? 'absent';
    // Pre-fill late reason if the record already has one
    final existing = widget.record['late_reason_code'] as String?;
    if (existing != null && existing.isNotEmpty) {
      _selectedLateReason = existing;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String get _studentName =>
      '${widget.record['student_first_name'] ?? ''} ${widget.record['student_last_name'] ?? ''}'
          .trim();

  int get _recordId => widget.record['id'] as int;

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final notifier   = ref.watch(adminAttendanceNotifierProvider);
    final isLoading  = notifier is AsyncLoading;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Student name
          Text(
            _studentName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Edit attendance record',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),

          // Status selector
          Text(
            'Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kStatuses.map((s) {
              final isSelected = s == _selectedStatus;
              final (_, bg, fg) = _statusColors(s);
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedStatus = s;
                  // Clear late reason when switching away from late
                  if (s != 'late') _selectedLateReason = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? fg.withValues(alpha: 0.25) : bg)
                        : cs.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? fg : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    s[0].toUpperCase() + s.substring(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? fg
                          : cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // Late reason — only shown when status is 'late'
          if (_selectedStatus == 'late') ...[
            const SizedBox(height: 20),
            Text(
              'Late Reason (required)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surfaceContainerHighest
                    : cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outline),
              ),
              child: DropdownButton<String>(
                value: _selectedLateReason,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: isDark ? AppTheme.darkCard : cs.surface,
                style: TextStyle(fontSize: 13, color: cs.onSurface),
                hint: Text(
                  'Select a reason',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                items: ref.read(lateReasonOptionsProvider).map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt.code,
                    child: Text(opt.label),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedLateReason = val),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Note field
          Text(
            'Note (optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            style: TextStyle(color: cs.onSurface),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Parent called — medical excuse',
              hintStyle: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.35),
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark
                  ? cs.surfaceContainerHighest
                  : cs.primary.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Guard: late requires a reason
                      if (_selectedStatus == 'late' &&
                          (_selectedLateReason == null ||
                              _selectedLateReason!.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a late reason.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      final note = _noteController.text.trim();
                      final navigator = Navigator.of(context);
                      final success = await ref
                          .read(adminAttendanceNotifierProvider.notifier)
                          .updateRecord(
                            _recordId,
                            _selectedStatus,
                            lateReasonCode: _selectedStatus == 'late'
                                ? _selectedLateReason
                                : null,
                            note: note.isEmpty ? null : note,
                          );
                      if (success && mounted) navigator.pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.onPrimary,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

(String, Color, Color) _statusColors(String status) => switch (status) {
      'early'   => ('Early',   const Color(0xFFD3F9D8), const Color(0xFF2F9E44)),
      'late'    => ('Late',    const Color(0xFFFFE8CC), const Color(0xFFE8590C)),
      'present' => ('Present', const Color(0xFFD0EBFF), const Color(0xFF1971C2)),
      'excused' => ('Excused', const Color(0xFFEDEDFF), const Color(0xFF5C5FC6)),
      _         => ('Absent',  const Color(0xFFFFE3E3), const Color(0xFFC92A2A)),
    };
