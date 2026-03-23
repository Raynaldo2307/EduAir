import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';
import 'package:edu_air/src/features/admin/staff/application/admin_staff_provider.dart';
import 'admin_staff_edit_page.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class AdminStaffListPage extends ConsumerWidget {
  const AdminStaffListPage({super.key, required this.onBackToHome});

  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(schoolStaffProvider);

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Manage Staff'),
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.white,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: onBackToHome,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add staff member',
            onPressed: () => _openEditPage(context, ref, null),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: AppTheme.grey),
                const SizedBox(height: 12),
                Text(
                  'Failed to load staff.\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(schoolStaffProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (staff) {
          if (staff.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 48,
                    color: AppTheme.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No staff found in this school.',
                    style: TextStyle(fontSize: 16, color: AppTheme.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openEditPage(context, ref, null),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Add First Staff Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final member = staff[i];
              return _StaffTile(
                member: member,
                onEdit: () => _openEditPage(context, ref, member),
              );
            },
          );
        },
      ),
    );
  }

  void _openEditPage(
    BuildContext context,
    WidgetRef ref,
    AppUser? staff,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminStaffEditPage(staff: staff),
      ),
    );

    if (result == true) {
      ref.invalidate(schoolStaffProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff record updated')),
        );
      }
    }
  }
}

// ─── Staff Tile ───────────────────────────────────────────────────────────────

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member, required this.onEdit});

  final AppUser member;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dept = member.teacherDepartment;
    final shift = _shiftLabel(member.currentShift);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(initials: member.initials, photoUrl: member.photoUrl, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dept != null ? 'Teacher · $dept' : 'Teacher',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 1),
                Text(
                  '$shift · ${member.email}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  String _shiftLabel(String? shift) {
    switch (shift) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      default:
        return 'Whole Day';
    }
  }
}
