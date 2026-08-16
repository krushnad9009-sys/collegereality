import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
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
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        title: Text(
          'My Reviews',
          style: AppFonts.plusJakarta(fontWeight: FontWeight.w800),
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

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return FadeInSection(
                delayMs: (index * 40).clamp(0, 240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReviewCardWidget(
                      review: review,
                      showCollegeName: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14, right: 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => context.go(
                            RouteNames.writeReviewPath(review.collegeId),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
