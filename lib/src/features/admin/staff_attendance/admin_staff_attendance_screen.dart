import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

class AdminStaffAttendanceScreen extends ConsumerStatefulWidget {
  const AdminStaffAttendanceScreen({super.key, this.onBackToHome});
  final VoidCallback? onBackToHome;

  @override
  ConsumerState<AdminStaffAttendanceScreen> createState() =>
      _AdminStaffAttendanceScreenState();
}

class _AdminStaffAttendanceScreenState
    extends ConsumerState<AdminStaffAttendanceScreen> {
  DateTime _date = DateTime.now();
  // Local status overrides — admin changes before saving: teacherId → status
  final Map<int, String> _overrides = {};
  bool _saving = false;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
        _overrides.clear();
      });
    }
  }

  // Cycles through the four statuses on each tap.
  void _cycleStatus(int teacherId, String? currentStatus) {
    const cycle = ['present', 'late', 'absent', 'excused'];
    final idx = cycle.indexOf(currentStatus ?? '');
    final next = cycle[(idx + 1) % cycle.length];
    setState(() => _overrides[teacherId] = next);
  }

  Future<void> _save(List<Map<String, dynamic>> rows) async {
    if (_overrides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Build records for every staff member that has a status (override or already saved).
      final records = <Map<String, dynamic>>[];
      for (final row in rows) {
        final id     = row['teacher_id'] as int;
        final status = _overrides[id] ?? row['status'] as String?;
        if (status != null) {
          records.add({'teacher_id': id, 'status': status});
        }
      }

      await ref
          .read(staffAttendanceApiRepositoryProvider)
          .batchMark(date: _dateKey, records: records);

      // Refresh from server and clear local overrides.
      ref.invalidate(staffAttendanceProvider(_dateKey));
      setState(() => _overrides.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved ${records.length} records'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final staffAsync = ref.watch(staffAttendanceProvider(_dateKey));
    final isToday    = _dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Staff Attendance'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: widget.onBackToHome,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              _overrides.clear();
              ref.invalidate(staffAttendanceProvider(_dateKey));
            },
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(staffAttendanceProvider(_dateKey)),
        ),
        data: (rows) {
          // Merge server statuses with local overrides for display.
          final effectiveStatuses = {
            for (final r in rows)
              (r['teacher_id'] as int):
                  _overrides[r['teacher_id'] as int] ?? r['status'] as String?,
          };

          final presentCount = effectiveStatuses.values.where((s) => s == 'present').length;
          final lateCount    = effectiveStatuses.values.where((s) => s == 'late').length;
          final absentCount  = effectiveStatuses.values.where((s) => s == 'absent').length;
          final unmarkedCount = effectiveStatuses.values.where((s) => s == null).length;

          return Column(
            children: [
              // ── Date bar ────────────────────────────────────────
              Container(
                color: cs.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 16, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            isToday
                                ? 'Today — ${DateFormat('MMM d, yyyy').format(_date)}'
                                : DateFormat('EEEE, MMM d, yyyy').format(_date),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down,
                              size: 18, color: cs.primary),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${rows.length} staff',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),

              // ── Summary chips ────────────────────────────────────
              Container(
                color: cs.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    _SummaryChip(label: 'Present', count: presentCount, color: Colors.green),
                    const SizedBox(width: 8),
                    _SummaryChip(label: 'Late', count: lateCount, color: Colors.orange),
                    const SizedBox(width: 8),
                    _SummaryChip(label: 'Absent', count: absentCount, color: Colors.red),
                    const SizedBox(width: 8),
                    _SummaryChip(
                      label: 'Unmarked',
                      count: unmarkedCount,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Staff list ───────────────────────────────────────
              Expanded(
                child: rows.isEmpty
                    ? Center(
                        child: Text('No staff found',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final row      = rows[i];
                          final id       = row['teacher_id'] as int;
                          final status   = effectiveStatuses[id];
                          final changed  = _overrides.containsKey(id);

                          return _StaffTile(
                            row: row,
                            status: status,
                            changed: changed,
                            onTap: () => _cycleStatus(id, status),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: staffAsync.hasValue
          ? FloatingActionButton.extended(
              heroTag: 'save_staff_attendance_fab',
              onPressed: _saving
                  ? null
                  : () => _save(staffAsync.asData!.value),
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save'),
              backgroundColor: _overrides.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            )
          : null,
    );
  }
}

// ─── Staff tile ───────────────────────────────────────────────────────────────

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.row,
    required this.status,
    required this.changed,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final String? status;
  final bool changed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final firstName  = row['first_name']  as String? ?? '';
    final lastName   = row['last_name']   as String? ?? '';
    final name       = '$firstName $lastName'.trim();
    final dept       = row['department']  as String? ?? '';
    final photoUrl   = row['photo_url']   as String?;
    final initials   = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
    final homeroom   = row['homeroom_class_name'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: changed
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: changed
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatar(initials: initials, photoUrl: photoUrl, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [dept, if (homeroom != null) 'Homeroom: $homeroom']
                        .join(' · '),
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusChip(status: status),
          ],
        ),
      ),
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'present' => ('Present', Colors.green),
      'late'    => ('Late',    Colors.orange),
      'absent'  => ('Absent',  Colors.red),
      'excused' => ('Excused', Colors.blue),
      _         => ('Tap to mark', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Summary chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(
      {required this.label, required this.count, required this.color});
  final String label;
  final int    count;
  final Color  color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ],
      );
}

// ─── Error view ───────────────────────────────────────────────────────────────

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
              Text('Failed to load staff attendance:\n$message',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
