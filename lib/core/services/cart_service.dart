import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

import 'analytics_service.dart';

class CartService {
  final SupabaseClient _supabase;
  final AnalyticsService _analyticsService;
  final Logger _logger = Logger();

  CartService(this._supabase, this._analyticsService);

  /// 장바구니에 제품 추가
  Future<bool> addToCart({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      // 제품 정보 확인
      final productResponse = await _supabase
          .from('products')
          .select('id, name, price, stock_quantity')
          .eq('id', productId)
          .eq('is_active', true)
          .single();

      final product = productResponse as Map<String, dynamic>;
      final stockQuantity = product['stock_quantity'] as int? ?? 0;

      // 재고 확인
      if (stockQuantity < quantity) {
        throw Exception('재고가 부족합니다. (재고: $stockQuantity개)');
      }

      // 기존 장바구니 항목 확인
      final existingItemResponse = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItemResponse != null) {
        // 기존 항목이 있으면 수량 업데이트
        final existingItem = existingItemResponse as Map<String, dynamic>;
        final newQuantity = (existingItem['quantity'] as int) + quantity;

        if (stockQuantity < newQuantity) {
          throw Exception('재고가 부족합니다. (재고: $stockQuantity개, 요청: $newQuantity개)');
        }

        await _supabase
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingItem['id']);
      } else {
        // 새 항목 추가
        await _supabase.from('cart_items').insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // 사용자 활동 추적
      await _analyticsService.trackAddToCart(
        userId: userId,
        productId: productId,
        quantity: quantity,
        price: product['price'] as int,
      );

      _logger.i('Added to cart: $productId x$quantity for user $userId');
      return true;
    } catch (e) {
      _logger.e('Failed to add to cart: $e');
      rethrow;
    }
  }

  /// 장바구니 항목 수량 업데이트
  Future<bool> updateCartItemQuantity({
    required String userId,
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        return await removeFromCart(userId: userId, cartItemId: cartItemId);
      }

      // 장바구니 항목 확인
      final cartItemResponse = await _supabase
          .from('cart_items')
          .select('''
            id,
            quantity,
            product_id,
            products!inner(stock_quantity)
          ''')
          .eq('id', cartItemId)
          .eq('user_id', userId)
          .single();

      final cartItem = cartItemResponse as Map<String, dynamic>;
      final stockQuantity = cartItem['products']['stock_quantity'] as int? ?? 0;

      if (stockQuantity < quantity) {
        throw Exception('재고가 부족합니다. (재고: $stockQuantity개)');
      }

      await _supabase
          .from('cart_items')
          .update({
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cartItemId);

      _logger.i('Updated cart item quantity: $cartItemId to $quantity');
      return true;
    } catch (e) {
      _logger.e('Failed to update cart item quantity: $e');
      rethrow;
    }
  }

  /// 장바구니에서 제품 제거
  Future<bool> removeFromCart({
    required String userId,
    required String cartItemId,
  }) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('id', cartItemId)
          .eq('user_id', userId);

      _logger.i('Removed from cart: $cartItemId for user $userId');
      return true;
    } catch (e) {
      _logger.e('Failed to remove from cart: $e');
      rethrow;
    }
  }

  /// 장바구니 비우기
  Future<bool> clearCart({required String userId}) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId);

      _logger.i('Cleared cart for user $userId');
      return true;
    } catch (e) {
      _logger.e('Failed to clear cart: $e');
      rethrow;
    }
  }

  /// 사용자 장바구니 조회
  Future<List<Map<String, dynamic>>> getCartItems({
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('''
            id,
            quantity,
            created_at,
            updated_at,
            products!inner(
              id,
              name,
              description,
              price,
              discount_price,
              image_url,
              stock_quantity,
              is_active
            )
          ''')
          .eq('user_id', userId)
          .eq('products.is_active', true)
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      _logger.e('Failed to get cart items: $e');
      return [];
    }
  }

  /// 장바구니 총 금액 계산
  Future<Map<String, int>> calculateCartTotal({
    required String userId,
    String? couponCode,
  }) async {
    try {
      final cartItems = await getCartItems(userId: userId);
      
      int subtotal = 0;
      int discountAmount = 0;
      int shippingFee = 0;

      // 상품 금액 계산
      for (final item in cartItems) {
        final product = item['products'] as Map<String, dynamic>;
        final quantity = item['quantity'] as int;
        final price = product['discount_price'] as int? ?? product['price'] as int;
        
        subtotal += price * quantity;
      }

      // 쿠폰 할인 적용
      if (couponCode != null && couponCode.isNotEmpty) {
        final couponDiscount = await _applyCouponDiscount(
          userId: userId,
          couponCode: couponCode,
          subtotal: subtotal,
        );
        discountAmount = couponDiscount;
      }

      // 배송비 계산 (30,000원 이상 무료배송)
      if (subtotal >= 30000) {
        shippingFee = 0;
      } else {
        shippingFee = 3000;
      }

      final total = subtotal - discountAmount + shippingFee;

      return {
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'shipping_fee': shippingFee,
        'total': total,
      };
    } catch (e) {
      _logger.e('Failed to calculate cart total: $e');
      return {
        'subtotal': 0,
        'discount_amount': 0,
        'shipping_fee': 0,
        'total': 0,
      };
    }
  }

  /// 장바구니 항목 수 조회
  Future<int> getCartItemCount({required String userId}) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('quantity')
          .eq('user_id', userId);

      final items = response as List<dynamic>;
      return items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    } catch (e) {
      _logger.e('Failed to get cart item count: $e');
      return 0;
    }
  }

  /// 쿠폰 할인 적용
  Future<int> _applyCouponDiscount({
    required String userId,
    required String couponCode,
    required int subtotal,
  }) async {
    try {
      // 쿠폰 정보 조회
      final couponResponse = await _supabase
          .from('coupons')
          .select()
          .eq('code', couponCode)
          .eq('is_active', true)
          .gte('valid_until', DateTime.now().toIso8601String())
          .single();

      final coupon = couponResponse as Map<String, dynamic>;
      
      // 최소 주문 금액 확인
      final minOrderAmount = coupon['min_order_amount'] as int? ?? 0;
      if (subtotal < minOrderAmount) {
        throw Exception('최소 주문 금액 ${minOrderAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원 이상이어야 합니다.');
      }

      // 사용 횟수 확인
      final usageLimit = coupon['usage_limit'] as int?;
      final usedCount = coupon['used_count'] as int? ?? 0;
      
      if (usageLimit != null && usedCount >= usageLimit) {
        throw Exception('쿠폰 사용 한도를 초과했습니다.');
      }

      // 사용자별 쿠폰 사용 이력 확인
      final userUsageResponse = await _supabase
          .from('user_coupon_usage')
          .select('id')
          .eq('user_id', userId)
          .eq('coupon_id', coupon['id'])
          .maybeSingle();

      if (userUsageResponse != null) {
        throw Exception('이미 사용한 쿠폰입니다.');
      }

      // 할인 금액 계산
      final discountType = coupon['discount_type'] as String;
      final discountValue = coupon['discount_value'] as int;
      final maxDiscountAmount = coupon['max_discount_amount'] as int?;

      int discountAmount = 0;

      if (discountType == 'percentage') {
        discountAmount = (subtotal * discountValue / 100).round();
        if (maxDiscountAmount != null && discountAmount > maxDiscountAmount) {
          discountAmount = maxDiscountAmount;
        }
      } else if (discountType == 'fixed_amount') {
        discountAmount = discountValue;
      }

      return discountAmount;
    } catch (e) {
      _logger.e('Failed to apply coupon discount: $e');
      rethrow;
    }
  }

  /// 쿠폰 유효성 검증
  Future<Map<String, dynamic>> validateCoupon({
    required String userId,
    required String couponCode,
    required int subtotal,
  }) async {
    try {
      final discountAmount = await _applyCouponDiscount(
        userId: userId,
        couponCode: couponCode,
        subtotal: subtotal,
      );

      return {
        'valid': true,
        'discount_amount': discountAmount,
        'message': '쿠폰이 적용되었습니다.',
      };
    } catch (e) {
      return {
        'valid': false,
        'discount_amount': 0,
        'message': e.toString(),
      };
    }
  }

  /// 장바구니 동기화 (로그인 시 로컬 장바구니와 서버 장바구니 병합)
  Future<void> syncCart({
    required String userId,
    required List<Map<String, dynamic>> localCartItems,
  }) async {
    try {
      for (final localItem in localCartItems) {
        await addToCart(
          userId: userId,
          productId: localItem['product_id'] as String,
          quantity: localItem['quantity'] as int,
        );
      }

      _logger.i('Cart synced for user $userId');
    } catch (e) {
      _logger.e('Failed to sync cart: $e');
    }
  }

  /// 장바구니 항목 재고 확인
  Future<List<Map<String, dynamic>>> checkCartItemsStock({
    required String userId,
  }) async {
    try {
      final cartItems = await getCartItems(userId: userId);
      final outOfStockItems = <Map<String, dynamic>>[];

      for (final item in cartItems) {
        final product = item['products'] as Map<String, dynamic>;
        final requestedQuantity = item['quantity'] as int;
        final stockQuantity = product['stock_quantity'] as int? ?? 0;

        if (stockQuantity < requestedQuantity) {
          outOfStockItems.add({
            'cart_item_id': item['id'],
            'product_name': product['name'],
            'requested_quantity': requestedQuantity,
            'stock_quantity': stockQuantity,
          });
        }
      }

      return outOfStockItems;
    } catch (e) {
      _logger.e('Failed to check cart items stock: $e');
      return [];
    }
  }
}
