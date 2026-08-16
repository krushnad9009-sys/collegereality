import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_theme.dart';
import '../../../core/constants/engagement_constants.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/premium_components.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/engagement_models.dart';
import '../providers/engagement_provider.dart';

class NotificationsCenterScreen extends ConsumerStatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  ConsumerState<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState
    extends ConsumerState<NotificationsCenterScreen> {
  final _scrollController = ScrollController();
  List<UserNotificationModel> _olderItems = [];
  dynamic _lastDoc;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertScanProvider.future);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(engagementRepositoryProvider).fetchNotificationsPage(
            userId: user.uid,
            startAfter: _lastDoc,
            limit: 20,
          );
      if (!mounted) return;
      final liveIds = ref.read(filteredNotificationsProvider).valueOrNull
              ?.map((n) => n.id)
              .toSet() ??
          {};
      final existingOlder = _olderItems.map((n) => n.id).toSet();
      final newItems = page.items
          .where((n) => !liveIds.contains(n.id) && !existingOlder.contains(n.id))
          .toList();
      setState(() {
        _olderItems = [..._olderItems, ...newItems];
        _lastDoc = page.lastDocument;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<UserNotificationModel> _mergeItems(List<UserNotificationModel> live) {
    final ids = live.map((n) => n.id).toSet();
    final merged = [...live, ..._olderItems.where((n) => !ids.contains(n.id))];
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final notificationsAsync = ref.watch(filteredNotificationsProvider);
    final filters = ref.watch(notificationFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppFonts.plusJakarta(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Preferences',
            onPressed: () => context.push(RouteNames.notificationPreferences),
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all read',
            onPressed: () async {
              final user = ref.read(authStateProvider).valueOrNull;
              if (user == null) return;
              await ref.read(engagementRepositoryProvider).markAllAsRead(user.uid);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: PremiumCard(
              radius: tokens.buttonRadius,
              padding: EdgeInsets.zero,
              child: TextField(
                style: AppFonts.plusJakarta(
                  fontSize: 14,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notifications...',
                  hintStyle: AppFonts.plusJakarta(
                    fontSize: 14,
                    color: tokens.textTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: tokens.textTertiary,
                  ),
                  filled: true,
                  fillColor: tokens.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (q) =>
                    ref.read(notificationFilterProvider.notifier).setSearch(q),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filters.category == null && !filters.unreadOnly,
                  onTap: () {
                    ref.read(notificationFilterProvider.notifier).setCategory(null);
                    ref.read(notificationFilterProvider.notifier).setUnreadOnly(false);
                  },
                ),
                _FilterChip(
                  label: 'Unread',
                  selected: filters.unreadOnly,
                  onTap: () =>
                      ref.read(notificationFilterProvider.notifier).setUnreadOnly(true),
                ),
                ...EngagementConstants.notificationCategories.map(
                  (c) => _FilterChip(
                    label: _categoryLabel(c),
                    selected: filters.category == c,
                    onTap: () =>
                        ref.read(notificationFilterProvider.notifier).setCategory(c),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.borderSubtle),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const ListSkeletonLoader(itemCount: 8),
              error: (e, _) => AsyncErrorView.fromError(e),
              data: (items) {
                final merged = _mergeItems(items);
                if (merged.isEmpty) {
                  return const AsyncEmptyView(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications yet',
                    subtitle: 'Updates about reviews, Q&A, and more will appear here.',
                  );
                }
                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: merged.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    if (i >= merged.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      );
                    }
                    return _NotificationTile(notification: merged[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String c) {
    switch (c) {
      case EngagementConstants.categoryReviews:
        return 'Reviews';
      case EngagementConstants.categoryQuestions:
        return 'Q&A';
      case EngagementConstants.categoryChat:
        return 'Chat';
      case EngagementConstants.categoryColleges:
        return 'Colleges';
      case EngagementConstants.categoryPlacements:
        return 'Placements';
      case EngagementConstants.categoryScholarships:
        return 'Scholarships';
      case EngagementConstants.categoryEvents:
        return 'Events';
      case EngagementConstants.categoryAdmission:
        return 'Admission';
      case EngagementConstants.categoryCareers:
        return 'Careers';
      case EngagementConstants.categoryCommunity:
        return 'Community';
      case EngagementConstants.categoryAdmin:
        return 'Admin';
      default:
        return c;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: PremiumChip(
        label: label,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

/// Category -> accent color, cycling through the theme's semantic colors so
/// each notification type reads as visually distinct at a glance.
Color _colorForCategory(BuildContext context, String category) {
  final scheme = Theme.of(context).colorScheme;
  switch (category) {
    case EngagementConstants.categoryReviews:
    case EngagementConstants.categoryColleges:
      return scheme.primary;
    case EngagementConstants.categoryQuestions:
    case EngagementConstants.categoryPlacements:
    case EngagementConstants.categoryCareers:
      return scheme.secondary;
    case EngagementConstants.categoryChat:
    case EngagementConstants.categoryScholarships:
    case EngagementConstants.categoryCommunity:
      return scheme.tertiary;
    case EngagementConstants.categoryEvents:
    case EngagementConstants.categoryAdmission:
      return AppTheme.warningColor;
    case EngagementConstants.categoryAdmin:
      return scheme.error;
    default:
      return scheme.primary;
  }
}

/// Short, human-friendly relative timestamp (e.g. "5m ago", "Yesterday").
String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 45) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(dt);
}

class _NotificationTile extends ConsumerWidget {
  final UserNotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = _colorForCategory(context, notification.category);
    final unread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(engagementRepositoryProvider).deleteNotification(notification.id);
      },
      child: PremiumCard(
        radius: tokens.buttonRadius,
        padding: const EdgeInsets.all(AppSpacing.lg),
        color: unread
            ? primary.withValues(alpha: isDark ? 0.14 : 0.06)
            : tokens.surfaceElevated,
        onTap: () async {
          if (!notification.isRead) {
            await ref
                .read(engagementRepositoryProvider)
                .markAsRead(notification.id);
          }
          if (notification.actionRoute.isNotEmpty && context.mounted) {
            context.push(notification.actionRoute);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unread accent bar — invisible (but space-preserving) when read
            // so every row stays aligned.
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: unread ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                _iconForCategory(notification.category),
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppFonts.plusJakarta(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                      color: tokens.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        color: tokens.textSecondary,
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${EngagementConstants.notificationTypeLabel(notification.type)} · ${_relativeTime(notification.createdAt)}',
                    style: AppFonts.plusJakarta(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case EngagementConstants.categoryReviews:
        return Icons.rate_review_outlined;
      case EngagementConstants.categoryQuestions:
        return Icons.help_outline;
      case EngagementConstants.categoryChat:
        return Icons.chat_bubble_outline;
      case EngagementConstants.categoryColleges:
        return Icons.school_outlined;
      case EngagementConstants.categoryPlacements:
        return Icons.work_outline;
      case EngagementConstants.categoryScholarships:
        return Icons.card_giftcard_outlined;
      case EngagementConstants.categoryEvents:
        return Icons.event_outlined;
      case EngagementConstants.categoryAdmission:
        return Icons.calendar_today_outlined;
      case EngagementConstants.categoryCareers:
        return Icons.work_outline;
      case EngagementConstants.categoryCommunity:
        return Icons.groups_outlined;
      case EngagementConstants.categoryAdmin:
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
