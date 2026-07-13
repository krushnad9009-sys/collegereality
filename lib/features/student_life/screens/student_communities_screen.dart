import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../models/student_life_models.dart';
import '../providers/student_life_provider.dart';
import '../services/firestore_student_life_service.dart';
import '../utils/student_life_filter_utils.dart';

class StudentCommunitiesScreen extends ConsumerWidget {
  const StudentCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(filteredCommunitiesProvider);
    final filters = ref.watch(communityFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Student Communities'),
      ),
      body: communitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Verified students only can post and comment.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search communities...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (q) => ref
                  .read(communityFilterProvider.notifier)
                  .update(filters.copyWith(searchQuery: q)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilterChip(
                  label: const Text('Branch'),
                  selected: filters.communityType == StudentLifeConstants.communityBranch,
                  onSelected: (_) => ref.read(communityFilterProvider.notifier).update(
                        filters.copyWith(communityType: StudentLifeConstants.communityBranch),
                      ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Year'),
                  selected: filters.communityType == StudentLifeConstants.communityYear,
                  onSelected: (_) => ref.read(communityFilterProvider.notifier).update(
                        filters.copyWith(communityType: StudentLifeConstants.communityYear),
                      ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('All'),
                  selected: filters.communityType == null,
                  onSelected: (_) => ref
                      .read(communityFilterProvider.notifier)
                      .update(filters.copyWith(clearType: true)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(child: Text('No communities found'))
            else
              ...items.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                      child: Icon(
                        c.communityType == StudentLifeConstants.communityBranch
                            ? Icons.account_tree_outlined
                            : Icons.calendar_today_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(c.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${c.branchOrYear} · ${c.collegeName}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RouteNames.studentLifeCommunityBoardPath(c.id)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CommunityBoardScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityBoardScreen({required this.communityId, super.key});

  @override
  ConsumerState<CommunityBoardScreen> createState() => _CommunityBoardScreenState();
}

class _CommunityBoardScreenState extends ConsumerState<CommunityBoardScreen> {
  final _postController = TextEditingController();
  String _postType = StudentLifeConstants.postDiscussion;
  bool _postAnonymous = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final communityAsync = ref.watch(communityByIdProvider(widget.communityId));
    final postsAsync = ref.watch(communityPostsProvider(widget.communityId));
    final verifiedAsync = ref.watch(isVerifiedForStudentLifeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: communityAsync.when(
          data: (c) => Text(c?.name ?? 'Community'),
          loading: () => const Text('Community'),
          error: (_, __) => const Text('Community'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet. Be the first!'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (_, i) => _PostCard(
                    post: posts[i],
                    communityId: widget.communityId,
                    onReport: () => _reportPost(posts[i]),
                  ),
                );
              },
            ),
          ),
          verifiedAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (verified) {
              if (!verified) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Verify your student profile to post and comment.',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
                  ),
                );
              }
              return _composeBar();
            },
          ),
        ],
      ),
    );
  }

  Widget _composeBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: AppTheme.gray200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Discussion'),
                  selected: _postType == StudentLifeConstants.postDiscussion,
                  onSelected: (_) =>
                      setState(() => _postType = StudentLifeConstants.postDiscussion),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Announcement'),
                  selected: _postType == StudentLifeConstants.postAnnouncement,
                  onSelected: (_) =>
                      setState(() => _postType = StudentLifeConstants.postAnnouncement),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Poll'),
                  selected: _postType == StudentLifeConstants.postPoll,
                  onSelected: (_) => setState(() => _postType = StudentLifeConstants.postPoll),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Post anonymously'),
                selected: _postAnonymous,
                onSelected: (v) => setState(() => _postAnonymous = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postController,
                  decoration: InputDecoration(
                    hintText: _postType == StudentLifeConstants.postPoll
                        ? 'Poll question...'
                        : 'Write a post...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _submitPost,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitPost() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    final user = await ref.read(currentUserDetailProvider.future);
    if (authUser == null || user == null) return;
    if (_postController.text.trim().isEmpty) return;

    try {
      final isVerified = await ref.read(studentLifeRepositoryProvider).isUserVerified(authUser.uid);
      if (_postType == StudentLifeConstants.postPoll) {
        await ref.read(studentLifeRepositoryProvider).createCommunityPost(
              communityId: widget.communityId,
              authorId: authUser.uid,
              authorDisplayName: user.displayName ?? 'Student',
              isVerifiedStudent: isVerified,
              postType: _postType,
              content: '',
              pollQuestion: _postController.text.trim(),
              pollOptions: [
                const PollOptionModel(id: 'opt_a', label: 'Option A'),
                const PollOptionModel(id: 'opt_b', label: 'Option B'),
              ],
              isAnonymous: _postAnonymous,
            );
      } else {
        await ref.read(studentLifeRepositoryProvider).createCommunityPost(
              communityId: widget.communityId,
              authorId: authUser.uid,
              authorDisplayName: user.displayName ?? 'Student',
              isVerifiedStudent: isVerified,
              postType: _postType,
              content: _postController.text.trim(),
              isAnonymous: _postAnonymous,
            );
      }
      _postController.clear();
      setState(() => _postAnonymous = false);
      if (mounted) SnackBarHelper.showSuccessSnackBar(context, message: 'Post published');
    } on StudentLifeException catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.message);
    }
  }

  Future<void> _reportPost(StudentCommunityPostModel post) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(studentLifeRepositoryProvider).reportPost(
            postId: post.id,
            communityId: widget.communityId,
            reporterId: user.uid,
            reason: 'Inappropriate content',
          );
      if (mounted) SnackBarHelper.showSuccessSnackBar(context, message: 'Report submitted');
    } catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }
}

