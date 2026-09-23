import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/models/chat_conversation_model.dart';
import '../../community/providers/community_provider.dart';
import '../models/public_guide_profile.dart';
import '../providers/communication_provider.dart';
import '../utils/guide_search_matcher.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../../consultations/widgets/availability_badge.dart';
import '../widgets/guide_badge_widget.dart';

/// "Talk to a Verified Student/Alumni" (`/guides`).
///
/// A direct list, never a dead end:
///  * a search bar (by college or stream) is always on top;
///  * recent chat conversations, when there are any, then the available
///    verified guides -- online ones first;
///  * when nothing is available (or nothing matches the search) it shows
///    active call-to-action cards instead of an empty-state card.
///
/// The Messages button in the app bar opens the main Chats list directly.
class GuidesDirectoryScreen extends ConsumerStatefulWidget {
  const GuidesDirectoryScreen({super.key});

  @override
  ConsumerState<GuidesDirectoryScreen> createState() =>
      _GuidesDirectoryScreenState();
}

class _GuidesDirectoryScreenState extends ConsumerState<GuidesDirectoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  /// How many recent conversations to surface above the guides.
  static const int _recentChatCount = 3;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // The directory is not filtered by language any more: every available
  // guide is listed.
  static final _guides = guidesDirectoryProvider(null);

  Future<void> _refresh() async {
    ref.invalidate(_guides);
    try {
      await ref.read(_guides.future);
    } catch (_) {
      // The error state is rendered by the provider itself.
    }
  }

  @override
  Widget build(BuildContext context) {
    final guidesAsync = ref.watch(_guides);
    final userId = ref.watch(currentUserDetailProvider).valueOrNull?.uid;
    final chats =
        ref.watch(privateConversationsProvider).valueOrNull ?? const [];
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk to a Verified Student/Alumni'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Messages',
            // Straight to the main Chats list.
            onPressed: () => context.go(RouteNames.communityPrivateChats),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search guides by college or stream',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: guidesAsync.when(
              loading: () => const ListSkeletonLoader(itemCount: 5),
              error: (e, _) => AsyncErrorView(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(_guides),
              ),
              data: (guides) {
                final query = _query.trim();
                final searching = query.isNotEmpty;
                final shown = GuideSearchMatcher.filter(
                  GuideSearchMatcher.sortByAvailability(guides),
                  query,
                );
                final recent = searching
                    ? const <ChatConversationModel>[]
                    : _recentChats(chats);

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (recent.isNotEmpty) ...[
                        _RecentChatsSection(chats: recent, userId: userId),
                        const SizedBox(height: 20),
                      ],
                      if (shown.isNotEmpty) ...[
                        _SectionTitle(
                          searching
                              ? '${shown.length} '
                                    '${shown.length == 1 ? 'guide' : 'guides'} '
                                    'for “$query”'
                              : 'Available guides',
                        ),
                        for (var i = 0; i < shown.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _GuideListTile(guide: shown[i]),
                        ],
                      ] else
                        _GuideHelpSection(
                          query: query,
                          hadGuides: guides.isNotEmpty,
                          onClearSearch: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ChatConversationModel> _recentChats(List<ChatConversationModel> chats) {
    final withMessages = [...chats];
    withMessages.sort((a, b) {
      final at = a.lastMessageAt ?? a.updatedAt;
      final bt = b.lastMessageAt ?? b.updatedAt;
      return bt.compareTo(at);
    });
    return withMessages.take(_recentChatCount).toList();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppFonts.plusJakarta(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: context.tokens.textPrimary,
        ),
      ),
    );
  }
}

/// The latest few conversations, each opening straight into that chat, with
/// "See all" going to the full Messages list.
class _RecentChatsSection extends StatelessWidget {
  final List<ChatConversationModel> chats;
  final String? userId;

