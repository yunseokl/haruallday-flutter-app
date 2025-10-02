import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/product_service.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../products/presentation/widgets/product_card.dart';

class FeaturedProducts extends StatefulWidget {
  const FeaturedProducts({super.key});

  @override
  State<FeaturedProducts> createState() => _FeaturedProductsState();
}

class _FeaturedProductsState extends State<FeaturedProducts> {
  final ProductService _productService = sl<ProductService>();
  final CartService _cartService = sl<CartService>();
  final AuthService _authService = sl<AuthService>();
  
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getFeaturedProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading featured products: $e');
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final result = await _cartService.addToCart(
        userId: userId,
        productId: product['id'],
        quantity: 1,
      );

      if (mounted) {
        final resultMap = result as Map<String, dynamic>? ?? {};
        if (resultMap['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('장바구니에 추가되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultMap['message']?.toString() ?? '장바구니 추가에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '추천 제품',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push(AppRouter.products);
                },
                child: const Text('전체보기'),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (_isLoading)
          const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_products.isEmpty)
          const SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('추천 제품이 없습니다.'),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Container(
                  width: 180,
                  margin: EdgeInsets.only(
                    right: index < _products.length - 1 ? 16 : 0,
                  ),
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      context.push('${AppRouter.productDetail}/${product['id']}');
                    },
                    onAddToCart: () => _addToCart(product),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
