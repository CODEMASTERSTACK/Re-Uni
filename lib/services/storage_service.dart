import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Profile image storage. Plan specifies R2; using Firebase Storage for MVP.
/// R2 can be swapped via presigned URL upload when backend is ready.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Path pattern: users/{userId}/profile/{index}.webp (0-4).
  String profileImagePath(String userId, int index) =>
      'users/$userId/profile/$index.webp';

  Future<String> uploadProfileImage(
    String userId,
    int index,
    Uint8List bytes, {
    String? contentType,
  }) async {
    final ref = _storage.ref().child(profileImagePath(userId, index));
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType ?? 'image/webp'),
    );
    return ref.getDownloadURL();
  }

  Future<void> deleteProfileImage(String userId, int index) async {
    final ref = _storage.ref().child(profileImagePath(userId, index));
    await ref.delete();
  }
}
