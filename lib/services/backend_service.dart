import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

/// Calls the external backend API (e.g. Vercel serverless) instead of Cloud Functions.
/// Endpoints: get-custom-token, send-verification-otp, verify-university-email.
class BackendService {
  String get _base => kBackendBaseUrl;

  Future<String> getCustomToken(String clerkSessionToken) async {
    final res = await http.post(
      Uri.parse('$_base/api/get-custom-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': clerkSessionToken}),
    );
    if (res.statusCode != 200) {
      throw Exception('getCustomToken failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    final token = data?['token'] as String?;
    if (token == null) throw Exception('No token returned');
    return token;
  }

  Future<void> sendVerificationOtp(String email) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) throw Exception('Not signed in to Firebase');
    final res = await http.post(
      Uri.parse('$_base/api/send-verification-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 200) {
      throw Exception('sendVerificationOtp failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> verifyUniversityEmail(String otp) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) throw Exception('Not signed in to Firebase');
    final res = await http.post(
      Uri.parse('$_base/api/verify-university-email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'otp': otp}),
    );
    if (res.statusCode != 200) {
      throw Exception('verifyUniversityEmail failed: ${res.statusCode} ${res.body}');
    }
  }
}
