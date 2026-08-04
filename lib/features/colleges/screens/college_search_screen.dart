import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../../../core/services/search_history_service.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/searchable_text_form_field.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../home/widgets/college_card_widget.dart';
import '../../compare/providers/compare_basket_provider.dart';
import '../../compare/widgets/compare_basket_bar.dart';
import '../models/college_model.dart';
import '../providers/college_provider.dart';
import '../utils/college_suggestion_utils.dart';
import '../widgets/premium_search_discovery_panel.dart';

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
  late final TextEditingController _universityController;
  String? _selectedState;
  String? _selectedCourse;
  String? _selectedCategory;
  String? _selectedType;
  bool _showFilters = false;
  String? _cursor;
  List<CollegeModel> _results = [];
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;
  String _liveQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _cityController = TextEditingController();
    _universityController = TextEditingController();
    _applyInitialFilters();
    if (_shouldAutoSearchFromInitials()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
    }
  }

  @override
  void didUpdateWidget(covariant CollegeSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.initialQuery != widget.initialQuery ||
        oldWidget.initialCity != widget.initialCity ||
        oldWidget.initialState != widget.initialState ||
        oldWidget.initialCourse != widget.initialCourse ||
        oldWidget.initialCategory != widget.initialCategory ||
        oldWidget.initialFilter != widget.initialFilter;
    if (!changed) return;
    _applyInitialFilters();
    _runSearch();
  }

  void _applyInitialFilters() {
    _searchController.text = widget.initialQuery ?? '';
    _cityController.text = widget.initialCity ?? '';
    _selectedState = widget.initialState;
    _selectedCourse = widget.initialCourse;
    _selectedCategory = CollegeConstants.clampToAllowed(
      widget.initialCategory,
      CollegeConstants.collegeCategories,
    );
    if (widget.initialFilter == 'city' ||
        widget.initialFilter == 'state' ||
        widget.initialCity != null ||
        widget.initialState != null ||
        widget.initialCourse != null ||
        widget.initialCategory != null ||
        widget.initialFilter != null) {
      _showFilters = true;
    }
  }

  bool _shouldAutoSearchFromInitials() {
    return widget.initialCity != null ||
        widget.initialState != null ||
        widget.initialCourse != null ||
        widget.initialCategory != null ||
        widget.initialFilter != null ||
        (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cityController.dispose();
    _universityController.dispose();
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
      university: _universityController.text.trim().isEmpty
          ? null
          : _universityController.text.trim(),
      course: _selectedCourse,
      category: _selectedCategory,
      type: _selectedType,
      startAfterDocumentId: startAfter,
    );
  }

  Future<void> _runSearch({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore || _cursor == null) return;
      setState(() => _isLoadingMore = true);
      try {
        final page = await ref.read(
          collegeSearchPageProvider(_buildParams(startAfter: _cursor)).future,
        );
        if (!mounted) return;
        setState(() {
          final existingIds = _results.map((c) => c.id).toSet();
          final fresh = page.colleges
              .where((c) => existingIds.add(c.id))
              .toList();
          _results = [..._results, ...fresh];
          _cursor = page.lastDocumentId;
          _hasMore = page.hasMore;
          _isLoadingMore = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoadingMore = false;
          _searchError = FirestoreErrorUtils.userMessage(e);
        });
      }
      return;
    }

    final params = _buildParams();
    setState(() {
      _cursor = null;
      _results = [];
      _hasMore = false;
      _isSearching = true;
      _searchError = null;
      _hasSearched = true;
      _liveQuery = '';
    });

    try {
      final page = await ref.read(collegeSearchPageProvider(params).future);
      if (!mounted) return;
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        await ref.read(searchHistoryServiceProvider).addSearch(query);
        ref.invalidate(recentSearchesProvider);
      }
      setState(() {
        _results = page.colleges;
        _cursor = page.lastDocumentId;
        _hasMore = page.hasMore;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      final isQuota = FirestoreErrorUtils.isQuotaExceededError(e);
      setState(() {
        _searchError = isQuota
            ? kFirestoreQuotaUserMessage
            : FirestoreErrorUtils.userMessage(e);
        _isSearching = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedState = null;
      _selectedCourse = null;
      _selectedCategory = null;
      _selectedType = null;
      _cityController.clear();
      _universityController.clear();
      _searchController.clear();
      _liveQuery = '';
      _results = [];
      _hasSearched = false;
      _searchError = null;
      _cursor = null;
      _hasMore = false;
    });
  }

  bool get _hasActiveFilters =>
      _selectedState != null ||
      _selectedCourse != null ||
      _selectedCategory != null ||
      _selectedType != null ||
      _universityController.text.trim().isNotEmpty ||
      _cityController.text.trim().isNotEmpty;

  InputDecoration _filterDecoration(BuildContext context, String label) {
    final tokens = context.tokens;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: tokens.surfaceMuted,
      labelStyle: AppFonts.plusJakarta(
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
    final searchSuggestions = _liveQuery.trim().isEmpty
        ? const <String>[]
        : CollegeSuggestionUtils.searchSuggestions(_liveQuery.trim());

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.gray900
          : AppTheme.surfaceMuted,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.home);
            }
          },
        ),
        title: Text(
          'Search Colleges',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
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
                style: AppFonts.plusJakarta(
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
                style: AppFonts.plusJakarta(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search college, city, state, university...',
                  hintStyle: AppFonts.plusJakarta(
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
                  });
                },
                onSubmitted: (_) => _runSearch(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSearching ? null : _runSearch,
                    icon: _isSearching
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.surfaceElevated,
                            ),
                          )
                        : const Icon(Icons.search_rounded, size: 20),
                    label: Text(
                      _isSearching ? 'Searching…' : 'Search Colleges',
                      style: AppFonts.plusJakarta(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.buttonRadius),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: Text(
                    'Reset Filters',
                    style: AppFonts.plusJakarta(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasSearched && !_isSearching && _searchError == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_results.length} result${_results.length == 1 ? '' : 's'} found',
                  style: AppFonts.plusJakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
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
                  if (_selectedType != null)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: PremiumChip(
                        label: _selectedType!,
                        icon: Icons.account_balance_outlined,
                        selected: true,
                        onTap: () {
                          setState(() => _selectedType = null);
                          _runSearch();
                        },
                      ),
                    ),
                  if (_universityController.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: PremiumChip(
                        label: _universityController.text.trim(),
                        icon: Icons.apartment_outlined,
                        selected: true,
                        onTap: () {
                          _universityController.clear();
                          _runSearch();
                        },
                      ),
                    ),
                ],
              ),
            ),
          if (searchSuggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: PremiumCard(
                radius: tokens.buttonRadius,
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: searchSuggestions.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: tokens.borderSubtle,
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = searchSuggestions[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        ),
                        title: Text(
                          suggestion,
                          style: AppFonts.plusJakarta(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          _searchController.text = suggestion;
                          _searchController.selection = TextSelection.fromPosition(
                            TextPosition(offset: suggestion.length),
                          );
                          setState(() => _liveQuery = '');
                          _runSearch();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          if (_showFilters)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: PremiumCard(
                  radius: tokens.cardRadius,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                  children: [
                    statesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (states) {
                        final uniqueStates =
                            CollegeConstants.dedupePreserveOrder(states);
                        final stateValue = CollegeConstants.clampToAllowed(
                          _selectedState,
                          uniqueStates,
                        );
                        return DropdownButtonFormField<String>(
                          key: ValueKey('state-$stateValue'),
                          initialValue: stateValue,
                          decoration: _filterDecoration(context, 'State'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All States'),
                            ),
                            ...uniqueStates.map(
                              (st) =>
                                  DropdownMenuItem(value: st, child: Text(st)),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedState = v);
                            _runSearch();
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SearchableTextFormField(
                      controller: _cityController,
                      decoration: _filterDecoration(context, 'City').copyWith(
                        hintText: 'e.g. Mumbai, Pune, Delhi',
                      ),
                      optionsBuilder: CollegeSuggestionUtils.citySuggestions,
                      onChanged: (_) {
                        _debounce?.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 350), _runSearch);
                        setState(() {});
                      },
                      onSubmitted: (_) => _runSearch(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SearchableTextFormField(
                      controller: _universityController,
                      decoration: _filterDecoration(context, 'University').copyWith(
                        hintText:
                            'e.g. Vasantrao Naik Marathwada Krishi Vidyapeeth',
                      ),
                      optionsBuilder: CollegeSuggestionUtils.universitySuggestions,
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
                      data: (courses) {
                        final uniqueCourses =
                            CollegeConstants.dedupePreserveOrder(courses);
                        final courseValue = CollegeConstants.clampToAllowed(
                          _selectedCourse,
                          uniqueCourses,
                        );
                        return DropdownButtonFormField<String>(
                          key: ValueKey('course-$courseValue'),
                          initialValue: courseValue,
                          decoration: _filterDecoration(context, 'Course'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Courses'),
                            ),
                            ...uniqueCourses.map(
                              (c) =>
                                  DropdownMenuItem(value: c, child: Text(c)),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedCourse = v);
                            _runSearch();
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      key: ValueKey('type-$_selectedType'),
                      initialValue: _selectedType,
                      decoration: _filterDecoration(context, 'College Type'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All College Types'),
                        ),
                        ...CollegeConstants.collegeTypes.map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              '${type[0].toUpperCase()}${type.substring(1)}',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedType = v);
                        _runSearch();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Builder(
                      builder: (context) {
                        final categoryValue = CollegeConstants.clampToAllowed(
                          _selectedCategory,
                          CollegeConstants.collegeCategories,
                        );
                        return DropdownButtonFormField<String>(
                          key: ValueKey('category-$categoryValue'),
                          initialValue: categoryValue,
                          decoration: _filterDecoration(context, 'Category'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ...CollegeConstants.collegeCategories.map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedCategory = v);
                            _runSearch();
                          },
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('Reset Filters'),
                      ),
                    ),
                  ],
                ),
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
                    : _results.isEmpty &&
                            !_isSearching &&
                            !_hasSearched &&
                            _searchController.text.trim().isEmpty &&
                            !_hasActiveFilters
                        ? PremiumSearchDiscoveryPanel(
                            onQuerySelected: (query) {
                              _searchController.text = query;
                              _runSearch();
                            },
                          )
                        : _results.isEmpty &&
                                !_isSearching &&
                                !_hasSearched &&
                                _searchController.text.trim().isNotEmpty
                            ? AsyncEmptyView(
                                icon: Icons.keyboard_return_rounded,
                                title: 'Press Search',
                                subtitle:
                                    'Tap Search to find colleges matching "${_searchController.text.trim()}"',
                                action: FilledButton.icon(
                                  onPressed: _runSearch,
                                  icon: const Icon(Icons.search_rounded),
                                  label: const Text('Search'),
                                ),
                              )
                        : _results.isEmpty && _hasSearched
                            ? AsyncEmptyView(
                                icon: Icons.search_off_rounded,
                                title: 'Can\'t find your college?',
                                subtitle:
                                    'No matching colleges found.',
                                action: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: () =>
                                          context.go(RouteNames.requestCollege),
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('+ Add My College'),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: _resetFilters,
                                      icon: const Icon(Icons.restart_alt_rounded),
                                      label: const Text('Reset Filters'),
                                    ),
                                  ],
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
                                        const EdgeInsets.only(bottom: 14),
                                    child: CollegeCardWidget.fromCollege(
                                      college,
                                      isSelectedForCompare:
                                          basket.contains(college.id),
                                      onCompareToggle: () {
                                        final message = ref
                                            .read(compareBasketProvider
                                                .notifier)
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
