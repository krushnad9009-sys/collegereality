import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../providers/ranking_provider.dart';

class CollegeInsightsScreen extends ConsumerWidget {
  const CollegeInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(collegeInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (insights) {
          if (insights.isEmpty) {
            return Center(
              child: Text(
                'No insights available yet',
                style: GoogleFonts.poppins(color: AppTheme.gray500),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: insights.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final insight = insights[i];
              return Card(
                child: ListTile(
                  leading: Icon(_iconFor(insight.insightType), color: AppTheme.primaryColor),
                  title: Text(insight.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight.college.name,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      Text(insight.description, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(RouteNames.collegeDetailsPath(insight.college.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'best_placement':
        return Icons.work_outline;
      case 'best_teaching':
        return Icons.menu_book_outlined;
      case 'best_infrastructure':
        return Icons.apartment_outlined;
      case 'best_value':
        return Icons.savings_outlined;
      case 'fastest_growing':
        return Icons.trending_up;
      case 'trending':
        return Icons.whatshot_outlined;
      default:
        return Icons.insights_outlined;
    }
  }
}
