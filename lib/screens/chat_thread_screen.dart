import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'view_match_profile_screen.dart';

// Tinder-inspired chat thread theme.
const Color _kBg = Color(0xFF0D0E10);
const Color _kCard = Color(0xFF17191C);
const Color _kPrimary = Color(0xFFFF4458);
const Color _kText = Color(0xFFF5F5F5);
const Color _kTextMuted = Color(0xFFB0B0B0);
const Color _kBubbleMe = Color(0xFFFF4458);
const Color _kBubbleThem = Color(0xFF2A2C30);

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
  final _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_canChat) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _firestore.sendMessage(widget.chatId, widget.userId, text);
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ViewMatchProfileScreen(
          otherUserId: widget.otherUserId,
          profile: _otherProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _otherProfile?.fullName ?? 'Chat';
    final imageUrl = _otherProfile?.profileImageUrls.isNotEmpty == true
        ? _otherProfile!.profileImageUrls.first
        : null;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kText, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: InkWell(
          onTap: _openProfile,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _kTextMuted.withValues(alpha: 0.2),
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null ? Icon(Icons.person, color: _kTextMuted, size: 22) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: _kText, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Tap to view profile',
                      style: TextStyle(color: _kTextMuted.withValues(alpha: 0.9), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          if (_myProfile != null && !_myProfile!.isStudentVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Verify your student mail account to start chatting',
                style: TextStyle(color: _kText, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _firestore.watchMessages(widget.chatId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, size: 48, color: _kTextMuted),
                          const SizedBox(height: 16),
                          const Text(
                            'Couldn\'t load messages',
                            style: TextStyle(color: _kTextMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _kPrimary));
                }
                final messages = snap.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 56, color: _kTextMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Say hi!',
                          style: TextStyle(color: _kTextMuted, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(color: _kTextMuted.withValues(alpha: 0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[messages.length - 1 - i];
                    final isMe = m.senderId == widget.userId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) const SizedBox(width: 4),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? _kBubbleMe : _kBubbleThem,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                m.text,
                                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 4),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _canChat
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: _kTextMuted.withValues(alpha: 0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _textController,
                              maxLines: 4,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'Message',
                                hintStyle: TextStyle(color: _kTextMuted),
                                filled: true,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              style: const TextStyle(color: _kText, fontSize: 16),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(28),
                          elevation: 4,
                          shadowColor: _kPrimary.withValues(alpha: 0.4),
                          child: InkWell(
                            onTap: _send,
                            borderRadius: BorderRadius.circular(28),
                            child: const SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 26),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kTextMuted.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: _kTextMuted, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Verify your student mail account to start chatting',
                            style: TextStyle(color: _kTextMuted, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
