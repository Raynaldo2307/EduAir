import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/student/home/widgets/search_box.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.name,
    required this.teacherId,
    required this.teacherDepartment,
    this.avatarUrl,
    this.onBellTap,
  });

  final String name;
  final String teacherId;
  final String teacherDepartment;
  final String? avatarUrl;
  final VoidCallback? onBellTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
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
              // LEFT: ID + Greeting + Department
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: $teacherId',
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Good Morning, $name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacherDepartment,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // RIGHT: bell + avatar
              Row(
                children: [
                  _IconCircle(
                    onTap: onBellTap,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  const SizedBox(width: 12),
                  _AvatarCircle(avatarUrl: avatarUrl),
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

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _DefaultAvatar(),
            )
          : const _DefaultAvatar(),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.12),
      child: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
    );
  }
}
