import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../home/widgets/college_card_widget.dart';
import '../../ranking/utils/cr_score_engine.dart';
import '../../compare/providers/compare_basket_provider.dart';
import '../../compare/widgets/compare_basket_bar.dart';
import '../models/college_model.dart';
import '../providers/college_provider.dart';

class CollegeSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialCity;
  final String? initialState;
  final String? initialCourse;
  final String? initialCategory;
  final String? initialFilter;

  const CollegeSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialState,
    this.initialCourse,
    this.initialCategory,
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
  String? _selectedCategory;
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
    _selectedCategory = widget.initialCategory;
    if (widget.initialFilter == 'city' || widget.initialFilter == 'state') {
      _showFilters = true;
    }
    if (widget.initialCity != null ||
        widget.initialState != null ||
        widget.initialCourse != null ||
        widget.initialCategory != null ||
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
      category: _selectedCategory,
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
        _searchError = FirestoreErrorUtils.isQuotaExceededError(e)
            ? kFirestoreQuotaUserMessage
            : e.toString();
        _isSearching = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedState = null;
      _selectedCourse = null;
      _selectedCategory = null;
      _cityController.clear();
      _searchController.clear();
    });
    _runSearch();
  }

  bool get _hasActiveFilters =>
      _selectedState != null ||
      _selectedCourse != null ||
      _selectedCategory != null ||
      _cityController.text.trim().isNotEmpty;

  InputDecoration _filterDecoration(BuildContext context, String label) {
    final tokens = context.tokens;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: tokens.surfaceMuted,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: tokens.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        borderSide: BorderSide(color: tokens.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        borderSide: BorderSide(color: tokens.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildSearchSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const CollegeCardSkeleton(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final statesAsync = ref.watch(indianStatesProvider);
    final coursesAsync = ref.watch(indianCoursesProvider);
    final metaAsync = ref.watch(collegeDirectoryMetaProvider);
    final basket = ref.watch(compareBasketProvider);
    final suggestionsAsync = _liveQuery.trim().isNotEmpty
        ? ref.watch(collegeInstantSuggestProvider(_liveQuery.trim()))
        : const AsyncValue<List<CollegeModel>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Colleges',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters || _hasActiveFilters
                  ? AppTheme.primaryColor
                  : tokens.textSecondary,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: metaAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (meta) => Text(
                meta.totalColleges > 0
                    ? '${meta.totalColleges.toString()} colleges indexed'
                    : 'Search 47,000+ colleges by name',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: PremiumCard(
              radius: tokens.cardRadius,
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search college, city, state, university...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: tokens.textTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryColor.withValues(alpha: 0.85),
                  ),
                  suffixIcon: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onPressed: _runSearch,
                  ),
                  filled: true,
                  fillColor: tokens.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
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
          ),
          if (_hasActiveFilters)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  if (_selectedState != null)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: PremiumChip(
                        label: _selectedState!,
                        icon: Icons.map_outlined,
                        selected: true,
                        onTap: () {
                          setState(() => _selectedState = null);
                          _runSearch();
                        },
                      ),
                    ),
                  if (_cityController.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: PremiumChip(
                        label: _cityController.text.trim(),
                        icon: Icons.location_city_outlined,
                        selected: true,
                        onTap: () {
                          _cityController.clear();
                          _runSearch();
                        },
                      ),
                    ),
                  if (_selectedCourse != null)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: PremiumChip(
                        label: _selectedCourse!,
                        icon: Icons.menu_book_outlined,
                        selected: true,
                        onTap: () {
                          setState(() => _selectedCourse = null);
                          _runSearch();
                        },
                      ),
                    ),
                  if (_selectedCategory != null)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: PremiumChip(
                        label: _selectedCategory!,
                        icon: Icons.category_outlined,
                        selected: true,
                        onTap: () {
                          setState(() => _selectedCategory = null);
                          _runSearch();
                        },
                      ),
                    ),
                ],
              ),
            ),
          suggestionsAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: LinearProgressIndicator(
                minHeight: 2,
                borderRadius: BorderRadius.circular(2),
                color: AppTheme.primaryColor,
                backgroundColor: tokens.shimmerBase,
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (suggestions) {
              if (suggestions.isEmpty || _liveQuery.trim().isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: PremiumCard(
                  radius: tokens.buttonRadius,
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: tokens.borderSubtle,
                      ),
                      itemBuilder: (context, index) {
                        final college = suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.school_outlined,
                            size: 20,
                            color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          ),
                          title: Text(
                            college.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              college.locationLabel,
                              if (college.universityName != null &&
                                  college.universityName!.isNotEmpty)
                                college.universityName!,
                            ].join(' · '),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: tokens.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => context.go(
                            RouteNames.collegeDetailsPath(college.id),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: PremiumCard(
                radius: tokens.cardRadius,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    statesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (states) => DropdownButtonFormField<String>(
                        initialValue: _selectedState,
                        decoration: _filterDecoration(context, 'State'),
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
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _cityController,
                      decoration: _filterDecoration(context, 'City').copyWith(
                        hintText: 'e.g. Mumbai, Pune, Delhi',
                      ),
                      onChanged: (_) {
                        _debounce?.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 350), _runSearch);
                        setState(() {});
                      },
                      onSubmitted: (_) => _runSearch(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    coursesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (courses) => DropdownButtonFormField<String>(
                        initialValue: _selectedCourse,
                        decoration: _filterDecoration(context, 'Course'),
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
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: _filterDecoration(context, 'Category'),
                      items: const [
                        DropdownMenuItem(
                            value: null, child: Text('All Categories')),
                        DropdownMenuItem(
                            value: 'Engineering', child: Text('Engineering')),
                        DropdownMenuItem(
                            value: 'Medical', child: Text('Medical')),
                        DropdownMenuItem(value: 'MBA', child: Text('MBA')),
                        DropdownMenuItem(value: 'Law', child: Text('Law')),
                        DropdownMenuItem(
                            value: 'Pharmacy', child: Text('Pharmacy')),
                        DropdownMenuItem(value: 'Arts', child: Text('Arts')),
                        DropdownMenuItem(
                            value: 'Commerce', child: Text('Commerce')),
                        DropdownMenuItem(
                            value: 'Science', child: Text('Science')),
                        DropdownMenuItem(
                            value: 'General', child: Text('General')),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedCategory = v);
                        _runSearch();
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        label: const Text('Clear filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isSearching && _results.isEmpty
                ? _buildSearchSkeleton()
                : _searchError != null && _results.isEmpty
                    ? AsyncErrorView(
                        message: _searchError!,
                        onRetry: _runSearch,
                      )
                    : _results.isEmpty && _activeParams == null
                        ? AsyncEmptyView(
                            icon: Icons.school_outlined,
                            title: 'Find your college',
                            subtitle: 'Search by name or use filters above',
                          )
                        : _results.isEmpty
                            ? AsyncEmptyView(
                                icon: Icons.search_off_rounded,
                                title: 'No colleges found',
                                subtitle:
                                    'Try a different name, city, or filter',
                                action: OutlinedButton.icon(
                                  onPressed: () =>
                                      context.push(RouteNames.requestCollege),
                                  icon: const Icon(Icons.add_business_outlined),
                                  label: const Text('Add My College'),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 96),
                                itemCount: _results.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _results.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Center(
                                        child: _isLoadingMore
                                            ? SizedBox(
                                                width: 28,
                                                height: 28,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              )
                                            : OutlinedButton.icon(
                                                onPressed: () =>
                                                    _runSearch(loadMore: true),
                                                icon: const Icon(
                                                    Icons.expand_more_rounded),
                                                label: const Text('Load more'),
                                              ),
                                      ),
                                    );
                                  }
                                  final college = _results[index];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: CollegeCardWidget(
                                      collegeId: college.id,
                                      collegeName: college.name,
                                      location: college.state,
                                      city: college.city,
                                      rating:
                                          college.aggregatedRatings.overall,
                                      crScore:
                                          CrScoreEngine.effectiveScore(college),
                                      reviewCount: college.reviewCount,
                                      imageUrl: college.coverPhotoUrl ??
                                          college.logoUrl,
                                      logoUrl: college.logoUrl,
                                      isSelectedForCompare:
                                          basket.contains(college.id),
                                      onCompareToggle: () {
                                        final message = ref
                                            .read(compareBasketProvider.notifier)
                                            .toggle(college.id);
                                        if (message != null && context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(content: Text(message)),
                                          );
                                        }
                                      },
                                      onTap: () => context.go(
                                        RouteNames.collegeDetailsPath(
                                            college.id),
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
