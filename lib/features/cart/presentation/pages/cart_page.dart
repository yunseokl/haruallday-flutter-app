import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/cart_service.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary_card.dart';
import '../widgets/coupon_input_widget.dart';

class CartPage extends StatefulWidget {
  final String userId;

  const CartPage({
    super.key,
    required this.userId,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = sl<CartService>();
  
  List<Map<String, dynamic>> _cartItems = [];
  Map<String, int> _cartTotal = {};
  bool _isLoading = true;
  String? _appliedCouponCode;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartItems = await _cartService.getCartItems(userId: widget.userId);
      final cartTotal = await _cartService.calculateCartTotal(
        userId: widget.userId,
        couponCode: _appliedCouponCode,
      );

      setState(() {
        _cartItems = cartItems;
        _cartTotal = cartTotal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('장바구니를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(String cartItemId, int newQuantity) async {
    try {
      await _cartService.updateCartItemQuantity(
        userId: widget.userId,
        cartItemId: cartItemId,
        quantity: newQuantity,
      );
      
      await _loadCartData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수량 변경에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    try {
      await _cartService.removeFromCart(
        userId: widget.userId,
        cartItemId: cartItemId,
      );
      
      await _loadCartData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품이 장바구니에서 제거되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상품 제거에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _applyCoupon(String couponCode) async {
    try {
      final subtotal = _cartTotal['subtotal'] ?? 0;
      final validation = await _cartService.validateCoupon(
        userId: widget.userId,
        couponCode: couponCode,
        subtotal: subtotal,
      );

      if (validation['valid'] == true) {
        setState(() {
          _appliedCouponCode = couponCode;
        });
        
        await _loadCartData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(validation['message'] ?? '쿠폰이 적용되었습니다.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(validation['message'] ?? '쿠폰 적용에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('쿠폰 적용에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _removeCoupon() async {
    setState(() {
      _appliedCouponCode = null;
    });
    
    await _loadCartData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('쿠폰이 제거되었습니다.')),
      );
    }
  }

  void _proceedToCheckout() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장바구니가 비어있습니다.')),
      );
      return;
    }

    context.push(
      AppRouter.checkout,
      extra: {
        'userId': widget.userId,
        'cartItems': _cartItems,
        'cartTotal': _cartTotal,
        'appliedCouponCode': _appliedCouponCode,
      },
    ).then((_) {
      // 결제 완료 후 장바구니 새로고침
      _loadCartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('장바구니 비우기'),
                    content: const Text('장바구니의 모든 상품을 제거하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => context.pop(true),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await _cartService.clearCart(userId: widget.userId);
                    await _loadCartData();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('장바구니가 비워졌습니다.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('장바구니 비우기에 실패했습니다: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text(
                '전체삭제',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCartData,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // 장바구니 항목들
                            ..._cartItems.map((item) => CartItemCard(
                              cartItem: item,
                              onQuantityChanged: (newQuantity) {
                                _updateQuantity(item['id'] as String, newQuantity);
                              },
                              onRemove: () {
                                _removeItem(item['id'] as String);
                              },
                            )).toList(),
                            
                            const SizedBox(height: 16),
                            
                            // 쿠폰 입력
                            CouponInputWidget(
                              appliedCouponCode: _appliedCouponCode,
                              onApplyCoupon: _applyCoupon,
                              onRemoveCoupon: _removeCoupon,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 주문 요약
                            CartSummaryCard(cartTotal: _cartTotal),
                          ],
                        ),
                      ),
                    ),
                    
                    // 결제 버튼
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _proceedToCheckout,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text(
                              '${(_cartTotal['total'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원 결제하기',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            MdiIcons.cartOutline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '장바구니가 비어있습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '우리 아이를 위한 제품을 담아보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // 홈 페이지로 이동
              context.go(AppRouter.home);
            },
            child: const Text('쇼핑 계속하기'),
          ),
        ],
      ),
    );
  }
}
