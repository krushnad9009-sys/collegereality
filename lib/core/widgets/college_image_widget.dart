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
    this.showComingSoonLabel = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = CollegeImageHelper.resolveCoverUrl(
      imageUrl,
      collegeId: collegeId,
    );

    if (resolvedUrl == null) {
      return _ImagePlaceholder(
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
      placeholder: (_, _) => _ImagePlaceholder(
        height: height,
        width: width,
        borderRadius: borderRadius,
        isLoading: true,
      ),
      errorWidget: (_, _, _) => _ImagePlaceholder(
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

class _ImagePlaceholder extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool showLabel;
  final bool isLoading;

  const _ImagePlaceholder({
    required this.height,
    this.width,
    this.borderRadius,
    this.showLabel = false,
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
            AppTheme.primaryColor.withValues(alpha: 0.08),
            AppTheme.secondaryColor.withValues(alpha: 0.14),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryColor.withValues(alpha: 0.7),
                ),
              )
            else
              Icon(
                Icons.school_rounded,
                color: AppTheme.primaryColor.withValues(alpha: 0.55),
                size: 42,
              ),
            if (showLabel && !isLoading) ...[
              const SizedBox(height: 8),
              Text(
                'Campus photo',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray500,
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
