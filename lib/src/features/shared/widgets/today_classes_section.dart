import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/models/class_session.dart';

class TodayClassesSection extends StatelessWidget {
  const TodayClassesSection({
    super.key,
    required this.sessions,
    this.onViewAll,
    this.title = "Today's classes",
    this.showTeacherName =
        false, // you said you DON'T want teacher name for now
  });

  final List<ClassSession> sessions;
  final VoidCallback? onViewAll;
  final String title;
  final bool showTeacherName;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row: title + "View all" ────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── List of today’s sessions ──────────────────────────────────────
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _ClassSessionTile(
              session: session,
              showTeacherName: showTeacherName,
            );
          },
        ),
      ],
    );
  }
}

class _ClassSessionTile extends StatelessWidget {
  const _ClassSessionTile({
    required this.session,
    required this.showTeacherName,
  });

  final ClassSession session;
  final bool showTeacherName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeRange = _formatTimeRange(session.startTime, session.endTime);

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      color: isDark ? AppTheme.darkCard : Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Left: subject initial / icon
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  session.subjectName.isNotEmpty
                      ? session.subjectName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Middle: subject, group, teacher (optional), time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject name
                  Text(
                    session.subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Group + time
                  Text(
                    '${session.groupName} • $timeRange',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),

                  if (showTeacherName) ...[
                    const SizedBox(height: 2),
                    Text(
                      session.teacherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right: room + "Online" chip if needed
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      session.room,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                if (session.isOnline) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple time formatting like "8:30–9:15"
String _formatTimeRange(DateTime start, DateTime end) {
  String fmt(DateTime dt) {
    final time = TimeOfDay.fromDateTime(dt);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  return '${fmt(start)} – ${fmt(end)}';
}
