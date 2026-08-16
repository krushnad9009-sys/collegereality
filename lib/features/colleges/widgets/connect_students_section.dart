import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/route_names.dart';
import '../../../config/theme/app_design_tokens.dart';
import '../../../config/theme/app_fonts.dart';
import '../../communication/providers/communication_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Compact Talk to Students entry on the college Reviews tab.
class ConnectStudentsSection extends ConsumerWidget {
  final String collegeId;
  final String collegeName;

  const ConnectStudentsSection({
    required this.collegeId,
    this.collegeName = '',
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final secondary = Theme.of(context).colorScheme.secondary;
    final authUser = ref.watch(currentUserProvider);
    final studentsAsync = ref.watch(
      collegeConnectableStudentsProvider((
        collegeId: collegeId,
        excludeUserId: authUser?.uid,
      )),
    );

    final studentCount = studentsAsync.valueOrNull?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(tokens.buttonRadius * 0.85),
                ),
                child: Icon(Icons.forum_outlined, color: secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talk to Students',
                      style: AppFonts.plusJakarta(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      studentsAsync.isLoading
                          ? 'Finding verified students...'
                          : studentCount > 0
                              ? '$studentCount verified student${studentCount == 1 ? '' : 's'} ready to chat'
                              : 'Ask verified students & alumni about this college',
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(
                RouteNames.talkToStudentsPath(
                  collegeId,
                  name: collegeName,
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Talk to Students'),
            ),
          ),
        ],
      ),
    );
  }
}
