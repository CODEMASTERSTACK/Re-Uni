import 'package:flutter/material.dart';
import '../learn_page.dart';
import '../safety_page.dart';
import '../support_page.dart';

class LandingPage extends StatefulWidget {
  /// When set (e.g. on web redirect flow), use these instead of Navigator.
  final VoidCallback? onSignUp;
  final VoidCallback? onSignIn;

  const LandingPage({super.key, this.onSignUp, this.onSignIn});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double viewportHeight = MediaQuery.of(context).size.height;
    final double heroHeight = viewportHeight;
    final double heroOpacity =
        1.0 - (_scrollOffset / (viewportHeight * 0.4)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scroll view first (bottom layer) so content scrolls under the hero.
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                SizedBox(height: heroHeight),
                Container(
                  color: const Color(0xFF111316),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UniDate stories',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Real connections, real friendships, real campus love.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 900;
                          // Constrain height so Flex with spaceBetween + Expanded doesn't get unbounded (avoids box.dart assertion).
                          const storyRowHeight = 300.0;
                          final flexChild = Flex(
                            direction: isNarrow ? Axis.vertical : Axis.horizontal,
                            mainAxisSize: isNarrow ? MainAxisSize.min : MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _StoryCard(
                                  imagePath: 'assets/images/image1.jpg',
                                  title: 'From classmates to soulmates',
                                  body: 'They sat two rows apart in lectures but never spoke. Unidate matched them over a shared love for late-night coffee and campus fests. Now they never miss a class—or a date.',
                                ),
                              ),
                              SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 16 : 0),
                              Expanded(
                                child: _StoryCard(
                                  imagePath: 'assets/images/image2.jpg',
                                  title: 'Finding your people',
                                  body: 'Not everyone is searching for "the one". Some just want a study buddy, gym partner, or someone to grab chai with after labs. Unidate made their friend circle feel a little less lonely.',
                                ),
                              ),
                              SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 16 : 0),
                              Expanded(
                                child: _StoryCard(
                                  imagePath: 'assets/images/image3.jpg',
                                  title: 'New campus, new connections',
                                  body: 'First year on a new campus can be scary. Swiping on Unidate helped them discover people from their hostel, clubs, and classes—turning awkward hellos into real friendships.',
                                ),
                              ),
                            ],
                          );
                          return isNarrow ? flexChild : SizedBox(height: storyRowHeight, child: flexChild);
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFF0B0C0D),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 800;
                          final flexChild = Flex(
                            direction: isNarrow ? Axis.vertical : Axis.horizontal,
                            mainAxisSize: isNarrow ? MainAxisSize.min : MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FooterColumn(title: 'Legal', items: const ['Privacy', 'Terms', 'Cookie Policy', 'Accessibility']),
                              SizedBox(width: isNarrow ? 0 : 40, height: isNarrow ? 24 : 0),
                              _FooterColumn(title: 'Campus life', items: const ['Clubs & events', 'Dating safety tips', 'Community guidelines']),
                              SizedBox(width: isNarrow ? 0 : 40, height: isNarrow ? 24 : 0),
                              _FooterColumn(title: 'Social', items: const ['Instagram', 'TikTok', 'YouTube', 'Twitter']),
                              SizedBox(width: isNarrow ? 0 : 40, height: isNarrow ? 24 : 0),
                              _FooterColumn(title: 'More', items: const ['FAQ', 'Contact', 'Safety resources']),
                            ],
                          );
                          // Give horizontal row a bounded height to avoid unbounded cross-axis (box.dart assertion).
                          return isNarrow ? flexChild : SizedBox(height: 200, child: flexChild);
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Unidate is where university students meet new people, build friendships, and maybe even find someone special—on their own campus.',
                        style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      const Text('© 2026 Unidate. All rights reserved.', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Hero on top so "Create account" button receives taps; non-button area uses IgnorePointer so scroll passes through.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/unidate_bg.png',
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(230, 0, 0, 0),
                        Color.fromARGB(180, 0, 0, 0),
                        Color.fromARGB(180, 0, 0, 0),
                      ],
                    ),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: heroOpacity,
                    duration: const Duration(milliseconds: 150),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Find your special one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 95,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.0,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const SizedBox(height: 56, width: 230),
                            const SizedBox(height: 16),
                            const Text(
                              'Meet new people, make friends, maybe find a date.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: heroOpacity,
                  duration: const Duration(milliseconds: 150),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IgnorePointer(
                            child: const Text(
                              'Find your special one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 95,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 230,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4458),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () {
                                if (widget.onSignUp != null) {
                                  widget.onSignUp!();
                                } else {
                                  Navigator.of(context).pushNamed('/sign-up');
                                }
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.favorite, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text('Create account', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          IgnorePointer(
                            child: const Text(
                              'Meet new people, make friends, maybe find a date.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/unidate_logo.png', height: 60),
                    const SizedBox(width: 2),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('UniDate', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: 0.0)),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    _NavItem(title: 'Learn'),
                    SizedBox(width: 24),
                    _NavItem(title: 'Safety'),
                    SizedBox(width: 24),
                    _NavItem(title: 'Support'),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                  ),
                  onPressed: () {
                    if (widget.onSignIn != null) {
                      widget.onSignIn!();
                    } else {
                      Navigator.of(context).pushNamed('/sign-in');
                    }
                  },
                  child: const Text('Log in', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  const _NavItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (title == 'Learn') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LearnPage()));
        } else if (title == 'Safety') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SafetyPage()));
        } else if (title == 'Support') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportPage()));
        }
      },
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String body;
  const _StoryCard({required this.imagePath, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17191C),
        borderRadius: BorderRadius.circular(8),
        border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 400;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.all(20.0), child: _StoryText(title: title, body: body)),
                Image.asset(imagePath, fit: BoxFit.contain),
              ],
            );
          }
          return SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(24.0), child: _StoryText(title: title, body: body))),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                    child: Container(color: Colors.black, alignment: Alignment.center, child: Image.asset(imagePath, fit: BoxFit.contain)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StoryText extends StatelessWidget {
  final String title;
  final String body;
  const _StoryText({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  const _FooterColumn({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ),
        ],
      ),
    );
  }
}
