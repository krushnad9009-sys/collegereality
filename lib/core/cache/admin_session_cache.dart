import '../constants/admin_constants.dart';
import '../../features/admin/models/admin_models.dart';

class AdminSessionCache {
  AdminSessionCache._();

  static AdminDashboardStats? _stats;
  static DateTime? _statsAt;
  static AdminAnalyticsData? _analytics;
  static DateTime? _analyticsAt;

  static AdminDashboardStats? getStats() {
    if (_stats == null || _statsAt == null) return null;
    if (DateTime.now().difference(_statsAt!) > AdminConstants.statsCacheTtl) {
      clearStats();
      return null;
    }
    return _stats;
  }

  static void setStats(AdminDashboardStats stats) {
    _stats = stats;
    _statsAt = DateTime.now();
  }

  static AdminAnalyticsData? getAnalytics() {
    if (_analytics == null || _analyticsAt == null) return null;
    if (DateTime.now().difference(_analyticsAt!) > AdminConstants.statsCacheTtl) {
      clearAnalytics();
      return null;
    }
    return _analytics;
  }

  static void setAnalytics(AdminAnalyticsData data) {
    _analytics = data;
    _analyticsAt = DateTime.now();
  }

  static void clearStats() {
    _stats = null;
    _statsAt = null;
  }

  static void clearAnalytics() {
    _analytics = null;
    _analyticsAt = null;
  }

  static void clearAll() {
    clearStats();
    clearAnalytics();
  }
}
