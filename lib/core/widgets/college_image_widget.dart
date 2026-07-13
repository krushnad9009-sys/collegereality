import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme/app_theme.dart';
import '../utils/college_image_helper.dart';

class CollegeImageWidget extends StatelessWidget {
  final String collegeId;
  final String? imageUrl;
  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showComingSoonLabel;

  const CollegeImageWidget({
    required this.collegeId,
    this.imageUrl,
    this.height = 160,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showComingSoonLabel = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = CollegeImageHelper.resolveCoverUrl(imageUrl);

    if (resolvedUrl == null) {
      return _ComingSoonPlaceholder(
        height: height,
        width: width,
        borderRadius: borderRadius,
        showLabel: showComingSoonLabel,
      );
    }

    final cacheWidth = width != null
        ? (width! * 2).toInt()
        : (MediaQuery.sizeOf(context).width * 2).toInt();

    Widget image = CachedNetworkImage(
      imageUrl: resolvedUrl,
      fit: fit,
      width: width ?? double.infinity,
      height: height,
      memCacheHeight: (height * 2).toInt(),
      memCacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      placeholder: (_, _) => _ComingSoonPlaceholder(
        height: height,
        width: width,
        borderRadius: borderRadius,
        showLabel: false,
        isLoading: true,
      ),
      errorWidget: (_, _, _) => _ComingSoonPlaceholder(
        height: height,
        width: width,
        borderRadius: borderRadius,
        showLabel: showComingSoonLabel,
      ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

class _ComingSoonPlaceholder extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool showLabel;
  final bool isLoading;

  const _ComingSoonPlaceholder({
    required this.height,
    this.width,
    this.borderRadius,
    this.showLabel = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.12),
            AppTheme.secondaryColor.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(
                Icons.photo_camera_outlined,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
                size: 40,
              ),
            if (showLabel && !isLoading) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'College photo coming soon',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }
}
