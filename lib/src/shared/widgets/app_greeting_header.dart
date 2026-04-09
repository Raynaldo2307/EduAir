import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/student/home/widgets/search_box.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

/// Shared greeting header used across all roles (student, teacher, admin,
/// principal, parent). Design stays consistent — only the context changes.
class AppGreetingHeader extends StatelessWidget {
  const AppGreetingHeader({
    super.key,
    required this.name,
    required this.id,
    required this.initials,
    this.subtitle,
    this.avatarUrl,
    this.onBellTap,
  });

  /// Display name of the logged-in user.
  final String name;

  /// Role-specific ID shown above the greeting (student ID, staff ID, etc.).
  final String id;

  /// Optional second line under the greeting (department, school name, etc.).
  final String? subtitle;

  final String? avatarUrl;
  final String initials;
  final VoidCallback? onBellTap;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting, $name',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  _IconCircle(
                    onTap: onBellTap,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  const SizedBox(width: 12),
                  UserAvatar(
                    initials: initials,
                    photoUrl: avatarUrl,
                    radius: 21,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SearchBox(),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

