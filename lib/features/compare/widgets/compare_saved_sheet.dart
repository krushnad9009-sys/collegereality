import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../models/saved_comparison_model.dart';
import '../providers/compare_basket_provider.dart';

Future<void> showSavedComparisonsSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _SavedComparisonsSheet(),
  );
}

class _SavedComparisonsSheet extends ConsumerWidget {
  const _SavedComparisonsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedComparisonsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Comparisons',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          savedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Failed to load saved comparisons: $e'),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No saved comparisons yet.',
                    style: GoogleFonts.poppins(color: AppTheme.gray500),
                  ),
                );
              }
              return SizedBox(
                height: 320,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return _SavedComparisonTile(item: item);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SavedComparisonTile extends ConsumerWidget {
  final SavedComparisonModel item;

  const _SavedComparisonTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${item.collegeIds.length} colleges • ${item.savedAt.toLocal()}'.split('.').first,
        style: GoogleFonts.poppins(fontSize: 11),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final service = await ref.read(compareSavedServiceProvider.future);
          await service.delete(item.id);
          ref.invalidate(savedComparisonsProvider);
        },
      ),
      onTap: () {
        ref.read(compareBasketProvider.notifier).setColleges(item.collegeIds);
        context.pop();
        context.go(RouteNames.comparePath(ids: item.collegeIds));
      },
    );
  }
}
