import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/match_record.dart';
import '../services/firestore_service.dart';
import 'chat_thread_screen.dart';
import 'view_match_profile_screen.dart';

class MatchesScreen extends StatefulWidget {
  final String userId;

  const MatchesScreen({super.key, required this.userId});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _firestore = FirestoreService();
  List<MatchRecord> _matches = [];
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
      final matches = await _firestore.getMatchesForUser(widget.userId);
      final profiles = <String, UserProfile>{};
      for (final m in matches) {
        final otherId = m.user1Id == widget.userId ? m.user2Id : m.user1Id;
        if (!profiles.containsKey(otherId)) {
          final p = await _firestore.getUserProfile(otherId);
          if (p != null) profiles[otherId] = p;
        }
      }
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _profiles = profiles;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _accept(MatchRecord m) async {
    final matchId = MatchRecord.docId(m.user1Id, m.user2Id);
    final otherId = m.user1Id == widget.userId ? m.user2Id : m.user1Id;
    // If pending (they liked me), my Accept = add my like → mutual match, then open chat.
    if (m.status == 'pending') {
      await _firestore.upsertMatchOnLike(widget.userId, otherId);
      if (!mounted) return;
    }
    await _firestore.createChatIfMatched(matchId, m.user1Id, m.user2Id);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          chatId: matchId,
          userId: widget.userId,
          otherUserId: otherId,
        ),
      ),
    );
  }

  Future<void> _reject(MatchRecord m) async {
    final matchId = MatchRecord.docId(m.user1Id, m.user2Id);
    await _firestore.rejectMatch(matchId, widget.userId);
    if (!mounted) return;
    _load();
  }

  void _viewProfile(String otherUserId, UserProfile? profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ViewMatchProfileScreen(
          otherUserId: otherUserId,
          profile: profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _error == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF4458))),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Matches', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Couldn\'t load matches.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _load,
                  child: const Text('Retry', style: TextStyle(color: Color(0xFFFF4458))),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final pending = _matches.where((m) => m.status == 'pending').toList();
    final matched = _matches.where((m) => m.status == 'matched').toList();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Matches', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (pending.isNotEmpty) ...[
            const Text(
              'Liked you',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...pending.map((m) {
              final otherId = m.user1Id == widget.userId ? m.user2Id : m.user1Id;
              final p = _profiles[otherId];
              return _MatchTile(
                profile: p,
                status: 'pending',
                onViewProfile: () => _viewProfile(otherId, p),
                onAccept: () => _accept(m),
                onReject: () => _reject(m),
              );
            }),
            const SizedBox(height: 24),
          ],
          if (matched.isNotEmpty) ...[
            const Text(
              'Mutual matches',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...matched.map((m) {
              final otherId = m.user1Id == widget.userId ? m.user2Id : m.user1Id;
              final p = _profiles[otherId];
              return _MatchTile(
                profile: p,
                status: 'matched',
                onViewProfile: () => _viewProfile(otherId, p),
                onAccept: () => _accept(m),
                onReject: () => _reject(m),
              );
            }),
          ],
          if (_matches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 48),
                child: Text(
                  'No matches yet. Keep swiping!',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final UserProfile? profile;
  final String status;
  final VoidCallback onViewProfile;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _MatchTile({
    required this.profile,
    required this.status,
    required this.onViewProfile,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox.shrink();
    final p = profile!;
    final imageUrl = p.profileImageUrls.isNotEmpty ? p.profileImageUrls.first : null;
    return Card(
      color: const Color(0xFF17191C),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white12,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null ? const Icon(Icons.person, color: Colors.white38) : null,
        ),
        title: Text(
          '${p.fullName}, ${p.age}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          p.location,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: status == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white70),
                    tooltip: 'View Profile',
                    onPressed: onViewProfile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: onReject,
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Color(0xFFFF4458)),
                    onPressed: onAccept,
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white70),
                    tooltip: 'View Profile',
                    onPressed: onViewProfile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat, color: Color(0xFFFF4458)),
                    onPressed: onAccept,
                  ),
                ],
              ),
      ),
    );
  }
}
