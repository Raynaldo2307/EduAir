import 'package:flutter/material.dart';
import 'package:edu_air/src/features/admin/home/widgets/dashboard_card.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

class AuditLogCard extends StatelessWidget {
  const AuditLogCard({super.key});

  static const _logs = [
    (name: 'Marcus B.', action: 'Submitted Attendance', time: '5 min ago'),
    (name: 'Sarah C.', action: 'Created Student Account', time: '10 min ago'),
    (name: 'David W.', action: 'Updated Student Account', time: '11 min ago'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
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
                onPressed: () {},
                child: Text(
                  'View Full Log',
                  style: TextStyle(fontSize: 12, color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Log rows
          ..._logs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  UserAvatar(initials: log.name.substring(0, 2), radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          log.action,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    log.time,
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
