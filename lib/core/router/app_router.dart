import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/pets/presentation/pages/my_pets_page.dart';
import '../../features/pets/presentation/pages/add_pet_page.dart';
import '../../features/pets/presentation/pages/pet_detail_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../services/auth_service.dart';
import '../injection/injection_container.dart';

/// 앱 라우팅 설정
class AppRouter {
  static final AuthService _authService = sl<AuthService>();

  /// 라우트 이름 상수
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String products = '/products';
  static const String productDetail = '/products/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderComplete = '/order-complete';
  static const String pets = '/pets';
  static const String addPet = '/pets/add';
  static const String petDetail = '/pets/:id';
  static const String profile = '/profile';

  /// GoRouter 인스턴스
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    redirect: _handleRedirect,
    routes: [
      // Splash
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Auth
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: signup,
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),

      // Home (메인 네비게이션)
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // Products
      GoRoute(
        path: products,
        name: 'products',
        builder: (context, state) => const ProductsPage(),
      ),
      GoRoute(
        path: productDetail,
        name: 'productDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailPage(productId: id);
        },
      ),

      // Cart
      GoRoute(
        path: cart,
        name: 'cart',
        builder: (context, state) {
          final userId = _authService.currentUserId ?? '';
          return CartPage(userId: userId);
        },
      ),

      // Checkout
      GoRoute(
        path: checkout,
        name: 'checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CheckoutPage(
            userId: extra?['userId'] ?? '',
            cartItems: extra?['cartItems'] ?? [],
            cartTotal: extra?['cartTotal'] ?? {},
            appliedCouponCode: extra?['appliedCouponCode'],
          );
        },
      ),

      // Order Complete
      GoRoute(
        path: orderComplete,
        name: 'orderComplete',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          // OrderCompletePage가 없으므로 임시로 간단한 페이지 표시
          return Scaffold(
            appBar: AppBar(title: const Text('주문 완료')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 100, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('주문이 완료되었습니다!', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go(home),
                    child: const Text('홈으로 돌아가기'),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // Pets
      GoRoute(
        path: pets,
        name: 'pets',
        builder: (context, state) => const MyPetsPage(),
      ),
      GoRoute(
        path: addPet,
        name: 'addPet',
        builder: (context, state) => const AddPetPage(),
      ),
      GoRoute(
        path: petDetail,
        name: 'petDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final pet = state.extra as Map<String, dynamic>?;
          return PetDetailPage(petId: id, pet: pet);
        },
      ),

      // Profile
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('페이지를 찾을 수 없습니다: ${state.uri.path}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
  );

  /// 리다이렉트 처리
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = _authService.isLoggedIn;
    final isSplash = state.matchedLocation == splash;
    final isAuth = state.matchedLocation == login || state.matchedLocation == signup;

    // Splash는 항상 허용
    if (isSplash) {
      return null;
    }

    // 로그인 필요한 페이지 목록
    final protectedRoutes = [cart, checkout, addPet];
    final isProtectedRoute = protectedRoutes.any((route) =>
      state.matchedLocation.startsWith(route.split(':').first)
    );

    // 로그인 안 된 상태에서 보호된 페이지 접근 시 로그인 페이지로
    if (!isLoggedIn && isProtectedRoute) {
      return login;
    }

    // 로그인된 상태에서 인증 페이지 접근 시 홈으로
    if (isLoggedIn && isAuth) {
      return home;
    }

    return null;
  }
}
