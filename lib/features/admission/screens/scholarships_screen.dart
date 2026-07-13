import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/admission_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/scholarship_model.dart';
import '../providers/admission_provider.dart';
import '../utils/admission_utils.dart';

class ScholarshipsScreen extends ConsumerStatefulWidget {
  const ScholarshipsScreen({super.key});

  @override
  ConsumerState<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends ConsumerState<ScholarshipsScreen> {
  final _searchController = TextEditingController();
  final _courseController = TextEditingController();
  final _incomeController = TextEditingController();
  String? _eligibilityCategory;
  String? _eligibilityState;
  String? _eligibilityCourse;
  double? _eligibilityIncome;

  @override
  void dispose() {
    _searchController.dispose();
    _courseController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scholarshipsAsync = ref.watch(filteredScholarshipsProvider);
    final filters = ref.watch(scholarshipFilterProvider);
    final savedIds = ref.watch(savedScholarshipIdsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Scholarships'),
      ),
      body: scholarshipsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (scholarships) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search scholarships...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (q) => ref.read(scholarshipFilterProvider.notifier).update(
                      filters.copyWith(searchQuery: q),
                    ),
              ),
              const SizedBox(height: 12),
              _FilterChips(
                filters: filters,
                onProviderChanged: (v) => ref
                    .read(scholarshipFilterProvider.notifier)
                    .update(filters.copyWith(providerType: v, clearProvider: v == null)),
                onCategoryChanged: (v) => ref
                    .read(scholarshipFilterProvider.notifier)
                    .update(filters.copyWith(category: v, clearCategory: v == null)),
                onStateChanged: (v) => ref
                    .read(scholarshipFilterProvider.notifier)
                    .update(filters.copyWith(state: v, clearState: v == null)),
                onCourseChanged: (v) => ref
                    .read(scholarshipFilterProvider.notifier)
                    .update(filters.copyWith(course: v, clearCourse: v == null)),
                onIncomeChanged: (v) => ref
                    .read(scholarshipFilterProvider.notifier)
                    .update(filters.copyWith(maxIncomeLpa: v, clearIncome: v == null)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showEligibilityChecker(context, scholarships),
                icon: const Icon(Icons.checklist_rtl_outlined),
                label: const Text('Eligibility Checker'),
              ),
              const SizedBox(height: 16),
              if (scholarships.isEmpty)
                const Center(child: Text('No scholarships match your filters'))
              else
                ...scholarships.map(
                  (s) => _ScholarshipCard(
                    scholarship: s,
                    isSaved: savedIds.contains(s.id),
                    onToggleSave: () => _toggleSave(s.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSave(String scholarshipId) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final repo = ref.read(admissionRepositoryProvider);
    final saved = ref.read(savedScholarshipIdsProvider).valueOrNull ?? {};
    try {
      if (saved.contains(scholarshipId)) {
        await repo.unsaveScholarship(user.uid, scholarshipId);
      } else {
        await repo.saveScholarship(user.uid, scholarshipId);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }

  void _showEligibilityChecker(BuildContext context, List<ScholarshipModel> all) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final eligible = all.where((s) {
              return checkScholarshipEligibility(
                scholarship: s,
                userCategory: _eligibilityCategory ?? 'General',
                userState: _eligibilityState,
                userCourse: _eligibilityCourse,
                userIncomeLpa: _eligibilityIncome,
              );
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eligibility Checker',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _eligibilityCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: AdmissionConstants.scholarshipCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _eligibilityCategory = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'State (optional)'),
                    onChanged: (v) => setState(() => _eligibilityState = v.isEmpty ? null : v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _courseController,
                    decoration: const InputDecoration(labelText: 'Course (optional)'),
                    onChanged: (v) => setState(() => _eligibilityCourse = v.isEmpty ? null : v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Family income (LPA)'),
                    onChanged: (v) => setState(
                      () => _eligibilityIncome = double.tryParse(v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${eligible.length} eligible scholarship${eligible.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...eligible.take(5).map(
                        (s) => ListTile(
                          dense: true,
                          title: Text(s.name, style: GoogleFonts.poppins(fontSize: 13)),
                          subtitle: Text(s.amount, style: GoogleFonts.poppins(fontSize: 11)),
                        ),
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChips extends StatelessWidget {
  final ScholarshipFilterState filters;
  final ValueChanged<String?> onProviderChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<double?> onIncomeChanged;

  const _FilterChips({
    required this.filters,
    required this.onProviderChanged,
    required this.onCategoryChanged,
    required this.onStateChanged,
    required this.onCourseChanged,
    required this.onIncomeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('All Types', filters.providerType == null, () => onProviderChanged(null)),
              ...AdmissionConstants.providerTypes.map((t) {
                final label = t == AdmissionConstants.providerCentralGovt
                    ? 'Central'
                    : t == AdmissionConstants.providerStateGovt
                        ? 'State'
                        : 'Private';
                return _chip(label, filters.providerType == t, () => onProviderChanged(t));
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AdmissionConstants.scholarshipCategories.take(6).map((c) {
              return _chip(c, filters.category == c, () => onCategoryChanged(
                    filters.category == c ? null : c,
                  ));
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.poppins(fontSize: 11)),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ScholarshipCard extends StatelessWidget {
  final ScholarshipModel scholarship;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const _ScholarshipCard({
    required this.scholarship,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = scholarship.lastDate != null
        ? DateFormat('MMM d, yyyy').format(scholarship.lastDate!)
        : 'Rolling';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    scholarship.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
                  color: isSaved ? AppTheme.primaryColor : AppTheme.gray500,
                  onPressed: onToggleSave,
                ),
              ],
            ),
            _badge(scholarship.providerLabel),
            const SizedBox(height: 8),
            Text('Amount: ${scholarship.amount}',
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.gray700)),
            Text('Last date: $dateStr',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
            if (scholarship.eligibility.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(scholarship.eligibility,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600)),
            ],
            if (scholarship.requiredDocuments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Documents: ${scholarship.requiredDocuments.join(', ')}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray500)),
            ],
            if (scholarship.officialWebsite.isNotEmpty)
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse(scholarship.officialWebsite)),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Official Website'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primaryColor)),
    );
  }
}
