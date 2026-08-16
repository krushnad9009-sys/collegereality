import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_fonts.dart';

class _RealityPoint {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? route;

  const _RealityPoint(this.title, this.description, this.icon, this.color, {this.route});
}

/// "Know the Reality Before You Take Admission" — College Reality's core
/// differentiation, told as five short feature statements rather than a
/// generic marketing paragraph. This is meant to be the strongest, most
/// distinct-looking section on the page: a dark, editorial-feeling surface
/// that breaks the pattern of light cards used everywhere else on Home.
class HomeRealityCheckSection extends StatelessWidget {
  const HomeRealityCheckSection({super.key});

  static const _points = [
    _RealityPoint(
      'Real Student Reviews',
      'Verified experiences from students who actually studied there — not marketing copy.',
      Icons.rate_review_rounded,
      Color(0xFF14B8A6),
    ),
    _RealityPoint(
      'CR Score',
      'A transparent score built from ratings, placements and verified student input.',
      Icons.insights_rounded,
      Color(0xFF38BDF8),
    ),
    _RealityPoint(
      'Placement Reality',
      'Understand real placement outcomes, not just the numbers a college chooses to publish.',
      Icons.work_rounded,
      Color(0xFFFBBF24),
    ),
    _RealityPoint(
      'Campus Reality',
      'Hostel, canteen, faculty and infrastructure — as students actually experience it.',
      Icons.apartment_rounded,
      Color(0xFFA78BFA),
    ),
    _RealityPoint(
      'Talk to Verified Students',
      'Book a private call with a verified student or alumnus before you decide.',
      Icons.support_agent_rounded,
      Color(0xFFFB7185),
      route: RouteNames.guidesDirectory,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1120), Color(0xFF0F2C29)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Know the Reality\nBefore You Take Admission.',
            style: AppFonts.plusJakarta(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.22,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'What makes College Reality different',
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: _points.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _RealityTile(point: _points[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealityTile extends StatelessWidget {
  final _RealityPoint point;

  const _RealityTile({required this.point});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: point.route == null ? null : () => context.go(point.route!),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 190,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: point.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(point.icon, color: point.color, size: 19),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    point.title,
                    style: AppFonts.plusJakarta(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point.description,
                    style: AppFonts.plusJakarta(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.62),
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
