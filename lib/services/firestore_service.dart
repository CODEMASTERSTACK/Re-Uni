import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../models/user_profile.dart';
import '../models/interest.dart';
import '../models/swipe.dart';
import '../models/match_record.dart';
import '../models/chat.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  DocumentReference<Map<String, dynamic>> get _configInterests =>
      _firestore.doc('config/interests');
  CollectionReference<Map<String, dynamic>> get _swipes =>
      _firestore.collection('swipes');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');
  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  // ---------- Users ----------
  Future<void> setUserProfile(UserProfile profile) async {
    await _users.doc(profile.clerkId).set(profile.toMap());
  }

  Future<UserProfile?> getUserProfile(String clerkId, {bool fromServer = false}) async {
    final options = fromServer ? const GetOptions(source: Source.server) : null;
    final doc = options != null
        ? await _users.doc(clerkId).get(options)
        : await _users.doc(clerkId).get();
    if (doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!, doc.id);
  }

  Stream<UserProfile?> watchUserProfile(String clerkId) {
    return _users.doc(clerkId).snapshots().map((doc) {
      if (doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateUserProfile(String clerkId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(clerkId).update(data);
  }

  /// When 72h past and not verified, set suspendedAt (enforce suspension).
  Future<void> setSuspendedIfPastDeadline(String clerkId) async {
    final doc = await _users.doc(clerkId).get();
    if (!doc.exists || doc.data() == null) return;
    final data = doc.data()!;
    final verified = data['isStudentVerified'] as bool? ?? false;
    final deadline = (data['verificationDeadlineAt'] as Timestamp?)?.toDate();
    final suspendedAt = (data['suspendedAt'] as Timestamp?)?.toDate();
    if (verified || deadline == null || DateTime.now().isBefore(deadline) || suspendedAt != null) return;
    await _users.doc(clerkId).update({
      'suspendedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Seed config/interests if not present.
  Future<void> ensureInterestsConfig() async {
    final doc = await _configInterests.get();
    if (!doc.exists || doc.data() == null) {
      await _configInterests.set({'items': kInterestsList});
    }
  }

  Future<List<Interest>> getInterests() async {
    await ensureInterestsConfig();
    final doc = await _configInterests.get();
    final data = doc.data();
    if (data == null) return [];
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => Interest.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  // ---------- Swipes ----------
  Future<void> recordSwipe(String actorId, String targetId, String action) async {
    final docId = SwipeRecord.docId(actorId, targetId);
    final record = SwipeRecord(
      actorId: actorId,
      targetId: targetId,
      action: action,
      createdAt: DateTime.now(),
    );
    await _swipes.doc(docId).set(record.toMap());
  }

  Future<bool> hasSwiped(String actorId, String targetId) async {
    final docId = SwipeRecord.docId(actorId, targetId);
    final doc = await _swipes.doc(docId).get();
    return doc.exists;
  }

  /// Get all user IDs the current user has swiped on (to exclude from discovery).
  Future<Set<String>> getSwipedTargetIds(String actorId) async {
    final q = await _firestore
        .collection('swipes')
        .where('actorId', isEqualTo: actorId)
        .get();
    return q.docs.map((d) => d.data()['targetId'] as String).toSet();
  }

  // ---------- Matches ----------
  Future<void> upsertMatchOnLike(String likerId, String likedId) async {
    final user1Id = likerId.compareTo(likedId) <= 0 ? likerId : likedId;
    final user2Id = likerId.compareTo(likedId) <= 0 ? likedId : likerId;
    final matchId = MatchRecord.docId(user1Id, user2Id);
    final ref = _matches.doc(matchId);
    final doc = await ref.get();

    final now = DateTime.now();
    if (!doc.exists) {
      await ref.set({
        'user1Id': user1Id,
        'user2Id': user2Id,
        'status': 'pending',
        'likedBy': [likerId],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      return;
    }

    final data = doc.data()!;
    final likedBy = List<String>.from(data['likedBy'] as List<dynamic>? ?? []);
    if (likedBy.contains(likerId)) return;
    likedBy.add(likerId);

    final bool isMutual = likedBy.length == 2;
    await ref.update({
      'likedBy': likedBy,
      'status': isMutual ? 'matched' : 'pending',
      if (isMutual) 'matchedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> rejectMatch(String matchId, String rejectedByUserId) async {
    await _matches.doc(matchId).update({
      'status': 'rejected',
      'rejectedBy': rejectedByUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Pending: users who liked current user; Matched: mutual. Excludes rejected.
  Future<List<MatchRecord>> getMatchesForUser(String userId) async {
    final q = await _matches
        .where(Filter.or(
          Filter('user1Id', isEqualTo: userId),
          Filter('user2Id', isEqualTo: userId),
        ))
        .get();

    final list = <MatchRecord>[];
    for (final doc in q.docs) {
      final data = doc.data();
      if (data['status'] == 'rejected') continue;
      final rejectedBy = data['rejectedBy'] as String?;
      if (rejectedBy == userId) continue;
      list.add(MatchRecord.fromMap(data, doc.id));
    }
    return list;
  }

  /// Create chat when status becomes matched (call after ensuring match is matched).
  Future<String> createChatIfMatched(String matchId, String user1Id, String user2Id) async {
    final chatId = matchId;
    final ref = _chats.doc(chatId);
    if ((await ref.get()).exists) return chatId;
    await ref.set({
      'matchId': matchId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return chatId;
  }

  Future<List<ChatRecord>> getChatsForUser(String userId) async {
    final q = await _chats
        .where('user1Id', isEqualTo: userId)
        .get();
    final q2 = await _chats
        .where('user2Id', isEqualTo: userId)
        .get();

    final seen = <String>{};
    final list = <ChatRecord>[];
    for (final doc in q.docs) {
      if (seen.add(doc.id)) {
        list.add(ChatRecord.fromMap(doc.id, doc.data()));
      }
    }
    for (final doc in q2.docs) {
      if (seen.add(doc.id)) {
        list.add(ChatRecord.fromMap(doc.id, doc.data()));
      }
    }
    list.sort((a, b) {
      final aAt = a.lastMessageAt ?? a.createdAt;
      final bAt = b.lastMessageAt ?? b.createdAt;
      return bAt.compareTo(aAt);
    });
    return list;
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _chats.doc(chatId).collection('messages').orderBy('createdAt').snapshots().map((snap) {
      return snap.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList();
    });
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final ref = _chats.doc(chatId).collection('messages').doc();
    await ref.set({
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _chats.doc(chatId).update({
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessagePreview': text.length > 80 ? '${text.substring(0, 80)}...' : text,
    });
  }

  /// Discovery: interest-matched first, then random. Gender filter: male viewer → female profiles, female → male.
  /// When [includeUnverified] is true (e.g. debug testing), profiles without student verification are included.
  /// When [maxResultsForUnverified] is set, returned list is capped at that many (for unverified users).
  Future<List<UserProfile>> getDiscoveryBatch({
    required String currentUserId,
    required String currentUserGender,
    required List<String> currentUserInterestIds,
    required String discoveryPreference,
    required Set<String> excludeUserIds,
    bool includeUnverified = false,
    int? maxResultsForUnverified,
  }) async {
    // Gender-based filtering: male users see female profiles, female users see male profiles.
    final List<String> gendersToShow = _gendersToShowForViewer(currentUserGender, discoveryPreference);
    if (gendersToShow.isEmpty) return [];

    final int limit = kDiscoveryBatchSize * 3 + excludeUserIds.length; // fetch extra for sorting
    Query<Map<String, dynamic>> q = _users
        .where('onboardingComplete', isEqualTo: true)
        .where('gender', whereIn: gendersToShow)
        .limit(limit);
    if (!includeUnverified) {
      q = q.where('isStudentVerified', isEqualTo: true);
    }

    final snapshot = await q.get();
    final candidates = <UserProfile>[];
    for (final doc in snapshot.docs) {
      if (doc.id == currentUserId) continue;
      if (excludeUserIds.contains(doc.id)) continue;
      candidates.add(UserProfile.fromMap(doc.data(), doc.id));
    }

    // Interest matching: profiles with at least one shared interest first, then fallback random.
    final currentInterests = currentUserInterestIds.toSet();
    final withSharedInterest = <UserProfile>[];
    final withoutSharedInterest = <UserProfile>[];
    for (final p in candidates) {
      final hasShared = p.interestIds.any((id) => currentInterests.contains(id));
      if (hasShared) {
        withSharedInterest.add(p);
      } else {
        withoutSharedInterest.add(p);
      }
    }
    withSharedInterest.shuffle();
    withoutSharedInterest.shuffle();
    final combined = [...withSharedInterest, ...withoutSharedInterest];
    final cap = maxResultsForUnverified ?? kDiscoveryBatchSize;
    return combined.take(cap).toList();
  }

  /// Increment how many profiles an unverified user has viewed in swipe (used for 10-profile cap).
  Future<void> incrementProfilesViewedWhileUnverified(String userId) async {
    await _users.doc(userId).update({
      'profilesViewedWhileUnverified': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Male viewer → female profiles; female viewer → male profiles; else use discovery preference.
  List<String> _gendersToShowForViewer(String viewerGender, String discoveryPreference) {
    switch (viewerGender) {
      case 'male':
        return ['female'];
      case 'female':
        return ['male'];
      case 'non_binary':
      case 'other':
      default:
        return _gendersForPreference(discoveryPreference);
    }
  }

  List<String> _gendersForPreference(String pref) {
    switch (pref) {
      case 'men':
        return ['male'];
      case 'women':
        return ['female'];
      case 'non_binary':
        return ['non_binary'];
      case 'everyone':
      default:
        return ['male', 'female', 'non_binary', 'other'];
    }
  }

  Future<void> incrementSwipeCount(String userId) async {
    await _users.doc(userId).update({
      'swipeCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
