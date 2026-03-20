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

/// Admin/Principal page to add or edit a staff member.
///
/// [staff] = null → Create mode (POST /api/staff)
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
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _staffCodeController;
  late TextEditingController _departmentController;

  late String _selectedShift;
  late String _selectedEmploymentType;

  bool _saving = false;
  bool get _isCreateMode => widget.staff == null;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;

    _firstNameController = TextEditingController(text: s?.firstName ?? '');
    _lastNameController = TextEditingController(text: s?.lastName ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _passwordController = TextEditingController();
    _staffCodeController = TextEditingController();
    _departmentController = TextEditingController(
      text: s?.teacherDepartment ?? '',
    );

    _selectedShift = s?.currentShift ?? 'whole_day';
    if (!_shiftOptions.containsValue(_selectedShift)) {
      _selectedShift = 'whole_day';
    }

    _selectedEmploymentType = 'full_time';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _staffCodeController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  // Matches shared_profile_edit_page: cs.surface fill, cs.outline / cs.primary borders.
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
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    setState(() => _saving = true);

    try {
      if (_isCreateMode) {
        // ── Create ──
        final payload = <String, dynamic>{
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'employment_type': _selectedEmploymentType,
          'current_shift_type': _selectedShift,
          if (clean(_staffCodeController) != null)
            'staff_code': clean(_staffCodeController),
          if (clean(_departmentController) != null)
            'department': clean(_departmentController),
        };

        await staffRepo.create(payload);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff member added successfully')),
          );
          Navigator.of(context).pop<bool>(true);
        }
      } else {
        // ── Edit ──
        final teacherId = int.parse(widget.staff!.uid);
        final payload = <String, dynamic>{
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'current_shift_type': _selectedShift,
          'employment_type': _selectedEmploymentType,
          if (clean(_departmentController) != null)
            'department': clean(_departmentController),
          if (clean(_staffCodeController) != null)
            'staff_code': clean(_staffCodeController),
        };

        await staffRepo.update(teacherId, payload);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff member updated successfully')),
          );
          Navigator.of(context).pop<bool>(true);
        }
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
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.red),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member deactivated')),
        );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

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
                  // ── Staff Information ────────────────────────────────
                  _SectionHeader(title: 'Staff Information'),
                  const SizedBox(height: 12),

                  // First / Last name
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: _decoration('First Name'),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              _required(v, label: 'First name'),
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
                              _required(v, label: 'Last name'),
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
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
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
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Department
                  TextFormField(
                    controller: _departmentController,
                    decoration: _decoration('Department (optional)'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),

                  // Staff code
                  TextFormField(
                    controller: _staffCodeController,
                    decoration: _decoration('Staff Code (optional)'),
                    textInputAction: TextInputAction.done,
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
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.key),
                          ),
                        )
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
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.key),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedEmploymentType = v);
                      }
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

// ── Section header (matches shared_profile_edit_page) ─────────────────────────

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
