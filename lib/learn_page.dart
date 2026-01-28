import 'package:flutter/material.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

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
              // Top bar similar to Tinder Learn header
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

              // Hero heading + paragraph (larger)
              const Text(
                'Why choose a dating/friendship app like UniDate?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 860,
                child: Text(
                  'Unidate is a space where every identity is celebrated. Our diverse range of orientation and gender identity options ensures that you can show up as your true self and find exactly who you’re looking for without compromise. ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 220,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () {
                    // Placeholder CTA similar to "Join Now"
                  },
                  child: const Text(
                    'Join Now',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 56),

              // Pinterest-style simple card layout (all learn cards, unique images)
              LayoutBuilder(
                builder: (context, constraints) {
                  final imagePaths = [
                    'assets/images/count.jpg',
                    'assets/images/posibilities.jpg',
                    'assets/images/vibes.jpg',
                    'assets/images/purpose.jpg',
                    'assets/images/bigheart.jpg',
                    'assets/images/matched.jpg',
                  ];

                  // All learn card contents
                  final cards = [
                    (
                      'Explore your passions',
                      'Your time at university is about more than just lectures; it’s about finding the people who make your downtime legendary. Use this space to discover students who share your specific hobbies, from late-night gaming sessions and indie film marathons to obscure campus societies and intramural sports. By highlighting your passions, you move past the small talk and dive straight into connections based on what you actually love to do.'
                    ),
                    (
                      'Endless possibilities',
                      'Whether you are looking for a casual coffee hang between seminars, a consistent gym buddy, or something more serious that lasts beyond graduation, Unidate is built to facilitate every type of connection. The student experience is diverse, and your dating life should be too. We provide the platform for you to define your own journey, offering the flexibility to meet new people on your own terms and at your own pace.'
                    ),
                    (
                      'See who vibes with you',
                      'Connections are built on more than just a single photo. Dive deep into detailed student profiles where personality takes center stage. By utilizing our "Likes" and "Matches" system, you can filter through the noise to find people who truly resonate with your outlook on life. This section explains how our intuitive interface helps you identify common ground and mutual interests, ensuring that every match has the potential for a real spark.'
                    ),
                    (
                      'Make every connection count',
                      'In a massive campus environment, it’s easy to feel like just another face in the crowd. Unidate focuses on high-quality interactions that translate into real-world friendships, productive study groups, and meaningful romantic relationships. We believe every swipe should be intentional. By prioritizing authentic engagement over mindless scrolling, we help you build a supportive network of peers that enriches your entire university experience and social life.'
                    ),
                    (
                      'Stay safe while you swipe',
                      'Your safety is our absolute priority, especially within the campus ecosystem. This section provides essential tips on maintaining digital privacy, understanding the importance of enthusiastic consent, and utilizing our in-app safety features. We look out for our students by providing tools to report suspicious behavior and offering reminders to meet in well-lit, public campus spots. Stay informed and empowered so you can focus on making connections with total peace of mind.'
                    ),
                    (
                      'Match your campus energy',
                      'Every university has its own unique "vibe"—from the high-energy atmosphere of game days to the quiet intensity of finals week. Unidate is designed to sync with your specific campus culture and local events. Stay updated on university-wide mixers, society meetups, and local student-only gatherings. This is your portal to everything happening in your immediate community, ensuring you never miss a beat or a chance to meet someone special nearby.'
                    ),
                  ];

                  double maxWidth = constraints.maxWidth;
                  double cardWidth;
                  if (maxWidth >= 1100) {
                    cardWidth = (maxWidth - 2 * 24) / 3; // 3 columns
                  } else if (maxWidth >= 750) {
                    cardWidth = (maxWidth - 24) / 2; // 2 columns
                  } else {
                    cardWidth = maxWidth; // 1 column
                  }

                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      for (int i = 0; i < cards.length && i < imagePaths.length; i++)
                        _LearnCard(
                          width: cardWidth,
                          title: cards[i].$1,
                          body: cards[i].$2,
                          // Each card gets a unique image, no repeats
                          imagePath: imagePaths[i],
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 56),
              // Bottom CTA similar to "Get Started"
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () {
                    // Placeholder
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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

class _LearnCard extends StatelessWidget {
  final double width;
  final String title;
  final String body;
  final String imagePath;

  const _LearnCard({
    required this.width,
    required this.title,
    required this.body,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
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
      ),
    );
  }
}

