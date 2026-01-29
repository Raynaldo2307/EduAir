// lib/src/features/attendance/application/late_reason_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

/// A single option for the late-reason dropdown.
///
/// - [code] is the MoEYI category code stored in Firestore (e.g. 'transportation').
/// - [label] is the human-readable label shown in the UI (e.g. 'Transportation').
class LateReasonOption {
  final String code;
  final String label;

  const LateReasonOption({required this.code, required this.label});

  @override
  String toString() => 'LateReasonOption(code: $code, label: $label)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LateReasonOption &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Provides the list of MoEYI late reason options for UI dropdowns.
///
/// This is the single source of truth for late reason categories.
/// The UI should use this provider to populate dropdowns/bottom sheets.
///
/// Example usage:
/// ```dart
/// final options = ref.watch(lateReasonOptionsProvider);
/// DropdownButton<String>(
///   items: options.map((o) => DropdownMenuItem(value: o.code, child: Text(o.label))).toList(),
///   ...
/// )
/// ```
final lateReasonOptionsProvider = Provider<List<LateReasonOption>>((ref) {
  return MoEYILateReason.values.map((reason) {
    return LateReasonOption(
      code: reason.code,
      label: reason.label,
    );
  }).toList();
});

/// Validates if a given code is a valid MoEYI late reason.
///
/// This is a convenience wrapper around [MoEYILateReasonLabel.isValid].
bool isValidLateReasonCode(String? code) {
  return MoEYILateReasonLabel.isValid(code);
}

/// Gets the human-readable label for a late reason code.
///
/// Returns null if the code is invalid.
String? getLateReasonLabel(String? code) {
  final reason = MoEYILateReasonLabel.fromCode(code);
  return reason?.label;
}
