import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/app_shell.dart';

/// Post-auth flow for web: same as AuthGate but only needs Firebase uid (no ClerkAuthState).
/// Used after redirect callback when we already signed in with Firebase custom token.
class WebAuthGate extends StatefulWidget {
  final String userId;
  /// Name/email from Clerk callback so profile setup shows the name user gave at sign-up.
  final String? initialName;
  final String? initialEmail;

  const WebAuthGate({
    super.key,
    required this.userId,
    this.initialName,
    this.initialEmail,
  });

  @override
  State<WebAuthGate> createState() => _WebAuthGateState();
}

class _WebAuthGateState extends State<WebAuthGate> {
  final _firestore = FirestoreService();

  bool _loading = true;
  String? _error;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!_loading) return;
    setState(() { _error = null; });
    try {
      // Skip Firestore if user just signed out (root will show landing).
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      // Ensure auth token is ready so Firestore rules see request.auth (avoids permission-denied on refresh).
      await firebaseUser.getIdToken(true);
      await _firestore.setSuspendedIfPastDeadline(widget.userId);
      final profile = await _firestore.getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _loading = false;
          _profile = profile;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _error == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF4458)),
              SizedBox(height: 16),
              Text('Setting up...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() { _loading = true; });
                    _loadProfile();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4458)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final p = _profile;
    final needsSetup = p == null || !p.onboardingComplete;
    if (needsSetup) {
      return ProfileSetupScreen(
        clerkId: widget.userId,
        email: widget.initialEmail?.isNotEmpty == true ? widget.initialEmail! : 'user@example.com',
        fullName: widget.initialName?.isNotEmpty == true ? widget.initialName! : 'User',
      );
    }
    return AppShell(userId: widget.userId);
  }
}
