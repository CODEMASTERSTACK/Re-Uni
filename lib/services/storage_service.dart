import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'backend_service.dart';

/// Profile image storage on Cloudflare R2 via presigned URLs from the backend.
/// Path pattern: users/{userId}/profile/{index}.webp (0–4).
class StorageService {
  final BackendService _backend = BackendService();

  String profileImagePath(String userId, int index) =>
      'users/$userId/profile/$index.webp';

  Future<String> uploadProfileImage(
    String userId,
    int index,
    Uint8List bytes, {
    String? contentType,
  }) async {
    final path = profileImagePath(userId, index);
    final urls = await _backend.getUploadUrl(path);
    final uploadUrl = urls['uploadUrl']!;
    final publicUrl = urls['publicUrl']!;

    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType ?? 'image/webp'},
      body: bytes,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('R2 upload failed: ${res.statusCode} ${res.body}');
    }
    return publicUrl;
  }

  /// Removing an image only updates Firestore (profileImageUrls).
  /// Object in R2 is left as-is unless you add a delete endpoint.
  Future<void> deleteProfileImage(String userId, int index) async {
    // No-op: R2 object remains. Add api/delete-object if you need to delete from R2.
  }
}
