import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';

class StudentLifeHubScreen extends StatelessWidget {
  const StudentLifeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
        title: const Text('Campus Life'),
      ),
      body: ListView(
        padding: EdgeInsets.all(isWide ? 24 : 16),
        children: [
          Text('Campus Life Hub',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Events, clubs, competitions, and verified student communities.',
            style: GoogleFonts.poppins(color: AppTheme.gray600, height: 1.5),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: isWide ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 1.4 : 1.1,
            children: [
              _tile(Icons.event_outlined, 'Events', 'Upcoming campus events',
                  AppTheme.primaryColor, () => context.push(RouteNames.studentLifeEvents)),
              _tile(Icons.groups_outlined, 'Clubs', 'Join college clubs',
                  AppTheme.secondaryColor, () => context.push(RouteNames.studentLifeClubs)),
              _tile(Icons.emoji_events_outlined, 'Competitions', 'Win prizes',
                  AppTheme.accentColor,
                  () => context.push(RouteNames.studentLifeCompetitions)),
              _tile(Icons.forum_outlined, 'Communities', 'Branch & year boards',
                  const Color(0xFF7C3AED),
                  () => context.push(RouteNames.studentLifeCommunities)),
              _tile(Icons.bookmark_outline, 'Saved Events', 'Your bookmarks',
                  AppTheme.warningColor, () => context.push(RouteNames.studentLifeSaved)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(sub, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
            ],
          ),
        ),
      ),
    );
  }
}
