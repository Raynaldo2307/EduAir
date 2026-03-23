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

const Map<String, String> _employmentTypes = {
  'Full Time': 'full_time',
  'Part Time': 'part_time',
  'Substitute': 'substitute',
  'Contract': 'contract',
};

/// Common Jamaican school departments — used for staff_code generation.
const List<String> _departments = [
  'Mathematics',
  'English',
  'Sciences',
  'Social Studies',
  'Physical Education',
  'Art & Craft',
  'Music',
  'Information Technology',
  'Business Studies',
  'Languages',
  'Administration',
];

/// Admin/Principal page to add or edit a staff member.
///
/// [staff] = null → Create mode (POST /api/staff)
///   - Backend auto-generates: email, staff_code, password (= staff_code)
///   - Department is required — it determines the code prefix (e.g. PAP-MATH-001)
///   - After save: credentials dialog shows email + staff_code
///
/// [staff] = AppUser → Edit mode (PUT /api/staff/:id)
class AdminStaffEditPage extends ConsumerStatefulWidget {
  const AdminStaffEditPage({super.key, this.staff});

  final AppUser? staff;

  @override
  ConsumerState<AdminStaffEditPage> createState() => _AdminStaffEditPageState();
}

class _AdminStaffEditPageState extends ConsumerState<AdminStaffEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  late String _selectedShift;
  late String _selectedEmploymentType;
  String? _selectedDepartment;
  int? _selectedClassId;

  bool _saving = false;
  bool get _isCreateMode => widget.staff == null;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;

    _firstNameController = TextEditingController(text: s?.firstName ?? '');
    _lastNameController  = TextEditingController(text: s?.lastName  ?? '');

    _selectedShift = s?.currentShift ?? 'whole_day';
    if (!_shiftOptions.containsValue(_selectedShift)) _selectedShift = 'whole_day';

    _selectedEmploymentType = (_employmentTypes.containsValue(s?.employmentType ?? ''))
        ? s!.employmentType!
        : 'full_time';

    // Pre-fill department if editing
    if (s?.teacherDepartment != null &&
        _departments.contains(s!.teacherDepartment)) {
      _selectedDepartment = s.teacherDepartment;
    }

    // Pre-select homeroom class in edit mode — validated against list in build()
    _selectedClassId = int.tryParse(s?.homeroomClassId ?? '');
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

    final staffRepo = ref.read(staffApiRepositoryProvider);
    setState(() => _saving = true);

    try {
      if (_isCreateMode) {
        final payload = <String, dynamic>{
          'first_name':         _firstNameController.text.trim(),
          'last_name':          _lastNameController.text.trim(),
          'employment_type':    _selectedEmploymentType,
          'current_shift_type': _selectedShift,
          if (_selectedDepartment != null) 'department': _selectedDepartment,
          if (_selectedClassId != null)    'homeroom_class_id': _selectedClassId,
        };

        final response = await staffRepo.create(payload);
        if (!mounted) return;

        // Staff repo already unwraps response.data['data'] — read directly
        final email     = response['email']      as String? ?? '—';
        final staffCode = response['staff_code'] as String? ?? '—';

        await _showCredentialsDialog(email: email, code: staffCode);
        if (mounted) Navigator.of(context).pop<bool>(true);
      } else {
        final teacherId = int.parse(widget.staff!.uid);
        final payload = <String, dynamic>{
          'first_name':         _firstNameController.text.trim(),
          'last_name':          _lastNameController.text.trim(),
          'current_shift_type': _selectedShift,
          'employment_type':    _selectedEmploymentType,
          if (_selectedDepartment != null) 'department': _selectedDepartment,
          if (_selectedClassId != null)    'homeroom_class_id': _selectedClassId,
        };

        await staffRepo.update(teacherId, payload);
        if (!mounted) return;

        Navigator.of(context).pop<bool>(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showCredentialsDialog({
    required String email,
    required String code,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Staff Member Added'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share these login credentials with the staff member:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _CredentialRow(label: 'Email', value: email),
            const SizedBox(height: 8),
            _CredentialRow(label: 'Staff Code', value: code),
            const SizedBox(height: 8),
            _CredentialRow(label: 'Password', value: code),
            const SizedBox(height: 12),
            const Text(
              'Password = Staff Code. They should change it on first login.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Staff Member'),
        content: Text(
          'Are you sure you want to deactivate '
          '${widget.staff?.displayName ?? "this staff member"}? '
          'They will no longer appear in the staff list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final staffRepo = ref.read(staffApiRepositoryProvider);
    setState(() => _saving = true);

    try {
      final teacherId = int.parse(widget.staff!.uid);
      await staffRepo.delete(teacherId);

      if (mounted) {
        Navigator.of(context).pop<bool>(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to deactivate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs     = theme.colorScheme;

    final classesAsync = ref.watch(schoolClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreateMode ? 'Add Staff Member' : 'Edit Staff Member'),
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isCreateMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Deactivate staff member',
              onPressed: _saving ? null : _confirmDelete,
            ),
        ],
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
                  // ── Staff Information ────────────────────────────────
                  _SectionHeader(title: 'Staff Information'),
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

                  // Department dropdown — drives staff_code generation on backend
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDepartment,
                    decoration: _decoration('Department'),
                    dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    hint: Text('Select department',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4))),
                    items: _departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDepartment = v),
                  ),
                  const SizedBox(height: 14),

                  // Homeroom class — optional
                  classesAsync.when(
                    loading: () => const SizedBox(
                      height: 56,
                      child: Center(child: LinearProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (classes) {
                      final validId = classes.any(
                              (c) => c['id'] == _selectedClassId)
                          ? _selectedClassId
                          : null;

                      return DropdownButtonFormField<int>(
                        initialValue: validId,
                        decoration: _decoration('Homeroom Class (optional)'),
                        dropdownColor:
                            isDark ? AppTheme.darkCard : Colors.white,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: cs.onSurface),
                        hint: Text('None — not a form teacher',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.4))),
                        items: [
                          DropdownMenuItem<int>(
                            value: null,
                            child: Text('None',
                                style: TextStyle(
                                    color:
                                        cs.onSurface.withValues(alpha: 0.5))),
                          ),
                          ...classes.map((c) => DropdownMenuItem<int>(
                                value: c['id'] as int,
                                child: Text(c['name'].toString()),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedClassId = v),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── Shift & Employment ───────────────────────────────
                  _SectionHeader(title: 'Shift & Employment'),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedShift,
                    decoration: _decoration('Shift'),
                    dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    items: _shiftOptions.entries
                        .map((e) => DropdownMenuItem(
                              value: e.value,
                              child: Text(e.key),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedShift = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedEmploymentType,
                    decoration: _decoration('Employment Type'),
                    dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    items: _employmentTypes.entries
                        .map((e) => DropdownMenuItem(
                              value: e.value,
                              child: Text(e.key),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedEmploymentType = v);
                    },
                  ),

                  // In edit mode show current staff code (read-only)
                  if (!_isCreateMode &&
                      widget.staff?.studentId != null) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(title: 'School Identity'),
                    const SizedBox(height: 12),
                    _ReadOnlyField(
                      label: 'Staff Code',
                      value: widget.staff!.studentId!,
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
                            : (_isCreateMode
                                ? 'Add Staff Member'
                                : 'Save Changes'),
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

// ── Read-only field ─────────────────────────────────────────────────────────────

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
          width: 90,
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
