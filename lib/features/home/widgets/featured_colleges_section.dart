import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/index.dart';
import '../../colleges/providers/college_provider.dart';
import '../../ranking/utils/cr_score_engine.dart';
import 'college_card_widget.dart';

class FeaturedCollegesSection extends ConsumerWidget {
  const FeaturedCollegesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegesAsync = ref.watch(homeFeaturedCollegesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: () => context.go(RouteNames.collegeSearch),
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
        collegesAsync.when(
          loading: () => Column(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: CollegeCardSkeleton(),
              ),
            ),
          ),
          error: (e, _) => AsyncErrorView(
            message: e.toString().replaceFirst('Exception: ', ''),
            onRetry: () {
              ref.invalidate(homeFeaturedCollegesProvider);
              ref.invalidate(collegeSeedProvider);
            },
          ),
          data: (colleges) {
            if (colleges.isEmpty) {
              return const AsyncEmptyView(
                icon: Icons.school_outlined,
                title: 'No featured colleges yet',
                subtitle: 'Colleges will appear here once the directory is seeded.',
              );
            }
            return Column(
              children: colleges
                  .map(
                    (college) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CollegeCardWidget(
                        collegeId: college.id,
                        collegeName: college.name,
                        location: college.state,
                        city: college.city,
                        rating: college.aggregatedRatings.overall,
                        crScore: CrScoreEngine.effectiveScore(college),
                        reviewCount: college.reviewCount,
                        imageUrl: college.coverPhotoUrl,
                        logoUrl: college.logoUrl,
                        onTap: () => context.go(
                          RouteNames.collegeDetailsPath(college.id),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
