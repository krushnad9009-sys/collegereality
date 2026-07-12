import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/communication_provider.dart';

class IncomingCallBanner extends ConsumerWidget {
  const IncomingCallBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final incomingAsync = ref.watch(incomingCallsProvider(user.uid));

    return incomingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (calls) {
        if (calls.isEmpty) return const SizedBox.shrink();
        final call = calls.first;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                call.isVideo ? Icons.videocam : Icons.call,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incoming ${call.isVideo ? 'video' : 'voice'} call',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text('From ${call.callerAlias}'),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.push(RouteNames.activeCallPath(call.id)),
                child: const Text('Answer'),
              ),
            ],
          ),
        );
      },
    );
  }
}
