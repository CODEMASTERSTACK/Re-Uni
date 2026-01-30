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

  const UniDateWebApp({super.key, this.initialClerkToken});

  @override
  State<UniDateWebApp> createState() => _UniDateWebAppState();
}

class _UniDateWebAppState extends State<UniDateWebApp> {
  final AuthService _auth = AuthService();
  final BackendService _backend = BackendService();

  bool _checkingCallback = true;
  String? _signedInUid;
  String? _error;

  @override
  void initState() {
    super.initState();
    // If we have a token from main(), start exchange immediately.
    if ((widget.initialClerkToken ?? '').isNotEmpty) {
      _handleCallback();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleCallback();
    });
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
        setState(() {
          _checkingCallback = false;
          _signedInUid = uid;
        });
      } else if (mounted) {
        setState(() { _checkingCallback = false; _error = 'Firebase sign-in failed'; });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() { _checkingCallback = false; _error = e.toString(); });
      }
      assert(() { debugPrint('Auth callback error: $e\n$stack'); return true; }());
    }
  }

  void _goToClerkSignIn({required bool isSignUp}) {
    final base = kClerkWebSignInUrl.split('?').first;
    final path = isSignUp ? base.replaceFirst(RegExp(r'sign-in$'), 'sign-up') : base;
    final redirectUri = Uri.base.replace(path: '', queryParameters: {}, fragment: '');
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
      return WebAuthGate(userId: _signedInUid!);
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
                  onPressed: () => setState(() { _error = null; _checkingCallback = true; _handleCallback(); }),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4458)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
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
    );
  }
}

