import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/compare_constants.dart';
import '../providers/compare_basket_provider.dart';

/// Floating bar shown when colleges are selected for comparison.
class CompareBasketBar extends ConsumerWidget {
  const CompareBasketBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(compareBasketProvider);
    if (basket.collegeIds.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.gray700
                    : AppTheme.gray200,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${basket.collegeIds.length}/${CompareConstants.maxColleges} selected',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(compareBasketProvider.notifier).clear(),
                child: Text('Clear', style: GoogleFonts.poppins(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: basket.canCompare
                    ? () => context.go(
                          RouteNames.comparePath(ids: basket.collegeIds),
                        )
                    : null,
                icon: const Icon(Icons.compare, size: 18),
                label: Text(
                  'Compare',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
