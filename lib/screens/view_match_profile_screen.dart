import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

// Shared colors for this screen (Tinder-inspired dark theme).
const Color _kVmpPrimary = Color(0xFFFF4458);
const Color _kVmpBg = Color(0xFF0D0E10);
const Color _kVmpCard = Color(0xFF17191C);
const Color _kVmpText = Color(0xFFF5F5F5);
const Color _kVmpTextMuted = Color(0xFFB0B0B0);
const Color _kVmpInstagramStart = Color(0xFFF58529);
const Color _kVmpInstagramEnd = Color(0xFFDD2A7B);
const Color _kVmpSnapchatYellow = Color(0xFFFFFC00);
const Color _kVmpSpotifyGreen = Color(0xFF1DB954);

/// Tinder-inspired full profile view for a match (photos, bio, interests, social).
/// Used when user taps "View Profile" from the matches screen.
class ViewMatchProfileScreen extends StatefulWidget {
  final String otherUserId;
  final UserProfile? profile;

  const ViewMatchProfileScreen({
    super.key,
    required this.otherUserId,
    this.profile,
  });

  @override
  State<ViewMatchProfileScreen> createState() => _ViewMatchProfileScreenState();
}

class _ViewMatchProfileScreenState extends State<ViewMatchProfileScreen> {
  final _firestore = FirestoreService();
  UserProfile? _profile;
  bool _loading = true;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      setState(() {
        _profile = widget.profile;
        _loading = false;
      });
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final p = await _firestore.getUserProfile(widget.otherUserId, fromServer: true);
    if (mounted) setState(() {
      _profile = p;
      _loading = false;
    });
  }

  static String _interestLabel(String id) {
    for (final e in kInterestsList) {
      final m = Map<String, dynamic>.from(e as Map);
      if (m['id'] == id) return m['label'] as String? ?? id;
    }
    return id.isNotEmpty ? '${id[0].toUpperCase()}${id.substring(1)}' : id;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _kVmpBg,
        body: Center(child: CircularProgressIndicator(color: _kVmpPrimary)),
      );
    }
    if (_profile == null) {
      return Scaffold(
        backgroundColor: _kVmpBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Profile not found', style: TextStyle(color: _kVmpTextMuted)),
        ),
      );
    }
    final p = _profile!;
    final urls = p.profileImageUrls;
    final wallpaperUrl = p.profileWallpaperUrl;
    return Scaffold(
      backgroundColor: _kVmpBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Profile wallpaper background (match's choice; default dark when null)
          if (wallpaperUrl != null && wallpaperUrl.isNotEmpty)
            Image.network(
              wallpaperUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _kVmpBg),
            )
          else
            Container(color: _kVmpBg),
          // Full-bleed photo carousel (Tinder-style)
          PageView.builder(
            itemCount: urls.isEmpty ? 1 : urls.length,
            onPageChanged: (i) => setState(() => _photoIndex = i),
            itemBuilder: (_, i) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (urls.isNotEmpty)
                    Image.network(
                      urls[i],
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: _kVmpCard,
                      child: Icon(Icons.person, size: 120, color: _kVmpTextMuted),
                    ),
                  // Gradient overlay at bottom (Tinder-style)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black26,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ),
          // Photo indicator (e.g. 1/3)
          if (urls.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_photoIndex + 1}/${urls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          // Bottom card with profile info (Tinder-style rounded card)
          DraggableScrollableSheet(
            initialChildSize: 0.52,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: _kVmpCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _kVmpTextMuted.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Name & age
                    Text(
                      '${p.fullName}, ${p.age}',
                      style: const TextStyle(
                        color: _kVmpText,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 18, color: _kVmpTextMuted),
                        const SizedBox(width: 6),
                        Text(
                          p.location.isNotEmpty ? p.location : 'No location',
                          style: const TextStyle(color: _kVmpTextMuted, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Gender
                    Row(
                      children: [
                        _InfoChip(label: p.gender.replaceAll('_', ' ')),
                      ],
                    ),
                    if (p.bio != null && p.bio!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'About',
                        style: TextStyle(
                          color: _kVmpText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.bio!,
                        style: const TextStyle(color: _kVmpTextMuted, fontSize: 15, height: 1.45),
                      ),
                    ],
                    if (p.interestIds.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Interests',
                        style: TextStyle(
                          color: _kVmpText,
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
                                    color: _kVmpPrimary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _kVmpPrimary.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    _interestLabel(id),
                                    style: const TextStyle(color: _kVmpText, fontSize: 14),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    if ((p.instagramHandle != null && p.instagramHandle!.isNotEmpty) ||
                        (p.snapchatHandle != null && p.snapchatHandle!.isNotEmpty) ||
                        (p.spotifyPlaylistUrl != null && p.spotifyPlaylistUrl!.isNotEmpty)) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Social',
                        style: TextStyle(
                          color: _kVmpText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (p.instagramHandle != null && p.instagramHandle!.isNotEmpty)
                            _SocialChip(
                              icon: const FaIcon(FontAwesomeIcons.instagram, size: 18, color: Colors.white),
                              label: p.instagramHandle!,
                              gradient: const LinearGradient(
                                colors: [_kVmpInstagramStart, _kVmpInstagramEnd],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          if (p.snapchatHandle != null && p.snapchatHandle!.isNotEmpty)
                            _SocialChip(
                              icon: const FaIcon(FontAwesomeIcons.snapchat, size: 18, color: Colors.black87),
                              label: p.snapchatHandle!,
                              color: _kVmpSnapchatYellow,
                            ),
                          if (p.spotifyPlaylistUrl != null && p.spotifyPlaylistUrl!.isNotEmpty)
                            _SocialChip(
                              icon: const FaIcon(FontAwesomeIcons.spotify, size: 18, color: Colors.white),
                              label: 'Spotify',
                              color: _kVmpSpotifyGreen,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kVmpTextMuted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: _kVmpTextMuted, fontSize: 13),
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color? color;
  final Gradient? gradient;

  const _SocialChip({
    required this.icon,
    required this.label,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color == _kVmpSnapchatYellow ? Colors.black87 : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
