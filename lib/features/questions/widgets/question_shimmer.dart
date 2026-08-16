import 'package:flutter/material.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../core/widgets/skeleton_loader.dart';

class QuestionListShimmer extends StatelessWidget {
  const QuestionListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 18, width: 220),
            SizedBox(height: 10),
            SkeletonBox(height: 14, width: double.infinity),
            SizedBox(height: 6),
            SkeletonBox(height: 14, width: 180),
            SizedBox(height: 12),
            SkeletonBox(height: 12, width: 120),
          ],
        ),
      ),
    );
  }
}
