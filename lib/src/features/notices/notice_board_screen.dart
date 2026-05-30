import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:edu_air/src/core/app_providers.dart';

class NoticeBoardScreen extends ConsumerWidget {
  const NoticeBoardScreen({super.key});

  static const _categoryMeta = {
    'general':     (Icons.info_outline,          Color(0xFF1565C0), Color(0xFFE3F2FD)),
    'urgent':      (Icons.warning_amber_outlined, Color(0xFFB71C1C), Color(0xFFFFEBEE)),
    'event':       (Icons.event_outlined,         Color(0xFF1B5E20), Color(0xFFE8F5E9)),
    'holiday':     (Icons.celebration_outlined,   Color(0xFF4A148C), Color(0xFFF3E5F5)),
    'maintenance': (Icons.build_outlined,         Color(0xFFE65100), Color(0xFFFFF3E0)),
  };

  (IconData, Color, Color) _categoryStyle(String cat) =>
      _categoryMeta[cat] ??
      (Icons.info_outline, const Color(0xFF1565C0), const Color(0xFFE3F2FD));

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours   < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays    < 7)  return '${diff.inDays} days ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs           = Theme.of(context).colorScheme;
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Notice Board',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? cs.surface : Colors.white,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(noticesProvider),
          ),
        ],
      ),
      body: noticesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text('Failed to load notices',
                  style: TextStyle(color: cs.error)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(noticesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notices) {
          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 56,
                      color: cs.onSurface.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),
                  Text('No notices posted yet.',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: notices.length,
            itemBuilder: (context, i) {
              final n      = notices[i];
              final cat    = n['category'] as String? ?? 'general';
              final style  = _categoryStyle(cat);
              final icon   = style.$1;
              final fg     = style.$2;
              final bg     = style.$3;
              final expiry = n['expires_at'] as String?;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? cs.surfaceContainerLow : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: bg, borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, color: fg, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category chip + title
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                    cat[0].toUpperCase() + cat.substring(1),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: fg),
                                  ),
                                ),
                                if (expiry != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.schedule_outlined,
                                      size: 12,
                                      color: cs.onSurface.withValues(alpha: 0.4)),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Expires ${DateFormat('MMM d').format(DateTime.parse(expiry))}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: cs.onSurface.withValues(alpha: 0.4)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n['title'] as String? ?? '',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface),
                            ),
                            if ((n['body'] as String?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                n['body'] as String,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurface.withValues(alpha: 0.7),
                                    height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              _timeAgo(n['created_at'] as String? ?? ''),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
