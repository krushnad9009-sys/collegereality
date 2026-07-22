import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/student_life_constants.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              widget.collegeName,
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
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
    if (_posts.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.4,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_outlined,
                        size: 64,
                        color: AppTheme.primaryColor.withValues(alpha: 0.35)),
                    const SizedBox(height: 12),
                    Text(
                      'No posts yet',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Verified students and alumni can start the conversation.',
                      style: GoogleFonts.poppins(color: AppTheme.gray500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: _loadMore,
                        child: const Text('Load more'),
                      ),
              ),
            );
          }
          return CollegeCommunityPostCard(
            post: _posts[index],
            onChanged: _refresh,
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
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.gray200)),
            ),
            child: Text(
              'Verify as a student or alumni to post in this community.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
              textAlign: TextAlign.center,
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: AppTheme.gray200),
              right: BorderSide(color: AppTheme.gray200),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create post',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Text'),
                      selected: _postType == StudentLifeConstants.postDiscussion,
                      onSelected: (_) => setState(() =>
                          _postType = StudentLifeConstants.postDiscussion),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Poll'),
                      selected: _postType == StudentLifeConstants.postPoll,
                      onSelected: (_) => setState(
                          () => _postType = StudentLifeConstants.postPoll),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Announcement'),
                      selected:
                          _postType == StudentLifeConstants.postAnnouncement,
                      onSelected: (_) => setState(() =>
                          _postType = StudentLifeConstants.postAnnouncement),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_postType == StudentLifeConstants.postPoll) ...[
                TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                    hintText: 'Poll question',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pollOptionAController,
                  decoration: const InputDecoration(
                    hintText: 'Option 1',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pollOptionBController,
                  decoration: const InputDecoration(
                    hintText: 'Option 2',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ] else
                TextField(
                  controller: _postController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share something with your college community...',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (_pendingImageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _pendingImageUrls
                      .map(
                        (url) => Chip(
                          label: Text('Image attached',
                              style: GoogleFonts.poppins(fontSize: 11)),
                          onDeleted: () =>
                              setState(() => _pendingImageUrls.remove(url)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Anonymous'),
                    selected: _postAnonymous,
                    onSelected: (v) => setState(() => _postAnonymous = v),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Add image',
                    onPressed: _uploading ? null : _pickImage,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _uploading ? null : _submitPost,
                    icon: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: const Text('Post'),
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
