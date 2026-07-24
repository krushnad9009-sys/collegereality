import 'package:flutter/material.dart';

import '../../config/theme/app_design_tokens.dart';

/// Shimmer skeleton with theme-aware colors and smooth animation.
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const SkeletonBox({
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    super.key,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 2, 0),
              end: Alignment(1.0 + _controller.value * 2, 0),
              colors: [
                tokens.shimmerBase,
                tokens.shimmerHighlight,
                tokens.shimmerBase,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

class CollegeCardSkeleton extends StatelessWidget {
  const CollegeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            height: 160,
            width: double.infinity,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 16, width: double.infinity),
                SizedBox(height: 8),
                SkeletonBox(height: 14, width: 140),
                SizedBox(height: 12),
                SkeletonBox(height: 14, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewListSkeleton extends StatelessWidget {
  const ReviewListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.borderSubtle),
        ),
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 18, width: 180),
            SizedBox(height: 10),
            SkeletonBox(height: 14, width: double.infinity),
            SizedBox(height: 6),
            SkeletonBox(height: 14, width: double.infinity),
            SizedBox(height: 6),
            SkeletonBox(height: 14, width: 220),
          ],
        ),
      ),
    );
  }
}

class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonBox(height: 88, width: 88, borderRadius: BorderRadius.all(Radius.circular(44))),
        SizedBox(height: 16),
        SkeletonBox(height: 20, width: 160),
        SizedBox(height: 8),
        SkeletonBox(height: 14, width: 120),
      ],
    );
  }
}

class ChatListSkeleton extends StatelessWidget {
  final int count;

  const ChatListSkeleton({this.count = 8, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => const Row(
        children: [
          SkeletonBox(height: 52, width: 52, borderRadius: BorderRadius.all(Radius.circular(26))),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 140),
                SizedBox(height: 8),
                SkeletonBox(height: 12, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 120, width: double.infinity),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 88)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 88)),
          ],
        ),
        SizedBox(height: 16),
        SkeletonBox(height: 200, width: double.infinity),
      ],
    );
  }
}
