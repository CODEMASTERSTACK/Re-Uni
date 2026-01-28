import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050607),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/unidate_logo.png',
                        height: 40,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'UniDate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Back to home',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Hero heading + paragraph
              const Text(
                'We’re here to help.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 820,
                child: Text(
                  'Whether you are having trouble logging in, managing matches or have a question about safety, our team is here to support you. Browse common topics below and reach out if you need individual help with your UniDate account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // FAQ-style columns similar to Tinder Support
              LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth = constraints.maxWidth;
                  double columnWidth;
                  if (maxWidth >= 1100) {
                    columnWidth = (maxWidth - 40) / 2;
                  } else {
                    columnWidth = maxWidth;
                  }

                  return Wrap(
                    spacing: 40,
                    runSpacing: 40,
                    children: [
                      SizedBox(
                        width: columnWidth,
                        child: const _SupportBlock(
                          title: 'Account & profile',
                          body:
                              'Learn how to edit your photos and bio, update your university or course details, and manage visibility settings. Use this section later to add specific instructions for verifying your email, changing your password and controlling which parts of your profile are shown to others.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SupportBlock(
                          title: 'Matches & messaging',
                          body:
                              'Find out what to do if your matches disappear, messages are not sending, or you accidentally unmatched someone. Here you can later add details on how the matching algorithm works, when messages are delivered, and how to mute or restrict conversations that you no longer want in your inbox.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SupportBlock(
                          title: 'Reporting issues',
                          body:
                              'If you see fake profiles, harassment, discrimination or anything that breaks our community guidelines, you can report directly from the profile or chat. Reports are confidential and help us remove harmful content, investigate repeated behaviour and keep UniDate safe and welcoming for everyone on campus.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SupportBlock(
                          title: 'Technical problems',
                          body:
                              'Having trouble logging in, verifying your email, or loading images? Start by checking your connection, updating to the latest version and clearing cache or cookies. If the issue continues, contact our team with a short description of the problem, the device and browser you are using, and any error messages you see.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SupportBlock(
                          title: 'Feedback & ideas',
                          body:
                              'UniDate is built for students, so your feedback matters. If you have ideas for new features, campus‑specific tools or accessibility improvements, we would love to hear from you. Sharing suggestions helps us shape the product around real student needs.',
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // Contact card with email
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF101214),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Contact UniDate support',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'If you can’t find what you’re looking for or need personal help with your account, you can email our support team any time. Be sure to include your university, the email you registered with, and as much detail as possible.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Email: Leosen.krish@gmail.com',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportBlock extends StatelessWidget {
  final String title;
  final String body;

  const _SupportBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

