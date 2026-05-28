import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:edu_air/src/services/api_client.dart';

class UploadApiRepository {
  const UploadApiRepository(this._client);
  final ApiClient _client;

  /// Uploads [file] to Cloudinary via the backend.
  /// Returns the public URL that was saved to the database.
  ///
  /// Pass [targetUserId] when an admin is uploading on behalf of
  /// another user (student or staff). Leave null to update own photo.
  Future<String> uploadProfilePhoto(
    XFile file, {
    int? targetUserId,
  }) async {
    // readAsBytes() works on both mobile (file path) and web (in-memory bytes).
    final bytes = await file.readAsBytes();

    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: file.name),
      if (targetUserId != null) 'target_user_id': targetUserId.toString(),
    });

    final response = await _client.dio.post(
      '/api/upload/profile-photo',
      data: formData,
    );

    return response.data['photoUrl'] as String;
  }
}
