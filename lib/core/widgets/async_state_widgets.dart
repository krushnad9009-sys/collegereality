import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_design_tokens.dart';
import '../../config/theme/app_theme.dart';
import '../utils/firestore_error_utils.dart';
import 'skeleton_loader.dart';

class AsyncLoadingView extends StatelessWidget {
  final String? message;

  const AsyncLoadingView({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: GoogleFonts.poppins(
                color: tokens.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class AsyncEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AsyncEmptyView({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: tokens.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class AsyncErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  const AsyncErrorView({
    required this.message,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  factory AsyncErrorView.fromError(
    Object error, {
    VoidCallback? onRetry,
    bool compact = false,
  }) {
    final isQuota = FirestoreErrorUtils.isQuotaExceededError(error) ||
        FirestoreErrorUtils.isUserFacingQuotaMessage(error.toString());
    return AsyncErrorView(
      message: isQuota ? kFirestoreQuotaUserMessage : error.toString(),
      onRetry: onRetry,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isQuota = FirestoreErrorUtils.isUserFacingQuotaMessage(message);
    final iconColor = isQuota ? tokens.textTertiary : AppTheme.errorColor;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Container(
              width: compact ? 56 : 72,
              height: compact ? 56 : 72,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isQuota ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                size: compact ? 28 : 36,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isQuota ? 'Service temporarily busy' : 'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: tokens.textSecondary,
                fontSize: compact ? 13 : 14,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;

  const ListSkeletonLoader({this.itemCount = 6, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const SkeletonBox(height: 88),
    );
  }
}

class AsyncOfflineView extends StatelessWidget {
  final VoidCallback? onRetry;

  const AsyncOfflineView({this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncEmptyView(
      icon: Icons.wifi_off_rounded,
      title: 'You appear to be offline',
      subtitle:
          'Showing cached data where available. Check your connection and try again.',
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
    );
  }
}

/// Standard AsyncValue renderer with loading, empty, offline, and error states.
class AsyncStateView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final Widget Function()? emptyBuilder;
  final VoidCallback? onRetry;
  final bool showSkeleton;
  final String? loadingMessage;

  const AsyncStateView({
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyBuilder,
    this.onRetry,
    this.showSkeleton = false,
    this.loadingMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => showSkeleton
          ? const ListSkeletonLoader()
          : AsyncLoadingView(message: loadingMessage),
      error: (e, _) {
        if (FirestoreErrorUtils.isQuotaExceededError(e) ||
            FirestoreErrorUtils.isUserFacingQuotaMessage(e.toString())) {
          return AsyncOfflineView(onRetry: onRetry);
        }
        return AsyncErrorView.fromError(e, onRetry: onRetry);
      },
      data: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          return emptyBuilder?.call() ??
              const AsyncEmptyView(
                icon: Icons.inbox_outlined,
                title: 'Nothing here yet',
                subtitle: 'Check back later for new content.',
              );
        }
        return builder(data);
      },
    );
  }
}
