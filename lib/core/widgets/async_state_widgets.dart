import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';
import '../utils/firestore_error_utils.dart';
import 'skeleton_loader.dart';

class AsyncLoadingView extends StatelessWidget {
  final String? message;

  const AsyncLoadingView({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.poppins(color: AppTheme.gray600),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.gray400),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray800,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.gray600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
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
    final isQuota = FirestoreErrorUtils.isUserFacingQuotaMessage(message);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              isQuota ? Icons.cloud_off_rounded : Icons.error_outline,
              size: compact ? 36 : 48,
              color: isQuota ? AppTheme.gray500 : AppTheme.errorColor,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: AppTheme.gray700,
                fontSize: compact ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
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
      subtitle: 'Showing cached data where available. Check your connection and try again.',
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
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
              );
        }
        return builder(data);
      },
    );
  }
}
