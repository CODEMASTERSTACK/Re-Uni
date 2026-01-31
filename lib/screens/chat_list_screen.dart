import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/chat.dart';
import '../services/firestore_service.dart';
import 'chat_thread_screen.dart';

// Tinder-inspired chat list theme.
const Color _kBg = Color(0xFF0D0E10);
const Color _kCard = Color(0xFF17191C);
const Color _kPrimary = Color(0xFFFF4458);
const Color _kText = Color(0xFFF5F5F5);
const Color _kTextMuted = Color(0xFFB0B0B0);

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) await firebaseUser.getIdToken(true);
      final chats = await _firestore.getChatsForUser(widget.userId);
      final profiles = <String, UserProfile>{};
      for (final c in chats) {
        final otherId = c.otherUserId(widget.userId);
        if (!profiles.containsKey(otherId)) {
          final p = await _firestore.getUserProfile(otherId);
          if (p != null) profiles[otherId] = p;
        }
      }
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _profiles = profiles;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _error == null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Couldn\'t load chats.', style: TextStyle(color: _kTextMuted)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _load,
                  child: const Text('Retry', style: TextStyle(color: _kPrimary)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _chats.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: _kTextMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text(
                      'No messages yet',
                      style: TextStyle(color: _kText, fontSize: 20, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Match with someone to start chatting',
                      style: TextStyle(color: _kTextMuted, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _chats.length,
              itemBuilder: (_, i) {
                final c = _chats[i];
                final otherId = c.otherUserId(widget.userId);
                final p = _profiles[otherId];
                final name = p?.fullName ?? 'Unknown';
                final imageUrl = p?.profileImageUrls.isNotEmpty == true ? p!.profileImageUrls.first : null;
                final preview = c.lastMessagePreview ?? 'No messages yet';
                final timeStr = _timeAgo(c.lastMessageAt);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: _kTextMuted.withValues(alpha: 0.2),
                              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                              child: imageUrl == null ? Icon(Icons.person, color: _kTextMuted, size: 28) : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(color: _kText, fontSize: 17, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    preview,
                                    style: TextStyle(color: _kTextMuted, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (timeStr.isNotEmpty)
                              Text(
                                timeStr,
                                style: TextStyle(color: _kTextMuted.withValues(alpha: 0.8), fontSize: 12),
                              ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: _kTextMuted.withValues(alpha: 0.6), size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      title: const Text('Messages', style: TextStyle(color: _kText, fontSize: 22, fontWeight: FontWeight.bold)),
      centerTitle: false,
    );
  }
}
