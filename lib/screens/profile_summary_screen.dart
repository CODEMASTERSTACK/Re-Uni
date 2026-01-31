import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../constants.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'profile_setup_screen.dart';
import 'verification_screen.dart';
import '../web_redirect_stub.dart' if (dart.library.html) '../web_redirect_web.dart' as web_redirect;

// Theme matching the reference: light background, rounded corners, accent red.
const Color _kPrimaryRed = Color(0xFFFF4458);
const Color _kBgLight = Color(0xFFFAFAFA);
const Color _kCardWhite = Color(0xFFFFFFFF);
const Color _kTextPrimary = Color(0xFF2D2D2D);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kTextMuted = Color(0xFF9E9E9E);
const Color _kPinkEngagement = Color(0xFFFFE5E9);
const Color _kBorderGray = Color(0xFFE0E0E0);
const Color _kInstagramStart = Color(0xFFF58529);
const Color _kInstagramEnd = Color(0xFFDD2A7B);
const Color _kSnapchatYellow = Color.fromARGB(255, 250, 250, 113);
const Color _kSpotifyGreen = Color(0xFF1DB954);

class ProfileSummaryScreen extends StatefulWidget {
  final String userId;

  const ProfileSummaryScreen({super.key, required this.userId});

  @override
  State<ProfileSummaryScreen> createState() => _ProfileSummaryScreenState();
}

