import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/bell_schedule/application/bell_schedule_provider.dart';
import 'package:edu_air/src/features/bell_schedule/domain/bell_period.dart';

/// Shift Settings → Bell Schedule config (MOCK data for now).
///
/// The school defines its period grid here at registration. A shift school
/// configures Morning and Afternoon separately (segmented control); a
/// whole-day school configures one grid. The timetable later assigns subjects
/// to these slots.
class BellScheduleConfigScreen extends ConsumerStatefulWidget {
  const BellScheduleConfigScreen({super.key, this.onBackToHome});

  /// Supplied when this lives inside the admin shell on mobile (shows a back
  /// arrow → home). Null on desktop (the rail handles nav) and when pushed as
  /// a route (the AppBar auto-adds a back button).
  final VoidCallback? onBackToHome;

  @override
  ConsumerState<BellScheduleConfigScreen> createState() =>
      _BellScheduleConfigScreenState();
}

class _BellScheduleConfigScreenState
    extends ConsumerState<BellScheduleConfigScreen> {
  // Which shift grid is on screen. For whole-day schools this stays 'whole_day'
  // and the segmented control is hidden.
  late String _shift;

  @override
  void initState() {
    super.initState();
    final isShiftSchool = ref.read(userProvider)?.isShiftSchool ?? false;
    _shift = isShiftSchool ? 'morning' : 'whole_day';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isShiftSchool = ref.watch(userProvider)?.isShiftSchool ?? false;

    // Watch the whole list so the screen rebuilds on any add/edit/delete, then
    // read the filtered+sorted slice for the selected shift.
    ref.watch(bellScheduleProvider);
    final periods =
        ref.read(bellScheduleProvider.notifier).periodsForShift(_shift);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Bell Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBackToHome)
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add bell'),
      ),
      body: Column(
        children: [
          if (isShiftSchool)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'morning', label: Text('Morning')),
                  ButtonSegment(value: 'afternoon', label: Text('Afternoon')),
                ],
                selected: {_shift},
                onSelectionChanged: (s) => setState(() => _shift = s.first),
              ),
            ),
          Expanded(
            child: periods.isEmpty
                ? _EmptyHint(cs: cs)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: periods.length,
                    itemBuilder: (_, i) => _BellCard(
                      period: periods[i],
                      onEdit: () => _openForm(existing: periods[i]),
                      onDelete: () => _confirmDelete(periods[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm({BellPeriod? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _BellFormSheet(shift: _shift, existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(BellPeriod p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bell?'),
        content: Text('${p.label} — ${p.timeRange}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      ref.read(bellScheduleProvider.notifier).remove(p.id);
    }
  }
}

// ─── Bell card ────────────────────────────────────────────────────────────────

class _BellCard extends StatelessWidget {
  const _BellCard({
    required this.period,
    required this.onEdit,
    required this.onDelete,
  });

  final BellPeriod period;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(period.timeRange,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(period.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                ),
                // Tag every non-teaching bell (Break, Lunch, Devotion, Dismissal)
                // so the admin can see at a glance which slots hold no subject.
                if (period.type != BellSlotType.period) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(period.type.label,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.onTertiaryContainer)),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: cs.onSurfaceVariant),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Add / edit sheet ─────────────────────────────────────────────────────────

class _BellFormSheet extends ConsumerStatefulWidget {
  const _BellFormSheet({required this.shift, this.existing});

  final String shift;
  final BellPeriod? existing;

  @override
  ConsumerState<_BellFormSheet> createState() => _BellFormSheetState();
}

class _BellFormSheetState extends ConsumerState<_BellFormSheet> {
  late final TextEditingController _label;
  late final TextEditingController _periodNumber;
  String? _start;
  String? _end;
  late BellSlotType _type;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _periodNumber =
        TextEditingController(text: e?.periodNumber.toString() ?? '');
    _start = e?.startTime;
    _end = e?.endTime;
    _type = e?.type ?? BellSlotType.period;
  }

  @override
  void dispose() {
    _label.dispose();
    _periodNumber.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final hhmm =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => isStart ? _start = hhmm : _end = hhmm);
    }
  }

  void _save() {
    final label = _label.text.trim();
    if (label.isEmpty || _start == null || _end == null) {
      setState(() => _error = 'Label, start time and end time are required.');
      return;
    }
    // 'HH:mm' strings compare correctly because they are zero-padded.
    // Dismissal is a single moment (end == start is fine); every other bell
    // has a real duration so end must come strictly after start.
    final cmp = _end!.compareTo(_start!);
    if (_type == BellSlotType.dismissal ? cmp < 0 : cmp <= 0) {
      setState(() => _error = _type == BellSlotType.dismissal
          ? 'End time cannot be before start time.'
          : 'End time must be after start time.');
      return;
    }
    // Period number only matters for real periods; other bells store 0.
    final periodNumber = _type == BellSlotType.period
        ? (int.tryParse(_periodNumber.text.trim()) ?? 0)
        : 0;
    final notifier = ref.read(bellScheduleProvider.notifier);
    if (_isEdit) {
      notifier.update(widget.existing!.copyWith(
        label: label,
        periodNumber: periodNumber,
        startTime: _start,
        endTime: _end,
        type: _type,
      ));
    } else {
      notifier.add(
        shiftType: widget.shift,
        periodNumber: periodNumber,
        label: label,
        startTime: _start!,
        endTime: _end!,
        type: _type,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_isEdit ? 'Edit bell' : 'Add bell',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          DropdownButtonFormField<BellSlotType>(
            initialValue: _type,
            decoration: const InputDecoration(
                labelText: 'Type', border: OutlineInputBorder()),
            items: BellSlotType.values
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _label,
            decoration: const InputDecoration(
                labelText: 'Label (e.g. Period 1, Devotion)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          // Period number only applies to real periods — hide it otherwise.
          if (_type == BellSlotType.period) ...[
            TextField(
              controller: _periodNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Period number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                  child: _TimeField(
                      label: 'Start',
                      value: _start,
                      onTap: () => _pickTime(isStart: true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _TimeField(
                      label: 'End',
                      value: _end,
                      onTap: () => _pickTime(isStart: false))),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Save changes' : 'Add bell'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField(
      {required this.label, required this.value, required this.onTap});

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        child: Text(value ?? '--:--'),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 52, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No bells for this shift yet.',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
