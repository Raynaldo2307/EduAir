import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/core/app_providers.dart';

final adminClassesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(classesApiRepositoryProvider).getAllWithDetails();
});
