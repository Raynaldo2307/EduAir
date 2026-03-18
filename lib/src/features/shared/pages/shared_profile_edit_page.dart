import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';

/// Role-aware profile edit page.
///
/// One page for all roles — student, teacher, admin, principal.
/// Sections shown depend on [AppUser.role]:
///
///   All roles   → Personal Information (name, phone) + Bio
///   student     → + Gender, Date of Birth, Parent/Guardian, Address
///   teacher     → + Department (read-only — managed by admin)
///   admin /
///   principal   → nothing extra beyond common fields
class SharedProfileEditPage extends ConsumerStatefulWidget {
  const SharedProfileEditPage({super.key});

  @override
  ConsumerState<SharedProfileEditPage> createState() =>
      _SharedProfileEditPageState();
}

class _SharedProfileEditPageState
    extends ConsumerState<SharedProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  // ── Common controllers ────────────────────────────────────────────────────
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  // ── Student-only controllers ──────────────────────────────────────────────
  late final TextEditingController _parentNameController;
  late final TextEditingController _parentPhoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _dobDisplayController;

  // ── Focus nodes ───────────────────────────────────────────────────────────
  final _firstNameFocus  = FocusNode();
  final _lastNameFocus   = FocusNode();
  final _phoneFocus      = FocusNode();
  final _bioFocus        = FocusNode();
  final _parentNameFocus = FocusNode();
  final _parentPhoneFocus = FocusNode();
  final _addressFocus    = FocusNode();

  String?  _selectedGender;
  DateTime? _selectedDob;
  bool     _saving = false;

  static const _genderOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);

    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController  = TextEditingController(text: user?.lastName  ?? '');
    _phoneController     = TextEditingController(text: user?.phone     ?? '');
    _bioController       = TextEditingController(text: user?.bio       ?? '');

    _parentNameController  = TextEditingController(text: user?.parentGuardianName  ?? '');
    _parentPhoneController = TextEditingController(text: user?.parentGuardianPhone ?? '');
    _addressController     = TextEditingController(text: user?.address             ?? '');

    final rawGender = user?.gender ?? user?.sex;
    if (rawGender == 'M' || rawGender == 'Male') {
      _selectedGender = 'Male';
    } else if (rawGender == 'F' || rawGender == 'Female') {
      _selectedGender = 'Female';
    }

    _selectedDob = user?.dateOfBirth;
    _dobDisplayController = TextEditingController(
      text: _selectedDob != null ? _formatDob(_selectedDob!) : '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    _dobDisplayController.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _bioFocus.dispose();
    _parentNameFocus.dispose();
    _parentPhoneFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _decoration(String label, {Widget? suffixIcon}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
      suffixIcon: suffixIcon,
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

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String _formatDob(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')} / '
        '${d.month.toString().padLeft(2, '0')} / '
        '${d.year}';
  }

  Future<void> _pickDob() async {
    final now     = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 15, 1, 1);
    final picked  = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 25),
      lastDate:  DateTime(now.year - 5),
      helpText: 'Select date of birth',
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobDisplayController.text = _formatDob(picked);
      });
    }
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final user = ref.read(userProvider);
    if (user == null) return;

    final role = user.role;
    String? clean(String v) => v.trim().isEmpty ? null : v.trim();

    final sexCode = _selectedGender == 'Male'
        ? 'M'
        : _selectedGender == 'Female'
            ? 'F'
            : user.sex;

    // Build API payload — student fields only sent for students
    final payload = <String, dynamic>{
      'first_name':   _firstNameController.text.trim(),
      'last_name':    _lastNameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      if (role == 'student' && sexCode != null) 'sex': sexCode,
      if (role == 'student' && _selectedDob != null)
        'date_of_birth': _selectedDob!.toIso8601String().split('T').first,
    };

    dev.log('▶ SharedProfileEdit _save() role=$role', name: 'SharedProfileEdit');

    setState(() => _saving = true);
    try {
      await ref.read(authApiRepositoryProvider).updateMe(payload);

      // Mirror changes in Riverpod immediately so all screens update
      final AppUser updated;
      if (role == 'student') {
        updated = user.copyWith(
          firstName:          _firstNameController.text.trim(),
          lastName:           _lastNameController.text.trim(),
          phone:              _phoneController.text.trim(),
          bio:                clean(_bioController.text)         ?? user.bio,
          gender:             _selectedGender                    ?? user.gender,
          sex:                sexCode,
          dateOfBirth:        _selectedDob,
          parentGuardianName:  clean(_parentNameController.text)  ?? user.parentGuardianName,
          parentGuardianPhone: clean(_parentPhoneController.text) ?? user.parentGuardianPhone,
          address:            clean(_addressController.text)      ?? user.address,
        );
      } else {
        updated = user.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName:  _lastNameController.text.trim(),
          phone:     _phoneController.text.trim(),
          bio:       clean(_bioController.text) ?? user.bio,
        );
      }

      ref.read(userProvider.notifier).state = updated;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
        Navigator.of(context).pop<AppUser>(updated);
      }
    } catch (e, stack) {
      dev.log('❌ Save failed: $e', name: 'SharedProfileEdit', error: e, stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(userProvider);
    final role   = user?.role ?? '';
    final theme  = Theme.of(context);
    final cs     = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.surfaceVariant,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
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
                  // ── Role badge (read-only) ────────────────────────
                  if (role.isNotEmpty) ...[
                    _RoleBadge(role: role),
                    const SizedBox(height: 24),
                  ],

                  // ── Personal Information (all roles) ─────────────
                  _SectionHeader(title: 'Personal Information'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          focusNode: _firstNameFocus,
                          decoration: _decoration('First Name'),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => _required(v, 'First name'),
                          onFieldSubmitted: (_) =>
                              _lastNameFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          focusNode: _lastNameFocus,
                          decoration: _decoration('Last Name'),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => _required(v, 'Last name'),
                          onFieldSubmitted: (_) =>
                              _phoneFocus.requestFocus(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    decoration: _decoration(
                      'Phone',
                      suffixIcon: Icon(
                        Icons.phone_outlined,
                        color: cs.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _bioFocus.requestFocus(),
                  ),

                  // ── Teacher: Department (read-only) ───────────────
                  if (role == 'teacher') ...[
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Department',
                      value: user?.teacherDepartment ??
                          user?.gradeLevel ??
                          '—',
                      note: 'Managed by admin',
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Student-only: Gender + DOB ────────────────────
                  if (role == 'student') ...[
                    _SectionHeader(title: 'Personal Details'),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: _decoration('Gender'),
                      dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurface),
                      items: _genderOptions
                          .map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(g),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedGender = val),
                      hint: Text(
                        'Select gender',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: _pickDob,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dobDisplayController,
                          readOnly: true,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurface),
                          decoration: _decoration(
                            'Date of Birth',
                            suffixIcon: Icon(
                              Icons.calendar_today_outlined,
                              color: cs.onSurface.withValues(alpha: 0.4),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Student-only: Parent / Guardian ───────────────
                  if (role == 'student') ...[
                    _SectionHeader(title: 'Parent / Guardian'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _parentNameController,
                      focusNode: _parentNameFocus,
                      decoration: _decoration(
                        'Parent / Guardian Name',
                        suffixIcon: Icon(
                          Icons.person_outline,
                          color: cs.onSurface.withValues(alpha: 0.4),
                          size: 20,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      onFieldSubmitted: (_) =>
                          _parentPhoneFocus.requestFocus(),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _parentPhoneController,
                      focusNode: _parentPhoneFocus,
                      decoration: _decoration(
                        'Parent / Guardian Contact',
                        suffixIcon: Icon(
                          Icons.phone_outlined,
                          color: cs.onSurface.withValues(alpha: 0.4),
                          size: 20,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _addressFocus.requestFocus(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Student-only: Address ─────────────────────────
                  if (role == 'student') ...[
                    _SectionHeader(title: 'Address & Bio'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _addressController,
                      focusNode: _addressFocus,
                      decoration: _decoration(
                        'Home Address',
                        suffixIcon: Icon(
                          Icons.home_outlined,
                          color: cs.onSurface.withValues(alpha: 0.4),
                          size: 20,
                        ),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      onFieldSubmitted: (_) => _bioFocus.requestFocus(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Bio (all roles, section header only for non-student) ──
                  if (role != 'student') ...[
                    _SectionHeader(title: 'About'),
                    const SizedBox(height: 12),
                  ],

                  TextFormField(
                    controller: _bioController,
                    focusNode: _bioFocus,
                    decoration: _decoration('Bio / About'),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    onFieldSubmitted: (_) => _bioFocus.unfocus(),
                  ),

                  const SizedBox(height: 32),

                  // ── Save button ───────────────────────────────────
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        disabledBackgroundColor:
                            cs.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
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

// ── Role badge (read-only) ────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (label, bg, fg) = switch (role) {
      'student'   => ('STUDENT',   const Color(0xFFD0EBFF), const Color(0xFF1971C2)),
      'teacher'   => ('TEACHER',   const Color(0xFFD3F9D8), const Color(0xFF2F9E44)),
      'admin'     => ('ADMIN',     const Color(0xFFF8F2DC), const Color(0xFFB7791F)),
      'principal' => ('PRINCIPAL', const Color(0xFFEDEDFF), const Color(0xFF5C5FC6)),
      _           => ('USER',      const Color(0xFFF1F3F5), const Color(0xFF495057)),
    };

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? fg.withValues(alpha: 0.2) : bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

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

// ── Read-only field (e.g. teacher department) ─────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.note,
  });

  final String  label;
  final String  value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surface.withValues(alpha: 0.5)
            : cs.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 11,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
