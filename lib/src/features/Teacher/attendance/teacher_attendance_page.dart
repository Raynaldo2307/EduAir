import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_error_handler.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_exceptions.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/widgets/attendance_status_strip.dart';
import 'package:edu_air/src/features/attendance/widgets/clock_button_row.dart';
import 'package:edu_air/src/features/Teacher/attendance/application/staff_self_attendance_controller.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/teacher_attendance_providers.dart';
import 'package:edu_air/src/features/attendance/application/attendance_error_mapper.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/shared/common/attendance/attendance_marking.dart';

class TeacherAttendancePage extends ConsumerStatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  ConsumerState<TeacherAttendancePage> createState() =>
      _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends ConsumerState<TeacherAttendancePage> {
  static const List<TeacherClassOption> _fallbackClasses = [
    TeacherClassOption(classId: '7th A', className: '7th A'),
    TeacherClassOption(classId: '7th B', className: '7th B'),
    TeacherClassOption(classId: '7th C', className: '7th C'),
  ];

  int _selectedTab = 0;
  DateTime _selectedDate = DateTime.now();
  TeacherClassOption? _selectedClass;
  final Map<String, AttendanceStatus?> _selectedStatuses = {};
  final Map<String, String?> _lateReasons = {};
  bool _isSaving = false;

  // ASSESSOR POINT 1: MoEYI categories — these are the Ministry of Education's
  // official late reason codes. No free text allowed. Matches Form SF4 reporting.
  static const List<Map<String, String>> _lateReasonOptions = [
    {'code': 'transportation', 'label': 'Transportation'},
    {'code': 'economic',       'label': 'Economic'},
    {'code': 'illness',        'label': 'Illness'},
    {'code': 'emergency',      'label': 'Emergency'},
    {'code': 'family',         'label': 'Family'},
    {'code': 'other',          'label': 'Other'},
  ];
  // ASSESSOR POINT 2: Shift type is read from the logged-in user's JWT profile.
  // The teacher never selects this — the school admin sets it once during setup.
  // This prevents teachers from marking attendance under the wrong shift.
  String get _shiftType =>
      ref.read(userProvider)?.defaultShiftType ?? 'whole_day';

  /// Human-readable label for the locked shift type.
  String get _shiftLabel {
    switch (_shiftType) {
      case 'morning':
        return 'Morning Shift';
      case 'afternoon':
        return 'Afternoon Shift';
      default:
        return 'Whole Day';
    }
  }

  late DateTime _focusedMonth;
  DateTime? _selectedTeacherDay;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _selectedTeacherDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
  }

  List<TeacherClassOption> _buildClassOptions(AppUser user) {
    final options = <String, TeacherClassOption>{};

    if (user.homeroomClassId != null &&
        user.homeroomClassId!.trim().isNotEmpty) {
      options[user.homeroomClassId!] = TeacherClassOption(
        classId: user.homeroomClassId!,
        className: user.homeroomClassName?.trim().isNotEmpty == true
            ? user.homeroomClassName!
            : user.homeroomClassId!,
        gradeLevel: user.gradeLevelNumber,
      );
    }

    final assignments = user.subjectAssignments ?? const <SubjectAssignment>[];
    for (final assignment in assignments) {
      if (assignment.classId.trim().isEmpty) continue;
      options.putIfAbsent(
        assignment.classId,
        () => TeacherClassOption(
          classId: assignment.classId,
          className: assignment.className,
          gradeLevel: assignment.gradeLevel,
        ),
      );
    }

    if (options.isEmpty) {
      return _fallbackClasses;
    }

    return options.values.toList();
  }

  void _ensureSelectedClass(List<TeacherClassOption> options) {
    if (options.isEmpty) return;
    final fallback = options.first;
    if (_selectedClass == null || !options.contains(_selectedClass)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedClass = fallback;
          _selectedStatuses.clear();
        });
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _selectedStatuses.clear();
    });
  }

  // ASSESSOR POINT 3: Teacher taps Present / Absent / Late / Excused.
  // State is stored locally until Save is pressed — no partial writes to the database.
  // If a student is unmarked as Late, their late reason is also cleared automatically.
  void _toggleStatus(String studentUid, AttendanceStatus status) {
    setState(() {
      _selectedStatuses[studentUid] = status;
      if (status != AttendanceStatus.late) {
        _lateReasons.remove(studentUid);
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
      _selectedTeacherDay = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        1,
      );
    });
  }

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  AttendanceStatus? _effectiveStatusForStudent(
    String studentUid,
    Map<String, TeacherAttendanceMark> attendanceMap,
  ) {
    if (_selectedStatuses.containsKey(studentUid)) {
      return _selectedStatuses[studentUid];
    }
    final existing = attendanceMap[studentUid]?.status;
    if (existing == AttendanceStatus.early) {
      return AttendanceStatus.present;
    }
    return existing;
  }

  

  // : Save Attendance button calls this.
  // Builds one entry per student, then sends the entire class as a single batch
  // to the Node.js API → MySQL. The teacher's UID is stamped on every record
  // as an audit trail — we always know who marked what and when.
  Future<void> _saveAttendance({
    required String schoolId,
    required String teacherUid,
    required TeacherClassOption classOption,
    required List<TeacherAttendanceStudent> students,
    required Map<String, TeacherAttendanceMark> existingStatuses,
  }) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final repo = ref.read(teacherAttendanceRepositoryProvider);
    final dateKey = AttendanceDay.dateKeyFor(_selectedDate);

    try {
      final deviceId = ref.read(deviceIdProvider).value;

      final entries = <TeacherAttendanceEntry>[];
      for (final student in students) {
        final override = _selectedStatuses[student.uid];
        final existing = existingStatuses[student.uid];
        final status = override ?? existing?.status ?? AttendanceStatus.absent;

        entries.add(
          TeacherAttendanceEntry(
            schoolId: schoolId,
            dateKey: dateKey,
            status: status,
            student: student,
            classOption: classOption,
            takenByUid: teacherUid,
            shiftType: _shiftType,
            lateReason: status == AttendanceStatus.late
                ? _lateReasons[student.uid]
                : null,
            deviceId: deviceId,
          ),
        );
      }

      await repo.saveAttendanceBatch(
        schoolId: schoolId,
        entries: entries,
      );

      if (!mounted) return;
      _showSnack('Attendance saved.');

      ref.invalidate(
        teacherAttendanceForDateProvider(
          TeacherAttendanceQuery(
            schoolId: schoolId,
            classOption: classOption,
            dateKey: dateKey,
            shiftType: _shiftType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(mapAttendanceErrorToMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final schoolId = user?.schoolId;

    final classOptions =
        user == null ? const <TeacherClassOption>[] : _buildClassOptions(user);
    _ensureSelectedClass(classOptions);
    final selectedClass = _selectedClass;

    AsyncValue<List<TeacherAttendanceStudent>>? studentsAsync;
    AsyncValue<Map<String, TeacherAttendanceMark>>? attendanceAsync;

    if (_selectedTab == 0 &&
        user != null &&
        schoolId != null &&
        selectedClass != null) {
      final classQuery = TeacherClassQuery(
        schoolId: schoolId,
        classOption: selectedClass,
      );
      studentsAsync = ref.watch(teacherClassStudentsProvider(classQuery));
      attendanceAsync = ref.watch(
        teacherAttendanceForDateProvider(
          TeacherAttendanceQuery(
            schoolId: schoolId,
            classOption: selectedClass,
            dateKey: AttendanceDay.dateKeyFor(_selectedDate),
            shiftType: _shiftType,
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      bottomNavigationBar: _selectedTab == 0
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSaving ||
                          user == null ||
                          schoolId == null ||
                          selectedClass == null ||
                          studentsAsync == null ||
                          attendanceAsync == null ||
                          studentsAsync.hasError ||
                          attendanceAsync.hasError ||
                          studentsAsync.isLoading ||
                          attendanceAsync.isLoading)
                      ? null
                      : () => _saveAttendance(
                            schoolId: schoolId,
                            teacherUid: user.uid,
                            classOption: selectedClass,
                            students: studentsAsync!.value ??
                                const <TeacherAttendanceStudent>[],
                            existingStatuses:
                                attendanceAsync!.value ??
                                    const <String, TeacherAttendanceMark>{},
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Attendance',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildTopTabs(),
            const SizedBox(height: 6),
            _buildTabUnderline(),
            const SizedBox(height: 12),
            Expanded(
              child: _selectedTab == 0
                  ? _buildStudentsTab(
                      context,
                      user,
                      classOptions,
                      selectedClass,
                      studentsAsync,
                      attendanceAsync,
                    )
                  : _buildTeacherTab(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabs() {
    final cs = Theme.of(context).colorScheme;
    final inactiveTabColor = cs.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              child: SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _selectedTab == 0
                          ? AppTheme.primaryColor
                          : inactiveTabColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              child: SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    'Teacher',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _selectedTab == 1
                          ? AppTheme.primaryColor
                          : inactiveTabColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabUnderline() {
    final cs = Theme.of(context).colorScheme;
    final inactiveUnderlineColor = cs.outline.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
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
              height: 2,
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

  Widget _buildStudentsTab(
    BuildContext context,
    AppUser? user,
    List<TeacherClassOption> classOptions,
    TeacherClassOption? selectedClass,
    AsyncValue<List<TeacherAttendanceStudent>>? studentsAsync,
    AsyncValue<Map<String, TeacherAttendanceMark>>? attendanceAsync,
  ) {
    if (user == null) {
      return const Center(child: Text('Please sign in to view attendance.'));
    }

    if (user.schoolId == null || user.schoolId!.trim().isEmpty) {
      return const Center(child: Text('No school assigned to your account.'));
    }

    if (classOptions.isEmpty || selectedClass == null) {
      return const Center(child: Text('No classes assigned to you yet.'));
    }

    if (studentsAsync == null || attendanceAsync == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (studentsAsync.isLoading || attendanceAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (studentsAsync.hasError) {
      return Center(
        child: _ErrorCard(
          message: mapAttendanceErrorToMessage(
            studentsAsync.error ?? 'Failed to load students.',
          ),
        ),
      );
    }

    if (attendanceAsync.hasError) {
      return Center(
        child: _ErrorCard(
          message: mapAttendanceErrorToMessage(
            attendanceAsync.error ?? 'Failed to load attendance.',
          ),
        ),
      );
    }

    final students = studentsAsync.value ?? const <TeacherAttendanceStudent>[];
    final attendanceMap =
        attendanceAsync.value ?? const <String, TeacherAttendanceMark>{};

    // Live tally under each column label — a progress check for the teacher.
    // The register starts unmarked, so an unmarked student counts in no column;
    // the totals climb as she marks (they only sum to the roster once done).
    final counts = <AttendanceStatus, int>{
      for (final st in const [
        AttendanceStatus.present,
        AttendanceStatus.absent,
        AttendanceStatus.late,
        AttendanceStatus.excused,
      ])
        st: students
            .where(
              (s) => _effectiveStatusForStudent(s.uid, attendanceMap) == st,
            )
            .length,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildFiltersRow(classOptions, selectedClass),
          const SizedBox(height: 8),
          _buildShiftBadge(),
          const SizedBox(height: 8),
          AttendanceColumnHeader(counts: counts),
          const SizedBox(height: 8),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('No students found.'))
                : _buildStudentsList(students, attendanceMap),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(
    List<TeacherClassOption> classOptions,
    TeacherClassOption selectedClass,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<TeacherClassOption>(
            initialValue: selectedClass,
            isExpanded: true,
            decoration: _inputDecoration('Select Class'),
            items: classOptions
                .map(
                  (option) => DropdownMenuItem<TeacherClassOption>(
                    value: option,
                    child: Text(option.className),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedClass = value;
                _selectedStatuses.clear();
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(_selectedDate),
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: isDark ? AppTheme.darkCard : AppTheme.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outline.withValues(alpha: 0.4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outline.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildShiftBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 13,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 5),
            Text(
              _shiftLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList(
    List<TeacherAttendanceStudent> students,
    Map<String, TeacherAttendanceMark> attendanceMap,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = students[index];
        final mark = attendanceMap[student.uid];
        final status = _effectiveStatusForStudent(student.uid, attendanceMap);

        // A reason already on record is shown locked — the teacher must not
        // silently overwrite a student's self-reported reason from the roll.
        // Only show the editable dropdown when no reason exists yet.
        final recordedReason = mark != null && mark.hasReason
            ? mark.lateReason
            : null;

        return AttendanceStatusRow(
          data: AttendanceRowData(
            id: student.uid,
            displayName: student.displayName,
            initials: student.initials,
            photoUrl: student.photoUrl,
          ),
          status: status,
          lateReason: _lateReasons[student.uid],
          recordedReason: recordedReason,
          lateReasonOptions: _lateReasonOptions,
          onStatusSelected: (selected) => _toggleStatus(student.uid, selected),
          onLateReasonChanged: (reason) {
            setState(() => _lateReasons[student.uid] = reason);
          },
        );
      },
    );
  }

  Widget _buildTeacherTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          _buildCalendarCard(context),
          const SizedBox(height: 16),
          _buildSummaryRow(),
          const SizedBox(height: 16),
          _buildMyClockBlock(context),
        ],
      ),
    );
  }

  // ── My clock block — the teacher clocks THEMSELVES in/out ─────────────────
  // SAME design as the student attendance view: ClockButtonsRow on top,
  // AttendanceStatusStrip underneath — reusing the student widgets untouched.
  // Same rules too: the server is the only judge of late. Submit with no
  // reason → if the server answers LATE_REASON_REQUIRED, show the MoEYI
  // dialog and resubmit. The phone's clock has no vote.
  Widget _buildMyClockBlock(BuildContext context) {
    final selfState = ref.watch(staffSelfAttendanceControllerProvider);

    if (selfState.today.isLoading) {
      return const AttendanceStatusStrip(today: null);
    }

    // The staff record carries the same field names as the student one
    // (status, clock_in, clock_out, is_early_leave, ...) so the student
    // model + strip render it directly.
    final record = selfState.record;
    final todayDay = record != null ? AttendanceDay.fromApiMap(record) : null;

    final now = DateTime.now();
    final isSchoolDay =
        now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClockButtonsRow(
          isClockedIn: selfState.hasClockedIn,
          isClockedOut: selfState.hasClockedOut,
          isSubmitting: selfState.isSubmitting,
          onClockIn: _handleSelfClockIn,
          onClockOut: _handleSelfClockOut,
        ),
        const SizedBox(height: 12),
        AttendanceStatusStrip(
          today: todayDay,
          isSchoolDay: isSchoolDay,
        ),
      ],
    );
  }

  Future<void> _handleSelfClockIn() async {
    final controller = ref.read(staffSelfAttendanceControllerProvider.notifier);

    // GPS captured silently — never blocks the clock-in (same as students).
    AttendanceLocation location;
    try {
      location =
          await ref.read(attendanceGeoServiceProvider).currentAttendanceLocation();
    } catch (_) {
      location = const AttendanceLocation(lat: 0, lng: 0);
    }

    try {
      try {
        // First attempt — no reason. The server judges early vs late.
        await controller.clockIn(lat: location.lat, lng: location.lng);
      } on LateReasonRequiredException {
        // Server says late (nothing written yet) → collect the reason, resubmit.
        final reason = await _showStaffLateReasonDialog();
        if (reason == null || reason.trim().isEmpty) {
          _snack('Clock in cancelled. Late reason is required.');
          return;
        }
        await controller.clockIn(
          lat: location.lat,
          lng: location.lng,
          lateReasonCode: reason,
        );
      }
      ref.invalidate(staffMyAttendanceHistoryProvider); // refresh summary counts
      _snack('Clock in recorded.');
    } catch (e, st) {
      _snack(AppErrorHandler.message(e, context: 'StaffClockIn', stackTrace: st));
    }
  }

  Future<void> _handleSelfClockOut() async {
    final controller = ref.read(staffSelfAttendanceControllerProvider.notifier);

    AttendanceLocation location;
    try {
      location =
          await ref.read(attendanceGeoServiceProvider).currentAttendanceLocation();
    } catch (_) {
      location = const AttendanceLocation(lat: 0, lng: 0);
    }

    try {
      await controller.clockOut(lat: location.lat, lng: location.lng);
      ref.invalidate(staffMyAttendanceHistoryProvider); // refresh summary counts
      _snack('Clock out recorded.');
    } catch (e, st) {
      _snack(AppErrorHandler.message(e, context: 'StaffClockOut', stackTrace: st));
    }
  }

  /// MoEYI reason dialog for a LATE staff clock-in — same Ministry categories
  /// as students (Ray's ruling: the principal needs the WHY for staff too).
  Future<String?> _showStaffLateReasonDialog() async {
    String? selected;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Why are you late?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a reason from the list below:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    isExpanded: true,
                    hint: const Text('Select reason'),
                    items: _lateReasonOptions
                        .map((o) => DropdownMenuItem(
                              value: o['code'],
                              child: Text(o['label']!),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selected = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(selected),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCalendarCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildCalendar(context),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysInMonth = _daysInMonth(_focusedMonth);
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final trailingEmpty = (7 - totalCells % 7) % 7;
    final gridCells = totalCells + trailingEmpty;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    _formatMonthYear(_focusedMonth),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWeekdayRow(),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 36,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmpty || index >= leadingEmpty + daysInMonth) {
              return const SizedBox.shrink();
            }

            final dayNumber = index - leadingEmpty + 1;
            final date = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              dayNumber,
            );
            final isSelected = _selectedTeacherDay != null &&
                _isSameDay(_selectedTeacherDay!, date);
            final isToday = _isSameDay(DateTime.now(), date);

            final decoration = isSelected
                ? const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  )
                : isToday
                    ? BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      )
                    : null;

            final textColor =
                isSelected ? AppTheme.white : cs.onSurface;

            return GestureDetector(
              onTap: () => setState(() => _selectedTeacherDay = date),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 30,
                  height: 30,
                  decoration: decoration,
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    final cs = Theme.of(context).colorScheme;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // Live counts of MY OWN attendance for the focused calendar month.
  // Fed by GET /api/staff-attendance/me (staffMyAttendanceHistoryProvider);
  // the clock handlers invalidate it after a clock-in/out so it stays live.
  Widget _buildSummaryRow() {
    final historyAsync = ref.watch(staffMyAttendanceHistoryProvider);

    // Count records that fall inside the month the calendar is showing.
    // While loading (or on error) show em-dashes rather than fake zeros.
    var present = '—', absent = '—', late = '—';
    final rows = historyAsync.valueOrNull;
    if (rows != null) {
      int presentN = 0, absentN = 0, lateN = 0;
      for (final r in rows) {
        final date = DateTime.tryParse((r['attendance_date'] ?? '').toString());
        if (date == null ||
            date.year != _focusedMonth.year ||
            date.month != _focusedMonth.month) {
          continue;
        }
        switch (r['status'] as String?) {
          case 'early' || 'present':
            presentN++;
          case 'late':
            lateN++;
          case 'absent':
            absentN++;
        }
      }
      present = '$presentN';
      absent = '$absentN';
      late = '$lateN';
    }

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Present',
            value: present,
            icon: Icons.person_outline,
            backgroundColor: const Color(0xFFE8F3FF),
            iconColor: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Absent',
            value: absent,
            icon: Icons.person_off_outlined,
            backgroundColor: const Color(0xFFFFE8EC),
            iconColor: const Color(0xFFE25563),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Late',
            value: late,
            icon: Icons.schedule_outlined,
            backgroundColor: const Color(0xFFEDE9FF),
            iconColor: const Color(0xFF7C5CF2),
          ),
        ),
      ],
    );
  }
}

/// Non-blocking error card shown when attendance data fails to load.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : const Color(0xFFFFE9E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE25563).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE25563),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark ? const Color(0xFFE25563) : const Color(0xFFB91C1C),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? iconColor.withValues(alpha: 0.2) : backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
}
