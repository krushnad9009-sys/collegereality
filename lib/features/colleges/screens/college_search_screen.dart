import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../home/widgets/college_card_widget.dart';
import '../../compare/providers/compare_basket_provider.dart';
import '../../compare/widgets/compare_basket_bar.dart';
import '../models/college_model.dart';
import '../providers/college_provider.dart';

class CollegeSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialCity;
  final String? initialState;
  final String? initialCourse;
  final String? initialFilter;

  const CollegeSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialState,
    this.initialCourse,
    this.initialFilter,
  });

  @override
  ConsumerState<CollegeSearchScreen> createState() =>
      _CollegeSearchScreenState();
}

class _CollegeSearchScreenState extends ConsumerState<CollegeSearchScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _cityController;
  String? _selectedState;
  String? _selectedCourse;
  bool _showFilters = false;
  String? _cursor;
  List<CollegeModel> _results = [];
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String? _searchError;
  CollegeSearchParams? _activeParams;
  String _liveQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _cityController = TextEditingController(text: widget.initialCity ?? '');
    _selectedState = widget.initialState;
    _selectedCourse = widget.initialCourse;
    if (widget.initialFilter == 'city' || widget.initialFilter == 'state') {
      _showFilters = true;
    }
    if (widget.initialCity != null ||
        widget.initialState != null ||
        widget.initialCourse != null ||
        widget.initialFilter != null) {
      _showFilters = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  CollegeSearchParams _buildParams({String? startAfter}) {
    return CollegeSearchParams(
      query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      state: _selectedState,
      course: _selectedCourse,
      startAfterDocumentId: startAfter,
    );
  }

  Future<void> _runSearch({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore || _cursor == null) return;
      setState(() => _isLoadingMore = true);
      final page = await ref.read(
        collegeSearchPageProvider(_buildParams(startAfter: _cursor)).future,
      );
      if (!mounted) return;
      setState(() {
        _results = [..._results, ...page.colleges];
        _cursor = page.lastDocumentId;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
      return;
    }

    final params = _buildParams();
    setState(() {
      _activeParams = params;
      _cursor = null;
      _results = [];
      _hasMore = false;
      _isSearching = true;
      _searchError = null;
    });

    try {
      final page = await ref.read(collegeSearchPageProvider(params).future);
      if (!mounted) return;
      setState(() {
        _results = page.colleges;
        _cursor = page.lastDocumentId;
        _hasMore = page.hasMore;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.toString();
        _isSearching = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedState = null;
      _selectedCourse = null;
      _cityController.clear();
      _searchController.clear();
    });
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final statesAsync = ref.watch(indianStatesProvider);
    final coursesAsync = ref.watch(indianCoursesProvider);
    final metaAsync = ref.watch(collegeDirectoryMetaProvider);
    final basket = ref.watch(compareBasketProvider);
    final suggestionsAsync = _liveQuery.trim().isNotEmpty
        ? ref.watch(collegeInstantSuggestProvider(_liveQuery.trim()))
        : const AsyncValue<List<CollegeModel>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Colleges'),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: metaAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (meta) => Text(
                meta.totalColleges > 0
                    ? '${meta.totalColleges.toString()} colleges indexed'
                    : 'Search 40,000+ colleges by name',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search college, city, state, university...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _runSearch,
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), () {
                  if (!mounted) return;
                  setState(() => _liveQuery = value);
                  if (value.trim().isNotEmpty) _runSearch();
                });
              },
              onSubmitted: (_) => _runSearch(),
            ),
          ),
          suggestionsAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, _) => const SizedBox.shrink(),
            data: (suggestions) {
              if (suggestions.isEmpty || _liveQuery.trim().isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gray200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final college = suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        college.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        [
                          college.locationLabel,
                          if (college.universityName != null &&
                              college.universityName!.isNotEmpty)
                            college.universityName!,
                        ].join(' · '),
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                      onTap: () => context.go(
                        RouteNames.collegeDetailsPath(college.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  statesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
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
                          (s) => DropdownMenuItem(value: s, child: Text(s)),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedState = v);
                        _runSearch();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      hintText: 'e.g. Mumbai, Pune, Delhi',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
                    },
                    onSubmitted: (_) => _runSearch(),
                  ),
                  const SizedBox(height: 12),
                  coursesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (courses) => DropdownButtonFormField<String>(
                      initialValue: _selectedCourse,
                      decoration: InputDecoration(
                        labelText: 'Course',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Courses'),
                        ),
                        ...courses.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedCourse = v);
                        _runSearch();
                      },
                    ),
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
            child: _isSearching && _results.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _searchError != null && _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off_rounded,
                                  size: 56, color: AppTheme.gray400),
                              const SizedBox(height: 16),
                              Text(
                                'Search temporarily unavailable',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchError!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.gray500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _runSearch,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _results.isEmpty && _activeParams == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.school_outlined,
                                    size: 64, color: AppTheme.gray400),
                                const SizedBox(height: 16),
                                Text(
                                  'Find your college',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Search by name or use filters',
                                  style:
                                      GoogleFonts.poppins(color: AppTheme.gray500),
                                ),
                              ],
                            ),
                          )
                        : _results.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded,
                                        size: 56, color: AppTheme.gray400),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No colleges found',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try a different name, city, or filter',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: _results.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _results.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: _isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton(
                                        onPressed: () =>
                                            _runSearch(loadMore: true),
                                        child: const Text('Load more'),
                                      ),
                              ),
                            );
                          }
                          final college = _results[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CollegeCardWidget(
                              collegeId: college.id,
                              collegeName: college.name,
                              location: college.state,
                              city: college.city,
                              rating: college.aggregatedRatings.overall,
                              reviewCount: college.reviewCount,
                              imageUrl: college.coverPhotoUrl ?? college.logoUrl,
                              logoUrl: college.logoUrl,
                              isSelectedForCompare: basket.contains(college.id),
                              onCompareToggle: () {
                                final message = ref
                                    .read(compareBasketProvider.notifier)
                                    .toggle(college.id);
                                if (message != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              },
                              onTap: () => context.go(
                                RouteNames.collegeDetailsPath(college.id),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const CompareBasketBar(),
    );
  }
}
