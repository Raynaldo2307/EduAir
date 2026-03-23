import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';

const Map<String, String> _shiftOptions = {
  'Whole Day': 'whole_day',
  'Morning': 'morning',
  'Afternoon': 'afternoon',
};

const Map<String, String> _sexOptions = {
  'Female': 'female',
  'Male': 'male',
};

/// Admin/Principal page to add or edit a student.
///
/// [student] = null → Create mode (POST /api/students)
///   - Backend auto-generates: email, student_code, password (= student_code)
///   - Admin provides: first name, last name, sex, class, shift
///   - After save: credentials dialog shows email + student_code
///
/// [student] = AppUser → Edit mode (PUT /api/students/:id)
///   - Admin can update: name, class assignment, shift, sex
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

  late String _selectedShift;
  String? _selectedSex;
  int? _selectedClassId;

  bool _saving = false;
  bool get _isCreateMode => widget.student == null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;

    _firstNameController = TextEditingController(text: s?.firstName ?? '');
    _lastNameController  = TextEditingController(text: s?.lastName  ?? '');

    _selectedShift = s?.currentShift ?? 'whole_day';
    if (!_shiftOptions.containsValue(_selectedShift)) _selectedShift = 'whole_day';

    _selectedSex = s?.sex;
    // Pre-select existing class in edit mode — validated against list in build()
    _selectedClassId = int.tryParse(s?.classId ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
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

  String? _required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final studentsRepo = ref.read(studentsApiRepositoryProvider);
    setState(() => _saving = true);

    try {
      if (_isCreateMode) {
        final payload = <String, dynamic>{
          'first_name':        _firstNameController.text.trim(),
          'last_name':         _lastNameController.text.trim(),
          'current_shift_type': _selectedShift,
          if (_selectedSex != null)     'sex': _selectedSex,
          if (_selectedClassId != null) 'homeroom_class_id': _selectedClassId,
        };

        final response = await studentsRepo.create(payload);
        if (!mounted) return;

        // Backend auto-generates email + student_code — show them to admin
        final created = response['data'] as Map<String, dynamic>?;
        final email   = created?['email']        as String? ?? '—';
        final code    = created?['student_code'] as String? ?? '—';

        await _showCredentialsDialog(email: email, code: code, label: 'Student Code');
        if (mounted) Navigator.of(context).pop<bool>(true);
      } else {
        final studentId = int.parse(widget.student!.uid);
        final payload = <String, dynamic>{
          'first_name':         _firstNameController.text.trim(),
          'last_name':          _lastNameController.text.trim(),
          'current_shift_type': _selectedShift,
          if (_selectedSex != null)     'sex': _selectedSex,
          if (_selectedClassId != null) 'homeroom_class_id': _selectedClassId,
        };

        await studentsRepo.update(studentId, payload);
        if (!mounted) return;

        Navigator.of(context).pop<bool>(true);
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
          'Remove ${widget.student?.displayName ?? 'this student'}? '
          'Their attendance history will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final studentId = int.parse(widget.student!.uid);
      await ref.read(studentsApiRepositoryProvider).delete(studentId);
      if (mounted) Navigator.of(context).pop<bool>(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showCredentialsDialog({
    required String email,
    required String code,
    required String label,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Student Added'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share these login credentials with the student:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _CredentialRow(label: 'Email', value: email),
            const SizedBox(height: 8),
            _CredentialRow(label: label, value: code),
            const SizedBox(height: 8),
            _CredentialRow(label: 'Password', value: code),
            const SizedBox(height: 12),
            Text(
              'Password = $label. Student should change it on first login.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs     = theme.colorScheme;

    final classesAsync = ref.watch(schoolClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreateMode ? 'Add Student' : 'Edit Student'),
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.surfaceVariant,
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
                          validator: (v) => _required(v, label: 'First name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: _decoration('Last Name'),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => _required(v, label: 'Last name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Sex
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSex,
                    decoration: _decoration('Gender'),
                    dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    hint: Text('Select gender',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4))),
                    items: _sexOptions.entries
                        .map((e) => DropdownMenuItem(
                              value: e.value,
                              child: Text(e.key),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSex = v),
                  ),
                  const SizedBox(height: 14),

                  // Class dropdown — loaded from GET /api/classes
                  classesAsync.when(
                    loading: () => const SizedBox(
                      height: 56,
                      child: Center(
                        child: LinearProgressIndicator(),
                      ),
                    ),
                    error: (_, __) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.error),
                      ),
                      child: Text('Could not load classes',
                          style: TextStyle(color: cs.error)),
                    ),
                    data: (classes) {
                      // initialValue comes from initState (student.classId).
                      // Validate it exists in the list — fall back to null if not.
                      final validId = classes.any(
                              (c) => c['id'] == _selectedClassId)
                          ? _selectedClassId
                          : null;

                      return DropdownButtonFormField<int>(
                        initialValue: validId,
                        decoration: _decoration('Homeroom Class'),
                        dropdownColor:
                            isDark ? AppTheme.darkCard : Colors.white,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: cs.onSurface),
                        hint: Text('Select class',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.4))),
                        items: classes
                            .map((c) => DropdownMenuItem<int>(
                                  value: c['id'] as int,
                                  child: Text(c['name'].toString()),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedClassId = v),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── Attendance Shift ─────────────────────────────────
                  _SectionHeader(title: 'Attendance Shift'),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedShift,
                    decoration: _decoration('Shift'),
                    dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    items: _shiftOptions.entries
                        .map((e) => DropdownMenuItem<String>(
                              value: e.value,
                              child: Text(e.key),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedShift = v);
                    },
                  ),

                  // In edit mode show current student code (read-only)
                  if (!_isCreateMode &&
                      widget.student?.studentId != null) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(title: 'School Identity'),
                    const SizedBox(height: 12),
                    _ReadOnlyField(
                      label: 'Student Code',
                      value: widget.student!.studentId!,
                    ),
                  ],

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
                  // ── Remove Student (edit mode only) ─────────────────
                  if (!_isCreateMode) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _delete,
                        icon: const Icon(Icons.person_remove_outlined,
                            color: Colors.red),
                        label: const Text(
                          'Remove Student',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
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

// ── Read-only info field ────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Credentials row in the post-creation dialog ─────────────────────────────────

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
