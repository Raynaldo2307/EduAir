import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

/// Holds the currently selected filter date (YYYY-MM-DD).
final _attendanceDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

/// Shift is locked to the school's configured shift type.
/// Reads from the logged-in user's profile — never a manual selection.
final _attendanceShiftProvider = StateProvider<String>(
  (ref) => ref.read(userProvider)?.defaultShiftType ?? 'whole_day',
);

/// Fetches school-wide attendance from Node API for the selected date + shift.
final adminAttendanceResultProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final date = ref.watch(_attendanceDateProvider);
  final shift = ref.watch(_attendanceShiftProvider);
  final repo = ref.read(attendanceApiRepositoryProvider);

  final dateKey =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  return repo.getByDateAndShift(date: dateKey, shiftType: shift);
});

// ─── Page ────────────────────────────────────────────────────────────────────

/// Admin/Principal screen — shows school-wide attendance from Node API + MySQL.
/// Demonstrates: Flutter → Dio → Node.js → MySQL end-to-end.
class AdminAttendancePage extends ConsumerWidget {
  const AdminAttendancePage({super.key , required this.onBackToHome});

  final VoidCallback onBackToHome;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(_attendanceDateProvider);
    final selectedShift = ref.watch(_attendanceShiftProvider);
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
                ref.read(_attendanceDateProvider.notifier).state = d,
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
                side: const BorderSide(color: AppTheme.primaryColor),
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
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _shiftLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
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
            color: AppTheme.primaryColor,
            tooltip: 'Reload',
          ),
        ],
      ),
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _AttendanceTile(record: records[i]),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.record});

  final Map<String, dynamic> record;

  String get _studentName =>
      '${record['student_first_name'] ?? ''} ${record['student_last_name'] ?? ''}'
          .trim();

  String get _initials {
    final first = (record['student_first_name'] as String? ?? '');
    final last = (record['student_last_name'] as String? ?? '');
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
        .toUpperCase();
  }

  String get _clockIn {
    final t = record['clock_in'];
    return t != null ? t.toString().substring(0, 5) : '--:--';
  }

  String get _clockOut {
    final t = record['clock_out'];
    return t != null ? t.toString().substring(0, 5) : '--:--';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = record['status'] as String? ?? 'absent';

    return Material(
      color: isDark ? AppTheme.darkCard : AppTheme.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  AppTheme.secondaryColor.withValues(alpha: 0.3),
              child: Text(
                _initials,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: cs.onSurface,
                ),
              ),
            ),
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
          ],
        ),
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
