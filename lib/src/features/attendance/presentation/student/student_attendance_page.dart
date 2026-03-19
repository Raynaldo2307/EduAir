// Student view – Calendar tab (Attendance + Time Table).
// UX rules (Jan 2026):

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as dev;

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_error_handler.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/widgets/attendance_status_strip.dart';
import 'package:edu_air/src/features/attendance/widgets/attendance_history_list.dart';
import 'package:edu_air/src/features/attendance/presentation/student/attendance_providers.dart';
import 'package:edu_air/src/features/attendance/widgets/clock_button_row.dart';
import 'package:edu_air/src/features/attendance/application/late_reason_provider.dart';
import 'package:edu_air/src/features/attendance/presentation/student/widgets/timetable_tab.dart';
import 'package:edu_air/src/features/attendance/presentation/student/widgets/attendance_calendar.dart';
import 'package:edu_air/src/features/attendance/presentation/student/widgets/attendance_summary_row.dart';

/// Student view – Calendar tab (Attendance + Time Table).
class StudentAttendancePage extends ConsumerStatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  ConsumerState<StudentAttendancePage> createState() =>
      _StudentAttendancePageState();
}

class _StudentAttendancePageState extends ConsumerState<StudentAttendancePage> {
  /// 0 = Attendance, 1 = Time Table
  int _selectedTab = 0;

  /// Today in *school time* (coming from AttendanceService).
  late DateTime _today;

  bool _isSubmitting = false;

  /// Which month is currently shown in the calendar
  late DateTime _focusedMonth;

