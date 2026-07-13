import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/careers_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../models/careers_models.dart';
import '../providers/careers_provider.dart';

class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(filteredCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Companies'),
      ),
      body: companiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (companies) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (q) => ref.read(companySearchProvider.notifier).set(q),
            ),
            const SizedBox(height: 16),
            if (companies.isEmpty)
              const Center(child: Text('No companies found'))
            else
              ...companies.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(c.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${c.industry} · ${c.hiringStatus.replaceAll('_', ' ')}\n'
                      '★ ${c.rating.toStringAsFixed(1)} (${c.reviewCount} reviews)',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RouteNames.careersCompanyDetailPath(c.id)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CompanyDetailScreen extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyDetailScreen({required this.companyId, super.key});

  @override
  ConsumerState<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  final _reviewController = TextEditingController();
  double _rating = 4;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyByIdProvider(widget.companyId));
    final reviewsAsync = ref.watch(companyReviewsProvider(widget.companyId));
    final verifiedAsync = ref.watch(isVerifiedForCompanyReviewProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Company'),
      ),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (company) {
          if (company == null) return const Center(child: Text('Company not found'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(company.name,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(company.industry,
                  style: GoogleFonts.poppins(color: AppTheme.gray500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: AppTheme.warningColor, size: 18),
                  Text(' ${company.rating.toStringAsFixed(1)} (${company.reviewCount} reviews)',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              _badge(company.hiringStatus),
              const SizedBox(height: 16),
              if (company.description.isNotEmpty)
                Text(company.description,
                    style: GoogleFonts.poppins(height: 1.5, color: AppTheme.gray700)),
              if (company.website.isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(company.website)),
                  icon: const Icon(Icons.language, size: 16),
                  label: const Text('Website'),
                ),
              if (company.placementHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Placement History',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ...company.placementHistory.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $h', style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Reviews from verified students',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              reviewsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return Text('No reviews yet.',
                        style: GoogleFonts.poppins(color: AppTheme.gray500));
                  }
                  return Column(
                    children: reviews
                        .map(
                          (r) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(r.authorDisplayName,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              subtitle: Text(r.textReview),
                              trailing: Text('★ ${r.rating.toStringAsFixed(1)}'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              verifiedAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (verified) {
                  if (!verified) {
                    return Text(
                      'Verify your student profile to write a company review.',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Write a review',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Slider(
                        value: _rating,
                        min: 1,
                        max: 5,
                        divisions: 8,
                        label: _rating.toStringAsFixed(1),
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                      TextField(
                        controller: _reviewController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Share your experience...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => _submitReview(company),
                        child: const Text('Submit Review'),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitReview(CompanyModel company) async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    final user = await ref.read(currentUserDetailProvider.future);
    if (authUser == null) return;
    try {
      await ref.read(careersRepositoryProvider).submitCompanyReview(
            companyId: company.id,
            userId: authUser.uid,
            authorDisplayName: user?.displayName ?? 'Verified Student',
            rating: _rating,
            textReview: _reviewController.text,
            isVerifiedStudent: true,
          );
      _reviewController.clear();
      ref.invalidate(companyReviewsProvider(company.id));
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Review submitted');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }

  Widget _badge(String status) {
    final color = status == CareersConstants.hiringActive
        ? AppTheme.accentColor
        : AppTheme.warningColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
