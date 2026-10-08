// College Kundli marketing site (collegekundli.com).
//
// A standalone Flutter Web entrypoint, kept separate from lib/main.dart (the
// full app, which boots Firebase, the router, ads, etc.). Build it with:
//
//   flutter build web -t lib/main_landing.dart --release
//
// Sections: navbar, hero, stats, features, download CTA, footer. Responsive
// at three breakpoints (mobile < 640, tablet < 1024, desktop).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CollegeKundliSite());
  // web/index.html is shared with the full app and shows its splash until
  // the Dart side removes it.
  FlutterNativeSplash.remove();
}

// ---------------------------------------------------------------------------
// Brand tokens
// ---------------------------------------------------------------------------

abstract final class Brand {
  static const indigo = Color(0xFF4F46E5);
  static const indigoDark = Color(0xFF3730A3);
  static const teal = Color(0xFF06B6D4);
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const body = Color(0xFF475569);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const footer = Color(0xFF0B1120);

  static const gradient = LinearGradient(
    colors: [indigo, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const maxContentWidth = 1200.0;
}

abstract final class Links {
  static const playStore =
      'https://play.google.com/store/apps/details?id=com.collegereality.india';
  static const privacyPolicy = 'https://collegekundli.com/privacy-policy';
  static const terms = 'https://collegekundli.com/terms';
  static const contact = 'https://collegekundli.com/contact';
}

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
    debugPrint('Could not open $url');
  }
}

// ---------------------------------------------------------------------------
// Responsive helpers
// ---------------------------------------------------------------------------

enum ScreenSize { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < 640) return ScreenSize.mobile;
    if (width < 1024) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isDesktop => screenSize == ScreenSize.desktop;

  double get gutter => switch (screenSize) {
        ScreenSize.mobile => 20,
        ScreenSize.tablet => 32,
        ScreenSize.desktop => 48,
      };
}

/// Centers content at [Brand.maxContentWidth] with responsive side gutters.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.vertical = 0});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.gutter,
        vertical: vertical,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Brand.maxContentWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Lays [children] out in a grid with [columns] equal-width columns.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.columns,
    required this.children,
    this.spacing = 24,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = 0; j < columns; j++) {
        if (j > 0) rowChildren.add(SizedBox(width: spacing));
        final index = i + j;
        rowChildren.add(
          Expanded(
            child: index < children.length
                ? children[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowChildren,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

class CollegeKundliSite extends StatelessWidget {
  const CollegeKundliSite({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: Brand.ink,
      displayColor: Brand.ink,
    );
    return MaterialApp(
      title: 'College Kundli: Make smart college choices',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Brand.indigo,
          primary: Brand.indigo,
          secondary: Brand.teal,
          surface: Brand.surface,
        ),
        scaffoldBackgroundColor: Brand.background,
        textTheme: textTheme,
      ),
      home: const LandingPage(),
    );
  }
}

enum Section { features, stats, about }

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _sectionKeys = {for (final s in Section.values) s: GlobalKey()};
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 8;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(Section section) {
    _scaffoldKey.currentState?.closeEndDrawer();
    final target = _sectionKeys[section]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _MobileNavDrawer(onNavigate: _scrollTo),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: NavBar.height),
                HeroSection(onExplore: () => _scrollTo(Section.features)),
                StatsSection(key: _sectionKeys[Section.stats]),
                FeaturesSection(key: _sectionKeys[Section.features]),
                DownloadCtaBanner(key: _sectionKeys[Section.about]),
                const SiteFooter(),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NavBar(
              elevated: _scrolled,
              onNavigate: _scrollTo,
              onOpenMenu: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: Brand.gradient,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: Brand.indigo.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          'College Kundli',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: light ? Colors.white : Brand.ink,
          ),
        ),
      ],
    );
  }
}

enum ButtonVariant { primary, secondary, light }

