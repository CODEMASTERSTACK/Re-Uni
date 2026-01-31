import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'services/auth_service.dart';
import 'services/backend_service.dart';
import 'web_auth_gate.dart';
import 'web_redirect_stub.dart' if (dart.library.html) 'web_redirect_web.dart' as web_redirect;
import 'screens/landing_page.dart';

/// Web-only app root: never builds ClerkAuth, so no path_provider/Platform crash.
/// Uses redirect to Clerk sign-in; on callback, exchanges token for Firebase and shows WebAuthGate.
class UniDateWebApp extends StatefulWidget {
  /// Token read in main() from window.location so we don't lose it after redirect.
  final String? initialClerkToken;
  /// Name/email from Clerk callback (clerk-bridge) so profile setup shows the name user gave at sign-up.
  final String? initialClerkName;
  final String? initialClerkEmail;

  const UniDateWebApp({
    super.key,
    this.initialClerkToken,
    this.initialClerkName,
    this.initialClerkEmail,
  });

  @override
  State<UniDateWebApp> createState() => _UniDateWebAppState();
}

class _UniDateWebAppState extends State<UniDateWebApp> {
  final AuthService _auth = AuthService();
  final BackendService _backend = BackendService();

  bool _checkingCallback = true;
  String? _signedInUid;
  String? _error;
  /// When true, user tapped "Sign in again" on session-expired; show landing and ignore URL token.
  bool _userChoseLanding = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initAuth();
    // When user signs out, clear signed-in state so we show landing instead of WebAuthGate (avoids permission-denied).
    _authSubscription = _auth.authStateChanges.listen((User? user) {
      if (user == null && mounted && _signedInUid != null) {
        setState(() {
          _signedInUid = null;
          _checkingCallback = false;
          _error = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Ensures the Firebase ID token is ready so Firestore requests have request.auth set.
  /// Call after we have currentUser but before any Firestore access (e.g. after refresh).
  Future<void> _ensureAuthTokenReady(User user) async {
    try {
      await user.getIdToken(true);
    } catch (_) {}
  }

  /// Prefer persisted Firebase session. Give Firebase a moment to restore from storage
  /// before trying Clerk token from URL, so refresh keeps the user logged in.
  Future<void> _initAuth() async {
    // 1) First emission: might be restored user or null (persistence not ready yet).
    User? user;
    try {
      user = await _auth.authStateChanges.first;
    } catch (_) {}
    if (!mounted) return;
    if (user != null) {
      await _ensureAuthTokenReady(user);
      if (!mounted) return;
      final uid = user.uid;
      setState(() {
        _signedInUid = uid;
        _checkingCallback = false;
      });
      return;
    }
    // 2) On web, persistence can restore slightly later; give it a short moment.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    user = _auth.currentFirebaseUser;
    if (user != null) {
      await _ensureAuthTokenReady(user);
      if (!mounted) return;
      final uid = user.uid;
      setState(() {
        _signedInUid = uid;
        _checkingCallback = false;
      });
      return;
    }
    // 3) No persisted session; try Clerk token from URL if present.
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    String? token = widget.initialClerkToken;
    if (token == null || token.isEmpty) {
      try {
        token = web_redirect.getClerkCallbackToken();
      } catch (_) {}
      if (token == null || token.isEmpty) {
        try {
          final q = Uri.base.queryParameters;
          token = q['__clerk_db_jwt'] ?? q['_clerk_db_jwt'] ?? q['_clerk_db_jwi'] ?? q['__clerk_ticket'] ?? q['token'] ?? q['code'];
        } catch (_) {}
      }
    }
    if (token == null || token.isEmpty) {
      if (mounted) setState(() { _checkingCallback = false; });
      return;
    }
    try {
      final customToken = await _backend.getCustomToken(token);
      if (customToken.isEmpty) throw Exception('No token returned');
      await _auth.signInWithCustomToken(customToken);
      final uid = _auth.clerkIdFromFirebase;
      if (mounted && uid != null && uid.isNotEmpty) {
        web_redirect.clearClerkCallbackFromUrl();
        setState(() {
          _checkingCallback = false;
          _signedInUid = uid;
        });
      } else if (mounted) {
        setState(() { _checkingCallback = false; _error = 'Firebase sign-in failed'; });
      }
    } catch (e, stack) {
      final isExpired = e.toString().contains('JWT is expired') || e.toString().contains('401');
      if (isExpired) web_redirect.clearClerkCallbackFromUrl();
      if (mounted) {
        setState(() {
          _checkingCallback = false;
          _error = isExpired
              ? 'Session expired. Please sign in again.'
              : e.toString();
        });
      }
      assert(() { debugPrint('Auth callback error: $e\n$stack'); return true; }());
    }
  }

  void _goToClerkSignIn({required bool isSignUp}) {
    final base = kClerkWebSignInUrl.split('?').first;
    final path = isSignUp ? base.replaceFirst(RegExp(r'sign-in$'), 'sign-up') : base;
    // Redirect to clerk-bridge.html so Clerk.js can exchange URL session for a JWT, then bridge redirects to app with __clerk_db_jwt.
    final redirectUri = Uri.base.replace(path: '/clerk-bridge.html', queryParameters: {}, fragment: '');
    final url = '$path?redirect_url=${Uri.encodeComponent(redirectUri.toString())}';
    web_redirect.redirectToClerkSignIn(url);
  }

  /// Single MaterialApp so we never swap root widgets (avoids updateChild/rebuild crashes).
  Widget _buildHome() {
    if (_checkingCallback) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF4458)),
              const SizedBox(height: 16),
              Text('Loading...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }
    if (_signedInUid != null) {
      return WebAuthGate(
        userId: _signedInUid!,
        initialName: widget.initialClerkName,
        initialEmail: widget.initialClerkEmail,
      );
    }
    if (_error != null) {
      final isSessionExpired = _error!.contains('Session expired');
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
                    setState(() {
                      _error = null;
                      if (isSessionExpired) _userChoseLanding = true;
                      else _checkingCallback = true;
                    });
                    if (!isSessionExpired) _handleCallback();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4458)),
                  child: Text(isSessionExpired ? 'Sign in again' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // User chose "Sign in again" after session expired – show landing and ignore URL token.
    if (_userChoseLanding) {
      return LandingPage(onSignUp: () => _goToClerkSignIn(isSignUp: true), onSignIn: () => _goToClerkSignIn(isSignUp: false));
    }
    // About to show landing – re-check token from main(), redirect helper, or Uri.base; retry once.
    String? tokenNow = widget.initialClerkToken;
    if (tokenNow == null || tokenNow.isEmpty) {
      try {
        tokenNow = web_redirect.getClerkCallbackToken() ?? Uri.base.queryParameters['__clerk_db_jwt'] ?? Uri.base.queryParameters['_clerk_db_jwt'] ?? Uri.base.queryParameters['_clerk_db_jwi'];
      } catch (_) {}
    }
    if (tokenNow != null && tokenNow.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() { _checkingCallback = true; });
          _handleCallback();
        }
      });
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF4458)),
              const SizedBox(height: 16),
              Text('Signing you in...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }
    return LandingPage(onSignUp: () => _goToClerkSignIn(isSignUp: true), onSignIn: () => _goToClerkSignIn(isSignUp: false));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _buildHome(),
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/app') {
          final uid = _auth.currentFirebaseUser?.uid;
          if (uid == null || uid.isEmpty) {
            return MaterialPageRoute<void>(builder: (_) => _buildHome());
          }
          return MaterialPageRoute<void>(builder: (_) => WebAuthGate(userId: uid));
        }
        return null;
      },
      onUnknownRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(builder: (_) => _buildHome());
      },
    );
  }
}

