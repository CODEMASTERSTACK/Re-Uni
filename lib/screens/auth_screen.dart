import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

/// Sign-in or sign-up using Clerk's built-in UI.
class AuthScreen extends StatelessWidget {
  final bool isSignUp;

  const AuthScreen({super.key, this.isSignUp = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: ClerkAuthentication(),
        ),
      ),
    );
  }
}
