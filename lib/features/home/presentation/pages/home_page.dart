import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../widgets/home_app_bar.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_grid.dart';
import '../widgets/featured_products.dart';
import '../widgets/health_tips_section.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../pets/presentation/pages/my_pets_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/injection/injection_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  final AuthService _authService = sl<AuthService>();

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContent(),
      const ProductsPage(),
      _buildCartPage(),
      const MyPetsPage(),
      const ProfilePage(),
    ];
  }

  Widget _buildCartPage() {
    final userId = _authService.currentUserId;
    if (userId != null) {
      return CartPage(userId: userId);
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('장바구니'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('로그인이 필요합니다.'),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.shopping),
            label: '제품',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.cart),
            label: '장바구니',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.dog),
            label: '내 반려견',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.account),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 배너 캐러셀
            const BannerCarousel(),
            
            const SizedBox(height: 24),
            
            // 카테고리 그리드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '카테고리',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CategoryGrid(),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 추천 제품
            const FeaturedProducts(),
            
            const SizedBox(height: 32),
            
            // 건강 팁
            const HealthTipsSection(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// 임시 페이지들 (추후 실제 구현으로 교체 예정)




