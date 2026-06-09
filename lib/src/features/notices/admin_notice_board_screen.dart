import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:edu_air/src/core/app_providers.dart';

class AdminNoticeBoardScreen extends ConsumerWidget {
  const AdminNoticeBoardScreen({super.key, this.onBackToHome});
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs           = Theme.of(context).colorScheme;
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Notice Board'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: onBackToHome,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(noticesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'post_notice_fab',
        onPressed: () => _showPostSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Post Notice'),
      ),
      body: noticesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      color: cs.onSurface.withValues(alpha: 0.18)),
                  const SizedBox(height: 12),
                  Text('No notices posted yet',
                      style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurface.withValues(alpha: 0.45))),
                  const SizedBox(height: 6),
                  Text('Tap "Post Notice" to create one',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.3))),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = notices[i];
              return _NoticeTile(
                notice: n,
                onDelete: () => _confirmDelete(context, ref, n),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPostSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _PostNoticeSheet(
        onPosted: () => ref.invalidate(noticesProvider),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Map<String, dynamic> notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete notice?'),
        content: Text('"${notice['title']}" will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(noticesApiRepositoryProvider)
          .delete(notice['id'] as int);
      ref.invalidate(noticesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── Notice tile ──────────────────────────────────────────────────────────────

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice, required this.onDelete});
  final Map<String, dynamic> notice;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final category = notice['category'] as String? ?? 'general';
    final (icon, iconColor, bgColor) = _categoryStyle(category);
    final createdAt = DateTime.tryParse(notice['created_at'] as String? ?? '');
    final expiresAt = notice['expires_at'] != null
        ? DateTime.tryParse(notice['expires_at'] as String)
        : null;

    return Dismissible(
      key: ValueKey(notice['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // let onDelete handle the actual delete + refresh
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip + title
                  Row(
                    children: [
                      _CategoryChip(category: category,
                          color: iconColor, bgColor: bgColor),
                      const Spacer(),
                      if (expiresAt != null)
                        Text(
                          'Expires ${DateFormat('MMM d').format(expiresAt)}',
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notice['title'] as String? ?? '',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notice['body'] as String? ?? '',
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.65),
                        height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  // Posted by + date
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.35)),
                      const SizedBox(width: 4),
                      Text(
                        notice['created_by_name'] as String? ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.45)),
                      ),
                      const Spacer(),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMM d, yyyy').format(createdAt),
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.35)),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.3)),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _categoryStyle(String category) =>
      switch (category) {
        'urgent'   => (Icons.warning_amber_outlined,  const Color(0xFFE65D7B), const Color(0xFFFDE9EC)),
        'event'    => (Icons.event_outlined,           const Color(0xFF4A7CFF), const Color(0xFFE8F2FF)),
        'reminder' => (Icons.alarm_outlined,           const Color(0xFFFF9F43), const Color(0xFFFFF3E0)),
        _          => (Icons.announcement_outlined,    const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
      };
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(
      {required this.category,
      required this.color,
      required this.bgColor});
  final String category;
  final Color  color;
  final Color  bgColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(20)),
        child: Text(
          category[0].toUpperCase() + category.substring(1),
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

// ─── Post notice bottom sheet ─────────────────────────────────────────────────

class _PostNoticeSheet extends ConsumerStatefulWidget {
  const _PostNoticeSheet({required this.onPosted});
  final VoidCallback onPosted;

  @override
  ConsumerState<_PostNoticeSheet> createState() => _PostNoticeSheetState();
}

class _PostNoticeSheetState extends ConsumerState<_PostNoticeSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  String   _category  = 'general';
  String   _audience  = 'all';
  DateTime? _expiresAt;
  bool     _saving    = false;
  String?  _error;

  static const _categories = {
    'general':  'General',
    'urgent':   'Urgent',
    'event':    'Event',
    'reminder': 'Reminder',
  };

  // "Send to" options — label + icon for the audience cards.
  static const _audiences = [
    (key: 'all',      label: 'Everyone', icon: Icons.groups_outlined),
    (key: 'teachers', label: 'Teachers', icon: Icons.co_present_outlined),
    (key: 'parents',  label: 'Parents',  icon: Icons.family_restroom_outlined),
    (key: 'students', label: 'Students', icon: Icons.backpack_outlined),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body  = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() => _error = 'Title and body are required.');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(noticesApiRepositoryProvider).create(
        title:          title,
        body:           body,
        category:       _category,
        targetAudience: _audience,
        expiresAt: _expiresAt != null
            ? DateFormat('yyyy-MM-dd').format(_expiresAt!)
            : null,
      );
      widget.onPosted();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = 'Failed to post: $e'; _saving = false; });
    }
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),

            Text('Post a Notice',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 20),

            // Error banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(_error!,
                    style: TextStyle(color: cs.onErrorContainer,
                        fontSize: 13)),
              ),
              const SizedBox(height: 14),
            ],

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),

            // Body
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Body',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // Category chips
            Text('Category',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.entries.map((e) {
                final selected = _category == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _category = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? cs.onPrimary
                              : cs.onSurface),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Send to (audience) — also picks the FCM push topic later.
            Text('Send to',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Row(
              children: _audiences.map((a) {
                final selected = _audience == a.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _audience = a.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                selected ? cs.primary : cs.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Icon(a.icon,
                              size: 22,
                              color: selected
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant),
                          const SizedBox(height: 6),
                          Text(a.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? cs.onPrimary
                                      : cs.onSurface)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Expiry date (optional)
            GestureDetector(
              onTap: _pickExpiry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _expiresAt != null
                            ? 'Expires ${DateFormat('MMM d, yyyy').format(_expiresAt!)}'
                            : 'No expiry date (optional)',
                        style: TextStyle(
                            fontSize: 13,
                            color: _expiresAt != null
                                ? cs.onSurface
                                : cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ),
                    if (_expiresAt != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiresAt = null),
                        child: Icon(Icons.close,
                            size: 16,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Post button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Post Notice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
