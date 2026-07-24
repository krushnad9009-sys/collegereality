import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';

class QuestionListShimmer extends StatelessWidget {
  const QuestionListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.gray200),
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
