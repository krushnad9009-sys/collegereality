import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/widgets/dialog_helper.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/status_badge.dart';
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
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final typeLabel = post.isPoll
        ? 'Poll'
        : post.isAnnouncement
            ? 'Announcement'
            : post.hasImages
                ? 'Photo'
                : 'Discussion';

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isPinned)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: StatusBadge(
                label: 'Pinned',
                icon: Icons.push_pin_rounded,
                color: primary,
                iconSize: 12,
              ),
            ),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withValues(alpha: 0.12),
                child: Text(
                  post.authorDisplayName.isNotEmpty
                      ? post.authorDisplayName[0].toUpperCase()
                      : 'S',
                  style: AppFonts.plusJakarta(
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
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
                            style: AppFonts.plusJakarta(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: tokens.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isVerifiedStudent) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded,
                              size: 14, color: AppTheme.secondaryColor),
                        ],
                      ],
                    ),
                    Text(
                      '$typeLabel · ${dateFmt.format(post.createdAt)}',
                      style: AppFonts.plusJakarta(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: tokens.textTertiary),
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
          const SizedBox(height: AppSpacing.sm),
          if (post.isPoll) ...[
            Text(
              post.pollQuestion,
              style: AppFonts.plusJakarta(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...post.pollOptions.map(
              (opt) => _PollOptionTile(post: post, option: opt),
            ),
          ] else ...[
            if (post.content.isNotEmpty)
              Text(
                post.content,
                style: AppFonts.plusJakarta(
                  fontSize: 14,
                  height: 1.5,
                  color: tokens.textPrimary,
                ),
              ),
            if (post.hasImages) ...[
              const SizedBox(height: 10),
              ...post.imageUrls.map(
                (url) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => Container(
                        height: 120,
                        color: tokens.surfaceMuted,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: tokens.textTertiary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: isLiked ? AppTheme.errorColor : tokens.textTertiary,
                ),
                onPressed: user == null ? null : () => _toggleLike(user.uid),
              ),
              if (post.likeCount > 0)
                Text(
                  '${post.likeCount}',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              IconButton(
                icon: Icon(Icons.chat_bubble_outline_rounded,
                    size: 20, color: tokens.textTertiary),
                onPressed: () =>
                    setState(() => _commentsExpanded = !_commentsExpanded),
              ),
              if (post.commentCount > 0)
                Text(
                  '${post.commentCount}',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              IconButton(
                icon: Icon(Icons.share_outlined,
                    size: 20, color: tokens.textTertiary),
                onPressed: _sharePost,
              ),
              if (post.shareCount > 0)
                Text(
                  '${post.shareCount}',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              const Spacer(),
              if (post.engagementScore >= 5 && !post.isPinned)
                StatusBadge(
                  label: 'Trending',
                  icon: Icons.local_fire_department_rounded,
                  color: AppTheme.warningColor,
                  iconSize: 12,
                  fontSize: 10.5,
                ),
            ],
          ),
          if (_commentsExpanded) _buildCommentsSection(user),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(dynamic user) {
    final commentsAsync = ref.watch(collegeCommunityCommentsProvider(post.id));
    final verifiedAsync = ref.watch(isVerifiedCommunityPosterProvider);
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(height: 1, color: tokens.borderSubtle),
        ),
        commentsAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          error: (e, _) => Text(
            '$e',
            style: AppFonts.plusJakarta(fontSize: 12, color: tokens.textTertiary),
          ),
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
                          style: AppFonts.plusJakarta(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: tokens.textTertiary,
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
                        style: AppFonts.plusJakarta(
                          fontSize: 13,
                          color: tokens.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _replyToCommentId != null
                              ? 'Write a reply...'
                              : 'Add a comment...',
                          hintStyle: AppFonts.plusJakarta(
                            fontSize: 13,
                            color: tokens.textTertiary,
                          ),
                          filled: true,
                          fillColor: tokens.surfaceMuted,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(tokens.buttonRadius),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send_rounded,
                          size: 18, color: Theme.of(context).colorScheme.primary),
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
            authorDisplayName: user?.effectivePublicDisplayName ?? 'Student',
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
    final tokens = context.tokens;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        comment.authorDisplayName,
        style: AppFonts.plusJakarta(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: tokens.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.content,
            style: AppFonts.plusJakarta(fontSize: 12.5, color: tokens.textSecondary),
          ),
          if (!isReply && onReply != null)
            TextButton(
              onPressed: onReply,
              child: const Text('Reply'),
            ),
        ],
      ),
      trailing: onReport != null
          ? IconButton(
              icon: Icon(Icons.flag_outlined, size: 16, color: tokens.textTertiary),
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
    final tokens = context.tokens;

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
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: tokens.borderSubtle),
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  style: AppFonts.plusJakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: AppFonts.plusJakarta(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
