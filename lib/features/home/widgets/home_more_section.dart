import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../core/widgets/premium_list_row.dart';

/// "More to Explore" — a lean, low-visual-weight list of genuinely
/// secondary entry points. Deliberately three rows, not another card
/// gallery, so it doesn't read as a second dashboard.
class HomeMoreSection extends StatelessWidget {
  const HomeMoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          PremiumListRow(
            leadingIcon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF0369A1),
            title: 'Your Chats',
            subtitle: 'Messages with verified students & guides',
            onTap: () => context.go(RouteNames.communityPrivateChats),
          ),
          Divider(height: 1, color: tokens.borderSubtle),
          PremiumListRow(
            leadingIcon: Icons.groups_rounded,
            iconColor: const Color(0xFF7B2D26),
            title: 'Alumni Stories',
            subtitle: 'Where graduates are today',
            onTap: () => context.go(RouteNames.careersAlumni),
          ),
          Divider(height: 1, color: tokens.borderSubtle),
          PremiumListRow(
            leadingIcon: Icons.add_circle_outline_rounded,
            iconColor: const Color(0xFF15803D),
            title: 'Add Your College',
            subtitle: 'Not listed yet? Help us add it',
            onTap: () => context.go(RouteNames.requestCollege),
          ),
        ],
      ),
    );
  }
}
