import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/widgets/attendance_status_strip.dart';
import 'package:edu_air/src/features/attendance/widgets/attendance_history_list.dart';

/// Student view – Calendar tab (Attendance + Time Table).
class StudentAttendancePage extends ConsumerStatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  ConsumerState<StudentAttendancePage> createState() =>
      _StudentAttendancePageState();
}

class _StudentAttendancePageState
    extends ConsumerState<StudentAttendancePage> {
  /// 0 = Attendance, 1 = Time Table
  int _selectedTab = 0;

  /// Today (for now we fake it – will be replaced by AttendanceService).
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface, // Fix: use existing surface token.
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
                  ? _buildAttendanceTab(context, user?.uid)
                  : _buildTimeTableTabPlaceholder(context),
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTopTabs(BuildContext context) {
    final inactiveTabColor = AppTheme.textPrimary.withOpacity(0.6); // Fix: AppTheme.textSecondary doesn't exist.
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
                        : inactiveTabColor, // Fix: replace missing textSecondary.
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
                        : inactiveTabColor, // Fix: replace missing textSecondary.
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
    final inactiveUnderlineColor = AppTheme.outline.withOpacity(0.3); // Fix: AppTheme.grey10 doesn't exist.
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
                    : inactiveUnderlineColor, // Fix: replace missing grey10.
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
                    : inactiveUnderlineColor, // Fix: replace missing grey10.
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── Attendance tab ─────────────────

  Widget _buildAttendanceTab(BuildContext context, String? studentUid) {
    // TEMP: fake data for layout. We will replace with real service calls.
    final fakeToday = AttendanceDay(
      dateKey: AttendanceDay.dateKeyFor(_today),
      studentUid: studentUid ?? 'demo-student',
      status: AttendanceStatus.early,
      clockInAt: DateTime(
        _today.year,
        _today.month,
        _today.day,
        8,
        10,
      ),
    );

    final fakeHistory = <AttendanceDay>[
      fakeToday,
      AttendanceDay(
        dateKey: AttendanceDay.dateKeyFor(_today.subtract(const Duration(days: 1))),
        studentUid: studentUid ?? 'demo-student',
        status: AttendanceStatus.late,
        clockInAt: DateTime(
          _today.year,
          _today.month,
          _today.day - 1,
          8,
          45,
        ),
        lateReason: 'Traffic',
      ),
      AttendanceDay(
        dateKey: AttendanceDay.dateKeyFor(_today.subtract(const Duration(days: 2))),
        studentUid: studentUid ?? 'demo-student',
        status: AttendanceStatus.absent,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 8),
        _buildCalendarPlaceholder(context),
        const SizedBox(height: 16),
        _buildSummaryRow(context,
            presentCount: 22, absentCount: 3, eventCount: 5),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AttendanceStatusStrip(
            today: fakeToday, // Fix: match AttendanceStatusStrip API.
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AttendanceHistoryList(
            days: fakeHistory,
            // Fix: onDayTap isn't supported by AttendanceHistoryList yet.
          ),
        ),
      ],
    );
  }

  /// For now, just a grey box. Later you can swap in `table_calendar`
  /// or any calendar widget you prefer.
  Widget _buildCalendarPlaceholder(BuildContext context) {
    final placeholderTextColor = AppTheme.textPrimary.withOpacity(0.6); // Fix: replace missing textSecondary.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant, // Fix: replace missing grey10.
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          'Calendar goes here (V1 placeholder)',
          style: TextStyle(color: placeholderTextColor), // Fix: replace missing textSecondary.
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
    final mutedTextColor = AppTheme.textPrimary.withOpacity(0.6); // Fix: replace missing textSecondary.
    return Center(
      child: Text(
        'Time Table coming soon',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mutedTextColor, // Fix: replace missing textSecondary.
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
            // You can swap in an SVG/icon later
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
                        color: AppTheme.textPrimary.withOpacity(0.6), // Fix: replace missing textSecondary.
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