/// Pill button with a subtle lift on hover.
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.variant = ButtonVariant.primary,
    this.large = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? leading;
  final ButtonVariant variant;
  final bool large;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (widget.variant) {
      ButtonVariant.primary => (Brand.indigo, Colors.white, Brand.indigo),
      ButtonVariant.secondary => (Brand.surface, Brand.ink, Brand.border),
      ButtonVariant.light => (Colors.white, Brand.indigo, Colors.white),
    };
    final padding = widget.large
        ? const EdgeInsets.symmetric(horizontal: 28, vertical: 18)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          padding: padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
            boxShadow: [
              if (widget.variant != ButtonVariant.secondary || _hovered)
                BoxShadow(
                  color: (widget.variant == ButtonVariant.primary
                          ? Brand.indigo
                          : Brand.ink)
                      .withValues(alpha: _hovered ? 0.28 : 0.16),
                  blurRadius: _hovered ? 22 : 14,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: widget.large ? 16 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Google Play-style triangle mark, drawn so we don't ship a brand asset.
class PlayStoreIcon extends StatelessWidget {
  const PlayStoreIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _PlayTrianglePainter());
}

class _PlayTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final center = Offset(w * 0.62, h / 2);
    void wedge(List<Offset> points, Color color) {
      canvas.drawPath(
        Path()..addPolygon(points, true),
        Paint()..color = color,
      );
    }

    final topLeft = Offset(w * 0.1, 0);
    final bottomLeft = Offset(w * 0.1, h);
    final tip = Offset(w, h / 2);
    wedge([topLeft, center, Offset(w * 0.1, h / 2)], const Color(0xFF00D7FE));
    wedge([Offset(w * 0.1, h / 2), center, bottomLeft], const Color(0xFF00F076));
    wedge([topLeft, tip, center], const Color(0xFF32BBFF));
    wedge([center, tip, bottomLeft], const Color(0xFFFF3A44));
    wedge([center, Offset(w * 0.83, h * 0.4), tip, Offset(w * 0.83, h * 0.6)],
        const Color(0xFFFFD500));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final mobile = context.isMobile;
    return Column(
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: Brand.indigo,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: mobile ? 28 : 38,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.6,
            color: Brand.ink,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, height: 1.6, color: Brand.body),
          ),
        ),
      ],
    );
  }
}

/// White card that lifts and gains a tinted border on hover.
class HoverCard extends StatefulWidget {
  const HoverCard({super.key, required this.child, this.padding = 28});

  final Widget child;
  final double padding;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
        padding: EdgeInsets.all(widget.padding),
        decoration: BoxDecoration(
          color: Brand.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered ? Brand.indigo.withValues(alpha: 0.35) : Brand.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Brand.ink.withValues(alpha: _hovered ? 0.08 : 0.03),
              blurRadius: _hovered ? 32 : 12,
              offset: Offset(0, _hovered ? 16 : 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class GradientIconTile extends StatelessWidget {
  const GradientIconTile({super.key, required this.icon, this.size = 52});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: Brand.gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

extension _Reveal on Widget {
  /// Fade-and-rise entrance, staggered by [index].
  Widget reveal([int index = 0]) => animate()
      .fadeIn(duration: 500.ms, delay: (80 * index).ms)
      .slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOut);
}

// ---------------------------------------------------------------------------
// Navbar
// ---------------------------------------------------------------------------

class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    required this.elevated,
    required this.onNavigate,
    required this.onOpenMenu,
  });

  static const height = 76.0;

