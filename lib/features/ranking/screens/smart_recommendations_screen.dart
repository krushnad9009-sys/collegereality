import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/ranking_constants.dart';
import '../models/ranking_models.dart';
import '../providers/ranking_provider.dart';
import '../utils/college_ranking_utils.dart';

class SmartRecommendationsScreen extends ConsumerStatefulWidget {
  const SmartRecommendationsScreen({super.key});

  @override
  ConsumerState<SmartRecommendationsScreen> createState() =>
      _SmartRecommendationsScreenState();
}

class _SmartRecommendationsScreenState extends ConsumerState<SmartRecommendationsScreen> {
  String _examType = RankingConstants.examCet;
  final _scoreController = TextEditingController();
  final _budgetController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _branchController = TextEditingController();
  String _category = 'General';
  bool _requireHostel = false;
  bool _preferPlacements = true;
  SmartRecommendationCriteria? _criteria;

  @override
  void dispose() {
    _scoreController.dispose();
    _budgetController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  void _runRecommendations() {
    setState(() {
      _criteria = SmartRecommendationCriteria(
        examType: _examType,
        examScore: int.tryParse(_scoreController.text.trim()) ?? 0,
        reservationCategory: _category,
        maxBudget: int.tryParse(_budgetController.text.trim()),
        preferredState: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        preferredCity:
            _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        requireHostel: _requireHostel,
        preferPlacements: _preferPlacements,
        branchPreference: _branchController.text.trim().isEmpty
            ? null
            : _branchController.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = _criteria == null
        ? const AsyncValue<List<SmartRecommendationResult>>.data([])
        : ref.watch(smartRecommendationsProvider(_criteria!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Recommendations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Enter your preferences', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _examType,
            decoration: const InputDecoration(labelText: 'Exam', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: RankingConstants.examCet, child: Text('MHT-CET / State CET')),
              DropdownMenuItem(value: RankingConstants.examJee, child: Text('JEE Main (rank)')),
              DropdownMenuItem(value: RankingConstants.examNeet, child: Text('NEET (rank)')),
            ],
            onChanged: (v) => setState(() => _examType = v ?? RankingConstants.examCet),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scoreController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _examType == RankingConstants.examCet ? 'Percentile' : 'Rank',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: RankingConstants.reservationCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'General'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max budget (₹/year)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stateController,
            decoration: const InputDecoration(
              labelText: 'Preferred state',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'Preferred city',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _branchController,
            decoration: const InputDecoration(
              labelText: 'Branch preference (e.g. CSE)',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            title: const Text('Require hostel'),
            value: _requireHostel,
            onChanged: (v) => setState(() => _requireHostel = v),
          ),
          SwitchListTile(
            title: const Text('Prioritize placements'),
            value: _preferPlacements,
            onChanged: (v) => setState(() => _preferPlacements = v),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _runRecommendations,
            child: const Text('Get Recommendations'),
          ),
          const SizedBox(height: 24),
          resultsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (results) {
              if (_criteria == null) {
                return Text(
                  'Fill in your details and tap Get Recommendations',
                  style: GoogleFonts.poppins(color: AppTheme.gray500),
                );
              }
              if (results.isEmpty) {
                return const Text('No matching colleges found. Try adjusting filters.');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${results.length} colleges matched',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...results.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(r.college.name,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${r.college.city} · Match ${r.matchScore}%'),
                              if (r.reasons.isNotEmpty)
                                Text(r.reasons.join(' · '),
                                    style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: Text(formatFees(r.college)),
                          onTap: () =>
                              context.push(RouteNames.collegeDetailsPath(r.college.id)),
                        ),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
