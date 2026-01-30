import 'package:cloud_firestore/cloud_firestore.dart';

/// One swipe per (actor, target). Doc ID = sorted "${id1}_${id2}".
class SwipeRecord {
  final String actorId;
  final String targetId;
  final String action; // like | dislike
  final DateTime createdAt;

  const SwipeRecord({
    required this.actorId,
    required this.targetId,
    required this.action,
    required this.createdAt,
  });

  static String docId(String actorId, String targetId) {
    if (actorId.compareTo(targetId) <= 0) {
      return '${actorId}_$targetId';
    }
    return '${targetId}_$actorId';
  }

  Map<String, dynamic> toMap() => {
        'actorId': actorId,
        'targetId': targetId,
        'action': action,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static SwipeRecord fromMap(Map<String, dynamic> map) => SwipeRecord(
        actorId: map['actorId'] as String? ?? '',
        targetId: map['targetId'] as String? ?? '',
        action: map['action'] as String? ?? 'dislike',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
