import 'package:flutter/material.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

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
                'Safety first, always.',
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
                  'Meeting new people should feel exciting, not stressful. UniDate is designed with student life in mind, combining product features, education and community guidelines so you can stay in control of every interaction—on campus, online and everywhere in between.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Safety content in two-column grid similar to Tinder
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
                        child: const _SafetyBlock(
                          title: 'Before you meet',
                          body:
                              'Take time to read profiles carefully and chat inside the app before you share any personal contact details. Look out for inconsistent information, requests for money, or attempts to move you quickly to private messaging apps. Trust your instincts—if something feels off, you are never obligated to keep talking.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SafetyBlock(
                          title: 'Protect your privacy',
                          body:
                              'Avoid sharing your full name, student ID, phone number, address or class schedule in your bio or early conversations. Do not share passwords, one‑time codes or banking information with anyone. Only send photos you would be comfortable seeing beyond your immediate circle—screenshots and forwards are always possible.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SafetyBlock(
                          title: 'Meeting on campus',
                          body:
                              'When you decide to meet in person, choose a public, well‑lit location on or near campus—cafeterias, libraries, student centers or busy cafés. Tell a friend where you are going, share your live location with someone you trust, and keep control of your own transportation and belongings so you can leave whenever you choose.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SafetyBlock(
                          title: 'Consent and respect',
                          body:
                              'Consent must always be clear, enthusiastic and ongoing. A “yes” to one thing does not mean “yes” to everything, and silence or uncertainty is never consent. You can change your mind at any time. If someone dismisses your boundaries, pressures you or minimises your feelings, step away from the situation and consider blocking and reporting them.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SafetyBlock(
                          title: 'Blocking & reporting',
                          body:
                              'If a match makes you uncomfortable, you can unmatch or block them at any time—no explanation required. Please report profiles that appear fake, share non‑consensual images, use hate speech, threaten harm or repeatedly ignore your boundaries. Our team reviews reports, and serious or repeated violations can result in warnings, temporary suspensions or permanent bans.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SafetyBlock(
                          title: 'Need help right now?',
                          body:
                              'If you ever feel in immediate danger, contact local emergency services or campus security first. For concerns related to a conversation or interaction on UniDate, email us at Leosen.krish@gmail.com with screenshots, dates and a short description of what happened. Our team prioritises safety‑related reports and will review and respond as quickly as possible.',
                        ),
                      ),
                      SizedBox(
                        width: columnWidth,
                        child: const _SafetyBlock(
                          title: 'Community expectations',
                          body:
                              'UniDate is for real students looking to build genuine friendships, connections and relationships. We do not tolerate hate speech, discrimination, bullying, threats or any form of harassment. By using UniDate you agree to treat others with respect, follow campus policies and abide by our community guidelines.',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyBlock extends StatelessWidget {
  final String title;
  final String body;

  const _SafetyBlock({required this.title, required this.body});

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

