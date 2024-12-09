import 'package:get/get.dart';
import 'package:logging/logging.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exceptions.dart';
import '../../../data/models/analytics/spending_analytics.dart';
import '../../../data/models/analytics/budget_utilization.dart';
import '../../../data/models/analytics/spending_trends.dart';
import '../../../data/models/analytics/spending_insights.dart';

/// Service responsible for tracking analytics events and user behavior
class AnalyticsService extends GetxService {
  final ApiClient _apiClient;
  final Logger _logger;
  
  // Observable states
  final Rx<SpendingAnalytics?> spendingAnalytics = Rx<SpendingAnalytics?>(null);
  final Rx<BudgetUtilization?> budgetUtilization = Rx<BudgetUtilization?>(null);
  final Rx<SpendingTrends?> spendingTrends = Rx<SpendingTrends?>(null);
  final Rx<SpendingInsights?> spendingInsights = Rx<SpendingInsights?>(null);

  AnalyticsService({
    ApiClient? apiClient,
  }) : 
    _apiClient = apiClient ?? Get.find<ApiClient>(),
    _logger = Logger('AnalyticsService');

  Future<void> fetchSpendingAnalytics() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.analyticsSpending,
      );
      
      final analytics = SpendingAnalytics.fromJson(response.data);
      spendingAnalytics.value = analytics;
    } catch (e) {
      _logger.severe('Error fetching spending analytics', e);
      throw ApiException('Failed to fetch spending analytics');
    }
  }

  Future<void> fetchBudgetUtilization() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.analyticsUtilization,
      );
      
      final utilization = BudgetUtilization.fromJson(response.data);
      budgetUtilization.value = utilization;
    } catch (e) {
      _logger.severe('Error fetching budget utilization', e);
      throw ApiException('Failed to fetch budget utilization');
    }
  }

  Future<void> fetchSpendingTrends() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.analyticsTrends,
      );
      
      final trends = SpendingTrends.fromJson(response.data);
      spendingTrends.value = trends;
    } catch (e) {
      _logger.severe('Error fetching spending trends', e);
      throw ApiException('Failed to fetch spending trends');
    }
  }

  Future<void> fetchSpendingInsights() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.analyticsInsights,
      );
      
      final insights = SpendingInsights.fromJson(response.data);
      spendingInsights.value = insights;
    } catch (e) {
      _logger.severe('Error fetching spending insights', e);
      throw ApiException('Failed to fetch spending insights');
    }
  }

  Future<void> refreshAllAnalytics() async {
    try {
      await Future.wait([
        fetchSpendingAnalytics(),
        fetchBudgetUtilization(),
        fetchSpendingTrends(),
        fetchSpendingInsights(),
      ]);
    } catch (e) {
      _logger.severe('Error refreshing analytics', e);
      throw ApiException('Failed to refresh analytics');
    }
  }

  @override
  void onInit() {
    super.onInit();
    refreshAllAnalytics();
  }
}