import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/dialog_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../student_life/models/student_life_models.dart';
import '../providers/college_community_feed_provider.dart';
import '../services/college_community_feed_service.dart';
import '../widgets/college_community_post_card.dart';

class CollegeCommunityFeedScreen extends ConsumerStatefulWidget {
  final String collegeId;
  final String collegeName;

  const CollegeCommunityFeedScreen({
    required this.collegeId,
    required this.collegeName,
    super.key,
  });

  @override
  ConsumerState<CollegeCommunityFeedScreen> createState() =>
      _CollegeCommunityFeedScreenState();
}

class _CollegeCommunityFeedScreenState
    extends ConsumerState<CollegeCommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<StudentCommunityPostModel> _posts = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = false;
  bool _hasMore = true;
  String _feedMode = StudentLifeConstants.feedLatest;

  final _postController = TextEditingController();
  final _pollOptionAController = TextEditingController();
  final _pollOptionBController = TextEditingController();
  String _postType = StudentLifeConstants.postDiscussion;
  bool _postAnonymous = false;
  final List<String> _pendingImageUrls = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _postController.dispose();
    _pollOptionAController.dispose();
    _pollOptionBController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final modes = [
      StudentLifeConstants.feedLatest,
      StudentLifeConstants.feedTrending,
      StudentLifeConstants.feedPinned,
    ];
    final nextMode = modes[_tabController.index];
    if (nextMode != _feedMode) {
      setState(() {
        _feedMode = nextMode;
        _posts.clear();
        _cursor = null;
        _hasMore = true;
      });
      _loadMore();
    }
  }

  Future<void> _bootstrap() async {
    await ref.read(collegeCommunityFeedRepositoryProvider).ensureCollegeCommunity(
          collegeId: widget.collegeId,
          collegeName: widget.collegeName,
        );
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page = await ref
          .read(collegeCommunityFeedRepositoryProvider)
          .fetchFeedPage(
            collegeId: widget.collegeId,
            mode: _feedMode,
            startAfter: _cursor,
          );
      if (!mounted) return;
      setState(() {
        final existingIds = _posts.map((p) => p.id).toSet();
        _posts.addAll(page.items.where((p) => !existingIds.contains(p.id)));
        _cursor = page.lastDocument;
        _hasMore = page.hasMore;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _posts.clear();
      _cursor = null;
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final verifiedAsync = ref.watch(isVerifiedCommunityPosterProvider);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: tokens.surfaceElevated,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community',
              style: AppFonts.plusJakarta(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: tokens.textPrimary,
              ),
            ),
            Text(
              widget.collegeName,
              style: AppFonts.plusJakarta(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: tokens.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: tokens.textTertiary,
          labelStyle: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w600),
          indicatorColor: primary,
          tabs: const [
            Tab(text: 'Latest'),
            Tab(text: 'Trending'),
            Tab(text: 'Pinned'),
          ],
        ),
      ),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: _composePanel(verifiedAsync)),
                Expanded(child: _feedList()),
              ],
            )
          : Column(
              children: [
                Expanded(child: _feedList()),
                _composePanel(verifiedAsync),
              ],
            ),
    );
  }

  Widget _feedList() {
    final tokens = context.tokens;

    if (_posts.isEmpty && _loading) {
      return const AsyncLoadingView();
    }
    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: AsyncEmptyView(
                icon: Icons.forum_outlined,
                title: 'No posts yet',
                subtitle: 'Verified students and alumni can start the conversation.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : OutlinedButton(
                        onPressed: _loadMore,
                        child: Text(
                          'Load more',
                          style: AppFonts.plusJakarta(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: CollegeCommunityPostCard(
              post: _posts[index],
              onChanged: _refresh,
            ),
          );
        },
      ),
    );
  }

  Widget _composePanel(AsyncValue<bool> verifiedAsync) {
    return verifiedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (verified) {
        if (!verified) {
          final tokens = context.tokens;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              border: Border(top: BorderSide(color: tokens.borderSubtle)),
            ),
            child: Text(
              'Verify as a student or alumni to post in this community.',
              style: AppFonts.plusJakarta(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: tokens.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final tokens = context.tokens;
        final primary = Theme.of(context).colorScheme.primary;
        final inputBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
          borderSide: BorderSide(color: tokens.borderSubtle),
        );
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            border: Border(
              top: BorderSide(color: tokens.borderSubtle),
              right: BorderSide(color: tokens.borderSubtle),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create post',
                style: AppFonts.plusJakarta(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Text'),
                      labelStyle: AppFonts.plusJakarta(fontSize: 12.5, fontWeight: FontWeight.w600),
                      selected: _postType == StudentLifeConstants.postDiscussion,
                      onSelected: (_) => setState(() =>
                          _postType = StudentLifeConstants.postDiscussion),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Poll'),
                      labelStyle: AppFonts.plusJakarta(fontSize: 12.5, fontWeight: FontWeight.w600),
                      selected: _postType == StudentLifeConstants.postPoll,
                      onSelected: (_) => setState(
                          () => _postType = StudentLifeConstants.postPoll),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Announcement'),
                      labelStyle: AppFonts.plusJakarta(fontSize: 12.5, fontWeight: FontWeight.w600),
                      selected:
                          _postType == StudentLifeConstants.postAnnouncement,
                      onSelected: (_) => setState(() =>
                          _postType = StudentLifeConstants.postAnnouncement),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_postType == StudentLifeConstants.postPoll) ...[
                TextField(
                  controller: _postController,
                  style: AppFonts.plusJakarta(fontSize: 13.5, color: tokens.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Poll question',
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pollOptionAController,
                  style: AppFonts.plusJakarta(fontSize: 13.5, color: tokens.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Option 1',
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pollOptionBController,
                  style: AppFonts.plusJakarta(fontSize: 13.5, color: tokens.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Option 2',
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    isDense: true,
                  ),
                ),
              ] else
                TextField(
                  controller: _postController,
                  maxLines: 3,
                  style: AppFonts.plusJakarta(fontSize: 13.5, color: tokens.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Share something with your college community...',
                    border: inputBorder,
                    enabledBorder: inputBorder,
                  ),
                ),
              if (_pendingImageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _pendingImageUrls
                      .map(
                        (url) => Chip(
                          label: Text(
                            'Image attached',
                            style: AppFonts.plusJakarta(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          onDeleted: () =>
                              setState(() => _pendingImageUrls.remove(url)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Anonymous'),
                    labelStyle: AppFonts.plusJakarta(fontSize: 12.5, fontWeight: FontWeight.w600),
                    selected: _postAnonymous,
                    onSelected: (v) => setState(() => _postAnonymous = v),
                  ),
                  IconButton(
                    icon: Icon(Icons.image_outlined, color: tokens.textSecondary),
                    tooltip: 'Add image',
                    onPressed: _uploading ? null : _pickImage,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _uploading ? null : _submitPost,
                    style: FilledButton.styleFrom(backgroundColor: primary),
                    icon: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'Post',
                      style: AppFonts.plusJakarta(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    setState(() => _uploading = true);
    try {
      final ext = file.extension ?? 'jpg';
      final url = await ref.read(collegeCommunityStorageServiceProvider).uploadPostImage(
            collegeId: widget.collegeId,
            userId: authUser.uid,
            postId: 'draft_${DateTime.now().millisecondsSinceEpoch}',
            extension: ext,
            bytes: file.bytes!,
          );
      setState(() => _pendingImageUrls.add(url));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submitPost() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    final user = await ref.read(currentUserDetailProvider.future);
    if (authUser == null || user == null) return;

    try {
      setState(() => _uploading = true);
      if (_postType == StudentLifeConstants.postPoll) {
        if (_postController.text.trim().isEmpty) return;
        await ref.read(collegeCommunityFeedRepositoryProvider).createPost(
              collegeId: widget.collegeId,
              collegeName: widget.collegeName,
              authorId: authUser.uid,
              authorDisplayName: user.effectivePublicDisplayName,
              isAnonymous: user.usesAnonymousPublicDisplayName,
              postType: _postType,
              content: '',
              pollQuestion: _postController.text.trim(),
              pollOptions: [
                PollOptionModel(
                  id: 'opt_a',
                  label: _pollOptionAController.text.trim().isEmpty
                      ? 'Option A'
                      : _pollOptionAController.text.trim(),
                ),
                PollOptionModel(
                  id: 'opt_b',
                  label: _pollOptionBController.text.trim().isEmpty
                      ? 'Option B'
                      : _pollOptionBController.text.trim(),
                ),
              ],
            );
      } else {
        if (_postController.text.trim().isEmpty &&
            _pendingImageUrls.isEmpty) {
          return;
        }
        await ref.read(collegeCommunityFeedRepositoryProvider).createPost(
              collegeId: widget.collegeId,
              collegeName: widget.collegeName,
              authorId: authUser.uid,
              authorDisplayName: user.effectivePublicDisplayName,
              isAnonymous: user.usesAnonymousPublicDisplayName,
              postType: _postType,
              content: _postController.text.trim(),
              imageUrls: List.from(_pendingImageUrls),
            );
      }

      _postController.clear();
      _pollOptionAController.clear();
      _pollOptionBController.clear();
      setState(() {
        _postAnonymous = false;
        _pendingImageUrls.clear();
      });
      await _refresh();
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Post published');
      }
    } on CollegeCommunityFeedException catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}