class _ProfileSummaryScreenState extends State<ProfileSummaryScreen> {
  final _firestore = FirestoreService();
  final _auth = AuthService();
  UserProfile? _profile;
  bool _loading = true;
  int _coverIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await firebaseUser.getIdToken(true);
    }
    final p = await _firestore.getUserProfile(widget.userId);
    if (mounted) {
      setState(() {
        _profile = p;
        _loading = false;
      });
    }
  }

  static String _interestLabel(String id) {
    for (final e in kInterestsList) {
      final m = Map<String, dynamic>.from(e as Map);
      if (m['id'] == id) return m['label'] as String? ?? id;
    }
    return id.isNotEmpty ? '${id[0].toUpperCase()}${id.substring(1)}' : id;
  }

  /// Appends a cache-bust query param so the browser refetches after profile save (same storage path = same URL otherwise).
  static String _imageUrlWithCacheBust(String url, DateTime updatedAt) {
    final t = updatedAt.millisecondsSinceEpoch;
    return url.contains('?') ? '$url&_t=$t' : '$url?_t=$t';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _kBgLight,
        body: Center(child: CircularProgressIndicator(color: _kPrimaryRed)),
      );
    }
    if (_profile == null) {
      return Scaffold(
        backgroundColor: _kBgLight,
        body: Center(child: Text('Profile not found', style: TextStyle(color: _kTextPrimary))),
      );
    }
    final p = _profile!;
    final suspended = p.isSuspended;
    return Scaffold(
      backgroundColor: _kBgLight,
      body: suspended
          ? _buildSuspended(p)
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildCoverAndPhotos(p)),
                SliverToBoxAdapter(child: _buildProfileInfo(p)),
                SliverToBoxAdapter(child: _buildEngagement(p)),
                SliverToBoxAdapter(child: _buildSocialAndActions(p)),
                SliverToBoxAdapter(child: _buildInterests(p)),
                if (!p.isStudentVerified) SliverToBoxAdapter(child: _buildVerifyCta(p)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildCoverAndPhotos(UserProfile p) {
    final urls = p.profileImageUrls;
    final hasCover = urls.isNotEmpty;
    final additionalUrls = hasCover && urls.length > 1
        ? urls.asMap().entries.where((e) => e.key != _coverIndex).map((e) => e.value).toList()
        : <String>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover photo carousel with rounded corners and camera button
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 360,
                  child: hasCover
                      ? PageView.builder(
                          itemCount: urls.length,
                          onPageChanged: (i) => setState(() => _coverIndex = i),
                          itemBuilder: (_, i) => Image.network(urls[i], fit: BoxFit.cover),
                        )
                      : Container(
                          color: _kBorderGray,
                          child: Icon(Icons.person, size: 80, color: _kTextMuted),
                        ),
                ),
                if (hasCover)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: () => _openEditProfile(p),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: _kPrimaryRed,
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasCover)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '(${_coverIndex + 1}/${urls.length})',
                  style: TextStyle(color: _kTextSecondary, fontSize: 14),
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Additional Photos
          if (urls.length > 1 || urls.length < kMaxProfileImages) ...[
            Text(
              'Additional Photos',
              style: TextStyle(
                color: _kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (additionalUrls.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(additionalUrls.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _thumbnailWithRemove(additionalUrls[i], p),
                    );
                  }),
                ),
              ),
            if (additionalUrls.isNotEmpty) const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: _addMorePhotosButton(p)),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _thumbnailWithRemove(String url, UserProfile p) {
    final cacheBustedUrl = _imageUrlWithCacheBust(url, p.updatedAt);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(cacheBustedUrl, width: 100, height: 100, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _openEditProfile(p),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade700,
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addMorePhotosButton(UserProfile p) {
    return OutlinedButton.icon(
      onPressed: () => _openEditProfile(p),
      icon: Icon(Icons.camera_alt_outlined, size: 20, color: _kTextSecondary),
      label: Text('Add More Photos', style: TextStyle(color: _kTextSecondary, fontSize: 14)),
      style: OutlinedButton.styleFrom(
        backgroundColor: _kCardWhite,
        side: const BorderSide(color: _kBorderGray),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildProfileInfo(UserProfile p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${p.fullName}, ${p.age}',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: _kTextPrimary),
              const SizedBox(width: 4),
              Text(
                p.location.isNotEmpty ? p.location : 'No location set',
                style: TextStyle(color: _kTextSecondary, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (p.bio != null && p.bio!.isNotEmpty) ? p.bio! : 'Nothing to describe about me yet.',
            style: TextStyle(color: _kTextMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagement(UserProfile p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: _kPinkEngagement,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: _kPrimaryRed, size: 32),
            const SizedBox(width: 10),
            Text(
              '${p.swipeCount}',
              style: TextStyle(
                color: _kTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Swiped my profile so far',
              style: TextStyle(color: _kTextSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialAndActions(UserProfile p) {
    final hasSocial = (p.instagramHandle != null && p.instagramHandle!.isNotEmpty) ||
        (p.snapchatHandle != null && p.snapchatHandle!.isNotEmpty) ||
        (p.spotifyPlaylistUrl != null && p.spotifyPlaylistUrl!.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSocial) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (p.instagramHandle != null && p.instagramHandle!.isNotEmpty)
                  _socialPill(
                    label: p.instagramHandle!,
                    icon: Icons.camera_alt,
                    gradient: const LinearGradient(
                      colors: [_kInstagramStart, _kInstagramEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                if (p.snapchatHandle != null && p.snapchatHandle!.isNotEmpty)
                  _socialPill(
                    label: p.snapchatHandle!,
                    icon: Icons.photo_camera_outlined,
                    color: _kSnapchatYellow,
                  ),
                if (p.spotifyPlaylistUrl != null && p.spotifyPlaylistUrl!.isNotEmpty)
                  _socialPill(
                    label: 'Spotify',
                    icon: Icons.music_note,
                    color: _kSpotifyGreen,
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openEditProfile(p),
                  icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                  label: const Text('Edit Profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(p),
                  icon: Icon(Icons.logout, size: 20, color: _kPrimaryRed),
                  label: Text('Sign Out', style: TextStyle(color: _kPrimaryRed, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kPrimaryRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialPill({
    required String label,
    required IconData icon,
    Color? color,
    Gradient? gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInterests(UserProfile p) {
    if (p.interestIds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Interests',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.interestIds
                .map((id) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        border: Border.all(color: _kBorderGray),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _interestLabel(id),
                        style: TextStyle(color: _kTextPrimary, fontSize: 14),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyCta(UserProfile p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: OutlinedButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerificationScreen(userId: widget.userId),
            ),
          );
          _load();
        },
        child: const Text('Verify student (@lpu.in)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimaryRed,
          side: const BorderSide(color: _kPrimaryRed),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  Future<void> _openEditProfile(UserProfile p) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(
          clerkId: p.clerkId,
          email: p.email,
          fullName: p.fullName,
          initialProfile: p,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  Future<void> _signOut(UserProfile p) async {
    if (kIsWeb) {
      await _auth.signOut();
      try {
        await _auth.authStateChanges
            .firstWhere((User? u) => u == null)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
      if (mounted) web_redirect.redirectToClerkSignOut();
    } else {
      try {
        await ClerkAuth.of(context).signOut();
      } catch (_) {}
      await _auth.signOut();
      try {
        await _auth.authStateChanges
            .firstWhere((User? u) => u == null)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Widget _buildSuspended(UserProfile p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, color: _kPrimaryRed, size: 64),
            const SizedBox(height: 16),
            Text(
              'Account suspended',
              style: TextStyle(color: _kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verify your @lpu.in email within 72 hours of signup to continue.',
              style: TextStyle(color: _kTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VerificationScreen(userId: widget.userId),
                  ),
                );
                _load();
              },
              child: const Text('Verify now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimaryRed,
                side: const BorderSide(color: _kPrimaryRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
