import 'package:flutter/material.dart';
import 'package:edu_air/src/features/admin/home/widgets/dashboard_card.dart';

class NoticeBoardCard extends StatelessWidget {
  const NoticeBoardCard({super.key});

  static const _notices = [
    (
      icon: Icons.menu_book_outlined,
      iconColor: Color(0xFF4A7CFF),
      bgColor: Color(0xFFE8F2FF),
      title: 'New Syllabus Released',
      body: 'Updated academic curriculum for Grade 10',
      time: '2 hrs ago',
    ),
    (
      icon: Icons.note_outlined,
      iconColor: Color(0xFF9B51E0),
      bgColor: Color(0xFFF5EBFF),
      title: 'Note for Second Term',
      body: 'New note for second term has been posted',
      time: 'Yesterday',
    ),
    (
      icon: Icons.poll_outlined,
      iconColor: Color(0xFFFF9F43),
      bgColor: Color(0xFFFFF3E0),
      title: 'Student Food Survey',
      body: 'Please complete the canteen feedback form',
      time: 'Last week',
    ),
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
                'Notice Board',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: Text(
                  'View More',
                  style: TextStyle(fontSize: 12, color: cs.primary),
                ),
                label: Icon(Icons.chevron_right, size: 16, color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Notice rows
          ..._notices.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: n.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(n.icon, color: n.iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          n.body,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    n.time,
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
