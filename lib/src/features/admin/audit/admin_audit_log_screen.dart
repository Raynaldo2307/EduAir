import 'dart:io';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html show Blob, Url, AnchorElement;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';

// ── Filter model ──────────────────────────────────────────────────────────────

class AuditFilter {
  final String search;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? source;
  final String? shiftType;
  final String? newStatus;
  final bool statusCorrection;
  final int limit;

  const AuditFilter({
    this.search          = '',
    this.fromDate,
    this.toDate,
    this.source,
    this.shiftType,
    this.newStatus,
    this.statusCorrection = false,
    this.limit           = 50,
  });

  AuditFilter copyWith({
    String?   search,
    Object?   fromDate  = _sentinel,
    Object?   toDate    = _sentinel,
    Object?   source    = _sentinel,
    Object?   shiftType = _sentinel,
    Object?   newStatus = _sentinel,
    bool?     statusCorrection,
    int?      limit,
  }) => AuditFilter(
    search:           search           ?? this.search,
    fromDate:         fromDate  == _sentinel ? this.fromDate  : fromDate  as DateTime?,
    toDate:           toDate    == _sentinel ? this.toDate    : toDate    as DateTime?,
    source:           source    == _sentinel ? this.source    : source    as String?,
    shiftType:        shiftType == _sentinel ? this.shiftType : shiftType as String?,
    newStatus:        newStatus == _sentinel ? this.newStatus : newStatus as String?,
    statusCorrection: statusCorrection ?? this.statusCorrection,
    limit:            limit            ?? this.limit,
  );

  // How many non-search filters are active — drives the badge on the filter button.
  int get activeCount {
    int n = 0;
    if (fromDate != null || toDate != null) n++;
    if (source   != null) n++;
    if (shiftType != null) n++;
    if (newStatus != null) n++;
    if (statusCorrection)  n++;
    return n;
  }

  bool get isEmpty =>
      search.isEmpty && activeCount == 0;

