import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/constants/consultation_constants.dart';
import '../../../core/widgets/index.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/consultation_model.dart';
import '../providers/consultation_provider.dart';

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
        itemBuilder: (context, i) => _ConsultationTile(consultation: page.items[i]),
      ),
    );
  }
}

class _ConsultationTile extends StatelessWidget {
  final ConsultationModel consultation;
  const _ConsultationTile({required this.consultation});

  Color _statusColor() {
    switch (consultation.status) {
      case ConsultationConstants.statusCompleted:
        return Colors.green;
      case ConsultationConstants.statusCancelled:
      case ConsultationConstants.statusExpired:
        return Colors.red;
      case ConsultationConstants.statusActive:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push(RouteNames.consultationRoomPath(consultation.id)),
      child: Row(
        children: [
          Icon(
            consultation.type == ConsultationConstants.typeChat
                ? Icons.chat_bubble_outline
                : Icons.call_outlined,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${consultation.type[0].toUpperCase()}${consultation.type.substring(1)} · ${consultation.durationMinutes} min',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  consultation.priceInfo.grossDisplay,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              consultation.status.replaceAll('_', ' '),
              style: TextStyle(color: _statusColor(), fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
