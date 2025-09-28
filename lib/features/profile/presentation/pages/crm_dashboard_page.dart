import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../core/injection/injection_container.dart';

class CRMDashboardPage extends StatefulWidget {
  final String userId;

  const CRMDashboardPage({
    super.key,
    required this.userId,
  });

  @override
  State<CRMDashboardPage> createState() => _CRMDashboardPageState();
}

class _CRMDashboardPageState extends State<CRMDashboardPage> {
  final AnalyticsService _analyticsService = sl<AnalyticsService>();
  final RecommendationService _recommendationService = sl<RecommendationService>();

  Map<String, dynamic> _behaviorAnalysis = {};
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 행동 분석 데이터 로드
      final behaviorAnalysis = await _analyticsService.getUserBehaviorAnalysis(widget.userId);
      
      // 개인화 추천 데이터 로드
      final recommendations = await _recommendationService.getPersonalizedRecommendations(
        userId: widget.userId,
        limit: 5,
      );

      setState(() {
        _behaviorAnalysis = behaviorAnalysis;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인화 대시보드'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사용자 활동 요약
                    _buildActivitySummaryCard(),
                    
                    const SizedBox(height: 16),
                    
                    // 선호도 분석
                    _buildPreferenceAnalysisCard(),
                    
                    const SizedBox(height: 16),
                    
                    // 개인화 추천
                    _buildPersonalizedRecommendationsCard(),
                    
                    const SizedBox(height: 16),
                    
                    // 참여도 점수
                    _buildEngagementScoreCard(),
                    
                    const SizedBox(height: 16),
                    
                    // 최근 검색어
                    _buildRecentSearchesCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActivitySummaryCard() {
    final totalActivities = _behaviorAnalysis['total_activities'] ?? 0;
    final activityCounts = _behaviorAnalysis['activity_counts'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.chartLine,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '활동 요약',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '최근 30일간 총 $totalActivities개의 활동',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            ...activityCounts.entries.map((entry) {
              final activityType = entry.key;
              final count = entry.value as int;
              final activityName = _getActivityName(activityType);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(activityName),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceAnalysisCard() {
    final preferredCategory = _behaviorAnalysis['preferred_category'] as String?;
    final topViewedProducts = _behaviorAnalysis['top_viewed_products'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.heart,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '선호도 분석',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (preferredCategory != null) ...[
              Row(
                children: [
                  const Text('선호 카테고리: '),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      preferredCategory,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (topViewedProducts.isNotEmpty) ...[
              const Text('관심 제품:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: topViewedProducts.take(3).map((productId) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '제품 ${productId.toString().substring(0, 8)}...',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      MdiIcons.lightbulb,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '맞춤 추천',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // 전체 추천 페이지로 이동
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recommendations.isEmpty)
              const Text('추천할 제품이 없습니다.')
            else
              Column(
                children: _recommendations.take(3).map((product) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            MdiIcons.package,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? '제품명',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product['price']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    MdiIcons.star,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '추천도: ${(product['recommendation_score'] as double? ?? 0.0).toStringAsFixed(1)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(MdiIcons.chevronRight),
                          onPressed: () {
                            // 제품 상세 페이지로 이동
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementScoreCard() {
    final engagementScore = _behaviorAnalysis['engagement_score'] as double? ?? 0.0;
    final maxScore = 100.0;
    final normalizedScore = (engagementScore / maxScore * 100).clamp(0.0, 100.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.trophy,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  '참여도 점수',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: normalizedScore / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(normalizedScore),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${normalizedScore.toInt()}점',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(normalizedScore),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getScoreDescription(normalizedScore),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchesCard() {
    final recentSearches = _behaviorAnalysis['recent_searches'] as List<dynamic>? ?? [];

    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.magnify,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '최근 검색어',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSearches.take(5).map((search) {
                return GestureDetector(
                  onTap: () {
                    // 해당 검색어로 검색 실행
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      search.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getActivityName(String activityType) {
    switch (activityType) {
      case 'session_start':
        return '앱 실행';
      case 'view_product':
        return '제품 조회';
      case 'search':
        return '검색';
      case 'add_to_cart':
        return '장바구니 추가';
      case 'purchase':
        return '구매';
      default:
        return activityType;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getScoreDescription(double score) {
    if (score >= 80) {
      return '매우 활발한 사용자입니다!';
    } else if (score >= 60) {
      return '활발한 사용자입니다.';
    } else if (score >= 40) {
      return '보통 수준의 사용자입니다.';
    } else {
      return '더 많은 활동을 해보세요!';
    }
  }
}
