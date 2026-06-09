import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/admin/home/widgets/dashboard_card.dart';

class NoticeBoardCard extends ConsumerWidget {
  const NoticeBoardCard({super.key, this.onTap});

  /// Tapping the card opens the full Notice Board (Communication tab).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs           = Theme.of(context).colorScheme;
    final noticesAsync = ref.watch(noticesProvider);

    return GestureDetector(
      onTap: onTap,
      // opaque so taps on empty space inside the card still register
      // (the refresh IconButton keeps its own tap — child wins).
      behavior: HitTestBehavior.opaque,
      child: DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────
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
              IconButton(
                icon: Icon(Icons.refresh_outlined,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                onPressed: () => ref.invalidate(noticesProvider),
                tooltip: 'Refresh',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Body ──────────────────────────────────────────────────
          noticesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Could not load notices',
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ),
            data: (notices) {
              if (notices.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.campaign_outlined,
                          size: 36,
                          color: cs.onSurface.withValues(alpha: 0.18)),
                      const SizedBox(height: 8),
                      Text(
                        'No notices posted yet',
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                );
              }

              // Show at most 3 notices on the dashboard card.
              final preview = notices.take(3).toList();
              return Column(
                children: preview.map((n) {
                  final category = n['category'] as String? ?? 'general';
                  final (icon, iconColor, bgColor) = _categoryStyle(category);
                  final createdAt = DateTime.tryParse(
                          n['created_at'] as String? ?? '') ??
                      DateTime.now();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n['title'] as String? ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n['body'] as String? ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      ),
    );
  }

  // Maps category → (icon, iconColor, bgColor)
  (IconData, Color, Color) _categoryStyle(String category) =>
      switch (category) {
        'urgent'   => (Icons.warning_amber_outlined,  const Color(0xFFE65D7B), const Color(0xFFFDE9EC)),
        'event'    => (Icons.event_outlined,           const Color(0xFF4A7CFF), const Color(0xFFE8F2FF)),
        'reminder' => (Icons.alarm_outlined,           const Color(0xFFFF9F43), const Color(0xFFFFF3E0)),
        _          => (Icons.announcement_outlined,    const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes} min ago';
    if (diff.inHours   < 24)  return '${diff.inHours} hrs ago';
    if (diff.inDays    == 1)  return 'Yesterday';
    if (diff.inDays    <  7)  return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} wk ago';
  }
}
