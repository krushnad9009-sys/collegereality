import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../auth/providers/auth_provider.dart';

/// Navigates to the write-review flow for a college.
class WriteReviewButton extends ConsumerWidget {
  final String collegeId;
  final String collegeName;
  final bool extended;
  final bool outlined;

  const WriteReviewButton({
    required this.collegeId,
    required this.collegeName,
    this.extended = false,
    this.outlined = false,
    super.key,
  });

  void _onPressed(BuildContext context, WidgetRef ref) {
    final writePath =
        '${RouteNames.writeReviewPath(collegeId)}?name=${Uri.encodeComponent(collegeName)}';
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go(RouteNames.loginWithReturn(writePath));
      return;
    }
    context.go(writePath);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (extended) {
      return FloatingActionButton.extended(
        heroTag: 'write_review_$collegeId',
        elevation: 4,
        onPressed: () => _onPressed(context, ref),
        icon: const Icon(Icons.rate_review),
        label: const Text('Write Review'),
      );
    }

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: () => _onPressed(context, ref),
        icon: const Icon(Icons.rate_review_outlined, size: 18),
        label: Text(
          'Write Review',
          style: AppFonts.plusJakarta(fontWeight: FontWeight.w600),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: () => _onPressed(context, ref),
      icon: const Icon(Icons.rate_review_outlined, size: 18),
      label: Text(
        'Write Review',
        style: AppFonts.plusJakarta(fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
