import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'firebase_options.dart';
import 'path_provider_stub_web.dart';
import 'screens/auth_gate.dart';
import 'screens/auth_screen.dart';

import 'web_app_root.dart' show UniDateWebApp;
import 'screens/landing_page.dart';
import 'web_redirect_stub.dart' if (dart.library.html) 'web_redirect_web.dart' as web_redirect;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerPathProviderStubWeb();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // On web, never build ClerkAuth (avoids path_provider/Platform crash). Use redirect-based auth.
  if (kIsWeb) {
    // Read Clerk callback token and user info at the very start (from window.location) so we don't lose them.
    final initialToken = web_redirect.getClerkCallbackToken();
    final initialName = web_redirect.getClerkCallbackName();
    final initialEmail = web_redirect.getClerkCallbackEmail();
    runApp(UniDateWebApp(
      initialClerkToken: initialToken,
      initialClerkName: initialName,
      initialClerkEmail: initialEmail,
    ));
    return;
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: const String.fromEnvironment(
          'CLERK_PUBLISHABLE_KEY',
          defaultValue: 'pk_test_d29ya2luZy10dXJ0bGUtNzQuY2xlcmsuYWNjb3VudHMuZGV2JA',
        ),
        // On web, dart:io (Directory, Platform.pathSeparator) is unsupported; use no persistence.
        persistor: kIsWeb ? Persistor.none : null,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => ClerkAuthBuilder(
            signedOutBuilder: (context, state) => const LandingPage(),
            signedInBuilder: (context, state) => AuthGate(authState: state),
          ),
          '/sign-up': (context) => const AuthScreen(isSignUp: true),
          '/sign-in': (context) => const AuthScreen(isSignUp: false),
        },
      ),
    );
  }
}