  // Build query string for the API call.
  String toQueryString() {
    final parts = <String>['limit=$limit'];
    if (search.isNotEmpty)  parts.add('search=${Uri.encodeComponent(search)}');
    if (fromDate != null)   parts.add('from_date=${_fmt(fromDate!)}');
    if (toDate   != null)   parts.add('to_date=${_fmt(toDate!)}');
    if (source   != null)   parts.add('source=${Uri.encodeComponent(source!)}');
    if (shiftType != null)  parts.add('shift_type=${Uri.encodeComponent(shiftType!)}');
    if (newStatus != null)  parts.add('new_status=${Uri.encodeComponent(newStatus!)}');
    if (statusCorrection)   parts.add('status_correction=true');
    return parts.join('&');
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _sentinel = Object();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final auditFilterProvider =
    StateProvider.autoDispose<AuditFilter>((ref) => const AuditFilter());

final adminAuditLogsProvider =
    FutureProvider.autoDispose<List<AuditLogEntry>>((ref) async {
  final client = ref.read(apiClientProvider);
  final filter = ref.watch(auditFilterProvider);
  final resp   = await client.dio.get('/api/dashboard/audit-logs?${filter.toQueryString()}');
  final raw    = (resp.data?['auditLogs'] as List<dynamic>?) ?? [];
  return raw.map((row) {
    final m = row as Map<String, dynamic>;
    return AuditLogEntry(
      changedByName:  m['changed_by_name']  as String? ?? 'Unknown',
      source:         m['source']           as String? ?? 'studentSelf',
      newStatus:      m['new_status']       as String? ?? '',
      previousStatus: m['previous_status']  as String?,
      createdAt:      DateTime.tryParse(m['created_at']      as String? ?? '') ?? DateTime.now(),
      studentName:    m['student_name']     as String? ?? '',
      shiftType:      m['shift_type']       as String? ?? '',
      attendanceDate: m['attendance_date']  as String? ?? '',
    );
  }).toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  final _searchController = TextEditingController();
  bool _exporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      // Call the dedicated export endpoint — no row cap, returns all matching records.
      final filter = ref.read(auditFilterProvider);
      final client = ref.read(apiClientProvider);

      // Build the same query string but without limit/offset.
      final params = filter.toQueryString()
          .replaceAll(RegExp(r'limit=\d+&?'), '')
          .replaceAll(RegExp(r'&limit=\d+'), '');

      final resp = await client.dio.get('/api/dashboard/audit-logs/export?$params');
      final raw  = (resp.data?['auditLogs'] as List<dynamic>?) ?? [];

      final buf = StringBuffer();
      buf.writeln('Date,Student,Changed By,Action,Previous Status,New Status,Shift,Timestamp');
      for (final row in raw) {
        final m = row as Map<String, dynamic>;
        buf.writeln(
          '"${m['attendance_date'] ?? ''}",'
          '"${m['student_name']    ?? ''}",'
          '"${m['changed_by_name'] ?? ''}",'
          '"${_sourceLabel(m['source'] as String? ?? '')}",'
          '"${m['previous_status'] ?? '-'}",'
          '"${m['new_status']      ?? ''}",'
          '"${m['shift_type']      ?? ''}",'
          '"${m['created_at']      ?? ''}"',
        );
      }

      if (!mounted) return;
      setState(() => _exporting = false);

      if (kIsWeb) {
        // Web: create a blob URL and click an invisible anchor to download.
        final blob = html.Blob([buf.toString()], 'text/csv');
        final url  = html.Url.createObjectUrlFromBlob(blob);
        (html.AnchorElement(href: url)
          ..setAttribute('download', 'audit_log_export.csv')
          ..click());
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile: write to temp file and open share sheet.
        final dir  = await getTemporaryDirectory();
        final file = File('${dir.path}/audit_log_export.csv');
        await file.writeAsString(buf.toString());
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv')],
          subject: 'EduAir Audit Log — ${raw.length} records',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ── Filter bottom sheet ───────────────────────────────────────────────────

  Future<void> _showFilterSheet() async {
    final current = ref.read(auditFilterProvider);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _FilterSheet(
        initial: current,
        onApply: (f) {
          ref.read(auditFilterProvider.notifier).state = f;
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final filter    = ref.watch(auditFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('System Audit Log',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          // Export button
          logsAsync.whenOrNull(
            data: (logs) => _exporting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Export CSV',
                    onPressed: _export,
                  ),
          ) ?? const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminAuditLogsProvider),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search + filter row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      ref.read(auditFilterProvider.notifier).state =
                          filter.copyWith(search: v);
                    },
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search student or staff name…',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      prefixIcon: Icon(Icons.search,
                          size: 20,
                          color: cs.onSurface.withValues(alpha: 0.45)),
                      suffixIcon: filter.search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(auditFilterProvider.notifier)
                                    .state = filter.copyWith(search: '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? cs.surfaceContainerHighest
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filter button with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showFilterSheet,
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Filters'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        side: BorderSide(color: cs.outlineVariant),
                        backgroundColor: isDark
                            ? cs.surfaceContainerHighest
                            : Colors.white,
                      ),
                    ),
                    if (filter.activeCount > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            '${filter.activeCount}',
                            style: TextStyle(
                                fontSize: 10,
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Active filter chips ──────────────────────────────────────────
          if (filter.activeCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (filter.fromDate != null || filter.toDate != null)
                    _ActiveChip(
                      label: '${filter.fromDate != null ? AuditFilter._fmt(filter.fromDate!) : '…'}'
                          ' → ${filter.toDate != null ? AuditFilter._fmt(filter.toDate!) : '…'}',
                      onRemove: () => ref
                          .read(auditFilterProvider.notifier)
                          .state = filter.copyWith(
                              fromDate: null, toDate: null),
                    ),
                  if (filter.source != null)
                    _ActiveChip(
                      label: _sourceLabel(filter.source!),
                      onRemove: () => ref
                          .read(auditFilterProvider.notifier)
                          .state = filter.copyWith(source: null),
                    ),
                  if (filter.shiftType != null)
                    _ActiveChip(
                      label: _capitalize(filter.shiftType!),
                      onRemove: () => ref
                          .read(auditFilterProvider.notifier)
                          .state = filter.copyWith(shiftType: null),
                    ),
                  if (filter.newStatus != null)
                    _ActiveChip(
                      label: _capitalize(filter.newStatus!),
                      onRemove: () => ref
                          .read(auditFilterProvider.notifier)
                          .state = filter.copyWith(newStatus: null),
                    ),
                  if (filter.statusCorrection)
                    _ActiveChip(
                      label: 'Corrections only',
                      onRemove: () => ref
                          .read(auditFilterProvider.notifier)
                          .state =
                          filter.copyWith(statusCorrection: false),
                    ),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(auditFilterProvider.notifier).state =
                          const AuditFilter();
                    },
                    child: Text('Clear all',
                        style: TextStyle(
                            fontSize: 12, color: cs.error)),
                  ),
                ],
              ),
            ),

          // ── Record count ─────────────────────────────────────────────────
          logsAsync.whenOrNull(
            data: (logs) => Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 16, 4),
              child: Text(
                '${logs.length} record${logs.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary),
              ),
            ),
          ) ?? const SizedBox(height: 10),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: logsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 12),
                    Text('Failed to load audit log',
                        style: TextStyle(color: cs.error)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(adminAuditLogsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history,
                            size: 52,
                            color: cs.onSurface.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Text(
                          filter.isEmpty
                              ? 'No audit records yet.'
                              : 'No results for the current filters.',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.45)),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: logs.length,
                  itemBuilder: (context, i) => _AuditTile(
                    log: logs[i],
                    cs: cs,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.onApply});
  final AuditFilter initial;
  final ValueChanged<AuditFilter> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late AuditFilter _f;

  @override
  void initState() {
    super.initState();
    _f = widget.initial;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _f.fromDate : _f.toDate) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _f = isFrom
          ? _f.copyWith(fromDate: picked)
          : _f.copyWith(toDate: picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),

            Text('Filters',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),

            const SizedBox(height: 20),

            // ── Date range ─────────────────────────────────────────────
            _SectionLabel('Date Range'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: _f.fromDate != null
                        ? AuditFilter._fmt(_f.fromDate!)
                        : 'From date',
                    onTap: () => _pickDate(isFrom: true),
                    onClear: _f.fromDate != null
                        ? () => setState(() =>
                            _f = _f.copyWith(fromDate: null))
                        : null,
                    cs: cs,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateButton(
                    label: _f.toDate != null
                        ? AuditFilter._fmt(_f.toDate!)
                        : 'To date',
                    onTap: () => _pickDate(isFrom: false),
                    onClear: _f.toDate != null
                        ? () => setState(
                            () => _f = _f.copyWith(toDate: null))
                        : null,
                    cs: cs,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Source ─────────────────────────────────────────────────
            _SectionLabel('Action Type'),
            const SizedBox(height: 8),
            _ChipRow(
              options: const {
                null:           'All',
                'studentSelf':  'Student Self',
                'teacherBatch': 'Teacher Batch',
                'adminEdit':    'Admin Edit',
              },
              selected: _f.source,
              onSelect: (v) => setState(() => _f = _f.copyWith(source: v)),
            ),

            const SizedBox(height: 20),

            // ── Shift ──────────────────────────────────────────────────
            _SectionLabel('Shift'),
            const SizedBox(height: 8),
            _ChipRow(
              options: const {
                null:        'All',
                'morning':   'Morning',
                'afternoon': 'Afternoon',
                'whole_day': 'Whole Day',
              },
              selected: _f.shiftType,
              onSelect: (v) =>
                  setState(() => _f = _f.copyWith(shiftType: v)),
            ),

            const SizedBox(height: 20),

            // ── Status ─────────────────────────────────────────────────
            _SectionLabel('Status'),
            const SizedBox(height: 8),
            _ChipRow(
              options: const {
                null:      'All',
                'early':   'Early',
                'present': 'Present',
                'late':    'Late',
                'absent':  'Absent',
                'excused': 'Excused',
              },
              selected: _f.newStatus,
              onSelect: (v) =>
                  setState(() => _f = _f.copyWith(newStatus: v)),
            ),

            const SizedBox(height: 20),

            // ── Status correction toggle ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surfaceContainerHighest
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: SwitchListTile(
                title: Text('Corrections only',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                subtitle: Text(
                    'Only show records where status was changed',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.55))),
                value: _f.statusCorrection,
                onChanged: (v) =>
                    setState(() => _f = _f.copyWith(statusCorrection: v)),
              ),
            ),

            const SizedBox(height: 28),

            // ── Limit ──────────────────────────────────────────────────
            _SectionLabel('Records to load'),
            const SizedBox(height: 8),
            _ChipRow(
              options: const {
                50:  '50',
                100: '100',
                200: '200',
              },
              selected: _f.limit,
              onSelect: (v) =>
                  setState(() => _f = _f.copyWith(limit: v ?? 50)),
            ),

            const SizedBox(height: 28),

            // ── Buttons ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _f = const AuditFilter()),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => widget.onApply(_f),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Audit tile ────────────────────────────────────────────────────────────────

