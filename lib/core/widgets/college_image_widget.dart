import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/college_image_helper.dart';
import 'branded_campus_fallback.dart';

class CollegeImageWidget extends StatelessWidget {
  final String collegeId;
  final String? imageUrl;
  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Threaded through to [BrandedCampusFallback] so its no-photo/loading/
  /// error placeholder can render this college's own initials instead of a
  /// generic mark. Optional — omitted call sites keep the generic fallback.
  final String? collegeName;

  const CollegeImageWidget({
    required this.collegeId,
    this.imageUrl,
    this.height = 160,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.collegeName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = CollegeImageHelper.resolveCoverUrl(
      imageUrl,
      collegeId: collegeId,
    );

    if (resolvedUrl == null) {
      return BrandedCampusFallback(
        collegeId: collegeId,
        collegeName: collegeName,
        height: height,
        width: width,
        borderRadius: borderRadius,
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
      placeholder: (_, _) => BrandedCampusFallback(
        collegeId: collegeId,
        collegeName: collegeName,
        height: height,
        width: width,
        borderRadius: borderRadius,
      ),
      errorWidget: (_, _, _) => BrandedCampusFallback(
        collegeId: collegeId,
        collegeName: collegeName,
        height: height,
        width: width,
        borderRadius: borderRadius,
      ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
