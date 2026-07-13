import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';

class RankingHubScreen extends StatelessWidget {
  const RankingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Rankings & Recommendations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Data-driven college rankings powered by verified reviews and placements',
            style: GoogleFonts.poppins(color: AppTheme.gray600),
          ),
          const SizedBox(height: 20),
          _Tile(
            icon: Icons.leaderboard_outlined,
            title: 'College Rankings',
            subtitle: 'Overall, state, city, course & type rankings',
            color: AppTheme.primaryColor,
            onTap: () => context.push(RouteNames.rankingColleges),
          ),
          _Tile(
            icon: Icons.auto_awesome,
            title: 'Smart Recommendations',
            subtitle: 'Match colleges to your exam score & preferences',
            color: const Color(0xFF7C3AED),
            onTap: () => context.push(RouteNames.rankingRecommendations),
          ),
          _Tile(
            icon: Icons.compare_arrows,
            title: 'Compare Top 5',
            subtitle: 'Best picks with strengths, ROI & placement',
            color: AppTheme.secondaryColor,
            onTap: () => context.push(RouteNames.rankingCompare),
          ),
          _Tile(
            icon: Icons.insights_outlined,
            title: 'AI Insights',
            subtitle: 'Best placement, teaching, value & trending',
            color: const Color(0xFF0EA5E9),
            onTap: () => context.push(RouteNames.rankingInsights),
          ),
          _Tile(
            icon: Icons.analytics_outlined,
            title: 'College Analytics',
            subtitle: 'Popular, most reviewed & highest rated',
            color: const Color(0xFF059669),
            onTap: () => context.push(RouteNames.rankingAnalytics),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(RouteNames.assistant),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Ask AI Assistant'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