  AttendanceDay? _findDayByKey(List<AttendanceDay> days, String key) {
    for (final d in days) {
      if (d.dateKey == key) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _focusedMonth = DateTime(_today.year, _today.month, 1);
  }

  /// Returns true for Monday–Friday (school days).
  /// Holidays are not checked here — the Node API enforces those server-side.
  bool _isSchoolDay(DateTime date) =>
      date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ───────────────── Clock in / out ─────────────────

  Future<void> _handleClockIn() async {
    final user = ref.read(userProvider);
    if (user == null) {
      _showSnack('Please sign in to clock in.');
      return;
    }

    final schoolId = user.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      _showSnack('No school assigned to your account.');
      return;
    }

    final now = DateTime.now();
    if (!_isSchoolDay(now)) {
      _showSnack('No school today. You can only clock in on school days.');
      return;
    }

    // Decide late status
    final status = AttendanceDay.resolveStatusFromClockIn(
      clockIn: now,
      classStart: DateTime(now.year, now.month, now.day, 8, 0),
      grace: const Duration(minutes: 30),
    );

    String? lateReason;

    // If late, ask for a reason BEFORE calling the API
    if (status == AttendanceStatus.late) {
      lateReason = await _showLateReasonDialog();
      if (lateReason == null || lateReason.trim().isEmpty) {
        _showSnack('Clock in cancelled. Late reason is required.');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      dev.log(
        'Clock-in requested | uid=${user.uid}, now=${now.toIso8601String()}, '
        'status=${status.name}, lateReason="$lateReason"',
        name: 'StudentAttendance',
      );

      // Try to get GPS silently — don't block clock-in if unavailable.
      // TODO (post-capstone): enforce on-campus check with real school coordinates.
      AttendanceLocation location;
      try {
        location = await ref.read(attendanceGeoServiceProvider).currentAttendanceLocation();
      } catch (_) {
        location = const AttendanceLocation(lat: 0, lng: 0);
      }

      final repo = ref.read(attendanceApiRepositoryProvider);
      final shiftType = AttendanceDay.normalizeShiftType(user.currentShift);

      await repo.clockIn(
        shiftType: shiftType,
        lat: location.lat,
        lng: location.lng,
        lateReasonCode: lateReason,
      );

      dev.log('Clock-in success', name: 'StudentAttendance');

      ref.invalidate(studentTodayRawProvider);
      ref.invalidate(studentRecentAttendanceProvider);
      ref.invalidate(studentAttendanceSummaryProvider);

      _showSnack('Clock in recorded.');
    } catch (e, st) {
      dev.log('Clock in FAILED: $e', name: 'StudentAttendance', error: e, stackTrace: st);
      _showSnack(AppErrorHandler.message(e, context: 'ClockIn', stackTrace: st));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleClockOut() async {
    final user = ref.read(userProvider);
    if (user == null) {
      _showSnack('Please sign in to clock out.');
      return;
    }

    final schoolId = user.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      _showSnack('No school assigned to your account.');
      return;
    }

    final now = DateTime.now();
    if (!_isSchoolDay(now)) {
      _showSnack('No school today. You can only clock out on school days.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get today's MySQL record id from the raw provider
      final todayRaw = await ref.read(studentTodayRawProvider.future);
      final attendanceId = todayRaw?['id'] as int?;
      if (attendanceId == null) {
        _showSnack('No clock-in found for today. Please clock in first.');
        return;
      }

      // Try to get GPS silently — don't block clock-out if unavailable.
      // TODO (post-capstone): enforce on-campus check with real school coordinates.
      AttendanceLocation location;
      try {
        location = await ref.read(attendanceGeoServiceProvider).currentAttendanceLocation();
      } catch (_) {
        location = const AttendanceLocation(lat: 0, lng: 0);
      }

      final repo = ref.read(attendanceApiRepositoryProvider);

      await repo.clockOut(
        attendanceId: attendanceId,
        lat: location.lat,
        lng: location.lng,
      );

      ref.invalidate(studentTodayRawProvider);
      ref.invalidate(studentRecentAttendanceProvider);
      ref.invalidate(studentAttendanceSummaryProvider);

      _showSnack('Clock-out recorded.');
    } catch (e, st) {
      _showSnack(AppErrorHandler.message(e, context: 'ClockOut', stackTrace: st));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  // ───────────────── Late reason dialog (MoEYI dropdown) ─────────────────

  /// Shows a dialog with MoEYI late reason categories.
  ///
  /// Returns the selected reason code (e.g. 'transportation') or null if cancelled.
  /// Free-text is not permitted per MoEYI compliance requirements.
  Future<String?> _showLateReasonDialog() async {
    // Get the list of MoEYI reason options
    final options = ref.read(lateReasonOptionsProvider);
    String? selectedCode;

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(
                'Why are you late?',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a reason from the list below:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // MoEYI reason dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCode,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.6,
                          ),
                        ),
                      ),
                      items: options.map((option) {
                        return DropdownMenuItem<String>(
                          value: option.code,
                          child: Text(option.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCode = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
                TextButton(
                  onPressed: selectedCode != null
                      ? () => Navigator.of(ctx).pop(selectedCode)
                      : null,
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selectedCode != null
                          ? AppTheme.primaryColor
                          : AppTheme.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ───────────────── Scaffold ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTopTabs(context),
            _buildTopTabUnderline(context),
            const SizedBox(height: 12),
            Expanded(
              child: _selectedTab == 0
                  ? _buildAttendanceTab(context)
                  : const TimetableTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── UI Pieces ─────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Calendar',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTopTabs(BuildContext context) {
    final inactiveTabColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                alignment: Alignment.center,
                height: 32,
                child: Text(
                  'Attendance',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedTab == 0
                        ? AppTheme.primaryColor
                        : inactiveTabColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                alignment: Alignment.center,
                height: 32,
                child: Text(
                  'Time Table',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedTab == 1
                        ? AppTheme.primaryColor
                        : inactiveTabColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabUnderline(BuildContext context) {
    final inactiveUnderlineColor = AppTheme.outline.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              decoration: BoxDecoration(
                color: _selectedTab == 0
                    ? AppTheme.primaryColor
                    : inactiveUnderlineColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              decoration: BoxDecoration(
                color: _selectedTab == 1
                    ? AppTheme.primaryColor
                    : inactiveUnderlineColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── Attendance tab ─────────────────

  Widget _buildAttendanceTab(BuildContext context) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return const Center(child: Text('Please sign in to view attendance.'));
    }

    final summaryAsync = ref.watch(studentAttendanceSummaryProvider);
    final recentAsync = ref.watch(studentRecentAttendanceProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Non-blocking error banner — keeps the rest of the screen usable
        if (recentAsync.hasError || summaryAsync.hasError)
          _buildErrorBanner(recentAsync.error ?? summaryAsync.error),
        const SizedBox(height: 8),
        AttendanceCalendar(
          focusedMonth: _focusedMonth,
          today: _today,
          recentAsync: recentAsync,
          onPreviousMonth: () => setState(() {
            _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month - 1,
              1,
            );
          }),
          onNextMonth: () => setState(() {
            _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month + 1,
              1,
            );
          }),
        ),
        const SizedBox(height: 16),

        // ── Present / Absent / Event row ──
        summaryAsync.when(
          data: (summary) => AttendanceSummaryRow(
            presentCount: summary.presentCount,
            absentCount: summary.absentCount,
            eventCount: 0,
          ),
          loading: () => const AttendanceSummaryRow(
            presentCount: 0,
            absentCount: 0,
            eventCount: 0,
          ),
          error: (_, __) => const AttendanceSummaryRow(
            presentCount: 0,
            absentCount: 0,
            eventCount: 0,
          ),
        ),

        const SizedBox(height: 16),

        // ── Today status + Clock buttons ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: recentAsync.when(
            data: (days) {
              final todayKey = AttendanceDay.dateKeyFor(_today);

              // 1) Try to find today's record; may be null if not clocked in yet
              final todayDay = _findDayByKey(days, todayKey);

              // 2) Base flags from the API record (handle null safely)
              //
              // Teacher-marked: status is present-like but no clockInAt timestamp.
              // Self clock-in:  clockInAt is set by the student.
              // Both count as "clocked in" for button purposes.
              final selfClockedIn  = todayDay?.clockInAt != null;
              final teacherMarked  = (todayDay?.status.isPresentLike ?? false) &&
                                     todayDay?.clockInAt == null;
              final hasClockedIn   = selfClockedIn || teacherMarked;
              final hasClockedOut  = todayDay?.clockOutAt != null;

              // 3) Figure out if we should *treat* this as "done for today"
              final now = DateTime.now();

              // Only auto-complete if we're looking at "today" on the calendar
              final isToday = todayKey == AttendanceDay.dateKeyFor(now);

              // Choose your auto cut-off time (here: 16:30 = 4:30pm)
              final autoCutoff = DateTime(now.year, now.month, now.day, 16, 30);

              final shouldTreatAsDone =
                  isToday &&
                  hasClockedIn &&
                  !hasClockedOut &&
                  now.isAfter(autoCutoff);

              final isClockedIn  = hasClockedIn;
              // Teacher-marked records have no clockOut — treat as done so
              // the student doesn't see a "Clock Out" button for a manual entry.
              final isClockedOut = hasClockedOut || shouldTreatAsDone || teacherMarked;

              final isSchoolDay = _isSchoolDay(_today);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Button first, then status strip
                  ClockButtonsRow(
                    isClockedIn: isClockedIn,
                    isClockedOut: isClockedOut,
                    isSubmitting: _isSubmitting,
                    onClockIn: _handleClockIn,
                    onClockOut: _handleClockOut,
                  ),
                  const SizedBox(height: 12),
                  AttendanceStatusStrip(
                    today: todayDay,
                    isSchoolDay: isSchoolDay,
                  ),
                ],
              );
            },
            loading: () => const AttendanceStatusStrip(today: null),
            error: (_, __) => const AttendanceStatusStrip(today: null),
          ),
        ),

        const SizedBox(height: 8),

        // ── History list ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: recentAsync.when(
            data: (days) => AttendanceHistoryList(days: days),
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Text('Could not load attendance history'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(Object? error) {
    final message = error != null
        ? AppErrorHandler.message(error, context: 'Attendance')
        : 'Something went wrong. Please try again.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9E9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE25563).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE25563),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

