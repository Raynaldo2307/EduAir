// Student view – Calendar tab (Attendance + Time Table).
// UX rules (Jan 2026):

import 'package:edu_air/src/features/attendance/domain/attendance_geo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as dev;

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/widgets/attendance_status_strip.dart';
import 'package:edu_air/src/features/attendance/widgets/attendance_history_list.dart';
import 'package:edu_air/src/features/attendance/presentation/student/attendance_providers.dart';
import 'package:edu_air/src/features/attendance/widgets/clock_button_row.dart';

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

  int _mockGpsStrikes = 0; // new

  AttendanceDay? _findDayByKey(List<AttendanceDay> days, String key) {
    for (final d in days) {
      if (d.dateKey == key) return d;
    }
    return null;
  }

  void _handleMockLocationError() async {
    _mockGpsStrikes++;

    if (_mockGpsStrikes >= 3) {
      // Harder UX after 3 strikes
      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Fake GPS detected'),
            content: const Text(
              'EduAir has detected repeated mock GPS locations.\n\n'
              'Please turn off any fake location or VPN apps and '
              'use your real location to clock in or out.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Softer UX for first 1–2 strikes
      _showSnack(
        'EduAir detected a mock GPS location.\n'
        'Please disable fake location apps and use your real location '
        'to check in.',
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Use the same time source as AttendanceService (school timezone).
    final service = ref.read(attendanceServiceProvider);
    final now = service.schoolNow();

    _today = now;
    _focusedMonth = DateTime(_today.year, _today.month, 1);
  }

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

    final service = ref.read(attendanceServiceProvider);
    final geo = ref.read(attendanceGeoServiceProvider);
    final school = ref.read(currentSchoolProvider);

    // Use the same time source as service
    final now = service.schoolNow();
    if (!service.isSchoolDay(now)) {
      _showSnack('No school today. You can only clock in on school days.');
      return;
    }

    // 0. Enforce on-campus rule (after confirming it's a school day)
    try {
      final onCampus = await geo.isUserOnCampus(school);
      if (!onCampus) {
        _showSnack('You must be on campus to clock in.');
        return;
      }
    } on LocationServiceDisabledException {
      _showSnack('Turn on location services to clock in.');
      return;
    } on PermissionDeniedException catch (e) {
      _showSnack(e.message);
      return;
    } on MockLocationsException {
      _handleMockLocationError();
      return;
    }

    // 1. Decide if this tap is "late" using the SAME logic as the service
    final status = AttendanceDay.resolveStatusFromClockIn(
      clockIn: now,
      classStart: DateTime(now.year, now.month, now.day, 8, 0),
      grace: const Duration(minutes: 30),
    );

    String? lateReason;

    // 2. If late, ask for a reason BEFORE calling the service.
    if (status == AttendanceStatus.late) {
      lateReason = await _showLateReasonDialog();
      if (lateReason == null || lateReason.trim().isEmpty) {
        _showSnack('Clock in cancelled. Late reason is required.');
        return;
      }
    }

    // 3. Call the service once with the correct lateReason.
    setState(() => _isSubmitting = true);

    try {
      dev.log(
        'Clock-in requested | schoolId=$schoolId, uid=${user.uid}, '
        'now=${now.toIso8601String()}, '
        'status=${status.name}, '
        'lateReason="$lateReason"',
        name: 'StudentAttendance',
      );

      // ✅ Use real device location via geo service
      final location = await geo.currentAttendanceLocation();

      final savedDay = await service.clockIn(
        schoolId: schoolId,
        studentUid: user.uid,
        location: location,
        classId: user.classId,
        className: user.className,
        gradeLevel: user.gradeLevelNumber,
        lateReason: lateReason,
        at: now,
      );

      dev.log(
        'Clock-in success | dateKey=${savedDay.dateKey}, '
        'savedStatus=${savedDay.status.name}, '
        'clockInAt=${savedDay.clockInAt?.toIso8601String()}',
        name: 'StudentAttendance',
      );

      // Refresh UI
      ref.invalidate(studentRecentAttendanceProvider);
      ref.invalidate(studentAttendanceSummaryProvider);

      _showSnack('Clock in recorded.');
    } on MockLocationsException {
      // 🔥 Use your nice UX instead of crashing
      _handleMockLocationError();
    } catch (e, st) {
      dev.log(
        'Clock in FAILED: $e',
        name: 'StudentAttendance',
        error: e,
        stackTrace: st,
      );
      _showSnack('Could not clock in: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      dev.log(
        'Clock-in flow finished | isSubmitting=$_isSubmitting',
        name: 'StudentAttendance',
      );
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

    final service = ref.read(attendanceServiceProvider);
    final geo = ref.read(attendanceGeoServiceProvider);
    final school = ref.read(currentSchoolProvider);

    final now = service.schoolNow();
    if (!service.isSchoolDay(now)) {
      _showSnack('No school today. You can only clock out on school days.');
      return;
    }

    // 🔹 0. Enforce on-campus rule BEFORE clock-out
    try {
      final onCampus = await geo.isUserOnCampus(school);
      if (!onCampus) {
        _showSnack('You must be on campus to clock out.');
        return;
      }
    } on LocationServiceDisabledException {
      _showSnack('Turn on location services to clock out.');
      return;
    } on PermissionDeniedException catch (e) {
      _showSnack(e.message);
      return;
    } on MockLocationsException {
      _handleMockLocationError();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ✅ Use real device location via geo service
      final location = await geo.currentAttendanceLocation();

      await service.clockOut(
        schoolId: schoolId,
        studentUid: user.uid,
        location: location,
        classId: user.classId,
        className: user.className,
        gradeLevel: user.gradeLevelNumber,
      );

      // Refresh UI data
      ref.invalidate(studentRecentAttendanceProvider);
      ref.invalidate(studentAttendanceSummaryProvider);

      _showSnack('Clock-out recorded.');
    } on MockLocationsException {
      _handleMockLocationError();
    } catch (e) {
      _showSnack('Could not clock out: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ───────────────── Late reason dialog ─────────────────

  Future<String?> _showLateReasonDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(
            'Late reason',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Explain why you are late...',
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.all(12),
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
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.6,
                  ),
                ),
              ),
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
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text(
                'Submit',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────── Scaffold ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
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
                  : _buildTimeTableTabPlaceholder(context),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── UI Pieces ─────────────────

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Calendar',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTopTabs(BuildContext context) {
    final inactiveTabColor = AppTheme.textPrimary.withValues(alpha: 0.6);

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

    // Use the same school time source for the "auto-done after 16:30" logic.
    final service = ref.read(attendanceServiceProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 8),
        _buildCalendarBox(context, recentAsync),
        const SizedBox(height: 16),

        // ── Present / Absent / Event row ──
        summaryAsync.when(
          data: (summary) => _buildSummaryRow(
            context,
            presentCount: summary.presentCount,
            absentCount: summary.absentCount,
            eventCount: 0,
          ),
          loading: () => _buildSummaryRow(
            context,
            presentCount: 0,
            absentCount: 0,
            eventCount: 0,
          ),
          error: (_, __) => _buildSummaryRow(
            context,
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

              // 2) Base flags from Firestore (handle null safely)
              final hasClockedIn = todayDay?.clockInAt != null;
              final hasClockedOut = todayDay?.clockOutAt != null;

              // 3) Figure out if we should *treat* this as "done for today"
              final now = service.schoolNow();

              // Only auto-complete if we're looking at "today" on the calendar
              final isToday = todayKey == AttendanceDay.dateKeyFor(now);

              // Choose your auto cut-off time (here: 16:30 = 4:30pm)
              final autoCutoff = DateTime(now.year, now.month, now.day, 16, 30);

              final shouldTreatAsDone =
                  isToday &&
                  hasClockedIn &&
                  !hasClockedOut &&
                  now.isAfter(autoCutoff);

              final isClockedIn = hasClockedIn;
              final isClockedOut = hasClockedOut || shouldTreatAsDone;

              // 👇 ask the service if *today* is a school day
              final isSchoolDay = service.isSchoolDay(_today);

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

  /// Calendar
  Widget _buildCalendarBox(
    BuildContext context,
    AsyncValue<List<AttendanceDay>> recentAsync,
  ) {
    final theme = Theme.of(context);

    const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.outline.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(12),
        child: recentAsync.when(
          data: (days) {
            // ── Month math ──
            final firstDayOfMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              1,
            );
            final lastDayOfMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month + 1,
              0,
            );
            final daysInMonth = lastDayOfMonth.day;
            final firstWeekday = firstDayOfMonth.weekday; // 1..7 (Mon..Sun)

            // total cells and rows we need
            final totalCells = (firstWeekday - 1) + daysInMonth;
            final weeks = (totalCells / 7).ceil();

            // current week highlight (based on "today")
            final weekStart = _today.subtract(
              Duration(days: _today.weekday - 1),
            );
            final weekEnd = weekStart.add(const Duration(days: 6));

            final monthLabel =
                '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}';

            // build table rows
            int cellIndex = 0;
            final rows = <TableRow>[];
            for (int week = 0; week < weeks; week++) {
              rows.add(
                TableRow(
                  children: List.generate(7, (col) {
                    const cellHeight = 40.0;

                    final dayNumber = cellIndex - (firstWeekday - 1) + 1;
                    cellIndex++;

                    // cells before day 1 and after last day are empty
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox(height: cellHeight);
                    }

                    final cellDate = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month,
                      dayNumber,
                    );
                    final key = AttendanceDay.dateKeyFor(cellDate);
                    final dayData = _findDayByKey(days, key);
                    final status = dayData?.status ?? AttendanceStatus.absent;

                    final inHighlightedRange =
                        !cellDate.isBefore(weekStart) &&
                        !cellDate.isAfter(weekEnd);

                    Color dotColor;
                    if (status.isPresentLike) {
                      dotColor = const Color(0xFF2F9E44);
                    } else if (status == AttendanceStatus.late) {
                      dotColor = const Color(0xFFE8590C);
                    } else {
                      dotColor = AppTheme.outline.withValues(alpha: 0.4);
                    }

                    final isToday =
                        AttendanceDay.dateKeyFor(cellDate) ==
                        AttendanceDay.dateKeyFor(_today);

                    return SizedBox(
                      height: cellHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 2.5,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: inHighlightedRange
                                ? AppTheme.heroStripBackground.withValues(
                                    alpha: 0.7,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 1.4,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayNumber.toString(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }

            return Column(
              children: [
                // ── Header: month label + prev/next ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month - 1,
                            1,
                          );
                        });
                      },
                    ),
                    Text(
                      monthLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month + 1,
                            1,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Weekday row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          weekdayShort[index],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textPrimary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),

                // ── Month table ──
                Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: rows,
                ),
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => Center(
            child: Text(
              'Calendar unavailable',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required int presentCount,
    required int absentCount,
    required int eventCount,
  }) {
    return Row(
      children: [
        const SizedBox(width: 20),
        Expanded(
          child: _SummaryCard(
            label: 'Present',
            count: presentCount,
            background: const Color(0xFFE7F5FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            label: 'Absent',
            count: absentCount,
            background: const Color(0xFFFFE9E9),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            label: 'Event',
            count: eventCount,
            background: const Color(0xFFEDEDFF),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  // ───────────────── Time table tab (placeholder) ─────────────────

  Widget _buildTimeTableTabPlaceholder(BuildContext context) {
    final mutedTextColor = AppTheme.textPrimary.withValues(alpha: 0.6);

    return Center(
      child: Text(
        'Time Table coming soon',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: mutedTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Small card used for Present / Absent / Event counts.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.background,
  });

  final String label;
  final int count;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_outline,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  count.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
