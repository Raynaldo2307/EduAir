import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';

// TODO: wire to GET /api/staff once backend endpoint is built
// For now shows hardcoded staff — same UI pattern as AdminStudentListPage

class AdminStaffListPage extends StatelessWidget {
  const AdminStaffListPage({super.key, required this.onBackToHome});

  final VoidCallback onBackToHome;

  static const _staff = [
    _StaffMember(
      initials: 'MB',
      name: 'Mr. Marcus Brown',
      role: 'Teacher',
      department: 'Mathematics',
      email: 'mr.brown@stcath.edu.jm',
    ),
    _StaffMember(
      initials: 'SC',
      name: 'Ms. Sandra Campbell',
      role: 'Teacher',
      department: 'Science',
      email: 'ms.campbell@stcath.edu.jm',
    ),
    _StaffMember(
      initials: 'DW',
      name: 'Mr. Devon Williams',
      role: 'Teacher',
      department: 'English',
      email: 'd.williams@stcath.edu.jm',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Manage Staff'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: onBackToHome,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add staff member',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add staff — coming soon')),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _staff.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final member = _staff[i];
          return _StaffTile(member: member);
        },
      ),
    );
  }
}

// ─── Staff Tile ───────────────────────────────────────────────────────────────

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member});

  final _StaffMember member;

  static const _bgColors = [
    Color(0xFFE8F2FF),
    Color(0xFFF5EBFF),
    Color(0xFFE6F6F3),
  ];

  static const _iconColors = [
    Color(0xFF4A7CFF),
    Color(0xFF9B51E0),
    Color(0xFF2D9CDB),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = member.initials.codeUnitAt(0) % _bgColors.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
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
          CircleAvatar(
            radius: 24,
            backgroundColor: _bgColors[idx],
            child: Text(
              member.initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _iconColors[idx],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.role} · ${member.department}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                ),
                const SizedBox(height: 1),
                Text(
                  member.email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppTheme.grey,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit ${member.name} — coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _StaffMember {
  const _StaffMember({
    required this.initials,
    required this.name,
    required this.role,
    required this.department,
    required this.email,
  });

  final String initials;
  final String name;
  final String role;
  final String department;
  final String email;
}
