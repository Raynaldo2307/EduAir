import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';
import 'package:edu_air/src/features/admin/clockin/application/clockin_records_provider.dart';
import 'package:edu_air/src/features/admin/attendance/widgets/attendance_edit_sheet.dart';

/// Admin/Principal attendance screen — the single source for daily attendance.
///
/// Merged from the old "Attendance Overview" + "Clock-in Records" screens:
///  - filter by date / shift / status
///  - see who clocked in & out, how long they stayed, and who marked them
///  - tap any record to correct the status (edit sheet)
///
/// Shift filter only appears for shift schools; whole-day schools see a single
/// locked "Whole Day" badge instead.
class AdminClockinRecordsScreen extends ConsumerStatefulWidget {
  const AdminClockinRecordsScreen({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  ConsumerState<AdminClockinRecordsScreen> createState() =>
      _AdminClockinRecordsScreenState();
}

class _AdminClockinRecordsScreenState
    extends ConsumerState<AdminClockinRecordsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Name search — applied client-side on top of the date/shift/status filters.
  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> rows) {
    if (_query.isEmpty) return rows;
    final q = _query.toLowerCase();
    return rows.where((r) {
      final name =
          '${r['student_first_name'] ?? ''} ${r['student_last_name'] ?? ''}'
              .toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // The logged-in admin carries the school's shift config in their JWT-backed
    // user object. Whole-day schools never run morning/afternoon shifts.
    final isShiftSchool = ref.watch(userProvider)?.isShiftSchool ?? false;

    final selectedDate  = ref.watch(clockinDateProvider);
    final selectedShift = ref.watch(clockinShiftProvider);
    final statusFilter  = ref.watch(clockinStatusFilterProvider);
    final recordsAsync  = ref.watch(clockinRecordsProvider);

    final allRows  = recordsAsync.valueOrNull ?? const [];
    final filtered = _applySearch(allRows);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Attendance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBackToHome,
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Control panel (search + date + shift + status) ───────────
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by student name…',
                    hintStyle:
                        TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date navigation
                _DateNav(date: selectedDate),
                const SizedBox(height: 10),

                // Shift: filter chips for shift schools, locked badge otherwise
                if (isShiftSchool)
                  _ShiftChips(selected: selectedShift)
                else
                  const _WholeDayBadge(),
                const SizedBox(height: 8),

                // Status filter
                _StatusChips(selected: statusFilter),
                const SizedBox(height: 4),

                // Count
                Text(
                  _query.isEmpty
                      ? '${allRows.length} records'
                      : '${filtered.length} of ${allRows.length} records',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(message: e.toString()),
              data: (_) => filtered.isEmpty
                  ? _EmptyView(isSearch: _query.isNotEmpty)
                  : _RecordList(rows: filtered, isShiftSchool: isShiftSchool),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date navigation ─────────────────────────────────────────────────────────

class _DateNav extends ConsumerWidget {
  const _DateNav({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isToday = _isSameDay(date, DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(clockinDateProvider.notifier).state =
              date.subtract(const Duration(days: 1)),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2025),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              ref.read(clockinDateProvider.notifier).state = picked;
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: cs.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  isToday ? 'Today' : DateFormat('EEE, MMM d').format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          // Cannot navigate into the future — there are no records yet.
          onPressed: isToday
              ? null
              : () => ref.read(clockinDateProvider.notifier).state =
                  date.add(const Duration(days: 1)),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Whole-day badge (non-shift schools) ──────────────────────────────────────

class _WholeDayBadge extends StatelessWidget {
  const _WholeDayBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: cs.onSurface),
          const SizedBox(width: 6),
          Text(
            'Whole Day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shift chips (shift schools only) ─────────────────────────────────────────

class _ShiftChips extends ConsumerWidget {
  const _ShiftChips({required this.selected});
  final String? selected;

  static const _shifts = [
    (label: 'All',       value: null),
    (label: 'Morning',   value: 'morning'),
    (label: 'Afternoon', value: 'afternoon'),
    (label: 'Whole Day', value: 'whole_day'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _shifts.map((s) {
          final active = selected == s.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s.label),
              selected: active,
              selectedColor: cs.primary,
              labelStyle: TextStyle(
                color: active ? cs.onPrimary : cs.onSurface,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) =>
                  ref.read(clockinShiftProvider.notifier).state = s.value,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Status chips ─────────────────────────────────────────────────────────────

class _StatusChips extends ConsumerWidget {
  const _StatusChips({required this.selected});
  final String? selected;

  static const _statuses = [
    (label: 'All',     value: null),
    (label: 'Present', value: 'present'),
    (label: 'Early',   value: 'early'),
    (label: 'Late',    value: 'late'),
    (label: 'Excused', value: 'excused'),
    (label: 'Absent',  value: 'absent'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statuses.map((s) {
          final active = selected == s.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s.label),
              selected: active,
              selectedColor: s.value != null ? _statusColor(s.value!) : cs.primary,
              labelStyle: TextStyle(
                color: active ? Colors.white : cs.onSurface,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) =>
                  ref.read(clockinStatusFilterProvider.notifier).state = s.value,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Record list ─────────────────────────────────────────────────────────────

class _RecordList extends StatelessWidget {
  const _RecordList({required this.rows, required this.isShiftSchool});
  final List<Map<String, dynamic>> rows;
  final bool isShiftSchool;

  @override
  Widget build(BuildContext context) {
    // Sort by clock-in time ascending; records with no clock-in go to the bottom.
    final sorted = List<Map<String, dynamic>>.from(rows)
      ..sort((a, b) {
        final aTime = a['clock_in'] as String?;
        final bTime = b['clock_in'] as String?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

    return Column(
      children: [
        _SummaryStrip(rows: sorted),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _AttendanceCard(
              record: sorted[i],
              isShiftSchool: isShiftSchool,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Summary strip ────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.rows});
  final List<Map<String, dynamic>> rows;

  int _count(bool Function(String) test) =>
      rows.where((r) => test(r['status'] as String? ?? 'absent')).length;

  @override
  Widget build(BuildContext context) {
    final total   = rows.length;
    final present = _count((s) => s == 'present' || s == 'early');
    final late    = _count((s) => s == 'late');
    final absent  = _count((s) => s == 'absent');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _SummaryPill(label: 'Total',   value: total,   color: Colors.grey),
          const SizedBox(width: 8),
          _SummaryPill(label: 'Present', value: present, color: Colors.green),
          const SizedBox(width: 8),
          _SummaryPill(label: 'Late',    value: late,    color: Colors.orange),
          const SizedBox(width: 8),
          _SummaryPill(label: 'Absent',  value: absent,  color: Colors.red),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Attendance card ──────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record, required this.isShiftSchool});
  final Map<String, dynamic> record;
  final bool isShiftSchool;

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final firstName = record['student_first_name'] as String? ?? '';
    final lastName  = record['student_last_name']  as String? ?? '';
    final name      = '$firstName $lastName'.trim();
    final initials  = _initials(firstName, lastName);

    final clockIn   = _formatTime(record['clock_in']  as String?);
    final clockOut  = _formatTime(record['clock_out'] as String?);
    final duration  = _duration(
        record['clock_in'] as String?, record['clock_out'] as String?);
    final status    = record['status']     as String? ?? 'absent';
    final source    = record['source']     as String? ?? '';
    final shiftType = record['shift_type'] as String?;

    final timeLabel = duration != null
        ? '$clockIn → $clockOut  ·  $duration'
        : '$clockIn → $clockOut';

    return GestureDetector(
      onTap: () => showAttendanceEditSheet(context, record),
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
            UserAvatar(initials: initials, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty ? 'Unknown' : name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Shift pill only matters when the school runs shifts.
                      if (isShiftSchool && shiftType != null) ...[
                        _MetaPill(label: _shiftLabel(shiftType)),
                        const SizedBox(width: 6),
                      ],
                      if (_sourceLabel(source).isNotEmpty)
                        _MetaPill(label: _sourceLabel(source)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    final init = '$f$l';
    return init.isEmpty ? '?' : init;
  }

  String _formatTime(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('h:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return '—';
    }
  }

  String? _duration(String? inIso, String? outIso) {
    if (inIso == null || outIso == null) return null;
    try {
      final diff = DateTime.parse(outIso).difference(DateTime.parse(inIso));
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      if (h > 0) return '${h}h ${m}m';
      return '${m}m';
    } catch (_) {
      return null;
    }
  }

  String _shiftLabel(String shift) => switch (shift) {
        'morning'   => 'Morning',
        'afternoon' => 'Afternoon',
        'whole_day' => 'Whole Day',
        _           => shift,
      };

  // Source values come from the backend's resolveSource(role) — see
  // attendanceService.js: student → studentSelf, teacher → teacherBatch,
  // admin/principal → adminEdit. The badge shows WHO marked the record.
  String _sourceLabel(String source) => switch (source) {
        'studentSelf'  => 'Self',
        'teacherBatch' => 'Teacher',
        'adminEdit'    => 'Admin',
        _              => '',
      };
}

// ─── Status chip (on each card) ───────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = _statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

// ─── Meta pill (shift / source) ───────────────────────────────────────────────

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isSearch});
  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.event_busy_outlined,
            size: 56,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            isSearch
                ? 'No students match your search'
                : 'No attendance records for this date',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load records:\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
}

// ─── Shared status helpers ────────────────────────────────────────────────────

Color _statusColor(String status) => switch (status) {
      'present' => Colors.green,
      'early'   => Colors.teal,
      'late'    => Colors.orange,
      'absent'  => Colors.red,
      'excused' => Colors.blue,
      _         => Colors.grey,
    };

String _statusLabel(String status) => switch (status) {
      'present' => 'Present',
      'early'   => 'Early',
      'late'    => 'Late',
      'absent'  => 'Absent',
      'excused' => 'Excused',
      _         => status,
    };
