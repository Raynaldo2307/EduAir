import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/bell_schedule/application/bell_schedule_controller.dart';
import 'package:edu_air/src/features/bell_schedule/application/bell_schedule_provider.dart';
import 'package:edu_air/src/features/bell_schedule/application/operating_model_controller.dart';
import 'package:edu_air/src/features/bell_schedule/domain/bell_period.dart';
import 'package:edu_air/src/features/bell_schedule/domain/shift.dart';

/// Shift Settings → Bell Schedule (LIVE — reads /api/shifts + /api/bell-periods,
/// writes bells, and recovers a school that has no shifts via the operating
/// model).
///
/// The shift structure comes from the school's OPERATING MODEL (set at
/// registration, or in-app here if it was skipped). A whole-day school shows one
/// schedule with no selector; a multi-shift school shows a selector over its
/// shifts. EduAir lays the frame; the admin fills in the bells.
class BellScheduleConfigScreen extends ConsumerStatefulWidget {
  const BellScheduleConfigScreen({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  ConsumerState<BellScheduleConfigScreen> createState() =>
      _BellScheduleConfigScreenState();
}

class _BellScheduleConfigScreenState
    extends ConsumerState<BellScheduleConfigScreen> {
  int? _selectedShiftId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shiftsAsync = ref.watch(schoolShiftsProvider);

    // Resolve the active shift up here so the FAB (add bell) can use it too —
    // null when there are no shifts (nothing to add a bell to yet).
    final shifts = shiftsAsync.valueOrNull ?? const <Shift>[];
    final int? selectedId = shifts.isEmpty
        ? null
        : (shifts.any((s) => s.id == _selectedShiftId) &&
                _selectedShiftId != null
            ? _selectedShiftId
            : shifts.first.id);

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
      floatingActionButton: selectedId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showBellForm(context, shiftId: selectedId),
              icon: const Icon(Icons.add),
              label: const Text('Add bell'),
            ),
      body: shiftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Hint(
            icon: Icons.error_outline, text: 'Could not load shifts.', cs: cs),
        data: (shifts) {
          if (shifts.isEmpty) {
            // Not a dead end: the admin sets the school's operating model right
            // here, and EduAir seeds the shifts. (New schools get this at
            // registration; this recovers one that skipped it.)
            return _Hint(
              icon: Icons.schedule_outlined,
              text: 'This school isn\'t set up yet.\n'
                  'Tell us how it runs and we\'ll build the schedule.',
              cs: cs,
              action: FilledButton.icon(
                onPressed: () => _showOperatingModelPicker(context),
                icon: const Icon(Icons.tune),
                label: const Text('Set up your school'),
              ),
            );
          }
          return Column(
            children: [
              if (shifts.length > 1) _shiftSelector(shifts, selectedId!),
              Expanded(child: _PeriodsList(shiftId: selectedId!)),
            ],
          );
        },
      ),
    );
  }

  Widget _shiftSelector(List<Shift> shifts, int selectedId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<int>(
        segments: shifts
            .map((s) => ButtonSegment(value: s.id, label: Text(s.name)))
            .toList(),
        selected: {selectedId},
        onSelectionChanged: (s) => setState(() => _selectedShiftId = s.first),
      ),
    );
  }
}

// ─── One shift's periods ──────────────────────────────────────────────────────

class _PeriodsList extends ConsumerWidget {
  const _PeriodsList({required this.shiftId});
  final int shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(bellPeriodsByShiftProvider(shiftId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _Hint(
          icon: Icons.error_outline,
          text: 'Could not load the bell schedule.',
          cs: cs),
      data: (periods) {
        if (periods.isEmpty) {
          return _Hint(
            icon: Icons.notifications_off_outlined,
            text: 'No bells set for this shift yet.\nTap “Add bell” to start.',
            cs: cs,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // room for the FAB
          itemCount: periods.length,
          itemBuilder: (_, i) => _BellCard(
            period: periods[i],
            onTap: () =>
                _showBellForm(context, shiftId: shiftId, period: periods[i]),
          ),
        );
      },
    );
  }
}

class _BellCard extends StatelessWidget {
  const _BellCard({required this.period, required this.onTap});
  final BellPeriod period;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
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
                      // Tag every non-teaching bell so the type is visible.
                      if (period.kind != BellSlotType.teaching) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(period.kind.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onTertiaryContainer)),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(
      {required this.icon, required this.text, required this.cs, this.action});
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 52, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// ─── Set up the school (operating model → seeded shifts) ──────────────────────

/// Asks how the school runs and seeds its shifts from the answer. Shown only
/// when the school has no shifts (the empty-state recovery).
Future<void> _showOperatingModelPicker(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _OperatingModelSheet(),
  );
}

