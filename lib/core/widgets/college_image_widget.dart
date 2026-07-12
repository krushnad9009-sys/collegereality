import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';
import '../utils/college_image_helper.dart';

class CollegeImageWidget extends StatelessWidget {
  final String collegeId;
  final String? imageUrl;
  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CollegeImageWidget({
    required this.collegeId,
    this.imageUrl,
    this.height = 160,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = CollegeImageHelper.getCoverImageUrl(
      collegeId,
      coverPhotoUrl: imageUrl,
    );

    Widget image = CachedNetworkImage(
      imageUrl: resolvedUrl,
      fit: fit,
      width: width ?? double.infinity,
      height: height,
      placeholder: (_, _) => _Placeholder(height: height, width: width),
      errorWidget: (_, _, _) => _Placeholder(height: height, width: width),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

class _Placeholder extends StatelessWidget {
  final double height;
  final double? width;

  const _Placeholder({required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.secondaryColor.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school_rounded,
          color: AppTheme.primaryColor,
          size: 48,
        ),
      ),
    );
  }
}
