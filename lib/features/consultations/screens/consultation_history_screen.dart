import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/consultation_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/consultation_model.dart';
import '../providers/consultation_provider.dart';
import '../widgets/two_way_rating_sheet.dart';

/// Paginated consultation history for the current user, both as student
/// and as guide (two tabs) — same cursor-pagination pattern already used
/// for notifications/messages (SocialPageResult + fetchHistoryPage).
class ConsultationHistoryScreen extends ConsumerStatefulWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  ConsumerState<ConsultationHistoryScreen> createState() =>
      _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState
    extends ConsumerState<ConsultationHistoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) {
      return const Scaffold(
        body: AsyncEmptyView(
          icon: Icons.person_off_outlined,
          title: 'Not signed in',
          subtitle: null,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'As student'), Tab(text: 'As guide')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HistoryList(userId: uid, asGuide: false),
          _HistoryList(userId: uid, asGuide: true),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final String userId;
  final bool asGuide;
  const _HistoryList({required this.userId, required this.asGuide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(
      consultationHistoryFirstPageProvider((userId: userId, asGuide: asGuide)),
    );
    return AsyncStateView(
      value: pageAsync,
      isEmpty: (page) => page.items.isEmpty,
      emptyBuilder: () => const AsyncEmptyView(
        icon: Icons.forum_outlined,
        title: 'No consultations yet',
        subtitle: 'Booked consultations will show up here.',
      ),
      builder: (page) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pageH),
        itemCount: page.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _ConsultationTile(
          consultation: page.items[i],
          currentUid: userId,
          asGuide: asGuide,
        ),
      ),
    );
  }
}

class _ConsultationTile extends StatelessWidget {
  final ConsultationModel consultation;
  final String currentUid;
  final bool asGuide;
  const _ConsultationTile({
    required this.consultation,
    required this.currentUid,
    required this.asGuide,
  });

  bool get _isCompleted =>
      consultation.status == ConsultationConstants.statusCompleted;

  String get _raterRole => asGuide
      ? ConsultationConstants.raterRoleGuide
      : ConsultationConstants.raterRoleStudent;

  String get _rateeId =>
      asGuide ? consultation.studentId : consultation.guideId;

  Future<void> _openRatingSheet(BuildContext context) {
    return showTwoWayRatingSheet(
      context: context,
      consultationId: consultation.id,
      raterId: currentUid,
      raterRole: _raterRole,
      rateeId: _rateeId,
      rateeLabel: asGuide ? 'the student' : 'the guide',
    );
  }

  Color _statusColor() {
    switch (consultation.status) {
      case ConsultationConstants.statusCompleted:
        return const Color(0xFF16A34A);
      case ConsultationConstants.statusCancelled:
      case ConsultationConstants.statusExpired:
        return const Color(0xFFDC2626);
      case ConsultationConstants.statusActive:
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final statusColor = _statusColor();
    final canRate = _isCompleted && consultation.canRate(currentUid);
    final rated = _isCompleted && !consultation.canRate(currentUid);
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push(RouteNames.consultationRoomPath(consultation.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              consultation.type == ConsultationConstants.typeChat
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.call_outlined,
              size: 18,
              color: primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${consultation.type[0].toUpperCase()}${consultation.type.substring(1)} · ${consultation.durationMinutes} min',
                  style: AppFonts.plusJakarta(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  consultation.priceInfo.grossDisplay,
                  style: AppFonts.plusJakarta(
                    color: tokens.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withValues(alpha: 0.32)),
            ),
            child: Text(
              consultation.status.replaceAll('_', ' '),
              style: AppFonts.plusJakarta(
                color: statusColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ),
            ],
          ),
          if (canRate) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openRatingSheet(context),
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: Text(
                  asGuide ? 'Rate the student' : 'Rate the guide',
                  style: AppFonts.plusJakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ] else if (rated) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 15, color: Color(0xFF16A34A)),
                const SizedBox(width: 5),
                Text(
                  'You rated this consultation',
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
