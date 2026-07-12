import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/widgets/review_card_widget.dart';

class AdminReviewsScreen extends ConsumerWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(allReviewsAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderate Reviews'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const Center(child: Text('No reviews to moderate'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return ReviewCardWidget(
                review: reviews[index],
                showCollegeName: true,
              );
            },
          );
        },
      ),
    );
  }
}
