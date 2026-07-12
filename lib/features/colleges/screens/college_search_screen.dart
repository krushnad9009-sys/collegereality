import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../home/widgets/college_card_widget.dart';
import '../providers/college_provider.dart';

class CollegeSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialCity;
  final String? initialState;

  const CollegeSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialState,
  });

  @override
  ConsumerState<CollegeSearchScreen> createState() =>
      _CollegeSearchScreenState();
}

class _CollegeSearchScreenState extends ConsumerState<CollegeSearchScreen> {
  late final TextEditingController _searchController;
  String? _selectedCity;
  String? _selectedState;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _selectedCity = widget.initialCity;
    _selectedState = widget.initialState;
    if (widget.initialCity != null || widget.initialState != null) {
      _showFilters = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CollegeSearchParams get _searchParams => CollegeSearchParams(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        city: _selectedCity,
        state: _selectedState,
      );

  void _applySearch() {
    setState(() {});
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedState = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(collegeSearchProvider(_searchParams));
    final statesAsync = ref.watch(indianStatesProvider);
    final citiesAsync = ref.watch(indianCitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Colleges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters ? AppTheme.primaryColor : null,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, city, or state...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applySearch();
                  },
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _applySearch(),
              onChanged: (_) => _applySearch(),
            ),
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: statesAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => const SizedBox.shrink(),
                          data: (states) => DropdownButtonFormField<String>(
                            initialValue: _selectedState,
                            decoration: InputDecoration(
                              labelText: 'State',
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All States'),
                              ),
                              ...states.map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _selectedState = v;
                                _selectedCity = null;
                              });
                              _applySearch();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: citiesAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => const SizedBox.shrink(),
                          data: (cities) {
                            final filtered = _selectedState == null
                                ? cities
                                : cities;
                            return DropdownButtonFormField<String>(
                              initialValue: _selectedCity,
                              decoration: InputDecoration(
                                labelText: 'City',
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Cities'),
                                ),
                                ...filtered.map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() => _selectedCity = v);
                                _applySearch();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load colleges: $e'),
              ),
              data: (colleges) {
                if (colleges.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: AppTheme.gray400),
                        const SizedBox(height: 16),
                        Text(
                          'No colleges found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search or filter',
                          style: GoogleFonts.poppins(color: AppTheme.gray500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: colleges.length,
                  itemBuilder: (context, index) {
                    final college = colleges[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CollegeCardWidget(
                        collegeId: college.id,
                        collegeName: college.name,
                        location: college.state,
                        city: college.city,
                        rating: college.aggregatedRatings.overall,
                        reviewCount: college.reviewCount,
                        imageUrl: college.coverPhotoUrl,
                        onTap: () => context.go(
                          RouteNames.collegeDetailsPath(college.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
