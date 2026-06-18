import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/bell_schedule/application/bell_schedule_provider.dart';
import 'package:edu_air/src/features/bell_schedule/domain/bell_period.dart';
import 'package:edu_air/src/features/bell_schedule/domain/shift.dart';

/// Shift Settings → Bell Schedule (now LIVE — reads /api/shifts + /api/bell-periods).
///
/// The shift selector is driven by the school's real shifts: a whole-day school
/// shows one schedule with no selector; a multi-shift school shows a selector
/// over its actual shift names. (Read-only this slice; add/edit/delete next.)
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
      body: shiftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Hint(
            icon: Icons.error_outline, text: 'Could not load shifts.', cs: cs),
        data: (shifts) {
          if (shifts.isEmpty) {
            return _Hint(
              icon: Icons.schedule_outlined,
              text: 'No shifts configured for this school yet.',
              cs: cs,
            );
          }
          // Default to the first shift; stay valid if the list changes.
          final selectedId =
              shifts.any((s) => s.id == _selectedShiftId) && _selectedShiftId != null
                  ? _selectedShiftId!
                  : shifts.first.id;

          return Column(
            children: [
              if (shifts.length > 1) _shiftSelector(shifts, selectedId),
              Expanded(child: _PeriodsList(shiftId: selectedId)),
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
          icon: Icons.error_outline, text: 'Could not load the bell schedule.', cs: cs),
      data: (periods) {
        if (periods.isEmpty) {
          return _Hint(
            icon: Icons.notifications_off_outlined,
            text: 'No bells set for this shift yet.',
            cs: cs,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: periods.length,
          itemBuilder: (_, i) => _BellCard(period: periods[i]),
        );
      },
    );
  }
}

class _BellCard extends StatelessWidget {
  const _BellCard({required this.period});
  final BellPeriod period;

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
                // Tag every non-teaching bell so the type is visible at a glance.
                if (period.kind != BellSlotType.teaching) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text, required this.cs});
  final IconData icon;
  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
