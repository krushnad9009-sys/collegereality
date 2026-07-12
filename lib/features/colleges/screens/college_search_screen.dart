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

  const CollegeSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialState,
    this.initialCourse,
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
  CollegeSearchParams? _activeParams;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _cityController = TextEditingController(text: widget.initialCity ?? '');
    _selectedState = widget.initialState;
    _selectedCourse = widget.initialCourse;
    if (widget.initialCity != null ||
        widget.initialState != null ||
        widget.initialCourse != null) {
      _showFilters = true;
    }
    if (widget.initialQuery != null ||
        widget.initialCity != null ||
        widget.initialState != null ||
        widget.initialCourse != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
    }
  }

  @override
  void dispose() {
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
    });

    final page = await ref.read(collegeSearchPageProvider(params).future);
    if (!mounted) return;
    setState(() {
      _results = page.colleges;
      _cursor = page.lastDocumentId;
      _hasMore = page.hasMore;
    });
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: metaAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
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
                hintText: 'Search by college name (min 2 chars)...',
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
              onSubmitted: (_) => _runSearch(),
            ),
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  statesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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
                      hintText: 'Exact city name',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _runSearch(),
                  ),
                  const SizedBox(height: 12),
                  coursesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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
            child: _results.isEmpty && _activeParams == null
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
                          style: GoogleFonts.poppins(color: AppTheme.gray500),
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          'No colleges found',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
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
