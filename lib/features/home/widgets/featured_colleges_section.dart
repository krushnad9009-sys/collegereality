import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../colleges/providers/college_provider.dart';
import 'college_card_widget.dart';

class FeaturedCollegesSection extends ConsumerWidget {
  const FeaturedCollegesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegesAsync = ref.watch(homeFeaturedCollegesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Featured Colleges',
          subtitle: 'Hand-picked campuses with verified ratings',
          actionLabel: 'View all',
          onAction: () => context.go(RouteNames.collegeSearch),
        ),
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
          error: (e, _) => AsyncErrorView.fromError(
            e,
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
                      child: CollegeCardWidget.fromCollege(
                        college,
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
