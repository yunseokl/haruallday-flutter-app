import 'package:flutter/material.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<BannerItem> _banners = [
    BannerItem(
      title: '신규 가입 혜택',
      subtitle: '첫 구매 시 10% 할인',
      imageUrl: 'assets/images/banner1.jpg',
      backgroundColor: const Color(0xFF2E7D32),
    ),
    BannerItem(
      title: '건강한 관절을 위한',
      subtitle: '하루올데이 관절 영양제',
      imageUrl: 'assets/images/banner2.jpg',
      backgroundColor: const Color(0xFFFF8F00),
    ),
    BannerItem(
      title: '우리 아이 피부 건강',
      subtitle: '피부 영양제 특가 이벤트',
      imageUrl: 'assets/images/banner3.jpg',
      backgroundColor: const Color(0xFF1976D2),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 자동 슬라이드
    Future.delayed(const Duration(seconds: 3), _autoSlide);
  }

  void _autoSlide() {
    if (mounted) {
      setState(() {
        _currentPage = (_currentPage + 1) % _banners.length;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      Future.delayed(const Duration(seconds: 3), _autoSlide);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      banner.backgroundColor,
                      banner.backgroundColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 배경 이미지
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: banner.backgroundColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // 텍스트 오버레이
                    Positioned(
                      left: 24,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner.subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // 배너 클릭 액션
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: banner.backgroundColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('자세히 보기'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 페이지 인디케이터
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _banners.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class BannerItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color backgroundColor;

  BannerItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.backgroundColor,
  });
}
