import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/models/app_user.dart';

// ─── Mapper ───────────────────────────────────────────────────────────────────

/// Maps a raw Node API teacher record → [AppUser].
/// Kept here (application layer) so the UI never touches raw API maps.
AppUser nodeStaffToAppUser(Map<String, dynamic> d) {
  return AppUser(
    uid:              d['teacher_id'].toString(),
    firstName:        d['first_name']          ?? '',
    lastName:         d['last_name']           ?? '',
    email:            d['email']               ?? '',
    phone:            '',
    role:             'teacher',
    teacherDepartment:  d['department'],
    employmentType:     d['employment_type'],
    currentShift:       d['current_shift_type'],
    studentId:          d['staff_code'],
    homeroomClassId:    d['homeroom_class_id']?.toString(),
    homeroomClassName:  d['homeroom_class_name'],
  );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Fetches all active staff for the admin's school via the Node API.
/// Invalidate this provider after any create / update / delete operation
/// so the list refreshes automatically.
final schoolStaffProvider = FutureProvider<List<AppUser>>((ref) async {
  final repo = ref.read(staffApiRepositoryProvider);
  final raw  = await repo.getAll();
  return raw.map(nodeStaffToAppUser).toList();
});
