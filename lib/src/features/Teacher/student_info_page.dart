import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';

class StudentInfoPage extends ConsumerStatefulWidget {
  const StudentInfoPage({super.key, this.onBackToHome});

  /// Called when the back arrow in the AppBar is pressed.
  /// In TeacherShell we’ll point this to `_onSelectTab(0)`.
  final VoidCallback? onBackToHome;

  @override
  ConsumerState<StudentInfoPage> createState() => _StudentInfoPageState();
}

class _StudentInfoPageState extends ConsumerState<StudentInfoPage> {
  static const List<String> _classes = ['7th A', '7th B', '7th C'];

  String? _selectedClass;

  final List<StudentInfoRow> _students = [
    StudentInfoRow(
      id: 's1',
      name: 'Leslie Alexander',
      className: '7th A',
      avatarUrl: '',
    ),
    StudentInfoRow(
      id: 's2',
      name: 'Wade Warren',
      className: '7th A',
      avatarUrl: '',
    ),
    StudentInfoRow(
      id: 's3',
      name: 'Brooklyn Simmons',
      className: '7th B',
      avatarUrl: '',
    ),
    StudentInfoRow(
      id: 's4',
      name: 'Jenny Wilson',
      className: '7th B',
      avatarUrl: '',
    ),
    StudentInfoRow(
      id: 's5',
      name: 'Bessie Cooper',
      className: '7th C',
      avatarUrl: '',
    ),
    StudentInfoRow(
      id: 's6',
      name: 'Jerome Bell',
      className: '7th C',
      avatarUrl: '',
    ),
    StudentInfoRow(
      id: 's7',
      name: 'Kathryn Murphy',
      className: '7th A',
      avatarUrl: '',
    ),
    StudentInfoRow(
      id: 's8',
      name: 'Annette Black',
      className: '7th B',
      avatarUrl: '',
    ),
  ];

  List<StudentInfoRow> get _visibleStudents {
    if (_selectedClass == null) return _students;
    return _students
        .where((student) => student.className == _selectedClass)
        .toList();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // If shell provided a callback, use it to jump back to Home tab.
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else {
              // Fallback: normal back navigation.
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text('Student Info'),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              _buildClassDropdown(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _visibleStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final student = _visibleStudents[index];
                    return _StudentInfoTile(
                      student: student,
                      onTap: () => _showSnack('Student details coming soon'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedClass,
      isExpanded: true,
      decoration: _inputDecoration('Select Class'),
      items: _classes
          .map(
            (value) =>
                DropdownMenuItem<String>(value: value, child: Text(value)),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedClass = value),
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
        borderSide: BorderSide(color: AppTheme.outline.withValues(alpha: 0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.outline.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _StudentInfoTile extends StatelessWidget {
  const _StudentInfoTile({required this.student, required this.onTap});

  final StudentInfoRow student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = student.name.trim().isNotEmpty
        ? student.name.trim().substring(0, 1).toUpperCase()
        : '?';

    final avatar = student.avatarUrl.isNotEmpty
        ? CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(student.avatarUrl),
          )
        : CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.35),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          );

    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              Icon(
                Icons.chevron_right,
                color: AppTheme.textPrimary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentInfoRow {
  StudentInfoRow({
    required this.id,
    required this.name,
    required this.className,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String className;
  final String avatarUrl;
}
