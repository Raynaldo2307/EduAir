import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';

class StudentProfileEditPage extends ConsumerStatefulWidget {
  const StudentProfileEditPage({super.key});

  @override
  ConsumerState<StudentProfileEditPage> createState() =>
      _StudentProfileEditPageState();
}

class _StudentProfileEditPageState
    extends ConsumerState<StudentProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _gradeLevelController;
  late final TextEditingController _bioController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _parentPhoneController;
  late final TextEditingController _addressController;

  // 🔹 Focus nodes for smooth “Next” / “Done” behaviour
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _studentIdFocus = FocusNode();
  final _gradeFocus = FocusNode();
  final _parentNameFocus = FocusNode();
  final _parentPhoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _bioFocus = FocusNode();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);

    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _studentIdController = TextEditingController(text: user?.studentId ?? '');
    _gradeLevelController = TextEditingController(text: user?.gradeLevel ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');

    _parentNameController = TextEditingController(
      text: user?.parentGuardianName ?? '',
    );
    _parentPhoneController = TextEditingController(
      text: user?.parentGuardianPhone ?? '',
    );
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _gradeLevelController.dispose();
    _bioController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _studentIdFocus.dispose();
    _gradeFocus.dispose();
    _parentNameFocus.dispose();
    _parentPhoneFocus.dispose();
    _addressFocus.dispose();
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
      // update global in-memory user
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
      studentId: clean(_studentIdController.text) ?? user.studentId,
      gradeLevel: clean(_gradeLevelController.text) ?? user.gradeLevel,
      bio: clean(_bioController.text) ?? user.bio,
      parentGuardianName:
          clean(_parentNameController.text) ?? user.parentGuardianName,
      parentGuardianPhone:
          clean(_parentPhoneController.text) ?? user.parentGuardianPhone,
      address: clean(_addressController.text) ?? user.address,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  // Student info
                  Text(
                    'Student Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

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
                    decoration: _decoration('Student Phone'),
                    // keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      _studentIdFocus.requestFocus();
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildRow(
                    left: TextFormField(
                      controller: _studentIdController,
                      focusNode: _studentIdFocus,
                      decoration: _decoration('Student ID'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        _gradeFocus.requestFocus();
                      },
                    ),
                    right: TextFormField(
                      controller: _gradeLevelController,
                      focusNode: _gradeFocus,
                      decoration: _decoration('Grade / Class'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        _parentNameFocus.requestFocus();
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Parent / guardian info
                  Text(
                    'Parent / Guardian',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _parentNameController,
                    focusNode: _parentNameFocus,
                    decoration: _decoration('Parent / Guardian Name'),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      _parentPhoneFocus.requestFocus();
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _parentPhoneController,
                    focusNode: _parentPhoneFocus,
                    decoration: _decoration('Parent / Guardian Contact'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,

                    onFieldSubmitted: (_) {
                      _addressFocus.requestFocus();
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _addressController,
                    focusNode: _addressFocus,
                    decoration: _decoration('Address'),
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      _bioFocus.requestFocus();
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _bioController,
                    focusNode: _bioFocus,
                    decoration: _decoration('Bio / About'),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      // last field → hide keyboard
                      _bioFocus.unfocus();
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