class _OperatingModelSheet extends ConsumerWidget {
  const _OperatingModelSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final busy = ref.watch(operatingModelControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('How does your school run?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('We\'ll build the right schedule structure for you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 18),
            _modelCard(
              context, ref, busy,
              model: 'whole_day',
              icon: Icons.wb_sunny_outlined,
              title: 'Whole day',
              subtitle: 'One full-day session for everyone.',
            ),
            const SizedBox(height: 10),
            _modelCard(
              context, ref, busy,
              model: 'multi_shift',
              icon: Icons.schedule_outlined,
              title: 'Multiple shifts',
              subtitle: 'Separate morning and afternoon shifts.',
            ),
            if (busy) ...[
              const SizedBox(height: 18),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modelCard(
    BuildContext context,
    WidgetRef ref,
    bool busy, {
    required String model,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: busy ? 0.5 : 1,
      child: IgnorePointer(
        ignoring: busy,
        child: Material(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _choose(context, ref, model),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(icon, color: cs.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12.5, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _choose(
      BuildContext context, WidgetRef ref, String model) async {
    final error =
        await ref.read(operatingModelControllerProvider.notifier).setup(model);
    if (!context.mounted) return;
    if (error != null) return _snack(context, error);
    Navigator.of(context).pop();
  }
}

// ─── Add / edit a bell ────────────────────────────────────────────────────────

/// Opens the add/edit sheet. [period] null = add, non-null = edit.
Future<void> _showBellForm(
  BuildContext context, {
  required int shiftId,
  BellPeriod? period,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true, // grow with the keyboard
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _BellFormSheet(shiftId: shiftId, existing: period),
    ),
  );
}

class _BellFormSheet extends ConsumerStatefulWidget {
  const _BellFormSheet({required this.shiftId, this.existing});
  final int shiftId;
  final BellPeriod? existing;

  @override
  ConsumerState<_BellFormSheet> createState() => _BellFormSheetState();
}

class _BellFormSheetState extends ConsumerState<_BellFormSheet> {
  late final TextEditingController _label;
  TimeOfDay? _start;
  TimeOfDay? _end;
  late BellSlotType _kind;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _start = e != null ? _parse(e.startTime) : null;
    _end = e != null ? _parse(e.endTime) : null;
    _kind = e?.kind ?? BellSlotType.teaching;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final busy = ref.watch(bellScheduleControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEditing ? 'Edit bell' : 'Add bell',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Period 1, Lunch, Devotion',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _timeField('Start', _start, () => _pick(true))),
                const SizedBox(width: 12),
                Expanded(child: _timeField('End', _end, () => _pick(false))),
              ],
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<BellSlotType>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: BellSlotType.values
                  .map((k) =>
                      DropdownMenuItem(value: k, child: Text(k.label)))
                  .toList(),
              onChanged:
                  busy ? null : (k) => setState(() => _kind = k ?? _kind),
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: busy ? null : _save,
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save changes' : 'Add bell'),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: busy ? null : _delete,
                icon: Icon(Icons.delete_outline, color: cs.error),
                label: Text('Delete bell', style: TextStyle(color: cs.error)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeField(String label, TimeOfDay? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(value == null ? 'Select' : value.format(context)),
      ),
    );
  }

  Future<void> _pick(bool isStart) async {
    final init =
        (isStart ? _start : _end) ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  /// Mirror the backend's required-field + end>start rules so the user gets
  /// instant feedback instead of a round-trip 400. The backend still re-checks
  /// everything — this is UX, not the real guard.
  Future<void> _save() async {
    final label = _label.text.trim();
    if (label.isEmpty) return _snack(context, 'Enter a name for this bell.');
    if (_start == null || _end == null) {
      return _snack(context, 'Pick a start and end time.');
    }
    if (_mins(_end!) <= _mins(_start!)) {
      return _snack(context, 'End time must be after start time.');
    }

    final controller = ref.read(bellScheduleControllerProvider.notifier);
    String? error;
    if (_isEditing) {
      error = await controller.editPeriod(
        widget.existing!.id,
        shiftId: widget.shiftId,
        label: label,
        startTime: _fmt(_start!),
        endTime: _fmt(_end!),
        kind: _kind,
      );
    } else {
      error = await controller.addPeriod(
        shiftId: widget.shiftId,
        position: _nextPosition(),
        label: label,
        startTime: _fmt(_start!),
        endTime: _fmt(_end!),
        kind: _kind,
      );
    }

    if (!mounted) return;
    if (error != null) return _snack(context, error);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bell?'),
        content: Text('“${widget.existing!.label}” will be removed from this '
            'shift\'s schedule.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(bellScheduleControllerProvider.notifier)
        .removePeriod(widget.existing!.id, shiftId: widget.shiftId);

    if (!mounted) return;
    if (error != null) return _snack(context, error);
    Navigator.of(context).pop();
  }

  /// Append after the current last bell. Use max(position)+1 (not list length)
  /// so a soft-deleted gap can't make a new bell collide with an existing one.
  int _nextPosition() {
    final periods =
        ref.read(bellPeriodsByShiftProvider(widget.shiftId)).valueOrNull ??
            const <BellPeriod>[];
    return periods.fold<int>(0, (m, p) => p.position >= m ? p.position + 1 : m);
  }

  TimeOfDay _parse(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;
}
