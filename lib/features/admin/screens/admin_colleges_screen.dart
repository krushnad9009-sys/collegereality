import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../colleges/providers/college_provider.dart';

class AdminCollegesScreen extends ConsumerWidget {
  const AdminCollegesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegesAsync = ref.watch(collegesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Colleges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: collegesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (colleges) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: colleges.length,
          itemBuilder: (context, index) {
            final college = colleges[index];
            return Card(
              child: ListTile(
                title: Text(
                  college.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${college.city}, ${college.state} · ${college.reviewCount} reviews'),
                trailing: Text(
                  '${college.aggregatedRatings.overall}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                onTap: () =>
                    context.go(RouteNames.collegeDetailsPath(college.id)),
              ),
            );
          },
        ),
      ),
    );
  }
}
