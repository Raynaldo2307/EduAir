import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/teacher_attendance_providers.dart';
import 'package:edu_air/src/models/app_user.dart';

class TeacherAttendancePage extends ConsumerStatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  ConsumerState<TeacherAttendancePage> createState() =>
      _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends ConsumerState<TeacherAttendancePage> {
  static const double _statusColumnWidth = 56;
  static const List<TeacherClassOption> _fallbackClasses = [
    TeacherClassOption(classId: '7th A', className: '7th A'),
    TeacherClassOption(classId: '7th B', className: '7th B'),
    TeacherClassOption(classId: '7th C', className: '7th C'),
  ];

  int _selectedTab = 0;
  DateTime _selectedDate = DateTime.now();
  TeacherClassOption? _selectedClass;
  final Map<String, AttendanceStatus?> _selectedStatuses = {};
  bool _isSaving = false;
  String? _shiftType = 'whole_day';

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

  void _toggleStatus(String studentUid, AttendanceStatus status) {
    setState(() => _selectedStatuses[studentUid] = status);
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
    Map<String, AttendanceStatus> attendanceMap,
  ) {
    if (_selectedStatuses.containsKey(studentUid)) {
      return _selectedStatuses[studentUid];
    }
    final existing = attendanceMap[studentUid];
    if (existing == AttendanceStatus.early) {
      return AttendanceStatus.present;
    }
    return existing;
  }

  Future<void> _saveAttendance({
    required String schoolId,
    required String teacherUid,
    required TeacherClassOption classOption,
    required List<TeacherAttendanceStudent> students,
    required Map<String, AttendanceStatus> existingStatuses,
  }) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final repo = ref.read(teacherAttendanceRepositoryProvider);
    final dateKey = AttendanceDay.dateKeyFor(_selectedDate);

    try {
      final entries = <TeacherAttendanceEntry>[];
      for (final student in students) {
        final override = _selectedStatuses[student.uid];
        final existing = existingStatuses[student.uid];
        final status = override ?? existing ?? AttendanceStatus.absent;

        entries.add(
          TeacherAttendanceEntry(
            schoolId: schoolId,
            dateKey: dateKey,
            status: status,
            student: student,
            classOption: classOption,
            takenByUid: teacherUid,
            shiftType: _shiftType,
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
            shiftType: null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not save attendance: $e');
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
    AsyncValue<Map<String, AttendanceStatus>>? attendanceAsync;

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
            shiftType: null,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
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
                                    const <String, AttendanceStatus>{},
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
    final inactiveTabColor = AppTheme.textPrimary.withValues(alpha: 0.6);

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
    final inactiveUnderlineColor = AppTheme.outline.withValues(alpha: 0.2);

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
    AsyncValue<Map<String, AttendanceStatus>>? attendanceAsync,
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
      return const Center(child: Text('Failed to load students.'));
    }

    if (attendanceAsync.hasError) {
      return const Center(child: Text('Failed to load attendance.'));
    }

    final students = studentsAsync.value ?? const <TeacherAttendanceStudent>[];
    final attendanceMap =
        attendanceAsync.value ?? const <String, AttendanceStatus>{};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildFiltersRow(classOptions, selectedClass),
          const SizedBox(height: 12),
          _buildTableHeader(),
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
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<TeacherClassOption>(
            value: selectedClass,
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
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(_selectedDate),
                      style: TextStyle(
                        color: AppTheme.textPrimary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppTheme.textPrimary.withValues(alpha: 0.7),
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
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.outline.withValues(alpha: 0.4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.outline.withValues(alpha: 0.4),
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

  Widget _buildTableHeader() {
    TextStyle headerStyle = TextStyle(
      fontSize: 11,
      color: AppTheme.textPrimary.withValues(alpha: 0.7),
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.outline.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Name', style: headerStyle),
          ),
          SizedBox(
            width: _statusColumnWidth,
            child: Center(child: Text('Present', style: headerStyle)),
          ),
          SizedBox(
            width: _statusColumnWidth,
            child: Center(child: Text('Absent', style: headerStyle)),
          ),
          SizedBox(
            width: _statusColumnWidth,
            child: Center(child: Text('Late', style: headerStyle)),
          ),
          SizedBox(
            width: _statusColumnWidth,
            child: Center(child: Text('Excused', style: headerStyle)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(
    List<TeacherAttendanceStudent> students,
    Map<String, AttendanceStatus> attendanceMap,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = students[index];
        final status = _effectiveStatusForStudent(student.uid, attendanceMap);

        return _StudentAttendanceRow(
          student: student,
          status: status,
          statusColumnWidth: _statusColumnWidth,
          onStatusSelected: (selected) => _toggleStatus(student.uid, selected),
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
        ],
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: AppTheme.textPrimary.withValues(alpha: 0.6),
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
                isSelected ? AppTheme.white : AppTheme.textPrimary;

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
                  color: AppTheme.textPrimary.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: const [
        Expanded(
          child: _SummaryCard(
            label: 'Present',
            value: '22',
            icon: Icons.person_outline,
            backgroundColor: Color(0xFFE8F3FF),
            iconColor: Color(0xFF3B82F6),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Absent',
            value: '03',
            icon: Icons.person_off_outlined,
            backgroundColor: Color(0xFFFFE8EC),
            iconColor: Color(0xFFE25563),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Event',
            value: '05',
            icon: Icons.event_note_outlined,
            backgroundColor: Color(0xFFEDE9FF),
            iconColor: Color(0xFF7C5CF2),
          ),
        ),
      ],
    );
  }
}

class _StudentAttendanceRow extends StatelessWidget {
  const _StudentAttendanceRow({
    required this.student,
    required this.status,
    required this.statusColumnWidth,
    required this.onStatusSelected,
  });

  final TeacherAttendanceStudent student;
  final AttendanceStatus? status;
  final double statusColumnWidth;
  final ValueChanged<AttendanceStatus> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final avatar = student.photoUrl != null && student.photoUrl!.isNotEmpty
        ? CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(student.photoUrl!),
          )
        : CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.4),
            child: Text(
              student.initials,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: statusColumnWidth,
            child: Center(
              child: _AttendanceIndicator(
                selected: status == AttendanceStatus.present,
                activeColor: AppTheme.primaryColor,
                onTap: () => onStatusSelected(AttendanceStatus.present),
              ),
            ),
          ),
          SizedBox(
            width: statusColumnWidth,
            child: Center(
              child: _AttendanceIndicator(
                selected: status == AttendanceStatus.absent,
                activeColor: AppTheme.danger,
                onTap: () => onStatusSelected(AttendanceStatus.absent),
              ),
            ),
          ),
          SizedBox(
            width: statusColumnWidth,
            child: Center(
              child: _AttendanceIndicator(
                selected: status == AttendanceStatus.late,
                activeColor: const Color(0xFFE68A00),
                onTap: () => onStatusSelected(AttendanceStatus.late),
              ),
            ),
          ),
          SizedBox(
            width: statusColumnWidth,
            child: Center(
              child: _AttendanceIndicator(
                selected: status == AttendanceStatus.excused,
                activeColor: const Color(0xFFF2B233),
                onTap: () => onStatusSelected(AttendanceStatus.excused),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.7),
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
                    color: AppTheme.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
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
