import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/social_constants.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
import '../../auth/providers/user_provider.dart';
import '../models/social_models.dart';
import '../providers/social_provider.dart';

class CollegeDiscussionFeedScreen extends ConsumerStatefulWidget {
  const CollegeDiscussionFeedScreen({super.key});

  @override
  ConsumerState<CollegeDiscussionFeedScreen> createState() =>
      _CollegeDiscussionFeedScreenState();
}

class _CollegeDiscussionFeedScreenState
    extends ConsumerState<CollegeDiscussionFeedScreen> {
  final List<DiscussionFeedItem> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _collegeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    final user = ref.read(currentUserDetailProvider).valueOrNull;
    if (user?.collegeId == null) return;
    _collegeId = user!.collegeId;
    setState(() {
      _items.clear();
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _collegeId == null) return;
    setState(() => _loading = true);
    try {
      final page = await ref.read(socialRepositoryProvider).fetchDiscussionFeedPage(
            collegeId: _collegeId!,
            limit: SocialConstants.defaultPageSize,
          );
      if (mounted) {
        setState(() {
          _items.addAll(page.items);
          _hasMore = page.hasMore;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailProvider).valueOrNull;
    final collegeName = user?.collegeName ?? 'Your College';
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.surfaceMuted,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: tokens.surfaceElevated,
        title: Text(
          'College Discussion Feed',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: tokens.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            tooltip: 'Open college chat',
            onPressed: () => context.push(RouteNames.community),
          ),
        ],
      ),
      body: user?.collegeId == null
          ? AsyncEmptyView(
              icon: Icons.school_outlined,
              title: 'Set your college first',
              subtitle: 'Add your college in Profile to see the discussion feed.',
            )
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: _items.isEmpty && !_loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.55,
                          child: AsyncEmptyView(
                            icon: Icons.forum_outlined,
                            title: 'No discussions yet',
                            subtitle: 'Be the first to start a discussion for $collegeName.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          if (_loading) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Center(
                              child: OutlinedButton(
                                onPressed: _loadMore,
                                child: Text(
                                  'Load more',
                                  style: AppFonts.plusJakarta(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return _FeedCard(
                          item: _items[index],
                          onTap: () {
                            if (_items[index].actionRoute.isNotEmpty) {
                              context.push(_items[index].actionRoute);
                            }
                          },
                        );
                      },
                    ),
            ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final DiscussionFeedItem item;
  final VoidCallback onTap;

  const _FeedCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final dateFmt = DateFormat('MMM d, h:mm a');

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.feedTypeLabel,
                  style: AppFonts.plusJakarta(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateFmt.format(item.createdAt),
                style: AppFonts.plusJakarta(fontSize: 11, color: tokens.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.isAnonymous ? 'Anonymous Student' : item.authorName,
            style: AppFonts.plusJakarta(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: tokens.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (item.preview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.preview,
              style: AppFonts.plusJakarta(
                fontSize: 13,
                color: tokens.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (item.likeCount > 0) ...[
                Icon(Icons.favorite_border_rounded, size: 14, color: tokens.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${item.likeCount}',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (item.replyCount > 0) ...[
                Icon(Icons.chat_bubble_outline_rounded, size: 14, color: tokens.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${item.replyCount}',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
