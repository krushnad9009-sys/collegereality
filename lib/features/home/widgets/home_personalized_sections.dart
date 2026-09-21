import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/premium_components.dart';
import '../../personalization/providers/personalized_colleges_provider.dart';
import '../../personalization/providers/user_preferences_provider.dart';
import 'home_college_discovery_card.dart';

/// "Recommended for You" — colleges in the user's most-searched stream, or
/// (when we don't know their stream yet) the global top-rated colleges under
/// an honest "Top Rated" heading rather than a claim of personalisation.
class RecommendedCollegesSection extends ConsumerWidget {
  const RecommendedCollegesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(recommendedCollegesProvider);
    final feed = feedAsync.valueOrNull;
    final personalized = feed?.isPersonalized ?? false;
    final category = feed?.matchedOn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: personalized ? 'Recommended for You' : 'Top Rated Colleges',
          subtitle: personalized
              ? 'Top-rated $category colleges, picked for you'
              : 'Real colleges, real ratings — highest rated first',
          actionLabel: 'View all',
          onAction: () => context.go(
            personalized
                ? '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(category!)}'
                : RouteNames.collegeSearch,
          ),
        ),
        CollegeDiscoveryCarousel(
          colleges: feedAsync.whenData((f) => f.colleges),
          onRetry: () => ref.invalidate(recommendedCollegesProvider),
          emptyTitle: 'No recommended colleges yet',
          emptySubtitle:
              'Colleges will appear here once the directory is seeded.',
        ),
        const SizedBox(height: AppSpacing.sectionXl),
      ],
    );
  }
}

/// "Colleges Near You" — best-rated colleges in the user's state. Renders
/// nothing (header, carousel and its trailing gap all collapse) when the
/// state is unknown or has no colleges; see [collegesNearYouProvider].
class CollegesNearYouSection extends ConsumerWidget {
  const CollegesNearYouSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Checked first so a user with no known state never sees a header or
    // skeleton flash before the (instantly empty) feed resolves.
    final hasState = ref.watch(
      userPreferencesProvider.select((p) => p.hasState),
    );
    if (!hasState) return const SizedBox.shrink();

    final feedAsync = ref.watch(collegesNearYouProvider);
    final feed = feedAsync.valueOrNull;
    if (feedAsync.hasValue && (feed == null || feed.colleges.isEmpty)) {
      return const SizedBox.shrink();
    }
    final state =
        feed?.matchedOn ??
        ref.watch(userPreferencesProvider.select((p) => p.preferredState));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Colleges Near You',
          subtitle: 'Top-rated colleges in $state',
          actionLabel: 'View all',
          onAction: () => context.go(
            '${RouteNames.collegeSearch}?state=${Uri.encodeComponent(state!)}',
          ),
        ),
        CollegeDiscoveryCarousel(
          colleges: feedAsync.whenData((f) => f.colleges),
          onRetry: () => ref.invalidate(collegesNearYouProvider),
          emptyTitle: 'No colleges found nearby',
          emptySubtitle: 'Try exploring by city or stream instead.',
        ),
        const SizedBox(height: AppSpacing.sectionXl),
      ],
    );
  }
}
