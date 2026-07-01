import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

/// Which kind of attendance a screen is marking.
///
/// The daily register (SF4) and a lesson roll share the SAME marking body —
/// the row, the columns, the colours, the dark/light theme, the scrolling.
/// [AttendanceKind] is the single flag a screen flips for the handful of
/// things that genuinely differ (the header source, the save-button label,
/// which endpoint the save goes to). Everything below the header is identical
/// code, so the two screens cannot drift apart.
enum AttendanceKind { daily, lesson }

/// The only person-fields the attendance row actually renders.
///
/// The row is deliberately NOT welded to a student model: both a student
/// (`TeacherAttendanceStudent`) and, later, a teacher (staff attendance) can
/// fill this holder, so all three attendance surfaces reuse one row widget
/// with no adapter.
class AttendanceRowData {
  const AttendanceRowData({
    required this.id,
    required this.displayName,
    required this.initials,
    this.photoUrl,
  });

  final String id;
  final String displayName;
  final String initials;
  final String? photoUrl;
}

/// Width of each status column. The header and every row use this same value
/// so the circles line up in one vertical column the eye can scan straight
/// down — the calm, organised feel of the daily register.
const double kAttendanceStatusColumnWidth = 44;

/// The four status columns, in the fixed order shared by every attendance
/// screen: Present, Absent, Late, Excused.
class AttendanceColumnHeader extends StatelessWidget {
  const AttendanceColumnHeader({
    super.key,
    this.columnWidth = kAttendanceStatusColumnWidth,
  });

  final double columnWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headerStyle = TextStyle(
      fontSize: 10,
      color: cs.onSurface.withValues(alpha: 0.7),
      fontWeight: FontWeight.w600,
    );

    Widget col(String label) => SizedBox(
          width: columnWidth,
          child: Center(child: Text(label, style: headerStyle)),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.outline.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Name', style: headerStyle)),
          col('Present'),
          col('Absent'),
          col('Late'),
          col('Excused'),
        ],
      ),
    );
  }
}

/// One person's attendance row: avatar + name + the four status circles, with
/// the MoEYI late-reason area appearing only when Late is selected.
///
/// Shared by the daily register and the lesson roll (and later staff). Reads
/// only [AttendanceRowData]; all state lives in the parent screen, passed down
/// via [status]/[lateReason] and reported back through the callbacks.
class AttendanceStatusRow extends StatelessWidget {
  const AttendanceStatusRow({
    super.key,
    required this.data,
    required this.status,
    required this.onStatusSelected,
    required this.lateReasonOptions,
    this.columnWidth = kAttendanceStatusColumnWidth,
    this.lateReason,
    this.recordedReason,
    this.onLateReasonChanged,
  });

  final AttendanceRowData data;
  final AttendanceStatus? status;
  final double columnWidth;
  final ValueChanged<AttendanceStatus> onStatusSelected;
  final String? lateReason;

  /// A late reason already on record (e.g. a student self-reported it at
  /// clock-in). When set, it is shown LOCKED instead of an editable dropdown so
  /// the marker cannot silently overwrite it (DPA: no silent edits). Lesson and
  /// staff marking pass null, so they always get the editable dropdown.
  final String? recordedReason;
  final List<Map<String, String>> lateReasonOptions;
  final ValueChanged<String?>? onLateReasonChanged;

  /// Human-readable MoEYI label for a stored reason code.
  String _labelForCode(String code) {
    for (final option in lateReasonOptions) {
      if (option['code'] == code) return option['label'] ?? code;
    }
    return code;
  }

  /// Locked, read-only view of a reason already on record.
  Widget _buildRecordedReason(BuildContext context, String code) {
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFFE68A00);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 14, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Late Reason (MoEYI)',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _labelForCode(code),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Shared avatar: photo when present, else the same per-name coloured
    // 2-letter initials used on every other screen.
    final avatar = UserAvatar(
      initials: data.initials,
      photoUrl: data.photoUrl,
      radius: 20,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              _statusCell(AttendanceStatus.present, AppTheme.primaryColor),
              _statusCell(AttendanceStatus.absent, AppTheme.danger),
              _statusCell(AttendanceStatus.late, const Color(0xFFE68A00)),
              _statusCell(AttendanceStatus.excused, const Color(0xFFF2B233)),
            ],
          ),
          // The late-reason area only appears when Late is selected. If a
          // reason is already on record it is shown LOCKED; otherwise an
          // editable dropdown forces a MoEYI reason before saving.
          if (status == AttendanceStatus.late) ...[
            const SizedBox(height: 8),
            if (recordedReason != null)
              _buildRecordedReason(context, recordedReason!)
            else
              DropdownButtonFormField<String>(
                initialValue: lateReason,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Late Reason (MoEYI)',
                  labelStyle: const TextStyle(fontSize: 12),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFFE68A00).withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: const Color(0xFFE68A00).withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: const Color(0xFFE68A00).withValues(alpha: 0.4)),
                  ),
                ),
                hint: const Text('Select reason',
                    style: TextStyle(fontSize: 13)),
                items: lateReasonOptions
                    .map((option) => DropdownMenuItem<String>(
                          value: option['code'],
                          child: Text(option['label']!,
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: onLateReasonChanged,
              ),
          ],
        ],
      ),
    );
  }

  Widget _statusCell(AttendanceStatus cellStatus, Color activeColor) {
    return SizedBox(
      width: columnWidth,
      child: Center(
        child: _AttendanceIndicator(
          selected: status == cellStatus,
          activeColor: activeColor,
          onTap: () => onStatusSelected(cellStatus),
        ),
      ),
    );
  }
}

/// A single tappable status circle — filled check when selected, hollow ring
/// otherwise.
class _AttendanceIndicator extends StatelessWidget {
  const _AttendanceIndicator({
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? Icons.check_circle : Icons.circle_outlined;
    final color =
        selected ? activeColor : AppTheme.outline.withValues(alpha: 0.6);

    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Icon(icon, size: 22, color: color),
    );
  }
}
