import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class AnalyticsService {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;
  final Logger _logger = Logger();

  AnalyticsService(this._supabase, this._prefs);

  /// 사용자 활동 추적
  Future<void> trackUserActivity({
    required String userId,
    required String activityType,
    Map<String, dynamic>? activityData,
  }) async {
    try {
      final activity = {
        'user_id': userId,
        'activity_type': activityType,
        'activity_data': activityData ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      // Supabase에 저장
      await _supabase.from('user_activities').insert(activity);

      // 로컬에도 임시 저장 (오프라인 대응)
      await _saveActivityLocally(activity);

      _logger.i('Activity tracked: $activityType for user $userId');
    } catch (e) {
      _logger.e('Failed to track activity: $e');
      // 실패 시 로컬에만 저장
      await _saveActivityLocally({
        'user_id': userId,
        'activity_type': activityType,
        'activity_data': activityData ?? {},
        'created_at': DateTime.now().toIso8601String(),
        'synced': false,
      });
    }
  }

  /// 제품 조회 추적
  Future<void> trackProductView({
    required String userId,
    required String productId,
    required String productName,
    String? category,
  }) async {
    await trackUserActivity(
      userId: userId,
      activityType: 'view_product',
      activityData: {
        'product_id': productId,
        'product_name': productName,
        'category': category,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// 장바구니 추가 추적
  Future<void> trackAddToCart({
    required String userId,
    required String productId,
    required int quantity,
    required int price,
  }) async {
    await trackUserActivity(
      userId: userId,
      activityType: 'add_to_cart',
      activityData: {
        'product_id': productId,
        'quantity': quantity,
        'price': price,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// 구매 추적
  Future<void> trackPurchase({
    required String userId,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
  }) async {
    await trackUserActivity(
      userId: userId,
      activityType: 'purchase',
      activityData: {
        'order_id': orderId,
        'items': items,
        'total_amount': totalAmount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// 검색 추적
  Future<void> trackSearch({
    required String userId,
    required String searchQuery,
    int? resultCount,
  }) async {
    await trackUserActivity(
      userId: userId,
      activityType: 'search',
      activityData: {
        'search_query': searchQuery,
        'result_count': resultCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// 앱 세션 시작 추적
  Future<void> trackSessionStart({
    required String userId,
    String? deviceInfo,
  }) async {
    await trackUserActivity(
      userId: userId,
      activityType: 'session_start',
      activityData: {
        'device_info': deviceInfo,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// 앱 세션 종료 추적
  Future<void> trackSessionEnd({
    required String userId,
    required Duration sessionDuration,
  }) async {
    await trackUserActivity(
      userId: userId,
      activityType: 'session_end',
      activityData: {
        'session_duration_seconds': sessionDuration.inSeconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// 사용자 행동 패턴 분석
  Future<Map<String, dynamic>> getUserBehaviorAnalysis(String userId) async {
    try {
      final response = await _supabase
          .from('user_activities')
          .select()
          .eq('user_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .order('created_at', ascending: false);

      final activities = response as List<dynamic>;

      // 활동 유형별 집계
      final activityCounts = <String, int>{};
      final productViews = <String, int>{};
      final searchQueries = <String>[];
      final categories = <String, int>{};

      for (final activity in activities) {
        final activityType = activity['activity_type'] as String;
        final activityData = activity['activity_data'] as Map<String, dynamic>?;

        activityCounts[activityType] = (activityCounts[activityType] ?? 0) + 1;

        if (activityType == 'view_product' && activityData != null) {
          final productId = activityData['product_id'] as String?;
          final category = activityData['category'] as String?;
          
          if (productId != null) {
            productViews[productId] = (productViews[productId] ?? 0) + 1;
          }
          
          if (category != null) {
            categories[category] = (categories[category] ?? 0) + 1;
          }
        }

        if (activityType == 'search' && activityData != null) {
          final searchQuery = activityData['search_query'] as String?;
          if (searchQuery != null) {
            searchQueries.add(searchQuery);
          }
        }
      }

      // 선호 카테고리 결정
      final preferredCategory = categories.isNotEmpty
          ? categories.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;

      // 최근 관심 제품
      final recentProducts = productViews.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'total_activities': activities.length,
        'activity_counts': activityCounts,
        'preferred_category': preferredCategory,
        'top_viewed_products': recentProducts.take(5).map((e) => e.key).toList(),
        'recent_searches': searchQueries.take(10).toList(),
        'engagement_score': _calculateEngagementScore(activityCounts),
      };
    } catch (e) {
      _logger.e('Failed to analyze user behavior: $e');
      return {};
    }
  }

  /// 참여도 점수 계산
  double _calculateEngagementScore(Map<String, int> activityCounts) {
    double score = 0.0;
    
    // 활동 유형별 가중치
    final weights = {
      'session_start': 1.0,
      'view_product': 2.0,
      'search': 1.5,
      'add_to_cart': 5.0,
      'purchase': 10.0,
    };

    activityCounts.forEach((activityType, count) {
      final weight = weights[activityType] ?? 1.0;
      score += count * weight;
    });

    return score;
  }

  /// 로컬에 활동 저장
  Future<void> _saveActivityLocally(Map<String, dynamic> activity) async {
    try {
      final localActivities = _prefs.getStringList('local_activities') ?? [];
      localActivities.add(jsonEncode(activity));
      
      // 최대 100개까지만 로컬에 저장
      if (localActivities.length > 100) {
        localActivities.removeAt(0);
      }
      
      await _prefs.setStringList('local_activities', localActivities);
    } catch (e) {
      _logger.e('Failed to save activity locally: $e');
    }
  }

  /// 로컬 활동 동기화
  Future<void> syncLocalActivities() async {
    try {
      final localActivities = _prefs.getStringList('local_activities') ?? [];
      final unsyncedActivities = <Map<String, dynamic>>[];

      for (final activityJson in localActivities) {
        final activity = jsonDecode(activityJson) as Map<String, dynamic>;
        if (activity['synced'] == false) {
          unsyncedActivities.add(activity);
        }
      }

      if (unsyncedActivities.isNotEmpty) {
        // 동기화되지 않은 활동들을 Supabase에 일괄 업로드
        await _supabase.from('user_activities').insert(
          unsyncedActivities.map((activity) {
            activity.remove('synced');
            return activity;
          }).toList(),
        );

        // 로컬 저장소 정리
        await _prefs.remove('local_activities');
        _logger.i('Synced ${unsyncedActivities.length} local activities');
      }
    } catch (e) {
      _logger.e('Failed to sync local activities: $e');
    }
  }
}
