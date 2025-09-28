import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HealthTipsSection extends StatelessWidget {
  const HealthTipsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final healthTips = [
      HealthTip(
        title: '강아지 관절 건강 관리법',
        summary: '슬개골 탈구 예방을 위한 일상 관리 방법을 알아보세요.',
        imageUrl: 'assets/images/joint_care.jpg',
        category: '관절 건강',
        readTime: '3분',
        publishDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      HealthTip(
        title: '반려견 피부 트러블 대처법',
        summary: '습진과 알레르기성 피부염의 원인과 관리 방법',
        imageUrl: 'assets/images/skin_care.jpg',
        category: '피부 건강',
        readTime: '5분',
        publishDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      HealthTip(
        title: '강아지 장 건강을 위한 식단',
        summary: '소화 불량과 설사를 예방하는 올바른 식단 구성',
        imageUrl: 'assets/images/diet_care.jpg',
        category: '장 건강',
        readTime: '4분',
        publishDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '건강 정보',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // 건강 정보 전체 페이지로 이동
                },
                child: const Text('전체보기'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: healthTips.length,
          itemBuilder: (context, index) {
            final tip = healthTips[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: HealthTipCard(tip: tip),
            );
          },
        ),
      ],
    );
  }
}

class HealthTipCard extends StatelessWidget {
  final HealthTip tip;

  const HealthTipCard({
    super.key,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 건강 팁 상세 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HealthTipDetailPage(tip: tip),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 이미지
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: Image.asset(
                  tip.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        MdiIcons.image,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),
            // 내용
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tip.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 제목
                    Text(
                      tip.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 요약
                    Text(
                      tip.summary,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // 메타 정보
                    Row(
                      children: [
                        Icon(
                          MdiIcons.clockOutline,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tip.readTime,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          MdiIcons.calendarOutline,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(tip.publishDate),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '어제';
    } else if (difference < 7) {
      return '${difference}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class HealthTip {
  final String title;
  final String summary;
  final String imageUrl;
  final String category;
  final String readTime;
  final DateTime publishDate;

  HealthTip({
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.category,
    required this.readTime,
    required this.publishDate,
  });
}

class HealthTipDetailPage extends StatelessWidget {
  final HealthTip tip;

  const HealthTipDetailPage({
    super.key,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tip.category),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 이미지
            Container(
              width: double.infinity,
              height: 200,
              child: Image.asset(
                tip.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(
                      MdiIcons.image,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리와 메타 정보
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tip.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${tip.readTime} • ${_formatDate(tip.publishDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 제목
                  Text(
                    tip.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 내용
                  Text(
                    tip.summary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '상세한 건강 정보 내용이 여기에 표시됩니다.\n\n'
                    '반려견의 건강 관리는 매우 중요합니다. 정기적인 검진과 올바른 영양 공급, '
                    '적절한 운동을 통해 우리 반려견이 건강하고 행복한 삶을 살 수 있도록 도와주세요.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '어제';
    } else if (difference < 7) {
      return '${difference}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
