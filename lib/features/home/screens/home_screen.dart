import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/router/route_names.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/college_card_widget.dart';
import '../widgets/search_bar_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.gray900
          : AppTheme.white,
      body: SafeArea(
        child: currentUser == null
            ? Center(
                child: Text(
                  'Loading...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with user profile
                      HomeHeaderWidget(user: currentUser),
                      const SizedBox(height: 24),

                      // Search Bar
                      SearchBarWidget(
                        onTap: () {
                          // TODO: Navigate to college search screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'College search coming soon!',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Quick Access Section
                      Text(
                        'Quick Access',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _QuickAccessCard(
                                icon: Icons.location_city_rounded,
                                label: 'By City',
                                color: AppTheme.primaryColor,
                                onTap: () {
                                  SnackBarHelper.showInfoSnackBar(
                                    context,
                                    message:
                                        'City search coming soon!',
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.map_rounded,
                                label: 'By State',
                                color: AppTheme.secondaryColor,
                                onTap: () {
                                  SnackBarHelper.showInfoSnackBar(
                                    context,
                                    message:
                                        'State search coming soon!',
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.star_rounded,
                                label: 'Top Rated',
                                color: AppTheme.accentColor,
                                onTap: () {
                                  SnackBarHelper.showInfoSnackBar(
                                    context,
                                    message:
                                        'Top rated colleges coming soon!',
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _QuickAccessCard(
                                icon: Icons.trending_up_rounded,
                                label: 'Trending',
                                color: AppTheme.warningColor,
                                onTap: () {
                                  SnackBarHelper.showInfoSnackBar(
                                    context,
                                    message:
                                        'Trending colleges coming soon!',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Featured Colleges Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured Colleges',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('View all coming soon!'),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Sample College Cards (placeholder)
                      _buildCollegeCardsPlaceholder(context),

                      const SizedBox(height: 32),

                      // Call to Action
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share Your Experience',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Help thousands of students by sharing your honest college review',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppTheme.white,
                                  foregroundColor:
                                      AppTheme.primaryColor,
                                ),
                                onPressed: () {
                                  SnackBarHelper.showInfoSnackBar(
                                    context,
                                    message:
                                        'Review submission coming soon!',
                                  );
                                },
                                child: Text(
                                  'Write a Review',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCollegeCardsPlaceholder(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SampleCollegeCard(
            name: 'IIT Bombay',
            location: 'Mumbai, Maharashtra',
            rating: 4.8,
            reviews: 1250,
            onTap: () {
              SnackBarHelper.showInfoSnackBar(
                context,
                message: 'College details coming soon!',
              );
            },
          ),
          const SizedBox(width: 12),
          _SampleCollegeCard(
            name: 'Delhi University',
            location: 'Delhi',
            rating: 4.5,
            reviews: 980,
            onTap: () {
              SnackBarHelper.showInfoSnackBar(
                context,
                message: 'College details coming soon!',
              );
            },
          ),
          const SizedBox(width: 12),
          _SampleCollegeCard(
            name: 'Bangalore Institute',
            location: 'Bangalore, Karnataka',
            rating: 4.6,
            reviews: 756,
            onTap: () {
              SnackBarHelper.showInfoSnackBar(
                context,
                message: 'College details coming soon!',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SampleCollegeCard extends StatelessWidget {
  final String name;
  final String location;
  final double rating;
  final int reviews;
  final VoidCallback onTap;

  const _SampleCollegeCard({
    required this.name,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 200,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.gray200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.gray400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppTheme.warningColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rating',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviews reviews)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
