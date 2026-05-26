import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';

class ReportsApiRepository {
  final ApiClient _apiClient;
  ReportsApiRepository(this._apiClient);

  // Fetches the SF4 PDF for the given month ('YYYY-MM') and returns
  // the raw bytes. Flutter writes these to a temp file then shares it.
  Future<List<int>> downloadSf4Pdf(String month) async {
    final response = await _apiClient.dio.get<List<int>>(
      '/reports/sf4',
      queryParameters: {'month': month},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }
}
