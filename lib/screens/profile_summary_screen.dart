import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'profile_setup_screen.dart';
import 'verification_screen.dart';
import '../web_redirect_stub.dart' if (dart.library.html) '../web_redirect_web.dart' as web_redirect;

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Ensure auth token is ready so Firestore rules see request.auth (avoids permission-denied on refresh).
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF4458))),
      );
    }
    if (_profile == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Profile not found', style: TextStyle(color: Colors.white))),
      );
    }
    final p = _profile!;
    final suspended = p.isSuspended;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
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
              if (result == true) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              if (kIsWeb) {
                // On web: sign out of Firebase, then redirect to Clerk sign-out page so user must re-enter credentials next login.
                await _auth.signOut();
                try {
                  await _auth.authStateChanges
                      .firstWhere((User? u) => u == null)
                      .timeout(const Duration(seconds: 5));
                } catch (_) {}
                if (context.mounted) {
                  web_redirect.redirectToClerkSignOut();
                }
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
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              }
            },
          ),
        ],
      ),
      body: suspended
          ? _buildSuspended(p)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.profileImageUrls.isNotEmpty)
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: p.profileImageUrls.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              p.profileImageUrls[i],
                              width: 240,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    '${p.fullName}, ${p.age}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    p.location,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  if (p.interestIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: p.interestIds.map((id) => Chip(label: Text(id))).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('Swipe count: ${p.swipeCount}', style: const TextStyle(color: Colors.white54)),
                  if (!p.isStudentVerified) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VerificationScreen(userId: widget.userId),
                          ),
                        );
                        _load();
                      },
                      child: const Text('Verify student (@lpu.in)'),
                    ),
                  ],
                  if (p.instagramHandle != null) Text('Instagram: ${p.instagramHandle}', style: const TextStyle(color: Colors.white70)),
                  if (p.snapchatHandle != null) Text('Snapchat: ${p.snapchatHandle}', style: const TextStyle(color: Colors.white70)),
                  if (p.spotifyPlaylistUrl != null) Text('Spotify: ${p.spotifyPlaylistUrl}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
    );
  }

  Widget _buildSuspended(UserProfile p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Account suspended',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Verify your @lpu.in email within 72 hours of signup to continue.',
              style: TextStyle(color: Colors.white70),
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
            ),
          ],
        ),
      ),
    );
  }
}
