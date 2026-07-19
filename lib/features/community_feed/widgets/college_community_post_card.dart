import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/dialog_helper.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../student_life/models/student_life_models.dart';
import '../../student_life/utils/student_life_filter_utils.dart';
import '../providers/college_community_feed_provider.dart';
import '../services/college_community_feed_service.dart';

class CollegeCommunityPostCard extends ConsumerStatefulWidget {
  final StudentCommunityPostModel post;
  final VoidCallback? onChanged;

  const CollegeCommunityPostCard({
    required this.post,
    this.onChanged,
    super.key,
  });

  @override
  ConsumerState<CollegeCommunityPostCard> createState() =>
      _CollegeCommunityPostCardState();
}

class _CollegeCommunityPostCardState
    extends ConsumerState<CollegeCommunityPostCard> {
  bool _commentsExpanded = false;
  String? _replyToCommentId;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  StudentCommunityPostModel get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM · h:mm a');
    final user = ref.watch(authStateProvider).valueOrNull;
    final isLiked = user != null && post.likedBy.contains(user.uid);
    final isAdminAsync = ref.watch(isAdminProvider);
    final typeLabel = post.isPoll
        ? 'Poll'
        : post.isAnnouncement
            ? 'Announcement'
            : post.hasImages
                ? 'Photo'
                : 'Discussion';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.isPinned)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.push_pin, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Pinned',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: Text(
                    post.authorDisplayName.isNotEmpty
                        ? post.authorDisplayName[0].toUpperCase()
                        : 'S',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorDisplayName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.isVerifiedStudent) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified,
                                size: 14, color: AppTheme.secondaryColor),
                          ],
                        ],
                      ),
                      Text(
                        '$typeLabel · ${dateFmt.format(post.createdAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'report':
                        _reportPost();
                      case 'pin':
                        _pinPost(true);
                      case 'unpin':
                        _pinPost(false);
                      case 'hide':
                        _hidePost();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'report', child: Text('Report')),
                    if (isAdminAsync.valueOrNull == true) ...[
                      PopupMenuItem(
                        value: post.isPinned ? 'unpin' : 'pin',
                        child: Text(post.isPinned ? 'Unpin' : 'Pin post'),
                      ),
                      const PopupMenuItem(value: 'hide', child: Text('Hide post')),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (post.isPoll) ...[
              Text(
                post.pollQuestion,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              ...post.pollOptions.map(
                (opt) => _PollOptionTile(post: post, option: opt),
              ),
            ] else ...[
              if (post.content.isNotEmpty)
                Text(post.content, style: GoogleFonts.poppins(height: 1.5)),
              if (post.hasImages) ...[
                const SizedBox(height: 10),
                ...post.imageUrls.map(
                  (url) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => Container(
                          height: 120,
                          color: AppTheme.gray100,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isLiked ? AppTheme.errorColor : AppTheme.gray500,
                  ),
                  onPressed: user == null ? null : () => _toggleLike(user.uid),
                ),
                if (post.likeCount > 0)
                  Text('${post.likeCount}',
                      style: GoogleFonts.poppins(fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  onPressed: () =>
                      setState(() => _commentsExpanded = !_commentsExpanded),
                ),
                if (post.commentCount > 0)
                  Text('${post.commentCount}',
                      style: GoogleFonts.poppins(fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  onPressed: _sharePost,
                ),
                if (post.shareCount > 0)
                  Text('${post.shareCount}',
                      style: GoogleFonts.poppins(fontSize: 12)),
                const Spacer(),
                if (post.engagementScore >= 5 && !post.isPinned)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Trending',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
              ],
            ),
            if (_commentsExpanded) _buildCommentsSection(user),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(dynamic user) {
    final commentsAsync = ref.watch(collegeCommunityCommentsProvider(post.id));
    final verifiedAsync = ref.watch(isVerifiedCommunityPosterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => Text('$e'),
          data: (comments) {
            final topLevel =
                comments.where((c) => !c.isReply).toList();
            final repliesByParent = <String, List<StudentCommunityCommentModel>>{};
            for (final c in comments.where((c) => c.isReply)) {
              final parent = c.parentCommentId!;
              repliesByParent.putIfAbsent(parent, () => []).add(c);
            }
            return Column(
              children: topLevel.map((comment) {
                final replies = repliesByParent[comment.id] ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CommentTile(
                      comment: comment,
                      onReply: () => setState(() {
                        _replyToCommentId = comment.id;
                        _commentController.text = '';
                      }),
                      onReport: () => _reportComment(comment),
                    ),
                    ...replies.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: _CommentTile(
                          comment: r,
                          isReply: true,
                          onReport: () => _reportComment(r),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
        verifiedAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (verified) {
            if (!verified || user == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_replyToCommentId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          'Replying to comment',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.gray500,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _replyToCommentId = null),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: _replyToCommentId != null
                              ? 'Write a reply...'
                              : 'Add a comment...',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, size: 18),
                      onPressed: () => _submitComment(user.uid),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggleLike(String userId) async {
    await ref
        .read(collegeCommunityFeedRepositoryProvider)
        .toggleLikePost(postId: post.id, userId: userId);
    widget.onChanged?.call();
  }

  Future<void> _sharePost() async {
    final link = RouteNames.collegeCommunityFeedPath(
      post.collegeId,
      name: post.collegeName,
    );
    await Clipboard.setData(ClipboardData(text: link));
    await ref
        .read(collegeCommunityFeedRepositoryProvider)
        .incrementShareCount(post.id);
    widget.onChanged?.call();
    if (mounted) {
      SnackBarHelper.showSuccessSnackBar(
        context,
        message: 'Link copied to clipboard',
      );
    }
  }

  Future<void> _submitComment(String userId) async {
    final user = await ref.read(currentUserDetailProvider.future);
    if (_commentController.text.trim().isEmpty) return;
    try {
      await ref.read(collegeCommunityFeedRepositoryProvider).addComment(
            post: post,
            authorId: userId,
            authorDisplayName: user?.displayName ?? 'Student',
            content: _commentController.text.trim(),
            parentCommentId: _replyToCommentId,
          );
      _commentController.clear();
      setState(() => _replyToCommentId = null);
      widget.onChanged?.call();
    } on CollegeCommunityFeedException catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: e.message);
      }
    }
  }

  Future<void> _reportPost() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(collegeCommunityFeedRepositoryProvider).reportPost(
            postId: post.id,
            communityId: post.communityId,
            reporterId: user.uid,
            reason: 'Inappropriate content',
          );
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(context, message: 'Report submitted');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, message: '$e');
      }
    }
  }

  Future<void> _reportComment(StudentCommunityCommentModel comment) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref.read(collegeCommunityFeedRepositoryProvider).reportComment(
          commentId: comment.id,
          postId: post.id,
          communityId: post.communityId,
          reporterId: user.uid,
          reason: 'Inappropriate comment',
        );
    if (mounted) {
      SnackBarHelper.showSuccessSnackBar(context, message: 'Report submitted');
    }
  }

  Future<void> _pinPost(bool pinned) async {
    await ref
        .read(collegeCommunityFeedRepositoryProvider)
        .pinPost(post.id, pinned: pinned);
    widget.onChanged?.call();
  }

  Future<void> _hidePost() async {
    await ref.read(collegeCommunityFeedRepositoryProvider).hidePost(post.id);
    widget.onChanged?.call();
  }
}

class _CommentTile extends StatelessWidget {
  final StudentCommunityCommentModel comment;
  final VoidCallback? onReply;
  final VoidCallback? onReport;
  final bool isReply;

  const _CommentTile({
    required this.comment,
    this.onReply,
    this.onReport,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        comment.authorDisplayName,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.content, style: GoogleFonts.poppins(fontSize: 12)),
          if (!isReply && onReply != null)
            TextButton(
              onPressed: onReply,
              child: const Text('Reply'),
            ),
        ],
      ),
      trailing: onReport != null
          ? IconButton(
              icon: const Icon(Icons.flag_outlined, size: 16),
              onPressed: onReport,
            )
          : null,
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
                  await ref
                      .read(collegeCommunityFeedRepositoryProvider)
                      .votePoll(
                        postId: post.id,
                        userId: user.uid,
                        optionId: option.id,
                      );
                } on CollegeCommunityFeedException catch (e) {
                  if (context.mounted) {
                    SnackBarHelper.showErrorSnackBar(
                      context,
                      message: e.message,
                    );
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
              Expanded(
                child: Text(option.label, style: GoogleFonts.poppins(fontSize: 13)),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.gray500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
