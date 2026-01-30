import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/chat.dart';
import '../services/firestore_service.dart';
import 'chat_thread_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String userId;

  const ChatListScreen({super.key, required this.userId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _firestore = FirestoreService();
  List<ChatRecord> _chats = [];
  Map<String, UserProfile> _profiles = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final chats = await _firestore.getChatsForUser(widget.userId);
    final profiles = <String, UserProfile>{};
    for (final c in chats) {
      final otherId = c.otherUserId(widget.userId);
      if (!profiles.containsKey(otherId)) {
        final p = await _firestore.getUserProfile(otherId);
        if (p != null) profiles[otherId] = p;
      }
    }
    setState(() {
      _chats = chats;
      _profiles = profiles;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF4458))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chat', style: TextStyle(color: Colors.white)),
      ),
      body: _chats.isEmpty
          ? const Center(
              child: Text(
                'No chats yet. Match with someone first!',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chats.length,
              itemBuilder: (_, i) {
                final c = _chats[i];
                final otherId = c.otherUserId(widget.userId);
                final p = _profiles[otherId];
                final name = p?.fullName ?? 'Unknown';
                final imageUrl = p?.profileImageUrls.isNotEmpty == true ? p!.profileImageUrls.first : null;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white12,
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null ? const Icon(Icons.person, color: Colors.white38) : null,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    c.lastMessagePreview ?? 'No messages yet',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatThreadScreen(
                          chatId: c.id,
                          userId: widget.userId,
                          otherUserId: otherId,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