class _PostCard extends ConsumerWidget {
  final StudentCommunityPostModel post;
  final String communityId;
  final VoidCallback onReport;

  const _PostCard({
    required this.post,
    required this.communityId,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('d MMM · h:mm a');
    final typeLabel = post.isPoll
        ? 'Poll'
        : post.isAnnouncement
            ? 'Announcement'
            : 'Discussion';

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorDisplayName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text(
                        '$typeLabel · ${dateFmt.format(post.createdAt)}',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.gray500),
                      ),
                    ],
                  ),
                ),
                if (post.isVerifiedStudent)
                  Icon(Icons.verified, size: 16, color: AppTheme.secondaryColor),
                IconButton(
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  onPressed: onReport,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (post.isPoll) ...[
              Text(post.pollQuestion,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              ...post.pollOptions.map(
                (opt) => _PollOptionTile(post: post, option: opt),
              ),
            ] else ...[
              Text(post.content, style: GoogleFonts.poppins(height: 1.5)),
            ],
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${post.imageUrls.length} image(s) attached',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
            ],
            if (post.pdfUrls.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...post.pdfUrls.map(
                (url) => TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(url)),
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('View PDF'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: post.likeCount > 0 ? AppTheme.errorColor : AppTheme.gray500,
                  ),
                  onPressed: () async {
                    final user = ref.read(authStateProvider).valueOrNull;
                    if (user == null) return;
                    await ref.read(studentLifeRepositoryProvider).likePost(
                          postId: post.id,
                          userId: user.uid,
                        );
                  },
                ),
                if (post.likeCount > 0)
                  Text('${post.likeCount}',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray600)),
                const Spacer(),
                if (post.commentCount > 0)
                  Text('${post.commentCount} comments',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
              ],
            ),
            _CommentsSection(post: post, communityId: communityId),
          ],
        ),
      ),
    );
  }
}

class _PollOptionTile extends ConsumerWidget {
  final StudentCommunityPostModel post;
  final PollOptionModel option;

  const _PollOptionTile({required this.post, required this.option});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = pollOptionPercent(option, post.pollOptions);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: user == null
            ? null
            : () async {
                try {
                  await ref.read(studentLifeRepositoryProvider).votePoll(
                        postId: post.id,
                        userId: user.uid,
                        optionId: option.id,
                      );
                } on StudentLifeException catch (e) {
                  if (context.mounted) {
                    SnackBarHelper.showErrorSnackBar(context, message: e.message);
                  }
                }
              },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.gray200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: Text(option.label, style: GoogleFonts.poppins(fontSize: 13))),
              Text('${pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  final StudentCommunityPostModel post;
  final String communityId;

  const _CommentsSection({required this.post, required this.communityId});

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _controller = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));
    final verifiedAsync = ref.watch(isVerifiedForStudentLifeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
          label: Text('${widget.post.commentCount} comments'),
        ),
        if (_expanded)
          commentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => Text('$e'),
            data: (comments) => Column(
              children: comments
                  .map(
                    (c) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.authorDisplayName,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(c.content, style: GoogleFonts.poppins(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.flag_outlined, size: 16),
                        onPressed: () => _reportComment(c),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        verifiedAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (verified) {
            if (!verified || !_expanded) return const SizedBox.shrink();
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, size: 18),
                  onPressed: _submitComment,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _submitComment() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    final user = await ref.read(currentUserDetailProvider.future);
    if (authUser == null || user == null) return;
    if (_controller.text.trim().isEmpty) return;

    try {
      final isVerified =
          await ref.read(studentLifeRepositoryProvider).isUserVerified(authUser.uid);
      await ref.read(studentLifeRepositoryProvider).addPostComment(
            postId: widget.post.id,
            communityId: widget.communityId,
            authorId: authUser.uid,
            authorDisplayName: user.displayName ?? 'Student',
            isVerifiedStudent: isVerified,
            content: _controller.text.trim(),
          );
      _controller.clear();
    } on StudentLifeException catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.message);
    }
  }

  Future<void> _reportComment(StudentCommunityCommentModel comment) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(studentLifeRepositoryProvider).reportComment(
            commentId: comment.id,
            postId: widget.post.id,
            communityId: widget.communityId,
            reporterId: user.uid,
            reason: 'Inappropriate comment',
          );
      if (mounted) SnackBarHelper.showSuccessSnackBar(context, message: 'Report submitted');
    } catch (e) {
      if (mounted) SnackBarHelper.showErrorSnackBar(context, message: e.toString());
    }
  }
}
