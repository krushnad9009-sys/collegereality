import 'package:flutter/material.dart';

import '../../config/theme/app_theme.dart';

/// College Reality Score (CR Score) weights and display thresholds.
class CrScoreConstants {
  CrScoreConstants._();

  static const double weightEducation = 0.25;
  static const double weightPlacements = 0.25;
  static const double weightCampusLife = 0.20;
  static const double weightInfrastructure = 0.15;
  static const double weightSafety = 0.15;

  static const int confidenceVeryHighMin = 1000;
  static const int confidenceHighMin = 200;
  static const int confidenceMediumMin = 50;
  static const int confidenceLowMin = 10;

  static const String categoryEducation = 'education';
  static const String categoryPlacements = 'placements';
  static const String categoryCampusLife = 'campusLife';
  static const String categoryInfrastructure = 'infrastructure';
  static const String categorySafety = 'safety';

  static const List<String> categoryKeys = [
    categoryEducation,
    categoryPlacements,
    categoryCampusLife,
    categoryInfrastructure,
    categorySafety,
  ];

  static String categoryLabel(String key) {
    switch (key) {
      case categoryEducation:
        return 'Education';
      case categoryPlacements:
        return 'Placements';
      case categoryCampusLife:
        return 'Campus Life';
      case categoryInfrastructure:
        return 'Infrastructure';
      case categorySafety:
        return 'Safety';
      default:
        return key;
    }
  }

  static String confidenceLabel(int verifiedReviewCount) {
    if (verifiedReviewCount >= confidenceVeryHighMin) {
      return 'Very High Confidence';
    }
    if (verifiedReviewCount >= confidenceHighMin) {
      return 'High Confidence';
    }
    if (verifiedReviewCount >= confidenceMediumMin) {
      return 'Medium Confidence';
    }
    if (verifiedReviewCount >= confidenceLowMin) {
      return 'Low Confidence';
    }
    return 'Not enough data';
  }

  static String gradeForScore(double score) {
    if (score >= 95) return 'A+';
    if (score >= 90) return 'A';
    if (score >= 85) return 'A-';
    if (score >= 80) return 'B+';
    if (score >= 75) return 'B';
    if (score >= 70) return 'B-';
    if (score >= 65) return 'C+';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  static Color colorForScore(double score) {
    if (score >= 80) return AppTheme.accentColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  static bool hasEnoughData(int verifiedReviewCount) {
    return verifiedReviewCount >= confidenceLowMin;
  }
}
