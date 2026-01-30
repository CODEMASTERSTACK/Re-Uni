import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../services/firestore_service.dart';
import 'profile_setup_screen.dart';
import 'app_shell.dart';

/// After Clerk sign-in: sync Firebase (custom token) then show ProfileSetup or AppShell.
class AuthGate extends StatefulWidget {
  final ClerkAuthState authState;

  const AuthGate({super.key, required this.authState});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  final _backend = BackendService();
  final _firestore = FirestoreService();

  bool _synced = false;
  bool _syncing = false;
  String? _error;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _syncFirebase();
  }

  Future<void> _syncFirebase() async {
    if (_syncing) return;
    setState(() { _syncing = true; _error = null; });
    try {
      final token = await widget.authState.getToken();
      if (token == null || token.isEmpty) {
        setState(() { _error = 'No session token'; _syncing = false; });
        return;
      }
      final customToken = await _backend.getCustomToken(token);
      await _auth.signInWithCustomToken(customToken);
      final uid = _auth.clerkIdFromFirebase;
      if (uid == null) {
        setState(() { _error = 'Firebase sign-in failed'; _syncing = false; });
        return;
      }
      final profile = await _firestore.getUserProfile(uid);
      await _firestore.setSuspendedIfPastDeadline(uid);
      final profileAfter = await _firestore.getUserProfile(uid);
      setState(() {
        _synced = true;
        _syncing = false;
        _profile = profileAfter ?? profile;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _syncing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_syncing || (!_synced && _error == null)) {
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
                  onPressed: _syncFirebase,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4458)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final uid = _auth.clerkIdFromFirebase;
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Not signed in', style: TextStyle(color: Colors.white))),
      );
    }
    final p = _profile;
    final needsSetup = p == null || !p.onboardingComplete;
    if (needsSetup) {
      final user = widget.authState.user;
      String email = '';
      String fullName = 'User';
      if (user != null) {
        try {
          final emails = user.emailAddresses;
          if (emails.isNotEmpty) email = emails.first.emailAddress;
        } catch (_) {}
        fullName = user.fullName ?? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
        if (fullName.isEmpty) fullName = 'User';
      }
      return ProfileSetupScreen(
        clerkId: uid,
        email: email.isEmpty ? 'user@example.com' : email,
        fullName: fullName,
      );
    }
    return AppShell(userId: uid);
  }
}
