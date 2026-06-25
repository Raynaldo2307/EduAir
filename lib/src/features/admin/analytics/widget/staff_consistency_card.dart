import 'package:flutter/material.dart';
import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

class StaffConsistencyCard extends StatelessWidget {
  const StaffConsistencyCard({super.key, required this.staff});

  final List<StaffConsistency> staff;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Staff Consistency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...staff.map((member) => _StaffRow(member: member, cs: cs)),
        ],
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.member, required this.cs});

  final StaffConsistency member;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          UserAvatar(
            initials: member.initials,
            photoUrl: member.photoUrl,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.firstName} ${member.lastName}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.department.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Shield badge — gold colour signals high consistency/reliability
          const Icon(Icons.shield, color: Color(0xFFB7791F), size: 22),
        ],
      ),
    );
  }
}
