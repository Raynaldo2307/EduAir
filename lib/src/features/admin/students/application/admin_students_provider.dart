import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/models/app_user.dart';

// ─── Mapper ───────────────────────────────────────────────────────────────────

/// Maps a raw Node API student record → [AppUser].
/// Kept here (application layer) so the UI never touches raw API maps.
AppUser nodeStudentToAppUser(Map<String, dynamic> d) {
  return AppUser(
    uid:          d['student_id'].toString(),
    firstName:    d['first_name']         ?? '',
    lastName:     d['last_name']          ?? '',
    email:        d['email']              ?? '',
    phone:        d['phone_number']       ?? '',
    role:         'student',
    studentId:    d['student_code'],
    currentShift: d['current_shift_type'],
    sex:          d['sex'],
    classId:      d['homeroom_class_id']?.toString(),
    className:    d['class_name'],
    gradeLevel:   d['grade_level']?.toString(),
    photoUrl:     d['photo_url'],
  );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Fetches all active students for the admin's school via the Node API.
/// Invalidate this provider after any create / update / delete operation
/// so the list refreshes automatically.
///
/// autoDispose for multi-tenancy: this list belongs to ONE school (the JWT's).
/// Without it, the cache outlives the user — log out, log into another school
/// on the same device, and that school would see the previous school's
/// students. autoDispose drops the cache when the screen unmounts (tab switch
/// or logout), so each visit refetches the current school's data.
final schoolStudentsProvider =
    FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final repo = ref.read(studentsApiRepositoryProvider);
  final raw  = await repo.getAll();
  return raw.map(nodeStudentToAppUser).toList();
});
