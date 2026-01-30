import 'package:cloud_firestore/cloud_firestore.dart';

/// One chat per mutual match. Subcollection: messages.
class ChatRecord {
  final String id;
  final String matchId;
  final String user1Id;
  final String user2Id;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final DateTime createdAt;

  const ChatRecord({
    required this.id,
    required this.matchId,
    required this.user1Id,
    required this.user2Id,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.createdAt,
  });

  String otherUserId(String currentUserId) =>
      currentUserId == user1Id ? user2Id : user1Id;

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'user1Id': user1Id,
        'user2Id': user2Id,
        if (lastMessageAt != null)
          'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
        if (lastMessagePreview != null) 'lastMessagePreview': lastMessagePreview,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static ChatRecord fromMap(String id, Map<String, dynamic> map) =>
      ChatRecord(
        id: id,
        matchId: map['matchId'] as String? ?? '',
        user1Id: map['user1Id'] as String? ?? '',
        user2Id: map['user2Id'] as String? ?? '',
        lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
        lastMessagePreview: map['lastMessagePreview'] as String?,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final Map<String, DateTime>? readAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.readAt,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        if (readAt != null)
          'readAt': readAt!.map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      };

  static ChatMessage fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        senderId: map['senderId'] as String? ?? '',
        text: map['text'] as String? ?? '',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        readAt: null,
      );
}
