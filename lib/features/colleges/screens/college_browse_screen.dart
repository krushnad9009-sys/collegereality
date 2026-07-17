import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../colleges/providers/college_provider.dart';

class CollegeBrowseScreen extends ConsumerWidget {
  const CollegeBrowseScreen({super.key});

  static const _categories = [
    ('Engineering', Icons.precision_manufacturing_rounded, Color(0xFF1E3A5F)),
    ('Medical', Icons.local_hospital_rounded, Color(0xFFB91C1C)),
    ('MBA', Icons.business_center_rounded, Color(0xFF0F766E)),
    ('Law', Icons.gavel_rounded, Color(0xFF5B21B6)),
    ('Pharmacy', Icons.medication_rounded, Color(0xFF0369A1)),
    ('Arts', Icons.palette_rounded, Color(0xFFBE185D)),
    ('Commerce', Icons.account_balance_rounded, Color(0xFFB45309)),
    ('Science', Icons.science_rounded, Color(0xFF15803D)),
    ('Polytechnic', Icons.build_rounded, Color(0xFF4B5563)),
    ('Nursing', Icons.health_and_safety_rounded, Color(0xFFDB2777)),
    ('Agriculture', Icons.agriculture_rounded, Color(0xFF65A30D)),
    ('Architecture', Icons.architecture_rounded, Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(collegeCategoryCountsProvider);
    final totalAsync = ref.watch(collegeCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Browse Colleges',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: countsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load categories')),
        data: (counts) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              totalAsync.when(
                data: (total) => Text(
                  total > 0
                      ? '$total colleges across India'
                      : '47,000+ colleges across India',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.gray600,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => Text(
                  '47,000+ colleges across India',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.gray600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ..._categories.map((entry) {
                final count = counts[entry.$1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryTile(
                    label: entry.$1,
                    icon: entry.$2,
                    color: entry.$3,
                    count: count,
                    onTap: () => context.go(
                      '${RouteNames.collegeSearch}?category=${Uri.encodeComponent(entry.$1)}',
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gray200.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (count != null && count! > 0)
                      Text(
                        '$count colleges',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.gray500,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.gray400),
            ],
          ),
        ),
      ),
    );
  }
}
