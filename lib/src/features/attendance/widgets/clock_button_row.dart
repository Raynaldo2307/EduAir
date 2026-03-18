import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';

class ClockButtonsRow extends StatelessWidget {
  const ClockButtonsRow({
    super.key,
    required this.isClockedIn,
    required this.isClockedOut,
    required this.isSubmitting,
    required this.onClockIn,
    required this.onClockOut,
  });

  final bool isClockedIn;
  final bool isClockedOut;
  final bool isSubmitting;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;

  @override
  Widget build(BuildContext context) {
    // Case 1: not clocked in yet
    if (!isClockedIn) {
      return SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : onClockIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Clock In', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // Case 2: clocked in but not out -> show "Clock Out"
    if (!isClockedOut) {
      return SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: isSubmitting ? null : onClockOut,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Clock Out',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
        ),
      );
    }

    // Case 3: done for today
    return Text(
      'You\'re all set for today',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
