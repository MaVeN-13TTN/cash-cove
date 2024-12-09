import 'package:dio/dio.dart';

class AnalyticsCacheConfig {
  static const Duration spendingCacheDuration = Duration(minutes: 15);
  static const Duration trendsCacheDuration = Duration(hours: 1);
  static const Duration insightsCacheDuration = Duration(minutes: 30);
  static const Duration utilizationCacheDuration = Duration(minutes: 15);

  static Options getSpendingCacheOptions() {
    return Options(
      headers: {
        'Cache-Control': 'max-age=${spendingCacheDuration.inSeconds}',
      },
      extra: {
        'cache_key': 'analytics_spending',
        'cache_duration': spendingCacheDuration,
      },
    );
  }

  static Options getTrendsCacheOptions() {
    return Options(
      headers: {
        'Cache-Control': 'max-age=${trendsCacheDuration.inSeconds}',
      },
      extra: {
        'cache_key': 'analytics_trends',
        'cache_duration': trendsCacheDuration,
      },
    );
  }

  static Options getInsightsCacheOptions() {
    return Options(
      headers: {
        'Cache-Control': 'max-age=${insightsCacheDuration.inSeconds}',
      },
      extra: {
        'cache_key': 'analytics_insights',
        'cache_duration': insightsCacheDuration,
      },
    );
  }

  static Options getUtilizationCacheOptions() {
    return Options(
      headers: {
        'Cache-Control': 'max-age=${utilizationCacheDuration.inSeconds}',
      },
      extra: {
        'cache_key': 'analytics_utilization',
        'cache_duration': utilizationCacheDuration,
      },
    );
  }
}
