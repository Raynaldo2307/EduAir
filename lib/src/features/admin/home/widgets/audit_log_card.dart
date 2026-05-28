import 'package:flutter/material.dart';
import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';
import 'package:edu_air/src/features/admin/home/widgets/dashboard_card.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

class AuditLogCard extends StatelessWidget {
  const AuditLogCard({super.key, required this.logs, this.onViewAll});

  final List<AuditLogEntry> logs;
  // Desktop: calls onSelectTab(6) so sidebar highlights correctly.
  // Mobile: null → falls back to Navigator.pushNamed('/adminAuditLog').
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Audit Logs',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: onViewAll ?? () => Navigator.pushNamed(context, '/adminAuditLog'),
                child: Text(
                  'View Full Log',
                  style: TextStyle(fontSize: 12, color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No activity yet today.',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            )
          else
            ...logs.take(5).map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    UserAvatar(initials: log.initials, radius: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.changedByName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            log.actionLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      log.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
