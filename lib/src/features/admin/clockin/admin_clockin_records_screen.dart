import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:edu_air/src/features/admin/clockin/application/clockin_records_provider.dart';

class AdminClockinRecordsScreen extends ConsumerWidget {
  const AdminClockinRecordsScreen({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs          = Theme.of(context).colorScheme;
    final selectedDate  = ref.watch(clockinDateProvider);
    final selectedShift = ref.watch(clockinShiftProvider);
    final statusFilter  = ref.watch(clockinStatusFilterProvider);
    final recordsAsync  = ref.watch(clockinRecordsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Clock-in Records'),
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
      ),
      body: Column(
        children: [
          _DateRow(date: selectedDate),
          const SizedBox(height: 4),
          _ShiftChips(selected: selectedShift),
          const SizedBox(height: 4),
          _StatusChips(selected: statusFilter),
          const Divider(height: 1),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => _ErrorView(message: e.toString()),
              data:    (rows) => rows.isEmpty
                  ? const _EmptyView()
                  : _RecordList(rows: rows),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date navigation ─────────────────────────────────────────────────────────

class _DateRow extends ConsumerWidget {
  const _DateRow({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isToday = _isSameDay(date, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isToday ? 'Today' : DateFormat('EEE, MMM d').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isToday
                ? null
                : () => ref.read(clockinDateProvider.notifier).state =
                    date.add(const Duration(days: 1)),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Shift chips ─────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
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
    (label: 'Late',    value: 'late'),
    (label: 'Absent',  value: 'absent'),
    (label: 'Excused', value: 'excused'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _statuses.map((s) {
          final active = selected == s.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s.label),
              selected: active,
              selectedColor: active && s.value != null
                  ? _statusColor(s.value!)
                  : cs.primary,
              labelStyle: TextStyle(
                color: active ? Colors.white : cs.onSurface,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) =>
                  ref.read(clockinStatusFilterProvider.notifier).state =
                      s.value,
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'present' => Colors.green,
        'late'    => Colors.orange,
        'absent'  => Colors.red,
        'excused' => Colors.blue,
        _         => Colors.grey,
      };
}

// ─── Record list ─────────────────────────────────────────────────────────────

class _RecordList extends StatelessWidget {
  const _RecordList({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    // Sort by clock_in time ascending; null clock_ins go to the bottom.
    final sorted = List<Map<String, dynamic>>.from(rows)
      ..sort((a, b) {
        final aTime = a['clock_in'] as String?;
        final bTime = b['clock_in'] as String?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 72, endIndent: 16),
      itemBuilder: (context, i) => _RecordTile(record: sorted[i]),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final firstName = record['student_first_name'] as String? ?? '';
    final lastName  = record['student_last_name']  as String? ?? '';
    final name      = '$firstName $lastName'.trim();
    final initials  = _initials(firstName, lastName);

    final clockIn  = _formatTime(record['clock_in']  as String?);
    final clockOut = _formatTime(record['clock_out'] as String?);
    final duration = _duration(record['clock_in'] as String?, record['clock_out'] as String?);
    final status   = record['status'] as String? ?? 'absent';
    final source   = record['source'] as String? ?? '';
    final classId  = record['class_id'];

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: _avatarColor(initials),
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name.isEmpty ? 'Unknown' : name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(status: status),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.login, size: 12, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(clockIn, style: _subtitleStyle(cs)),
              const Text('  →  '),
              Icon(Icons.logout, size: 12, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(clockOut, style: _subtitleStyle(cs)),
              if (duration != null) ...[
                const Text('  ·  '),
                Text(duration, style: _subtitleStyle(cs)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (classId != null)
                Text('Class $classId', style: _subtitleStyle(cs)),
              const SizedBox(width: 8),
              _SourceBadge(source: source),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _subtitleStyle(ColorScheme cs) => TextStyle(
        fontSize: 12,
        color: cs.onSurface.withValues(alpha: 0.6),
      );

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty  ? last[0].toUpperCase()  : '';
    return '$f$l';
  }

  Color _avatarColor(String initials) {
    final colors = [
      Colors.indigo, Colors.teal, Colors.deepPurple,
      Colors.blue, Colors.green, Colors.orange,
    ];
    final code = initials.codeUnits.fold(0, (a, b) => a + b);
    return colors[code % colors.length];
  }

  String _formatTime(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('h:mm a').format(dt);
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'present' => (Colors.green,  'Present'),
      'late'    => (Colors.orange, 'Late'),
      'absent'  => (Colors.red,    'Absent'),
      'excused' => (Colors.blue,   'Excused'),
      'early'   => (Colors.teal,   'Early'),
      _         => (Colors.grey,   status),
    };
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

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final label = switch (source) {
      'self_clockin' => 'Self',
      'teacher'      => 'Teacher',
      'admin'        => 'Admin',
      'batch'        => 'Batch',
      _              => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade600,
        ),
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
            Icon(Icons.schedule_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No records for this date',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
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
