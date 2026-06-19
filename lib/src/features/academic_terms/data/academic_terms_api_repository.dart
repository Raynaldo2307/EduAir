import 'package:dio/dio.dart';

import 'package:edu_air/src/services/api_client.dart';
import 'package:edu_air/src/features/academic_terms/domain/academic_term.dart';

/// Talks to /api/academic-terms. school_id is enforced server-side from the
/// JWT — the client never sends it. The backend re-validates dates + overlap,
/// so this repo just shapes the HTTP calls (no client-side guards here).
class AcademicTermsApiRepository {
  final Dio _dio;

  AcademicTermsApiRepository({required ApiClient client}) : _dio = client.dio;

  /// GET /api/academic-terms — this school's terms, earliest first.
  Future<List<AcademicTerm>> getAll() async {
    final res = await _dio.get('/api/academic-terms');
    final rows = List<Map<String, dynamic>>.from(res.data['data'] as List);
    return rows.map(AcademicTerm.fromMap).toList();
  }

  /// GET /api/academic-terms/current — the term containing today, or null
  /// (today falls in a gap / no terms set up).
  Future<AcademicTerm?> getCurrent() async {
    final res = await _dio.get('/api/academic-terms/current');
    final data = res.data['data'];
    return data == null
        ? null
        : AcademicTerm.fromMap(data as Map<String, dynamic>);
  }

  /// POST /api/academic-terms — add a term. Dates go up as 'YYYY-MM-DD'. The
  /// backend re-checks real dates, end > start, and no overlap, so a bad call
  /// 400/409s rather than writing junk. Returns the saved row (with its id).
  Future<AcademicTerm> create({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final res = await _dio.post('/api/academic-terms', data: {
      'name': name,
      'start_date': AcademicTerm.ymd(startDate),
      'end_date': AcademicTerm.ymd(endDate),
    });
    return AcademicTerm.fromMap(res.data['data'] as Map<String, dynamic>);
  }

  /// PUT /api/academic-terms/:id — edit. Nullable to mirror the backend's
  /// COALESCE: send only what changed. Returns the updated row.
  Future<AcademicTerm> update(
    int id, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await _dio.put('/api/academic-terms/$id', data: {
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': AcademicTerm.ymd(startDate),
      if (endDate != null) 'end_date': AcademicTerm.ymd(endDate),
    });
    return AcademicTerm.fromMap(res.data['data'] as Map<String, dynamic>);
  }

  /// DELETE /api/academic-terms/:id — soft delete (status → 'inactive').
  Future<void> delete(int id) async {
    await _dio.delete('/api/academic-terms/$id');
  }
}
