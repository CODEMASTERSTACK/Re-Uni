import 'package:flutter/material.dart';
import '../learn_page.dart';
import '../safety_page.dart';
import '../support_page.dart';

/// Breakpoints for responsive layout: mobile < 600, tablet 600–900, desktop 900+.
const double _kMobileBreakpoint = 600;
const double _kTabletBreakpoint = 900;

/// Clipper that gives the menu a heart-inspired bottom (two lobes).
class _HeartBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double r = (w / 2) * 0.45;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w / 2, h), radius: Radius.circular(r), clockwise: true)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r), clockwise: true)
      ..lineTo(0, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Draws a heart shape (full or left/right half). Used for heart-split menu animation.
class _HeartShapePainter extends CustomPainter {
  final Color color;
  final bool leftHalf;
  final bool rightHalf;

  _HeartShapePainter({required this.color, this.leftHalf = false, this.rightHalf = false});

  static Path _heartPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w / 2, h * 0.22);
    path.cubicTo(w * 0.15, -h * 0.05, -w * 0.1, h * 0.35, w / 2, h * 0.9);
    path.cubicTo(w * 1.1, h * 0.35, w * 0.85, -h * 0.05, w / 2, h * 0.22);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _heartPath(size);
    if (leftHalf) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
      canvas.drawPath(path, Paint()..color = color);
      canvas.restore();
    } else if (rightHalf) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height));
      canvas.drawPath(path, Paint()..color = color);
      canvas.restore();
    } else {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated menu: heart appears → splits in two → menu drops down.
class _HeartSplitMenuContent extends StatefulWidget {
  final Widget menuPanel;
  final double topPadding;

  const _HeartSplitMenuContent({required this.menuPanel, required this.topPadding});

  @override
  State<_HeartSplitMenuContent> createState() => _HeartSplitMenuContentState();
}

class _HeartSplitMenuContentState extends State<_HeartSplitMenuContent>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1300);
  static const _heartSize = 72.0;
  static const _maxSplitOffset = 56.0;

  late final AnimationController _controller;
  late final Animation<double> _heartScale;
  late final Animation<double> _splitOffset;
  late final Animation<double> _menuSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _heartScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.28, curve: Curves.elasticOut),
      ),
    );
    _splitOffset = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.52, curve: Curves.easeInOutCubic),
      ),
    );
    _menuSlide = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final showFullHeart = _heartScale.value > 0.01 && _splitOffset.value < 0.05;
        final splitOffset = _splitOffset.value * _maxSplitOffset;
        final menuOffset = (1 - _menuSlide.value) * -100;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (showFullHeart)
              Positioned(
                left: 0,
                right: 0,
                top: widget.topPadding,
                child: Center(
                  child: ScaleTransition(
                    scale: _heartScale,
                    child: Icon(
                      Icons.favorite,
                      size: _heartSize,
                      color: const Color(0xFFFF4458),
                    ),
                  ),
                ),
              ),
            if (_splitOffset.value > 0.02)
              Positioned(
                left: 0,
                right: 0,
                top: widget.topPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(-splitOffset, 0),
                      child: SizedBox(
                        width: _heartSize,
                        height: _heartSize,
                        child: CustomPaint(
                          painter: _HeartShapePainter(color: const Color(0xFFFF4458), leftHalf: true),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(splitOffset, 0),
                      child: SizedBox(
                        width: _heartSize,
                        height: _heartSize,
                        child: CustomPaint(
                          painter: _HeartShapePainter(color: const Color(0xFFFF4458), rightHalf: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Transform.translate(
              offset: Offset(0, menuOffset),
              child: Opacity(
                opacity: _menuSlide.value.clamp(0.0, 1.0),
                child: widget.menuPanel,
              ),
            ),
          ],
        );
      },
    );
  }
}

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
      if (mounted) setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showTopMenu(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final topPadding = padding.top + 24;

    final menuPanel = Padding(
      padding: const EdgeInsets.only(top: 88),
      child: ClipPath(
        clipper: _HeartBottomClipper(),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2A1C22),
                const Color(0xFF1E1618),
                const Color(0xFF1A1C1E),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF4458).withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4458).withValues(alpha: 0.2),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: const Color(0xFFFF4458).withValues(alpha: 0.9), size: 18),
                    const SizedBox(width: 6),
                    Icon(Icons.favorite, color: const Color(0xFFFF4458), size: 26),
                    const SizedBox(width: 6),
                    Icon(Icons.favorite, color: const Color(0xFFFF4458).withValues(alpha: 0.9), size: 18),
                  ],
                ),
              ),
              Divider(color: const Color(0xFFFF4458).withValues(alpha: 0.25), height: 1, indent: 32, endIndent: 32),
              _NavItem(title: 'Learn', fontSize: 18),
              const SizedBox(height: 2),
              _NavItem(title: 'Safety', fontSize: 18),
              const SizedBox(height: 2),
              _NavItem(title: 'Support', fontSize: 18),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(color: Colors.transparent, child: child),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          bottom: false,
          child: _HeartSplitMenuContent(menuPanel: menuPanel, topPadding: topPadding),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final viewportHeight = size.height;
    final padding = MediaQuery.paddingOf(context);
    final isMobile = width < _kMobileBreakpoint;
    final isTablet = width >= _kMobileBreakpoint && width < _kTabletBreakpoint;

    final double heroHeight = viewportHeight;
    final double navBarFadeEnd = viewportHeight * 0.35;
    final double navBarOpacity = _scrollOffset <= 0
        ? 1.0
        : (1.0 - (_scrollOffset / navBarFadeEnd).clamp(0.0, 1.0)).toDouble();

    // Responsive horizontal padding
    final heroPaddingH = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final sectionPaddingH = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final heroTitleSize = isMobile ? 36.0 : (isTablet ? 42.0 : 72.0);
    final heroTaglineSize = isMobile ? 15.0 : 14.0;
    final heroButtonWidth = isMobile ? (width - heroPaddingH * 2).clamp(240.0, 500.0) : 230.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Single scrollable column: hero first, then stories and footer, so the page scrolls.
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                SizedBox(
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
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40.0 + padding.top, left: heroPaddingH, right: heroPaddingH),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Find your lovely one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: heroTitleSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.0,
                                ),
                              ),
                              SizedBox(height: isMobile ? 20 : 32),
                              SizedBox(
                                width: heroButtonWidth,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF4458),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 18, horizontal: isMobile ? 24 : 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                      side: BorderSide.none,
                                    ),
                                    elevation: 0,
                                    textStyle: TextStyle(
                                      fontSize: isMobile ? 18 : 20,
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.favorite, color: Colors.white, size: isMobile ? 22 : 22),
                                      SizedBox(width: isMobile ? 8 : 8),
                                      const Text('Create account', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              Text(
                                'Meet new people, make friends, maybe find a date.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: heroTaglineSize),
                              ),
                              SizedBox(height: isMobile ? 24 : 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFF111316),
                  padding: EdgeInsets.symmetric(horizontal: sectionPaddingH, vertical: isMobile ? 24 : 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UniDate stories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Real connections, real friendships, real campus love.',
                        style: TextStyle(color: Colors.white70, fontSize: isMobile ? 12 : 14),
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < _kTabletBreakpoint;
                          final storyRowHeight = constraints.maxWidth >= _kTabletBreakpoint
                              ? (constraints.maxWidth >= 1200 ? 520.0 : 420.0)
                              : null;
                          if (isNarrow) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _StoryCard(
                                  imagePath: 'assets/images/image1.jpg',
                                  title: 'From classmates to soulmates',
                                  body: 'They sat two rows apart in lectures but never spoke. Unidate matched them over a shared love for late-night coffee and campus fests. Now they never miss a class—or a date.',
                                ),
                                const SizedBox(height: 16),
                                _StoryCard(
                                  imagePath: 'assets/images/image2.jpg',
                                  title: 'Finding your people',
                                  body: 'Not everyone is searching for "the one". Some just want a study buddy, gym partner, or someone to grab chai with after labs. Unidate made their friend circle feel a little less lonely.',
                                ),
                                const SizedBox(height: 16),
                                _StoryCard(
                                  imagePath: 'assets/images/image3.jpg',
                                  title: 'New campus, new connections',
                                  body: 'First year on a new campus can be scary. Swiping on Unidate helped them discover people from their hostel, clubs, and classes—turning awkward hellos into real friendships.',
                                ),
                              ],
                            );
                          }
                          final flexChild = Flex(
                            direction: Axis.horizontal,
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _StoryCard(
                                  imagePath: 'assets/images/image1.jpg',
                                  title: 'From classmates to soulmates',
                                  body: 'They sat two rows apart in lectures but never spoke. Unidate matched them over a shared love for late-night coffee and campus fests. Now they never miss a class—or a date.',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StoryCard(
                                  imagePath: 'assets/images/image2.jpg',
                                  title: 'Finding your people',
                                  body: 'Not everyone is searching for "the one". Some just want a study buddy, gym partner, or someone to grab chai with after labs. Unidate made their friend circle feel a little less lonely.',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StoryCard(
                                  imagePath: 'assets/images/image3.jpg',
                                  title: 'New campus, new connections',
                                  body: 'First year on a new campus can be scary. Swiping on Unidate helped them discover people from their hostel, clubs, and classes—turning awkward hellos into real friendships.',
                                ),
                              ),
                            ],
                          );
                          return SizedBox(height: storyRowHeight ?? 420, child: flexChild);
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFF0B0C0D),
                  padding: EdgeInsets.symmetric(horizontal: sectionPaddingH, vertical: isMobile ? 28 : 42),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white24),
                      SizedBox(height: isMobile ? 16 : 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < _kTabletBreakpoint;
                          if (isNarrow) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FooterColumn(title: 'Legal', items: const ['Privacy', 'Terms', 'Cookie Policy', 'Accessibility']),
                                SizedBox(height: isMobile ? 20 : 24),
                                _FooterColumn(title: 'Campus life', items: const ['Clubs & events', 'Dating safety tips', 'Community guidelines']),
                                SizedBox(height: isMobile ? 20 : 24),
                                _FooterColumn(title: 'Social', items: const ['Instagram', 'TikTok', 'YouTube', 'Twitter']),
                                SizedBox(height: isMobile ? 20 : 24),
                                _FooterColumn(title: 'More', items: const ['FAQ', 'Contact', 'Safety resources']),
                              ],
                            );
                          }
                          return SizedBox(
                            height: isMobile ? 160 : 200,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _FooterColumn(title: 'Legal', items: const ['Privacy', 'Terms', 'Cookie Policy', 'Accessibility'])),
                                const SizedBox(width: 40),
                                Expanded(child: _FooterColumn(title: 'Campus life', items: const ['Clubs & events', 'Dating safety tips', 'Community guidelines'])),
                                const SizedBox(width: 40),
                                Expanded(child: _FooterColumn(title: 'Social', items: const ['Instagram', 'TikTok', 'YouTube', 'Twitter'])),
                                const SizedBox(width: 40),
                                Expanded(child: _FooterColumn(title: 'More', items: const ['FAQ', 'Contact', 'Safety resources'])),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      Text(
                        'Unidate is where university students meet new people, build friendships, and maybe even find someone special—on their own campus.',
                        style: TextStyle(color: Colors.white70, fontSize: isMobile ? 14 : 16, height: 1.5),
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        '© 2026 Unidate. All rights reserved.',
                        style: TextStyle(color: Colors.white54, fontSize: isMobile ? 12 : 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nav bar overlay: fixed at top, fades out as user scrolls down. Responsive padding and sizes.
          IgnorePointer(
            ignoring: navBarOpacity < 0.1,
            child: AnimatedOpacity(
              opacity: navBarOpacity,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: padding.top + (isMobile ? 12 : 20),
                  bottom: isMobile ? 12 : 20,
                  left: sectionPaddingH + padding.left,
                  right: sectionPaddingH + padding.right,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/unidate_logo.png',
                          height: isMobile ? 36 : (isTablet ? 48 : 60),
                        ),
                        SizedBox(width: isMobile ? 4 : 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'UniDate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 20 : (isTablet ? 26 : 30),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isMobile)
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () => _showTopMenu(context),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _NavItem(title: 'Learn', fontSize: isTablet ? 18 : 24),
                          SizedBox(width: isTablet ? 16 : 24),
                          _NavItem(title: 'Safety', fontSize: isTablet ? 18 : 24),
                          SizedBox(width: isTablet ? 16 : 24),
                          _NavItem(title: 'Support', fontSize: isTablet ? 18 : 24),
                        ],
                      ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 26,
                          vertical: isMobile ? 8 : 10,
                        ),
                      ),
                      onPressed: () {
                        if (widget.onSignIn != null) {
                          widget.onSignIn!();
                        } else {
                          Navigator.of(context).pushNamed('/sign-in');
                        }
                      },
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final double fontSize;
  const _NavItem({required this.title, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).maybePop(); // close bottom sheet if open
        if (title == 'Learn') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LearnPage()));
        } else if (title == 'Safety') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SafetyPage()));
        } else if (title == 'Support') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportPage()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ),
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
          final isNarrow = constraints.maxWidth < 400; // card layout: column when card is narrow
          final isMobileCard = constraints.maxWidth < _kMobileBreakpoint; // smaller padding when viewport is mobile
          if (isNarrow) {
            final cardPadding = isMobileCard ? 16.0 : 20.0;
            final imageHeight = isMobileCard ? 220.0 : 280.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: _StoryText(title: title, body: body),
                ),
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset(imagePath),
                  ),
                ),
              ],
            );
          }
          final storyCardHeight = constraints.maxWidth >= 1200 ? 520.0 : 420.0;
          return SizedBox(
            height: storyCardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _StoryText(title: title, body: body),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                    child: Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Image.asset(imagePath),
                        ),
                      ),
                    ),
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
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < _kMobileBreakpoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Text(
          body,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isMobile ? 12 : 13,
            height: 1.5,
          ),
        ),
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
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < _kMobileBreakpoint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              item,
              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 12 : 14),
            ),
          ),
      ],
    );
  }
}
