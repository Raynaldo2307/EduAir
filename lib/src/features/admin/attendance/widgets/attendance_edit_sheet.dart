import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/admin/attendance/application/admin_attendance_provider.dart';
import 'package:edu_air/src/features/attendance/application/late_reason_provider.dart';

// Valid statuses the admin can set on a record.
const _kStatuses = ['early', 'present', 'late', 'excused', 'absent'];

/// Bottom sheet that lets admin/principal correct a student's attendance record.
/// Architecture: UI → AdminAttendanceNotifier → AttendanceApiRepository → Node API
///
/// Open it with [showAttendanceEditSheet] so the provider scope is carried into
/// the modal route (modals are pushed on a separate navigator).
class AttendanceEditSheet extends ConsumerStatefulWidget {
  const AttendanceEditSheet({super.key, required this.record});

  final Map<String, dynamic> record;

  @override
  ConsumerState<AttendanceEditSheet> createState() =>
      _AttendanceEditSheetState();
}

class _AttendanceEditSheetState extends ConsumerState<AttendanceEditSheet> {
  late String _selectedStatus;
  String? _selectedLateReason;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.record['status'] as String? ?? 'absent';
    // Pre-fill late reason if the record already has one.
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
    final cs        = Theme.of(context).colorScheme;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final notifier  = ref.watch(adminAttendanceNotifierProvider);
    final isLoading = notifier is AsyncLoading;

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
                  // Clear late reason when switching away from late.
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
                      // Guard: late requires a reason.
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

/// Opens the edit sheet, carrying the current provider scope into the modal route.
void showAttendanceEditSheet(
  BuildContext context,
  Map<String, dynamic> record,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: AttendanceEditSheet(record: record),
    ),
  );
}

// status → (label, background, foreground) for the selector chips.
(String, Color, Color) _statusColors(String status) => switch (status) {
      'early'   => ('Early',   const Color(0xFFD3F9D8), const Color(0xFF2F9E44)),
      'late'    => ('Late',    const Color(0xFFFFE8CC), const Color(0xFFE8590C)),
      'present' => ('Present', const Color(0xFFD0EBFF), const Color(0xFF1971C2)),
      'excused' => ('Excused', const Color(0xFFEDEDFF), const Color(0xFF5C5FC6)),
      _         => ('Absent',  const Color(0xFFFFE3E3), const Color(0xFFC92A2A)),
    };
