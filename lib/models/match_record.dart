import 'package:cloud_firestore/cloud_firestore.dart';

/// Mutual like and rejection state. Doc ID = sorted user1Id_user2Id.
class MatchRecord {
  final String user1Id;
  final String user2Id;
  final String status; // pending | matched | rejected
  final List<String> likedBy;
  final String? rejectedBy;
  final DateTime? matchedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MatchRecord({
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.likedBy,
    this.rejectedBy,
    this.matchedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static String docId(String userId1, String userId2) {
    if (userId1.compareTo(userId2) <= 0) return '${userId1}_$userId2';
    return '${userId2}_$userId1';
  }

  String get otherUserId => ''; // call site passes current user to resolve

  Map<String, dynamic> toMap() => {
        'user1Id': user1Id,
        'user2Id': user2Id,
        'status': status,
        'likedBy': likedBy,
        if (rejectedBy != null) 'rejectedBy': rejectedBy,
        if (matchedAt != null) 'matchedAt': Timestamp.fromDate(matchedAt!),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static MatchRecord fromMap(Map<String, dynamic> map, String docId) {
    final u1 = map['user1Id'] as String? ?? '';
    final u2 = map['user2Id'] as String? ?? '';
    return MatchRecord(
      user1Id: u1,
      user2Id: u2,
      status: map['status'] as String? ?? 'pending',
      likedBy: List<String>.from(map['likedBy'] as List<dynamic>? ?? []),
      rejectedBy: map['rejectedBy'] as String?,
      matchedAt: (map['matchedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
