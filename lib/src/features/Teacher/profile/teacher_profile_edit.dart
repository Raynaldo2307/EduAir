import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';

class TeacherProfileEditPage extends ConsumerStatefulWidget {
  const TeacherProfileEditPage({super.key});

  @override
  ConsumerState<TeacherProfileEditPage> createState() =>
      _TeacherProfileEditPageState();
}

class _TeacherProfileEditPageState
    extends ConsumerState<TeacherProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _teacherIdController;
  late final TextEditingController _departmentController;
  late final TextEditingController _bioController;

  // 🔹 Focus nodes for smooth “Next / Done” keyboard flow
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _teacherIdFocus = FocusNode();
  final _departmentFocus = FocusNode();
  final _bioFocus = FocusNode();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);

    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');

    // Teacher ID: still using studentId field under the hood for now
    _teacherIdController = TextEditingController(text: user?.studentId ?? '');

    // Department: prefer teacherDepartment, fall back to gradeLevel for old docs
    _departmentController = TextEditingController(
      text: user?.teacherDepartment ?? user?.gradeLevel ?? '',
    );

    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _teacherIdController.dispose();
    _departmentController.dispose();
    _bioController.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _teacherIdFocus.dispose();
    _departmentFocus.dispose();
    _bioFocus.dispose();

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

    final user = ref.read(userProvider);
    if (user == null) return;

    final userService = ref.read(userServiceProvider);
    final updated = _buildUpdatedUser(user);

    setState(() => _saving = true);

    try {
      await userService.updateUser(updated);
      // keep in-memory user in sync
      ref.read(userProvider.notifier).state = updated;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.of(context).pop<AppUser>(updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  AppUser _buildUpdatedUser(AppUser user) {
    String? clean(String value) => value.trim().isEmpty ? null : value.trim();

    return user.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),

      // Still using studentId as Teacher ID for now
      studentId: clean(_teacherIdController.text) ?? user.studentId,

      // Write department into teacherDepartment, not gradeLevel
      teacherDepartment:
          clean(_departmentController.text) ?? user.teacherDepartment,

      bio: clean(_bioController.text) ?? user.bio,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppTheme.surfaceVariant,
      body: SafeArea(
        child: GestureDetector(
          // 🔹 Tap outside to dismiss keyboard
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRow(
                    left: TextFormField(
                      controller: _firstNameController,
                      focusNode: _firstNameFocus,
                      decoration: _decoration('First name'),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          _requiredValidator(v, label: 'First name'),
                      onFieldSubmitted: (_) {
                        _lastNameFocus.requestFocus();
                      },
                    ),
                    right: TextFormField(
                      controller: _lastNameController,
                      focusNode: _lastNameFocus,
                      decoration: _decoration('Last name'),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          _requiredValidator(v, label: 'Last name'),
                      onFieldSubmitted: (_) {
                        _phoneFocus.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    decoration: _decoration('Phone'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      _teacherIdFocus.requestFocus();
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildRow(
                    left: TextFormField(
                      controller: _teacherIdController,
                      focusNode: _teacherIdFocus,
                      decoration: _decoration('Teacher ID'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        _departmentFocus.requestFocus();
                      },
                    ),
                    right: TextFormField(
                      controller: _departmentController,
                      focusNode: _departmentFocus,
                      decoration: _decoration('Department / Subject'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        _bioFocus.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _bioController,
                    focusNode: _bioFocus,
                    decoration: _decoration('Bio / About'),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      _bioFocus.unfocus(); // hide keyboard on last field
                    },
                  ),
                  const SizedBox(height: 24),

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
                    label: Text(_saving ? 'Saving...' : 'Save changes'),
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

  Widget _buildRow({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}
