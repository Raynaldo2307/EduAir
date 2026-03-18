import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/attendance/application/timetable_provider.dart';

/// Time Table tab — shown when the student switches to the "Time Table" tab
/// on the Calendar screen. Design mirrors the FlutterFlow template reference.
class TimetableTab extends ConsumerWidget {
  const TimetableTab({super.key});

  static const _monthNames = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  static const _dayNames = [
    '', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Mon … 7 = Sun

    final className = user?.className ?? 'Your Class';
    final entries = ref.watch(timetableProvider(weekday));

    final dateLabel =
        '${now.day} ${_monthNames[now.month - 1]} ${now.year}';

    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ── Date header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Column headers ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  'Time',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Text(
                'Class',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Timeline list or empty state ─────────────────────────────
        Expanded(
          child: entries.isEmpty
              ? _buildWeekendState(context, _dayNames[weekday])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isLast = index == entries.length - 1;
                    return _TimetableRow(
                      time: entry.time,
                      subject: entry.subject,
                      className: className,
                      isLast: isLast,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWeekendState(BuildContext context, String dayName) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.weekend_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            dayName.isEmpty ? 'No classes today' : 'No classes on $dayName',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy your day off!',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single row in the timetable — time on left, blue dot timeline,
/// subject + class on right.
class _TimetableRow extends StatelessWidget {
  const _TimetableRow({
    required this.time,
    required this.subject,
    required this.className,
    required this.isLast,
  });

  final String time;
  final String subject;
  final String className;
  final bool isLast;

  static const _dotSize = 10.0;
  static const _lineWidth = 2.0;
  static const _timeWidth = 48.0;
  static const _rowMinHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time ──────────────────────────────────
          SizedBox(
            width: _timeWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Vertical timeline ──────────────────────
          SizedBox(
            width: 20,
            child: Column(
              children: [
                // line above dot
                Container(
                  width: _lineWidth,
                  height: 18,
                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                ),
                // dot
                Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                // line below dot (hidden on last item)
                Expanded(
                  child: Container(
                    width: _lineWidth,
                    color: isLast
                        ? Colors.transparent
                        : AppTheme.primaryColor.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Subject + class ────────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: _rowMinHeight),
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '($className)',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
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
