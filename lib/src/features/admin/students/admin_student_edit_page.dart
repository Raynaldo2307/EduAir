import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';

/// Shift options for the dropdown.
/// Maps display label -> API value.
const Map<String, String> _shiftOptions = {
  'Whole Day': 'whole_day',
  'Morning': 'morning',
  'Afternoon': 'afternoon',
};

/// Admin/Principal page to add or edit a student.
///
/// [student] = null → Create mode (POST /api/students)
/// [student] = AppUser → Edit mode (PUT /api/students/:id)
class AdminStudentEditPage extends ConsumerStatefulWidget {
  const AdminStudentEditPage({super.key, this.student});

  final AppUser? student;

  @override
  ConsumerState<AdminStudentEditPage> createState() =>
      _AdminStudentEditPageState();
}

class _AdminStudentEditPageState extends ConsumerState<AdminStudentEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _studentIdController;
  late TextEditingController _classNameController;
  late TextEditingController _gradeLevelController;

  late String _selectedShift;

  bool _saving = false;
  bool get _isCreateMode => widget.student == null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;

    _firstNameController = TextEditingController(text: s?.firstName ?? '');
    _lastNameController = TextEditingController(text: s?.lastName ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _passwordController = TextEditingController();
    _studentIdController = TextEditingController(text: s?.studentId ?? '');
    _classNameController = TextEditingController(text: s?.className ?? '');
    _gradeLevelController = TextEditingController(text: s?.gradeLevel ?? '');

    _selectedShift = s?.currentShift ?? 'whole_day';
    if (!_shiftOptions.containsValue(_selectedShift)) {
      _selectedShift = 'whole_day';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentIdController.dispose();
    _classNameController.dispose();
    _gradeLevelController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 1.8),
      ),
    );
  }

  String? _requiredValidator(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final studentsRepo = ref.read(studentsApiRepositoryProvider);
    String? clean(String v) => v.trim().isEmpty ? null : v.trim();

    setState(() => _saving = true);

    try {
      if (_isCreateMode) {
        // ── Create ──
        final payload = <String, dynamic>{
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'current_shift_type': _selectedShift,
          if (clean(_studentIdController.text) != null)
            'student_code': clean(_studentIdController.text),
          if (clean(_classNameController.text) != null)
            'class_name': clean(_classNameController.text),
          if (clean(_gradeLevelController.text) != null)
            'grade_level': clean(_gradeLevelController.text),
        };

        await studentsRepo.create(payload);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student added successfully')),
          );
          Navigator.of(context).pop<bool>(true);
        }
      } else {
        // ── Edit ──
        final studentId = int.parse(widget.student!.uid);
        final payload = <String, dynamic>{
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'current_shift_type': _selectedShift,
          if (clean(_studentIdController.text) != null)
            'student_code': clean(_studentIdController.text),
        };

        await studentsRepo.update(studentId, payload);

        final updated = widget.student!.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          studentId: clean(_studentIdController.text),
          currentShift: _selectedShift,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student updated successfully')),
          );
          Navigator.of(context).pop<AppUser>(updated);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isCreateMode ? 'Failed to add: $e' : 'Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreateMode ? 'Add Student' : 'Edit Student'),
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.surfaceVariant,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Student Information ──────────────────────────────
                  _SectionHeader(title: 'Student Information'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: _decoration('First Name'),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              _requiredValidator(v, label: 'First name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: _decoration('Last Name'),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              _requiredValidator(v, label: 'Last name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Email + Password (create mode only)
                  if (_isCreateMode) ...[
                    TextFormField(
                      controller: _emailController,
                      decoration: _decoration('Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _decoration('Password'),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Student ID
                  TextFormField(
                    controller: _studentIdController,
                    decoration: _decoration('Student ID (optional)'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),

                  // Class / Grade row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _classNameController,
                          decoration: _decoration('Class'),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _gradeLevelController,
                          decoration: _decoration('Grade Level'),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Attendance Shift ─────────────────────────────────
                  _SectionHeader(title: 'Attendance Shift'),
                  const SizedBox(height: 8),
                  Text(
                    'Select the shift this student attends. This determines their expected arrival time for attendance.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedShift,
                    decoration: _decoration('Shift'),
                    dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    items: _shiftOptions.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.value,
                            child: Text(entry.key),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedShift = value);
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── Save button ──────────────────────────────────────
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving
                            ? 'Saving...'
                            : (_isCreateMode ? 'Add Student' : 'Save Changes'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        disabledBackgroundColor:
                            cs.primary.withValues(alpha: 0.5),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
