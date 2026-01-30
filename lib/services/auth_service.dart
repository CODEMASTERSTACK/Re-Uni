import 'package:firebase_auth/firebase_auth.dart';

/// Bridges Clerk (auth UI + session) and Firebase (Firestore access).
/// After Clerk sign-in, call backend to get Firebase custom token and sign in.
/// For sign-out, call Firebase signOut here and Clerk signOut from the UI (ClerkAuth.of(context).signOut()).
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign in to Firebase with a custom token (from backend that verifies Clerk JWT).
  Future<void> signInWithCustomToken(String token) async {
    await _firebaseAuth.signInWithCustomToken(token);
  }

  /// Signs out of Firebase only. Call Clerk signOut from UI via ClerkAuth.of(context).signOut().
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Clerk user ID is the canonical userId for Firestore and R2.
  /// When using Firebase custom token, the token's uid should be set to Clerk user ID
  /// so that request.auth.uid in Firestore rules matches Clerk ID.
  String? get clerkIdFromFirebase => _firebaseAuth.currentUser?.uid;
}
