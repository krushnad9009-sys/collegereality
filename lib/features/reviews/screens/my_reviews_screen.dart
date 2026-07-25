import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/review_provider.dart';
import '../widgets/review_card_widget.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final reviewsAsync = ref.watch(userReviewsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.gray900
          : const Color(0xFFF3F5FA),
      appBar: AppBar(
        title: Text(
          'My Reviews',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.profile);
            }
          },
        ),
      ),
      body: reviewsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => const SkeletonBox(height: 140),
        ),
        error: (e, _) => AsyncErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(userReviewsProvider),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return AsyncEmptyView(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              subtitle: 'Share honest experiences to help future students',
              action: FilledButton.icon(
                onPressed: () => context.go(RouteNames.collegeSearch),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Find a college'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: reviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 220 + (index * 20).clamp(0, 120)),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(tokens.cardRadius),
                  border: Border.all(color: tokens.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ReviewCardWidget(
                  review: review,
                  showCollegeName: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