  final bool elevated;
  final ValueChanged<Section> onNavigate;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final desktop = context.screenSize != ScreenSize.mobile;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      decoration: BoxDecoration(
        color: Brand.background.withValues(alpha: elevated ? 1 : 0),
        border: Border(
          bottom: BorderSide(
            color: elevated ? Brand.border : Colors.transparent,
          ),
        ),
        boxShadow: [
          if (elevated)
            BoxShadow(
              color: Brand.ink.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ContentWidth(
        child: Row(
          children: [
            const BrandLogo(),
            const Spacer(),
            if (desktop) ...[
              for (final section in Section.values)
                _NavLink(
                  label: _labelFor(section),
                  onTap: () => onNavigate(section),
                ),
              const SizedBox(width: 16),
              PillButton(
                label: 'Get App',
                leading: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => openUrl(Links.playStore),
              ),
            ] else
              IconButton(
                tooltip: 'Menu',
                onPressed: onOpenMenu,
                icon: const Icon(Icons.menu_rounded, color: Brand.ink),
              ),
          ],
        ),
      ),
    );
  }
}

String _labelFor(Section section) => switch (section) {
      Section.features => 'Features',
      Section.stats => 'Stats',
      Section.about => 'About',
    };

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              fontFamily: GoogleFonts.inter().fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _hovered ? Brand.indigo : Brand.body,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _MobileNavDrawer extends StatelessWidget {
  const _MobileNavDrawer({required this.onNavigate});

  final ValueChanged<Section> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Brand.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(),
              const SizedBox(height: 32),
              for (final section in Section.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _labelFor(section),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onNavigate(section),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: 'Get App',
                  large: true,
                  leading: const PlayStoreIcon(),
                  onPressed: () => openUrl(Links.playStore),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final desktop = context.isDesktop;
    final copy = _HeroCopy(onExplore: onExplore, centered: !desktop);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Soft brand glows behind the hero.
        Positioned(
          top: -160,
          right: -120,
          child: _Glow(color: Brand.teal.withValues(alpha: 0.18), size: 520),
        ),
        Positioned(
          top: 120,
          left: -200,
          child: _Glow(color: Brand.indigo.withValues(alpha: 0.12), size: 480),
        ),
        ContentWidth(
          vertical: desktop ? 88 : 56,
          child: desktop
              ? Row(
                  children: [
                    Expanded(flex: 11, child: copy),
                    const SizedBox(width: 56),
                    const Expanded(flex: 9, child: AppPreviewMockup()),
                  ],
                )
              : Column(
                  children: [
                    copy,
                    const SizedBox(height: 56),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: const AppPreviewMockup(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onExplore, required this.centered});

  final VoidCallback onExplore;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final mobile = context.isMobile;
    final align = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Brand.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Brand.indigo.withValues(alpha: 0.2)),
          ),
          child: Text(
            '⚡ Discover 45,000+ Verified Colleges Across India',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Brand.indigoDark,
              fontWeight: FontWeight.w600,
              fontSize: mobile ? 12.5 : 14,
            ),
          ),
        ).reveal(0),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Brand.ink, Brand.indigoDark],
          ).createShader(bounds),
          child: Text(
            'Make Smart College Choices With Authentic Insights',
            textAlign: align,
            style: GoogleFonts.poppins(
              fontSize: switch (context.screenSize) {
                ScreenSize.mobile => 36,
                ScreenSize.tablet => 48,
                ScreenSize.desktop => 58,
              },
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1.2,
              color: Colors.white,
            ),
          ),
        ).reveal(1),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Read genuine reviews from verified students, predict your '
            'admission chances with real cutoff data, and get 1-on-1 video or '
            'audio guidance from experts who have been there.',
            textAlign: align,
            style: TextStyle(
              fontSize: mobile ? 16 : 18,
              height: 1.65,
              color: Brand.body,
            ),
          ),
        ).reveal(2),
        const SizedBox(height: 36),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: [
            PillButton(
              label: 'Download Android App',
              large: true,
              leading: const PlayStoreIcon(),
              onPressed: () => openUrl(Links.playStore),
            ),
            PillButton(
              label: 'Explore Colleges',
              large: true,
              variant: ButtonVariant.secondary,
              leading: const Icon(
                Icons.explore_outlined,
                color: Brand.ink,
                size: 20,
              ),
              onPressed: onExplore,
            ),
          ],
        ).reveal(3),
        const SizedBox(height: 32),
        Wrap(
          spacing: 22,
          runSpacing: 10,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: const [
            _TrustPoint('Free to download'),
            _TrustPoint('Verified students only'),
            _TrustPoint('No spam calls'),
          ],
        ).reveal(4),
      ],
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: Brand.teal, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Brand.body,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Stylised preview of the app built from widgets (no screenshots needed).
class AppPreviewMockup extends StatelessWidget {
  const AppPreviewMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Brand.border),
        boxShadow: [
          BoxShadow(
            color: Brand.indigo.withValues(alpha: 0.14),
            blurRadius: 60,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // College card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: Brand.gradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFDE68A), size: 18),
                    const SizedBox(width: 4),
                    const Text(
                      '4.6',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Government College of Engineering',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pune, Maharashtra · B.Tech',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Cutoff prediction
          _MockTile(
            icon: Icons.insights_rounded,
            title: 'Your admission chance',
            subtitle: 'Based on last 3 years of cutoffs',
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '82%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Brand.indigo,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      value: 0.82,
                      minHeight: 6,
                      backgroundColor: Brand.border,
                      color: Brand.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Consultation call
          _MockTile(
            icon: Icons.videocam_rounded,
            title: 'Talk to a senior student',
            subtitle: 'Online now · Computer Engg, 3rd year',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Brand.indigo,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Call',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms, delay: 250.ms)
        .slideY(begin: 0.06, end: 0, duration: 700.ms, curve: Curves.easeOut);
  }
}

class _MockTile extends StatelessWidget {
  const _MockTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        children: [
          GradientIconTile(icon: icon, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Brand.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

class _Stat {
  const _Stat(this.icon, this.value, this.label, this.caption);

  final IconData icon;
  final String value;
  final String label;
  final String caption;
}

const _stats = [
  _Stat(Icons.account_balance_rounded, '45,000+', 'Colleges & Institutes',
      'Every state, every stream'),
  _Stat(Icons.verified_user_rounded, '100%', 'Verified Reviews',
      'Written by ID-checked students'),
  _Stat(Icons.headset_mic_rounded, '1-on-1', 'Consultation Calls',
      'HD video & audio, powered by Agora'),
  _Stat(Icons.bolt_rounded, 'Instant', 'Cutoff Predictions',
      'From your rank in seconds'),
];

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = switch (context.screenSize) {
      ScreenSize.mobile => 1,
      ScreenSize.tablet => 2,
      ScreenSize.desktop => 4,
    };
    return ContentWidth(
      vertical: 48,
      child: ResponsiveGrid(
        columns: columns,
        spacing: 20,
        children: [
          for (final (i, stat) in _stats.indexed)
            HoverCard(
              padding: 24,
              child: Row(
                children: [
                  GradientIconTile(icon: stat.icon, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat.value,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: Brand.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stat.caption,
                          style: const TextStyle(
                            color: Brand.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).reveal(i),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Features
// ---------------------------------------------------------------------------

class _Feature {
  const _Feature(this.icon, this.title, this.description, this.points);

  final IconData icon;
  final String title;
  final String description;
  final List<String> points;
}

const _features = [
  _Feature(
    Icons.query_stats_rounded,
    'Cutoff Data & Ranking Analysis',
    'Enter your rank or score and instantly see which colleges you can '
        'realistically get into, backed by year-on-year cutoff trends.',
    ['Category-wise cutoffs', 'Multi-year trend charts', 'Rank-based predictor'],
  ),
  _Feature(
    Icons.video_call_rounded,
    'Real-time Expert Guidance',
    'Book in-app video or audio calls with verified seniors and counsellors. '
        'Ask anything about admissions, hostels, placements and campus life.',
    ['In-app video & audio calls', 'Verified student guides', 'Free trial minutes'],
  ),
  _Feature(
    Icons.rate_review_rounded,
    'Authentic Student Reviews',
    'Every review comes from a student whose enrolment we have verified, so '
        'you get the real picture, not marketing brochures.',
    ['ID-verified reviewers', 'Placements & fees insights', 'Campus photos'],
  ),
];

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = context.isDesktop ? 3 : 1;
    return ContentWidth(
      vertical: context.isMobile ? 64 : 96,
      child: Column(
        children: [
          const SectionHeading(
            eyebrow: 'Features',
            title: 'Everything you need to choose right',
            subtitle: 'Data, real voices and expert help, all in one app '
                'built for Indian students and parents.',
          ).reveal(),
          const SizedBox(height: 56),
          ResponsiveGrid(
            columns: columns,
            children: [
              for (final (i, feature) in _features.indexed)
                _FeatureCard(feature: feature).reveal(i),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      padding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconTile(icon: feature.icon, size: 56),
          const SizedBox(height: 24),
          Text(
            feature.title,
            style: GoogleFonts.poppins(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            feature.description,
            style: const TextStyle(fontSize: 15, height: 1.65, color: Brand.body),
          ),
          const SizedBox(height: 20),
          for (final point in feature.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Brand.teal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 14, color: Brand.teal),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA banner
// ---------------------------------------------------------------------------

class DownloadCtaBanner extends StatelessWidget {
  const DownloadCtaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = context.isMobile;
    return ContentWidth(
      vertical: 24,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 24 : 56,
          vertical: mobile ? 40 : 64,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Brand.indigoDark, Brand.indigo, Brand.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Brand.indigo.withValues(alpha: 0.3),
              blurRadius: 48,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Your college journey, in your pocket',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: mobile ? 26 : 38,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                'College Kundli is about helping every student make an '
                'informed choice. Get the Android app for live calls with '
                'verified seniors, personalised cutoff predictions and '
                'saved shortlists.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: mobile ? 15 : 17,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),
            PillButton(
              label: 'Download Android App',
              large: true,
              variant: ButtonVariant.light,
              leading: const PlayStoreIcon(),
              onPressed: () => openUrl(Links.playStore),
            ),
          ],
        ),
      ),
    ).reveal();
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = context.isMobile;
    final brand = Column(
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const BrandLogo(light: true),
        const SizedBox(height: 12),
        Text(
          'Know the reality before you choose your college.',
          textAlign: mobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      ],
    );
    final links = Wrap(
      spacing: 28,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: const [
        _FooterLink('Privacy Policy', Links.privacyPolicy),
        _FooterLink('Terms of Service', Links.terms),
        _FooterLink('Contact', Links.contact),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(top: 72),
      color: Brand.footer,
      child: ContentWidth(
        vertical: 48,
        child: Column(
          children: [
            if (mobile) ...[
              brand,
              const SizedBox(height: 28),
              links,
            ] else
              Row(children: [Expanded(child: brand), links]),
            const SizedBox(height: 36),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 20),
            Text(
              '© ${DateTime.now().year} College Kundli. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink(this.label, this.url);

  final String label;
  final String url;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => openUrl(widget.url),
        child: Text(
          widget.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: _hovered ? 1 : 0.7),
            fontWeight: FontWeight.w500,
            decoration: _hovered ? TextDecoration.underline : null,
            decorationColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
