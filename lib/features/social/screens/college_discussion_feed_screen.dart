import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/social_constants.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('College Discussion Feed'),
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Set your college in profile to see the discussion feed.',
                  style: GoogleFonts.poppins(color: AppTheme.gray600),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: _items.isEmpty && !_loading
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No discussions yet for $collegeName',
                            style: GoogleFonts.poppins(color: AppTheme.gray500),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          if (_loading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return Center(
                            child: TextButton(
                              onPressed: _loadMore,
                              child: const Text('Load more'),
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
    final dateFmt = DateFormat('MMM d, h:mm a');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      item.feedTypeLabel,
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                  const Spacer(),
                  Text(
                    dateFmt.format(item.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.gray500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.isAnonymous ? 'Anonymous Student' : item.authorName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (item.preview.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.preview,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.gray700,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.likeCount > 0) ...[
                    const Icon(Icons.favorite_border, size: 14, color: AppTheme.gray500),
                    const SizedBox(width: 4),
                    Text('${item.likeCount}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                  if (item.replyCount > 0) ...[
                    const Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.gray500),
                    const SizedBox(width: 4),
                    Text('${item.replyCount}', style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
