import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';

class TeacherAttendancePage extends ConsumerStatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  ConsumerState<TeacherAttendancePage> createState() =>
      _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends ConsumerState<TeacherAttendancePage> {
  static const List<String> _classes = ['7th A', '7th B', '7th C'];
  static const double _statusColumnWidth = 72;

  int _selectedTab = 0;
  String? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<TeacherStudentRow> _students = [];
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
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _students = _buildSampleStudents();
      _isLoading = false;
    });
  }

  List<TeacherStudentRow> _buildSampleStudents() {
    return [
      TeacherStudentRow(
        id: 's1',
        name: 'Leslie Alexander',
        avatarUrl: '',
        isPresent: true,
        isAbsent: false,
      ),
      TeacherStudentRow(
        id: 's2',
        name: 'Wade Warren',
        avatarUrl: '',
        isPresent: false,
        isAbsent: true,
      ),
      TeacherStudentRow(
        id: 's3',
        name: 'Brooklyn Simmons',
        avatarUrl: '',
        isPresent: true,
        isAbsent: false,
      ),
      TeacherStudentRow(
        id: 's4',
        name: 'Jenny Wilson',
        avatarUrl: '',
        isPresent: true,
        isAbsent: false,
      ),
      TeacherStudentRow(
        id: 's5',
        name: 'Bessie Cooper',
        avatarUrl: '',
        isPresent: true,
        isAbsent: false,
      ),
      TeacherStudentRow(
        id: 's6',
        name: 'Jerome Bell',
        avatarUrl: '',
        isPresent: false,
        isAbsent: true,
      ),
      TeacherStudentRow(
        id: 's7',
        name: 'Kathryn Murphy',
        avatarUrl: '',
        isPresent: true,
        isAbsent: false,
      ),
      TeacherStudentRow(
        id: 's8',
        name: 'Annette Black',
        avatarUrl: '',
        isPresent: true,
        isAbsent: false,
      ),
    ];
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
    setState(() => _selectedDate = picked);
  }

  void _togglePresent(TeacherStudentRow row) {
    setState(() {
      row.isPresent = true;
      row.isAbsent = false;
    });
  }

  void _toggleAbsent(TeacherStudentRow row) {
    setState(() {
      row.isAbsent = true;
      row.isPresent = false;
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () => _showSnack('Attendance saved (stub).'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
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
                  ? _buildStudentsTab(context)
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

  Widget _buildStudentsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildFiltersRow(),
          const SizedBox(height: 12),
          _buildTableHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStudentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedClass,
            isExpanded: true,
            decoration: _inputDecoration('Select Class'),
            items: _classes
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedClass = value),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.outline.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Name',
              style: TextStyle(
                color: AppTheme.textPrimary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: _statusColumnWidth,
            child: Center(
              child: Text(
                'Present',
                style: TextStyle(
                  color: AppTheme.textPrimary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _statusColumnWidth,
            child: Center(
              child: Text(
                'Absent',
                style: TextStyle(
                  color: AppTheme.textPrimary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: _students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = _students[index];
        return _StudentAttendanceRow(
          student: student,
          statusColumnWidth: _statusColumnWidth,
          onPresent: () => _togglePresent(student),
          onAbsent: () => _toggleAbsent(student),
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
    required this.statusColumnWidth,
    required this.onPresent,
    required this.onAbsent,
  });

  final TeacherStudentRow student;
  final double statusColumnWidth;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;

  @override
  Widget build(BuildContext context) {
    final initials = student.name.trim().isNotEmpty
        ? student.name.trim().substring(0, 1).toUpperCase()
        : '?';

    final avatar = student.avatarUrl.isNotEmpty
        ? CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(student.avatarUrl),
          )
        : CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.4),
            child: Text(
              initials,
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
              student.name,
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
                selected: student.isPresent,
                activeColor: AppTheme.primaryColor,
                onTap: onPresent,
              ),
            ),
          ),
          SizedBox(
            width: statusColumnWidth,
            child: Center(
              child: _AttendanceIndicator(
                selected: student.isAbsent,
                activeColor: AppTheme.danger,
                onTap: onAbsent,
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

class TeacherStudentRow {
  TeacherStudentRow({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isPresent,
    required this.isAbsent,
  });

  final String id;
  final String name;
  final String avatarUrl;
  bool isPresent;
  bool isAbsent;
}
