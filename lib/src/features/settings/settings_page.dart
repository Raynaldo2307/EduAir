import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';
import 'package:edu_air/src/features/shared/pages/shared_profile_edit_page.dart';
import 'package:edu_air/src/features/shared/pages/shared_profile_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notifications = true;

  String _schoolName(String? schoolId) {
    switch (schoolId) {
      case '1':
        return 'Papine High School';
      case '2':
        return 'Maggotty High School';
      case '3':
        return 'St. Catherine High School';
      default:
        return 'EduAir School';
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.delete();
    ref.read(userProvider.notifier).state = null;

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final role = user?.role ?? '';
    final isAdminOrPrincipal = role == 'admin' || role == 'principal';
    final name = user?.displayName ?? 'User';
    final email = user?.email ?? '—';
    final school = _schoolName(user?.schoolId);
    final className = user?.className;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // ── Profile card ──────────────────────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          UserAvatar(
                            initials: user?.initials ?? 'U',
                            photoUrl: user?.photoUrl,
                            radius: 40,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RoleBadge(role: role),
                      const SizedBox(height: 6),
                      Text(
                        school,
                        style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55)),
                      ),
                      if (role == 'student' && className != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          className,
                          style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55)),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
              ),

              // ── MY ACCOUNT ────────────────────────────────────────
              _SectionLabel('MY ACCOUNT'),
              _SectionCard(
                children: [
                  _SettingsRow(
                    icon: Icons.person_outline,
                    iconBg: const Color(0xFFE8F2FF),
                    iconColor: const Color(0xFF4A7CFF),
                    label: 'View Profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SharedProfilePage(),
                      ),
                    ),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: Icons.edit_outlined,
                    iconBg: const Color(0xFFE8F2FF),
                    iconColor: const Color(0xFF4A7CFF),
                    label: 'Edit Profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SharedProfileEditPage(),
                      ),
                    ),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: Icons.lock_outline,
                    iconBg: const Color(0xFFF5EBFF),
                    iconColor: const Color(0xFF9B51E0),
                    label: 'Change Password',
                    onTap: () => _showComingSoon(context, 'Change Password'),
                  ),
                ],
              ),

              // ── SCHOOL (admin / principal only) ───────────────────
              if (isAdminOrPrincipal) ...[
                _SectionLabel('SCHOOL'),
                _SectionCard(
                  children: [
                    _SettingsRow(
                      icon: Icons.school_outlined,
                      iconBg: const Color(0xFFE6F6F3),
                      iconColor: const Color(0xFF2D9CDB),
                      label: 'School Information',
                      onTap: () => _showComingSoon(context, 'School Information'),
                    ),
                    const _Divider(),
                    _SettingsRow(
                      icon: Icons.schedule_outlined,
                      iconBg: const Color(0xFFF8F2DC),
                      iconColor: const Color(0xFFB7791F),
                      label: 'Shift Settings',
                      onTap: () => _showComingSoon(context, 'Shift Settings'),
                    ),
                  ],
                ),
              ],

              // ── PREFERENCES ───────────────────────────────────────
              _SectionLabel('PREFERENCES'),
              _SectionCard(
                children: [
                  _ToggleRow(
                    icon: Icons.notifications_outlined,
                    iconBg: const Color(0xFFFDE9EC),
                    iconColor: const Color(0xFFE65D7B),
                    label: 'Push Notifications',
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                  const _Divider(),
                  _ToggleRow(
                    icon: Icons.dark_mode_outlined,
                    iconBg: const Color(0xFFEFF4FF),
                    iconColor: const Color(0xFF4A5568),
                    label: 'Dark Mode',
                    value: ref.watch(themeModeProvider) == ThemeMode.dark,
                    onChanged: (v) => ref.read(themeModeProvider.notifier).state =
                        v ? ThemeMode.dark : ThemeMode.light,
                  ),
                ],
              ),

              // ── SUPPORT ───────────────────────────────────────────
              _SectionLabel('SUPPORT'),
              _SectionCard(
                children: [
                  _SettingsRow(
                    icon: Icons.help_outline,
                    iconBg: const Color(0xFFE6F6F3),
                    iconColor: const Color(0xFF2D9CDB),
                    label: 'Help & FAQ',
                    onTap: () => _showComingSoon(context, 'Help & FAQ'),
                  ),
                  const _Divider(),
                  _SettingsRow(
                    icon: Icons.info_outline,
                    iconBg: const Color(0xFFE8F2FF),
                    iconColor: const Color(0xFF4A7CFF),
                    label: 'About EduAir',
                    onTap: () => _showComingSoon(context, 'About EduAir'),
                  ),
                ],
              ),

              // ── LOG OUT ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature — coming soon')));
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ─── Settings Row ─────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Toggle Row ───────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.secondaryColor,
          ),
        ],
      ),
    );
  }
}

// ─── Role Badge ───────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (role) {
      'student'   => ('STUDENT',   const Color(0xFFD0EBFF), const Color(0xFF1971C2)),
      'teacher'   => ('TEACHER',   const Color(0xFFD3F9D8), const Color(0xFF2F9E44)),
      'admin'     => ('ADMIN',     const Color(0xFFF8F2DC), const Color(0xFFB7791F)),
      'principal' => ('PRINCIPAL', const Color(0xFFEDEDFF), const Color(0xFF5C5FC6)),
      _           => ('USER',      const Color(0xFFF1F3F5), const Color(0xFF495057)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}
