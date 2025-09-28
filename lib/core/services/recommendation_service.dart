import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

import 'analytics_service.dart';

class RecommendationService {
  final SupabaseClient _supabase;
  final AnalyticsService _analyticsService;
  final Logger _logger = Logger();

  RecommendationService(this._supabase, this._analyticsService);

  /// 사용자 맞춤 제품 추천
  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // 사용자 행동 분석 데이터 가져오기
      final behaviorAnalysis = await _analyticsService.getUserBehaviorAnalysis(userId);
      
      // 사용자의 반려견 정보 가져오기
      final petInfo = await _getUserPetInfo(userId);
      
      // 추천 점수 계산
      final recommendations = await _calculateRecommendationScores(
        userId: userId,
        behaviorAnalysis: behaviorAnalysis,
        petInfo: petInfo,
        limit: limit,
      );

      // 추천 결과 저장
      await _saveRecommendations(userId, recommendations);

      return recommendations;
    } catch (e) {
      _logger.e('Failed to get personalized recommendations: $e');
      return [];
    }
  }

  /// 건강 기반 제품 추천
  Future<List<Map<String, dynamic>>> getHealthBasedRecommendations({
    required String userId,
    required String petId,
    int limit = 5,
  }) async {
    try {
      // 반려견의 건강 기록 가져오기
      final healthRecords = await _supabase
          .from('health_records')
          .select()
          .eq('pet_id', petId)
          .order('recorded_at', ascending: false)
          .limit(10);

      // 건강 이슈 추출
      final healthIssues = <String>[];
      for (final record in healthRecords) {
        final recordType = record['record_type'] as String?;
        if (recordType != null) {
          healthIssues.add(recordType);
        }
      }

      // 건강 이슈에 맞는 제품 추천
      final recommendations = await _getProductsByHealthIssues(healthIssues, limit);

      return recommendations;
    } catch (e) {
      _logger.e('Failed to get health-based recommendations: $e');
      return [];
    }
  }

  /// 협업 필터링 기반 추천
  Future<List<Map<String, dynamic>>> getCollaborativeRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // 유사한 사용자 찾기
      final similarUsers = await _findSimilarUsers(userId);
      
      if (similarUsers.isEmpty) {
        return [];
      }

      // 유사 사용자들이 구매한 제품 중 현재 사용자가 구매하지 않은 제품 추천
      final recommendations = await _getProductsFromSimilarUsers(
        userId: userId,
        similarUsers: similarUsers,
        limit: limit,
      );

      return recommendations;
    } catch (e) {
      _logger.e('Failed to get collaborative recommendations: $e');
      return [];
    }
  }

  /// 카테고리 기반 추천
  Future<List<Map<String, dynamic>>> getCategoryBasedRecommendations({
    required String userId,
    required String category,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('products')
          .select('''
            *,
            product_categories!inner(name)
          ''')
          .eq('product_categories.name', category)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      _logger.e('Failed to get category-based recommendations: $e');
      return [];
    }
  }

  /// 인기 제품 추천
  Future<List<Map<String, dynamic>>> getPopularRecommendations({
    int limit = 10,
  }) async {
    try {
      // 최근 30일간 가장 많이 조회된 제품
      final popularProducts = await _supabase.rpc('get_popular_products', params: {
        'days_limit': 30,
        'result_limit': limit,
      });

      return popularProducts as List<Map<String, dynamic>>;
    } catch (e) {
      _logger.e('Failed to get popular recommendations: $e');
      return [];
    }
  }

  /// 사용자 반려견 정보 가져오기
  Future<List<Map<String, dynamic>>> _getUserPetInfo(String userId) async {
    try {
      final response = await _supabase
          .from('pets')
          .select()
          .eq('user_id', userId);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      _logger.e('Failed to get user pet info: $e');
      return [];
    }
  }

  /// 추천 점수 계산
  Future<List<Map<String, dynamic>>> _calculateRecommendationScores({
    required String userId,
    required Map<String, dynamic> behaviorAnalysis,
    required List<Map<String, dynamic>> petInfo,
    required int limit,
  }) async {
    try {
      // 모든 활성 제품 가져오기
      final products = await _supabase
          .from('products')
          .select('''
            *,
            product_categories(name)
          ''')
          .eq('is_active', true);

      final scoredProducts = <Map<String, dynamic>>[];

      for (final product in products) {
        double score = 0.0;

        // 1. 카테고리 선호도 점수
        final preferredCategory = behaviorAnalysis['preferred_category'] as String?;
        final productCategory = product['product_categories']?['name'] as String?;
        
        if (preferredCategory != null && productCategory == preferredCategory) {
          score += 30.0;
        }

        // 2. 최근 조회 제품과의 유사성
        final topViewedProducts = behaviorAnalysis['top_viewed_products'] as List<dynamic>? ?? [];
        if (topViewedProducts.contains(product['id'])) {
          score += 20.0;
        }

        // 3. 반려견 정보 기반 점수
        if (petInfo.isNotEmpty) {
          final targetHealthIssues = product['target_health_issues'] as List<dynamic>? ?? [];
          final ageGroup = product['age_group'] as String?;
          final sizeGroup = product['size_group'] as String?;

          // 나이 그룹 매칭
          for (final pet in petInfo) {
            final petAge = _calculatePetAge(pet['birth_date'] as String?);
            if (_matchesAgeGroup(petAge, ageGroup)) {
              score += 15.0;
            }

            // 크기 그룹 매칭 (체중 기반)
            final petWeight = pet['weight'] as double?;
            if (_matchesSizeGroup(petWeight, sizeGroup)) {
              score += 10.0;
            }
          }
        }

        // 4. 가격 선호도 (사용자의 평균 구매 가격대 고려)
        final avgPurchaseAmount = await _getUserAveragePurchaseAmount(userId);
        final priceScore = _calculatePriceScore(product['price'] as int, avgPurchaseAmount);
        score += priceScore;

        // 5. 제품 평점
        final rating = await _getProductRating(product['id'] as String);
        score += rating * 2;

        scoredProducts.add({
          ...product,
          'recommendation_score': score,
          'recommendation_type': 'personalized',
        });
      }

      // 점수순으로 정렬하고 상위 제품 반환
      scoredProducts.sort((a, b) => 
        (b['recommendation_score'] as double).compareTo(a['recommendation_score'] as double));

      return scoredProducts.take(limit).toList();
    } catch (e) {
      _logger.e('Failed to calculate recommendation scores: $e');
      return [];
    }
  }

  /// 건강 이슈별 제품 가져오기
  Future<List<Map<String, dynamic>>> _getProductsByHealthIssues(
    List<String> healthIssues,
    int limit,
  ) async {
    if (healthIssues.isEmpty) return [];

    try {
      final response = await _supabase
          .from('products')
          .select()
          .overlaps('target_health_issues', healthIssues)
          .eq('is_active', true)
          .limit(limit);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      _logger.e('Failed to get products by health issues: $e');
      return [];
    }
  }

  /// 유사한 사용자 찾기
  Future<List<String>> _findSimilarUsers(String userId) async {
    try {
      // 간단한 협업 필터링: 비슷한 구매 패턴을 가진 사용자 찾기
      final userPurchases = await _supabase
          .from('order_items')
          .select('product_id, orders!inner(user_id)')
          .eq('orders.user_id', userId);

      final userProductIds = userPurchases
          .map((item) => item['product_id'] as String)
          .toSet();

      if (userProductIds.isEmpty) return [];

      // 같은 제품을 구매한 다른 사용자들 찾기
      final similarUserPurchases = await _supabase
          .from('order_items')
          .select('orders!inner(user_id)')
          .inFilter('product_id', userProductIds.toList())
          .neq('orders.user_id', userId);

      final similarUsers = <String, int>{};
      for (final purchase in similarUserPurchases) {
        final otherUserId = purchase['orders']['user_id'] as String;
        similarUsers[otherUserId] = (similarUsers[otherUserId] ?? 0) + 1;
      }

      // 공통 구매 제품이 많은 순으로 정렬
      final sortedUsers = similarUsers.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedUsers.take(10).map((e) => e.key).toList();
    } catch (e) {
      _logger.e('Failed to find similar users: $e');
      return [];
    }
  }

  /// 유사 사용자들의 제품 추천
  Future<List<Map<String, dynamic>>> _getProductsFromSimilarUsers({
    required String userId,
    required List<String> similarUsers,
    required int limit,
  }) async {
    try {
      // 현재 사용자가 구매한 제품들
      final userPurchases = await _supabase
          .from('order_items')
          .select('product_id, orders!inner(user_id)')
          .eq('orders.user_id', userId);

      final userProductIds = userPurchases
          .map((item) => item['product_id'] as String)
          .toSet();

      // 유사 사용자들이 구매한 제품들 (현재 사용자가 구매하지 않은 것만)
      final similarUserPurchases = await _supabase
          .from('order_items')
          .select('product_id, orders!inner(user_id)')
          .inFilter('orders.user_id', similarUsers);

      final recommendedProductIds = <String, int>{};
      for (final purchase in similarUserPurchases) {
        final productId = purchase['product_id'] as String;
        if (!userProductIds.contains(productId)) {
          recommendedProductIds[productId] = (recommendedProductIds[productId] ?? 0) + 1;
        }
      }

      // 추천 빈도순으로 정렬
      final sortedProductIds = recommendedProductIds.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topProductIds = sortedProductIds.take(limit).map((e) => e.key).toList();

      if (topProductIds.isEmpty) return [];

      // 제품 정보 가져오기
      final products = await _supabase
          .from('products')
          .select()
          .inFilter('id', topProductIds)
          .eq('is_active', true);

      return products as List<Map<String, dynamic>>;
    } catch (e) {
      _logger.e('Failed to get products from similar users: $e');
      return [];
    }
  }

  /// 추천 결과 저장
  Future<void> _saveRecommendations(
    String userId,
    List<Map<String, dynamic>> recommendations,
  ) async {
    try {
      final recommendationData = recommendations.map((product) => {
        'user_id': userId,
        'product_id': product['id'],
        'recommendation_type': product['recommendation_type'] ?? 'personalized',
        'score': product['recommendation_score'] ?? 0.0,
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      }).toList();

      // 기존 추천 삭제
      await _supabase
          .from('product_recommendations')
          .delete()
          .eq('user_id', userId);

      // 새 추천 저장
      await _supabase
          .from('product_recommendations')
          .insert(recommendationData);

    } catch (e) {
      _logger.e('Failed to save recommendations: $e');
    }
  }

  /// 반려견 나이 계산
  int _calculatePetAge(String? birthDate) {
    if (birthDate == null) return 0;
    
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      return now.difference(birth).inDays ~/ 365;
    } catch (e) {
      return 0;
    }
  }

  /// 나이 그룹 매칭
  bool _matchesAgeGroup(int petAge, String? ageGroup) {
    if (ageGroup == null || ageGroup == 'all') return true;
    
    switch (ageGroup) {
      case 'puppy':
        return petAge < 1;
      case 'adult':
        return petAge >= 1 && petAge < 7;
      case 'senior':
        return petAge >= 7;
      default:
        return true;
    }
  }

  /// 크기 그룹 매칭
  bool _matchesSizeGroup(double? petWeight, String? sizeGroup) {
    if (sizeGroup == null || sizeGroup == 'all' || petWeight == null) return true;
    
    switch (sizeGroup) {
      case 'small':
        return petWeight < 10;
      case 'medium':
        return petWeight >= 10 && petWeight < 25;
      case 'large':
        return petWeight >= 25;
      default:
        return true;
    }
  }

  /// 사용자 평균 구매 금액 계산
  Future<double> _getUserAveragePurchaseAmount(String userId) async {
    try {
      final orders = await _supabase
          .from('orders')
          .select('final_price')
          .eq('user_id', userId)
          .eq('status', 'delivered');

      if (orders.isEmpty) return 25000.0; // 기본값

      final totalAmount = orders.fold<int>(0, (sum, order) => sum + (order['final_price'] as int));
      return totalAmount / orders.length;
    } catch (e) {
      return 25000.0; // 기본값
    }
  }

  /// 가격 점수 계산
  double _calculatePriceScore(int productPrice, double avgPurchaseAmount) {
    final priceDiff = (productPrice - avgPurchaseAmount).abs();
    final maxScore = 10.0;
    
    // 평균 구매 금액과 가까울수록 높은 점수
    if (priceDiff <= avgPurchaseAmount * 0.2) {
      return maxScore;
    } else if (priceDiff <= avgPurchaseAmount * 0.5) {
      return maxScore * 0.7;
    } else {
      return maxScore * 0.3;
    }
  }

  /// 제품 평점 가져오기
  Future<double> _getProductRating(String productId) async {
    try {
      final reviews = await _supabase
          .from('product_reviews')
          .select('rating')
          .eq('product_id', productId);

      if (reviews.isEmpty) return 0.0;

      final totalRating = reviews.fold<int>(0, (sum, review) => sum + (review['rating'] as int));
      return totalRating / reviews.length;
    } catch (e) {
      return 0.0;
    }
  }
}
