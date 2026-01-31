import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class ChatThreadScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String otherUserId;

  const ChatThreadScreen({
    super.key,
    required this.chatId,
    required this.userId,
    required this.otherUserId,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _firestore = FirestoreService();
  final _textController = TextEditingController();
  UserProfile? _otherProfile;
  UserProfile? _myProfile;

  bool get _canChat => _myProfile == null || _myProfile!.isStudentVerified;

  @override
  void initState() {
    super.initState();
    _firestore.getUserProfile(widget.otherUserId).then((p) {
      if (mounted) setState(() => _otherProfile = p);
    });
    _firestore.getUserProfile(widget.userId).then((p) {
      if (mounted) setState(() => _myProfile = p);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_canChat) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _firestore.sendMessage(widget.chatId, widget.userId, text);
  }

  @override
  Widget build(BuildContext context) {
    final name = _otherProfile?.fullName ?? 'Chat';
    final imageUrl = _otherProfile?.profileImageUrls.isNotEmpty == true
        ? _otherProfile!.profileImageUrls.first
        : null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white12,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null ? const Icon(Icons.person, color: Colors.white38, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_myProfile != null && !_myProfile!.isStudentVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFFF4458).withValues(alpha: 0.2),
              child: const Text(
                'Verify your student mail account to start chatting',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _firestore.watchMessages(widget.chatId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4458)));
                }
                final messages = snap.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Say hi!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[messages.length - 1 - i];
                    final isMe = m.senderId == widget.userId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFFF4458) : const Color(0xFF17191C),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          m.text,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _canChat
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF17191C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _send,
                        icon: const Icon(Icons.send, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFFFF4458)),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: const Text(
                      'Verify your student mail account to start chatting',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
