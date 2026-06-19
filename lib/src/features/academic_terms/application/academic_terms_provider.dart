import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/academic_terms/data/academic_terms_api_repository.dart';
import 'package:edu_air/src/features/academic_terms/domain/academic_term.dart';

final academicTermsApiRepositoryProvider =
    Provider<AcademicTermsApiRepository>((ref) {
  return AcademicTermsApiRepository(client: ref.read(apiClientProvider));
});

/// This school's terms, earliest first. autoDispose for multi-tenancy — these
/// belong to ONE school (the JWT's), so the cache must not outlive the session
/// (same reason as schoolShiftsProvider / schoolStaffProvider).
final schoolTermsProvider =
    FutureProvider.autoDispose<List<AcademicTerm>>((ref) {
  return ref.read(academicTermsApiRepositoryProvider).getAll();
});

/// The term containing today, or null (gap / no terms set up). autoDispose for
/// the same multi-tenant reason. The student/teacher header reads this.
final currentTermProvider =
    FutureProvider.autoDispose<AcademicTerm?>((ref) {
  return ref.read(academicTermsApiRepositoryProvider).getCurrent();
});
