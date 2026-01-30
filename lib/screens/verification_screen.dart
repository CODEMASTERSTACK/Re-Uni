import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/backend_service.dart';
import '../services/firestore_service.dart';

class VerificationScreen extends StatefulWidget {
  final String userId;

  const VerificationScreen({super.key, required this.userId});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _backend = BackendService();
  final _firestore = FirestoreService();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (!email.endsWith(kUniversityEmailDomain)) {
      setState(() => _error = 'Use a valid $kUniversityEmailDomain email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _backend.sendVerificationOtp(email);
      setState(() { _otpSent = true; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter 6-digit code');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _backend.verifyUniversityEmail(otp);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Student verification', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _otpSent ? _buildOtpForm() : _buildEmailForm(),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter your university email to verify student status.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email ($kUniversityEmailDomain)',
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4458),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Send code'),
        ),
      ],
    );
  }

  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Enter the 6-digit code sent to your email.', style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          decoration: const InputDecoration(
            labelText: 'Code',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4458),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Verify'),
        ),
      ],
    );
  }
}