class _AuditTile extends StatelessWidget {
  const _AuditTile(
      {required this.log, required this.cs, required this.isDark});
  final AuditLogEntry log;
  final ColorScheme cs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          UserAvatar(initials: log.initials, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Changed by name — primary colour like staff list
                Text(
                  log.changedByName,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary),
                ),
                const SizedBox(height: 2),
                // Student name
                if (log.studentName.isNotEmpty)
                  Text(
                    'Student: ${log.studentName}',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                const SizedBox(height: 4),
                // Action chip + status chip (+ arrow if correction)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _SourceChip(source: log.source),
                    if (log.isCorrection && log.previousStatus != null) ...[
                      _StatusChip(status: log.previousStatus!),
                      Icon(Icons.arrow_forward,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                    ],
                    _StatusChip(status: log.newStatus),
                    _ShiftChip(shift: log.shiftType),
                  ],
                ),
                const SizedBox(height: 4),
                // Date + time ago
                Text(
                  '${log.attendanceDate}  ·  ${log.timeAgo}',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close,
                size: 14, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface),
      );
}

class _ChipRow extends StatelessWidget {
  const _ChipRow(
      {required this.options,
      required this.selected,
      required this.onSelect});
  final Map<Object?, String> options;
  final Object? selected;
  final ValueChanged<dynamic> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final isSelected = selected == e.key;
        return GestureDetector(
          onTap: () => onSelect(e.key),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? cs.onPrimary : cs.onSurface),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton(
      {required this.label,
      required this.onTap,
      required this.cs,
      required this.isDark,
      this.onClear});
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final ColorScheme cs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 15,
                color: cs.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurface)),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.clear,
                    size: 15,
                    color: cs.onSurface.withValues(alpha: 0.4)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'early':
      case 'present':
        bg = Colors.green.shade100; fg = Colors.green.shade800; break;
      case 'late':
        bg = Colors.orange.shade100; fg = Colors.orange.shade800; break;
      case 'absent':
        bg = Colors.red.shade100; fg = Colors.red.shade800; break;
      case 'excused':
        bg = Colors.blue.shade100; fg = Colors.blue.shade800; break;
      default:
        bg = Colors.grey.shade100; fg = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(20)),
      child: Text(_sourceLabel(source),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: cs.onSecondaryContainer)),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.shift});
  final String shift;

  @override
  Widget build(BuildContext context) {
    if (shift.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(20)),
      child: Text(_capitalize(shift),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.purple.shade700)),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _sourceLabel(String source) {
  switch (source) {
    case 'teacherBatch': return 'Teacher Batch';
    case 'adminEdit':    return 'Admin Edit';
    default:             return 'Student Self';
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
}
