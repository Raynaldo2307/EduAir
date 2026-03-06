import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';

/// Shift options for the dropdown.
/// Maps display label -> Firestore value.
const Map<String, String> _shiftOptions = {
  'Whole Day': 'whole_day',
  'Morning': 'morning',
  'Afternoon': 'afternoon',
};

/// Admin/Principal page to edit a student's profile, including their shift assignment.
class AdminStudentEditPage extends ConsumerStatefulWidget {
  const AdminStudentEditPage({super.key, required this.student});

  final AppUser student;

  @override
  ConsumerState<AdminStudentEditPage> createState() =>
      _AdminStudentEditPageState();
}

class _AdminStudentEditPageState extends ConsumerState<AdminStudentEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _studentIdController;
  late TextEditingController _classNameController;
  late TextEditingController _gradeLevelController;

  /// The selected shift value ('whole_day', 'morning', 'afternoon').
  late String _selectedShift;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;

    _firstNameController = TextEditingController(text: s.firstName);
    _lastNameController = TextEditingController(text: s.lastName);
    _studentIdController = TextEditingController(text: s.studentId ?? '');
    _classNameController = TextEditingController(text: s.className ?? '');
    _gradeLevelController = TextEditingController(text: s.gradeLevel ?? '');

    // Default to 'whole_day' if currentShift is null or empty
    _selectedShift = s.currentShift ?? 'whole_day';
    // Ensure it's a valid option
    if (!_shiftOptions.containsValue(_selectedShift)) {
      _selectedShift = 'whole_day';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    _classNameController.dispose();
    _gradeLevelController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.accent.withValues(alpha: 0.18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
      ),
    );
  }

  String? _requiredValidator(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final studentsRepo = ref.read(studentsApiRepositoryProvider);

    String? clean(String value) => value.trim().isEmpty ? null : value.trim();

    final payload = <String, dynamic>{
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'current_shift_type': _selectedShift,
      if (clean(_studentIdController.text) != null)
        'student_code': clean(_studentIdController.text),
    };

    setState(() => _saving = true);

    try {
      final studentId = int.parse(widget.student.uid);
      await studentsRepo.update(studentId, payload);

      final updated = widget.student.copyWith(
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Student'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppTheme.surfaceVariant,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Student Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // First / Last name row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: _decoration('First Name'),
                          textInputAction: TextInputAction.next,
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
                          validator: (v) =>
                              _requiredValidator(v, label: 'Last name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Student ID
                  TextFormField(
                    controller: _studentIdController,
                    decoration: _decoration('Student ID'),
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

                  const SizedBox(height: 24),

                  // Shift section header
                  Text(
                    'Attendance Shift',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the shift this student attends. This determines their expected arrival time for attendance.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Shift dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedShift,
                    decoration: _decoration('Shift'),
                    items: _shiftOptions.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.value,
                            child: Text(entry.key),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedShift = value);
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
