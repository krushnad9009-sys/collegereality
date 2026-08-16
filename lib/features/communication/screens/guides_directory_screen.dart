import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/communication_constants.dart';
import '../../../core/widgets/index.dart';
import '../models/public_guide_profile.dart';
import '../providers/communication_provider.dart';
import '../../verification/widgets/verification_badge_widget.dart';
import '../../consultations/widgets/availability_badge.dart';
import '../widgets/guide_badge_widget.dart';

class GuidesDirectoryScreen extends ConsumerStatefulWidget {
  const GuidesDirectoryScreen({super.key});

  @override
  ConsumerState<GuidesDirectoryScreen> createState() =>
      _GuidesDirectoryScreenState();
}

class _GuidesDirectoryScreenState extends ConsumerState<GuidesDirectoryScreen> {
  String? _languageFilter;

  @override
  Widget build(BuildContext context) {
    final guidesAsync = ref.watch(guidesDirectoryProvider(_languageFilter));
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk to a Verified Student/Alumni'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
            ),
            child: Row(
              children: [
                Icon(Icons.language_outlined, size: 18, color: tokens.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        PremiumChip(
                          label: 'All languages',
                          selected: _languageFilter == null,
                          onTap: () {
                            setState(() => _languageFilter = null);
                            ref.invalidate(
                                guidesDirectoryProvider(_languageFilter));
                          },
                        ),
                        ...CommunicationConstants.supportedLanguages.map(
                          (lang) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: PremiumChip(
                              label: lang,
                              selected: _languageFilter == lang,
                              onTap: () {
                                setState(() => _languageFilter = lang);
                                ref.invalidate(
                                    guidesDirectoryProvider(_languageFilter));
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: guidesAsync.when(
              loading: () => const ListSkeletonLoader(itemCount: 5),
              error: (e, _) => AsyncErrorView(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(guidesDirectoryProvider(_languageFilter)),
              ),
              data: (guides) {
                if (guides.isEmpty) {
                  return AsyncEmptyView(
                    icon: Icons.school_outlined,
                    title: 'No guides available yet',
                    subtitle:
                        'Guides are verified students who help others.\nEnable guide mode in your profile to appear here.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(guidesDirectoryProvider(_languageFilter));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: guides.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _GuideListTile(guide: guides[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideListTile extends StatelessWidget {
  final PublicGuideProfile guide;

  const _GuideListTile({required this.guide});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final settings = guide.settings;
    final priceLabel = settings.chatAvailable && settings.chatPricePaise > 0
        ? '₹${(settings.chatPricePaise / 100).round()} chat'
        : (settings.callAvailable &&
                settings.callPricing.any((p) => p.pricePaise > 0)
            ? 'Call from ₹${(settings.callPricing
                    .where((p) => p.pricePaise > 0)
                    .map((p) => p.pricePaise)
                    .reduce((a, b) => a < b ? a : b) / 100)
                .round()}'
            : null);

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: InkWell(
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
                              color: guide.presence.isOnline
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
                        AvailabilityBadge(presence: guide.presence, compact: true),
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
