import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class SwipeScreen extends StatefulWidget {
  final String userId;

  const SwipeScreen({super.key, required this.userId});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final _firestore = FirestoreService();
  List<UserProfile> _batch = [];
  int _index = 0;
  bool _loading = true;
  UserProfile? _currentProfile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatch();
  }

  Future<void> _loadBatch() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      await firebaseUser.getIdToken(true);
      final swiped = await _firestore.getSwipedTargetIds(widget.userId);
      final profile = await _firestore.getUserProfile(widget.userId);
      if (!mounted) return;
      if (profile == null) {
        setState(() => _loading = false);
        return;
      }
      final batch = await _firestore.getDiscoveryBatch(
        currentUserId: widget.userId,
        currentUserGender: profile.gender,
        currentUserInterestIds: profile.interestIds,
        discoveryPreference: profile.discoveryPreference,
        excludeUserIds: swiped,
      );
      if (!mounted) return;
      setState(() {
        _batch = batch;
        _index = 0;
        _currentProfile = batch.isEmpty ? null : batch[0];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
          _batch = [];
          _currentProfile = null;
        });
      }
    }
  }

  Future<void> _swipe(String action) async {
    if (_currentProfile == null) return;
    final targetId = _currentProfile!.clerkId;
    await _firestore.recordSwipe(widget.userId, targetId, action);
    await _firestore.upsertMatchOnLike(widget.userId, targetId);
    if (action == 'like') {
      await _firestore.incrementSwipeCount(widget.userId);
    }
    if (!mounted) return;
    setState(() {
      _index++;
      if (_index < _batch.length) {
        _currentProfile = _batch[_index];
      } else {
        _currentProfile = null;
        _loadBatch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _batch.isEmpty && _error == null) {
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
          title: const Text('Swipe', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Couldn\'t load profiles.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _loadBatch(),
                  child: const Text('Retry', style: TextStyle(color: Color(0xFFFF4458))),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final p = _currentProfile;
    if (p == null && _batch.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Swipe', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No profiles to show for now.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (p == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF4458))),
      );
    }
    final imageUrl = p.profileImageUrls.isNotEmpty ? p.profileImageUrls.first : null;
    final interests = p.interestIds
        .where((id) => id.isNotEmpty)
        .take(5)
        .map((id) => id.length > 1 ? '${id[0].toUpperCase()}${id.substring(1)}' : id.toUpperCase())
        .join(' · ');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Swipe', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
          child: Card(
            color: const Color(0xFF17191C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 380,
                    child: imageUrl != null
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : const ColoredBox(
                            color: Colors.white12,
                            child: Icon(Icons.person, size: 80, color: Colors.white38),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.fullName}, ${p.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (p.gender.isNotEmpty)
                        Text(
                          p.gender[0].toUpperCase() + p.gender.substring(1).replaceAll('_', ' '),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      if (p.location.isNotEmpty)
                        Text(
                          p.location,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      if (interests.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          interests,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton.filled(
                        onPressed: () => _swipe('dislike'),
                        icon: const Icon(Icons.close, color: Colors.white, size: 32),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white24,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => _swipe('like'),
                        icon: const Icon(Icons.favorite, color: Color(0xFFFF4458), size: 36),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4458).withValues(alpha: 0.3),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