  const _RecentChatsSection({required this.chats, required this.userId});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent chats',
                style: AppFonts.plusJakarta(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.communityPrivateChats),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final chat in chats) ...[
          PremiumCard(
            padding: EdgeInsets.zero,
            radius: tokens.cardRadius,
            onTap: () => context.push(RouteNames.communityChatPath(chat.id)),
            child: ListTile(
              key: ValueKey('recent-chat-${chat.id}'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 2,
              ),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: primary.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, color: primary, size: 20),
              ),
              title: Text(
                userId != null ? chat.displayTitle(userId!) : 'Chat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.plusJakarta(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              subtitle: Text(
                chat.lastMessageText ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  color: tokens.textSecondary,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: tokens.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Shown instead of an empty-state card when no guide is available, or none
/// matches the search: says what happened and offers real next steps.
class _GuideHelpSection extends StatelessWidget {
  final String query;

  /// There ARE guides, just none matching [query].
  final bool hadGuides;
  final VoidCallback onClearSearch;

  const _GuideHelpSection({
    required this.query,
    required this.hadGuides,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final searching = query.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          searching
              ? 'No guides match “$query”'
              : 'No guides are online right now',
          style: AppFonts.plusJakarta(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          searching
              ? 'Try another college or stream, or start from one of these.'
              : 'Verified students are joining all the time. Meanwhile, '
                    'you can get answers here:',
          style: AppFonts.plusJakarta(
            fontSize: 13.5,
            height: 1.4,
            color: tokens.textSecondary,
          ),
        ),
        if (searching && hadGuides)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onClearSearch,
              child: const Text('Show all guides'),
            ),
          ),
        const SizedBox(height: 16),
        if (searching) ...[
          _ActionCard(
            icon: Icons.search_rounded,
            title: 'Search colleges for “$query”',
            subtitle: 'See the college and what its students say',
            onTap: () => context.go(
              Uri(
                path: RouteNames.collegeSearch,
                queryParameters: {'q': query},
              ).toString(),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _ActionCard(
          icon: Icons.school_outlined,
          title: 'Browse colleges',
          subtitle: 'Find a college and its verified students',
          onTap: () => context.go(RouteNames.collegeSearch),
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.forum_outlined,
          title: 'Ask seniors',
          subtitle: 'Post a question and get answers from students',
          onTap: () => context.go(RouteNames.communityAskSeniors),
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.auto_awesome_rounded,
          title: 'Ask the AI Assistant',
          subtitle: 'Instant answers on colleges, fees and cutoffs',
          onTap: () => context.go(RouteNames.assistant),
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.verified_outlined,
          title: 'Become a guide',
          subtitle: 'Get verified and help other students',
          onTap: () => context.go(RouteNames.verification),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return PremiumCard(
      padding: EdgeInsets.zero,
      radius: tokens.cardRadius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.plusJakarta(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.plusJakarta(
                      fontSize: 12.5,
                      height: 1.3,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _GuideListTile extends ConsumerWidget {
  final PublicGuideProfile guide;

  const _GuideListTile({required this.guide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    // Live presence (autoDispose -- only rows currently on/near screen keep
    // a listener open) so a guide flipping online/offline updates this row
    // in real time instead of only showing the search snapshot.
    final presence =
        ref.watch(presenceProvider(guide.uid)).valueOrNull ?? guide.presence;
    final settings = guide.settings;
    final priceLabel = settings.chatAvailable && settings.chatPricePaise > 0
        ? '₹${(settings.chatPricePaise / 100).round()} chat'
        : (settings.callAvailable &&
                  settings.callPricing.any((p) => p.pricePaise > 0)
              ? 'Call from ₹${(settings.callPricing.where((p) => p.pricePaise > 0).map((p) => p.pricePaise).reduce((a, b) => a < b ? a : b) / 100).round()}'
              : null);

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('guide-${guide.uid}'),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        onTap: () => context.push(RouteNames.guideProfilePath(guide.uid)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: primary.withValues(alpha: 0.15),
                        backgroundImage: guide.photoURL != null
                            ? NetworkImage(guide.photoURL!)
                            : null,
                        child: guide.photoURL == null
                            ? Text(
                                guide.displayName.isNotEmpty
                                    ? guide.displayName[0].toUpperCase()
                                    : 'G',
                                style: AppFonts.plusJakarta(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: tokens.surfaceElevated,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: presence.isLiveOnline
                                  ? PresenceState.online.color
                                  : tokens.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                guide.displayName,
                                style: AppFonts.plusJakarta(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            VerificationBadgeWidget(
                              badge: guide.verificationBadge,
                            ),
                          ],
                        ),
                        if (guide.collegeName != null)
                          Text(
                            guide.collegeName!,
                            style: AppFonts.plusJakarta(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: tokens.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        AvailabilityBadge(
                          presence: presence,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  GuideBadgeWidget(badgeTier: guide.stats.badgeTier),
                  if (guide.stats.totalRatings > 0)
                    _MiniChip(
                      icon: Icons.star_rounded,
                      label: guide.stats.overallRating.toStringAsFixed(1),
                      color: const Color(0xFFF59E0B),
                    ),
                  if (priceLabel != null)
                    _MiniChip(
                      icon: Icons.payments_outlined,
                      label: priceLabel,
                      color: primary,
                    ),
                ],
              ),
              if (guide.languagesKnown.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  guide.languagesKnown.join(' · '),
                  style: AppFonts.plusJakarta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
