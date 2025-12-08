import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';

class SelectRolePage extends ConsumerStatefulWidget {
  const SelectRolePage({super.key});

  @override
  ConsumerState<SelectRolePage> createState() => _SelectRolePageState();
}

class _SelectRolePageState extends ConsumerState<SelectRolePage> {
  String? _selectedRole; // 'student' or 'teacher'
  bool _isSaving = false;
  bool _isLoadingUser = true;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadCurrentUser() async {
    try {
      final cachedUser = ref.read(userProvider);
      final userService = ref.read(userServiceProvider);
      final profile = cachedUser ?? await userService.getCurrentUserProfile();

      if (!mounted) return;
      setState(() {
        _currentUser = profile;
        _selectedRole = profile?.role; // pre-select if already set
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _saveRoleAndContinue() async {
    if (_selectedRole == null) {
      _showSnack('Please select a role');
      return;
    }

    final currentUser = _currentUser ?? ref.read(userProvider);

    if (currentUser == null) {
      _showSnack('Unable to load your profile. Please log in again.');
      return;
    }

    // Hide keyboard before we start async work
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    try {
      final userService = ref.read(userServiceProvider);

      // 1. Save to Firestore
      await userService.updateUserRole(currentUser.uid, _selectedRole!);

      // 2. Update in-memory state
      final updatedUser = currentUser.copyWith(role: _selectedRole!);
      ref.read(userProvider.notifier).state = updatedUser;

      if (!mounted) return;

      // 3. Route to the correct shell
      final nextRoute = _selectedRole == 'teacher'
          ? '/teacherHome'
          : '/studentHome';
      Navigator.pushReplacementNamed(context, nextRoute);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error saving role: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildRoleCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == value;

    return Expanded(
      child: AnimatedScale(
        scale: isSelected ? 1.003 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedRole = value;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: isSelected ? 18 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade500,
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primaryColor : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _currentUser?.displayName ?? 'there';

    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      appBar: AppBar(
        title: Text(
          'Select Role',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Welcome, $name 👋',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Select how you will use the app.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildRoleCard(
                        label: 'Student',
                        value: 'student',
                        icon: Icons.school,
                      ),
                      _buildRoleCard(
                        label: 'Teacher',
                        value: 'teacher',
                        icon: Icons.person,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "We'll remember this choice for your account. You can change it later in Settings.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(25),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveRoleAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
