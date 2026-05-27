import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:edu_air/src/core/app_providers.dart';

class ExportSf4Button extends ConsumerStatefulWidget {
  const ExportSf4Button({super.key});

  @override
  ConsumerState<ExportSf4Button> createState() => _ExportSf4ButtonState();
}

class _ExportSf4ButtonState extends ConsumerState<ExportSf4Button> {
  bool _loading = false;

  // Month/year the admin has selected (defaults to current month)
  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;

  static const _months = [
    'January', 'February', 'March',    'April',
    'May',     'June',     'July',     'August',
    'September','October', 'November', 'December',
  ];

  // ── Month picker dialog ──────────────────────────────────────────────────
  Future<void> _pickMonth() async {
    int tempMonth = _selectedMonth;
    int tempYear  = _selectedYear;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: const Text('Select Report Period'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year row
                Row(
                  children: [
                    const Text('Year', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    DropdownButton<int>(
                      value: tempYear,
                      items: List.generate(
                        10,
                        // Show current year and 9 years back so admins can
                        // pull historical records (2026 audit in 2030, etc.)
                        (i) {
                          final y = DateTime.now().year - i;
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        },
                      ),
                      onChanged: (y) => setInner(() => tempYear = y!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Month row
                Row(
                  children: [
                    const Text('Month', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    DropdownButton<int>(
                      value: tempMonth,
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(_months[i]),
                        ),
                      ),
                      onChanged: (m) => setInner(() => tempMonth = m!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Exporting: ${_months[tempMonth - 1]} $tempYear',
                  style: TextStyle(fontSize: 13, color: cs.primary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Export'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      setState(() {
        _selectedMonth = tempMonth;
        _selectedYear  = tempYear;
      });
      await _export();
    }
  }

  // ── Download + share ─────────────────────────────────────────────────────
  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      final month     = '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';
      final repo      = ref.read(reportsApiRepositoryProvider);
      final bytes     = await repo.downloadSf4Pdf(month);

      // Write bytes to a temp file so share_plus can attach it
      final dir       = await getTemporaryDirectory();
      final file      = File('${dir.path}/SF4_$month.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) setState(() => _loading = false);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'SF4 Attendance Report — ${_months[_selectedMonth - 1]} $_selectedYear',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _pickMonth,
        icon: _loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
              )
            : Icon(Icons.download_outlined, color: cs.primary),
        label: Text(
          _loading ? 'Generating SF4...' : 'Export SF4 Report',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _loading ? cs.onSurfaceVariant : cs.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: _loading ? cs.outlineVariant : cs.primary,
            width: 2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
