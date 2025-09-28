import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';

import '../constants/app_constants.dart';
import 'analytics_service.dart';
import 'notification_service.dart';

class PaymentService {
  final SupabaseClient _supabase;
  final AnalyticsService _analyticsService;
  final NotificationService _notificationService;
  final Logger _logger = Logger();

  PaymentService(
    this._supabase,
    this._analyticsService,
    this._notificationService,
  );

  /// 주문 생성
  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required List<Map<String, dynamic>> orderItems,
    required Map<String, dynamic> shippingAddress,
    String? couponCode,
    String? specialInstructions,
  }) async {
    try {
      // 주문 총액 계산
      int subtotal = 0;
      int discountAmount = 0;
      int shippingFee = 0;

      for (final item in orderItems) {
        final price = item['price'] as int;
        final quantity = item['quantity'] as int;
        subtotal += price * quantity;
      }

      // 쿠폰 할인 적용
      if (couponCode != null && couponCode.isNotEmpty) {
        discountAmount = await _calculateCouponDiscount(
          userId: userId,
          couponCode: couponCode,
          subtotal: subtotal,
        );
      }

      // 배송비 계산
      shippingFee = subtotal >= 30000 ? 0 : 3000;
      final finalPrice = subtotal - discountAmount + shippingFee;

      // 주문 번호 생성
      final orderNumber = _generateOrderNumber();

      // 주문 생성
      final orderResponse = await _supabase.from('orders').insert({
        'user_id': userId,
        'order_number': orderNumber,
        'status': 'pending',
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'shipping_fee': shippingFee,
        'final_price': finalPrice,
        'shipping_address': shippingAddress,
        'special_instructions': specialInstructions,
        'coupon_code': couponCode,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final order = orderResponse as Map<String, dynamic>;
      final orderId = order['id'] as String;

      // 주문 항목 생성
      final orderItemsData = orderItems.map((item) => {
        'order_id': orderId,
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'price': item['price'],
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase.from('order_items').insert(orderItemsData);

      // 쿠폰 사용 기록
      if (couponCode != null && couponCode.isNotEmpty) {
        await _recordCouponUsage(userId: userId, couponCode: couponCode, orderId: orderId);
      }

      _logger.i('Order created: $orderNumber for user $userId');

      return {
        'order_id': orderId,
        'order_number': orderNumber,
        'final_price': finalPrice,
        'payment_required': true,
      };
    } catch (e) {
      _logger.e('Failed to create order: $e');
      rethrow;
    }
  }

  /// 결제 처리 (아임포트 연동)
  Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required String paymentMethod,
    required int amount,
    Map<String, dynamic>? paymentData,
  }) async {
    try {
      // 주문 정보 확인
      final orderResponse = await _supabase
          .from('orders')
          .select('user_id, order_number, final_price, status')
          .eq('id', orderId)
          .single();

      final order = orderResponse as Map<String, dynamic>;
      
      if (order['status'] != 'pending') {
        throw Exception('이미 처리된 주문입니다.');
      }

      if (order['final_price'] != amount) {
        throw Exception('결제 금액이 일치하지 않습니다.');
      }

      // 결제 정보 생성
      final paymentId = _generatePaymentId();
      
      // 실제 결제 처리 (아임포트 API 호출)
      final paymentResult = await _processIamportPayment(
        paymentId: paymentId,
        orderNumber: order['order_number'] as String,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentData: paymentData,
      );

      if (paymentResult['success'] == true) {
        // 결제 성공 시 주문 상태 업데이트
        await _supabase.from('orders').update({
          'status': 'paid',
          'payment_method': paymentMethod,
          'payment_id': paymentId,
          'paid_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);

        // 결제 기록 저장
        await _supabase.from('payments').insert({
          'order_id': orderId,
          'payment_id': paymentId,
          'payment_method': paymentMethod,
          'amount': amount,
          'status': 'completed',
          'payment_data': paymentResult['payment_data'],
          'created_at': DateTime.now().toIso8601String(),
        });

        // 재고 차감
        await _updateProductStock(orderId);

        // 장바구니에서 주문한 항목 제거
        await _clearCartAfterOrder(order['user_id'] as String, orderId);

        // 사용자 활동 추적
        final orderItems = await _getOrderItems(orderId);
        await _analyticsService.trackPurchase(
          userId: order['user_id'] as String,
          orderId: orderId,
          items: orderItems,
          totalAmount: amount,
        );

        // 결제 완료 알림
        await _notificationService.sendOrderStatusNotification(
          userId: order['user_id'] as String,
          orderId: orderId,
          status: 'paid',
        );

        _logger.i('Payment completed: $paymentId for order $orderId');

        return {
          'success': true,
          'payment_id': paymentId,
          'order_id': orderId,
          'message': '결제가 완료되었습니다.',
        };
      } else {
        // 결제 실패
        await _supabase.from('orders').update({
          'status': 'payment_failed',
        }).eq('id', orderId);

        await _supabase.from('payments').insert({
          'order_id': orderId,
          'payment_id': paymentId,
          'payment_method': paymentMethod,
          'amount': amount,
          'status': 'failed',
          'payment_data': paymentResult['payment_data'],
          'created_at': DateTime.now().toIso8601String(),
        });

        return {
          'success': false,
          'error': paymentResult['error'] ?? '결제에 실패했습니다.',
        };
      }
    } catch (e) {
      _logger.e('Failed to process payment: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 결제 취소
  Future<Map<String, dynamic>> cancelPayment({
    required String orderId,
    required String reason,
  }) async {
    try {
      // 주문 정보 확인
      final orderResponse = await _supabase
          .from('orders')
          .select('user_id, payment_id, final_price, status')
          .eq('id', orderId)
          .single();

      final order = orderResponse as Map<String, dynamic>;
      
      if (order['status'] != 'paid') {
        throw Exception('결제 취소할 수 없는 주문 상태입니다.');
      }

      final paymentId = order['payment_id'] as String?;
      if (paymentId == null) {
        throw Exception('결제 정보를 찾을 수 없습니다.');
      }

      // 아임포트 결제 취소 API 호출
      final cancelResult = await _cancelIamportPayment(
        paymentId: paymentId,
        reason: reason,
      );

      if (cancelResult['success'] == true) {
        // 주문 상태 업데이트
        await _supabase.from('orders').update({
          'status': 'cancelled',
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancel_reason': reason,
        }).eq('id', orderId);

        // 결제 취소 기록
        await _supabase.from('payment_cancellations').insert({
          'order_id': orderId,
          'payment_id': paymentId,
          'reason': reason,
          'cancelled_amount': order['final_price'],
          'created_at': DateTime.now().toIso8601String(),
        });

        // 재고 복구
        await _restoreProductStock(orderId);

        _logger.i('Payment cancelled: $paymentId for order $orderId');

        return {
          'success': true,
          'message': '결제가 취소되었습니다.',
        };
      } else {
        return {
          'success': false,
          'error': cancelResult['error'] ?? '결제 취소에 실패했습니다.',
        };
      }
    } catch (e) {
      _logger.e('Failed to cancel payment: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 주문 상태 조회
  Future<Map<String, dynamic>?> getOrderStatus(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(
              *,
              products(name, image_url)
            )
          ''')
          .eq('id', orderId)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to get order status: $e');
      return null;
    }
  }

  /// 사용자 주문 목록 조회
  Future<List<Map<String, dynamic>>> getUserOrders({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(
              *,
              products(name, image_url)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      _logger.e('Failed to get user orders: $e');
      return [];
    }
  }

  /// 아임포트 결제 처리 (실제 구현에서는 서버 사이드에서 처리)
  Future<Map<String, dynamic>> _processIamportPayment({
    required String paymentId,
    required String orderNumber,
    required int amount,
    required String paymentMethod,
    Map<String, dynamic>? paymentData,
  }) async {
    try {
      // 실제 구현에서는 아임포트 API를 호출하여 결제 처리
      // 여기서는 시뮬레이션
      
      await Future.delayed(const Duration(seconds: 2)); // 결제 처리 시뮬레이션

      // 결제 성공 시뮬레이션 (실제로는 아임포트 응답 처리)
      final success = DateTime.now().millisecond % 10 != 0; // 90% 성공률

      if (success) {
        return {
          'success': true,
          'payment_data': {
            'imp_uid': 'imp_${DateTime.now().millisecondsSinceEpoch}',
            'merchant_uid': orderNumber,
            'amount': amount,
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
          },
        };
      } else {
        return {
          'success': false,
          'error': '결제 승인에 실패했습니다.',
          'payment_data': {
            'imp_uid': 'imp_${DateTime.now().millisecondsSinceEpoch}',
            'merchant_uid': orderNumber,
            'amount': amount,
            'status': 'failed',
            'fail_reason': '카드사 승인 거절',
          },
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 아임포트 결제 취소
  Future<Map<String, dynamic>> _cancelIamportPayment({
    required String paymentId,
    required String reason,
  }) async {
    try {
      // 실제 구현에서는 아임포트 취소 API 호출
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'cancel_data': {
          'imp_uid': paymentId,
          'cancelled_at': DateTime.now().toIso8601String(),
          'reason': reason,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 주문 번호 생성
  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    return 'ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${timestamp.substring(timestamp.length - 6)}';
  }

  /// 결제 ID 생성
  String _generatePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode % 10000).toString().padLeft(4, '0');
    return 'PAY$timestamp$random';
  }

  /// 쿠폰 할인 계산
  Future<int> _calculateCouponDiscount({
    required String userId,
    required String couponCode,
    required int subtotal,
  }) async {
    try {
      final couponResponse = await _supabase
          .from('coupons')
          .select()
          .eq('code', couponCode)
          .eq('is_active', true)
          .single();

      final coupon = couponResponse as Map<String, dynamic>;
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
      return 0;
    }
  }

  /// 쿠폰 사용 기록
  Future<void> _recordCouponUsage({
    required String userId,
    required String couponCode,
    required String orderId,
  }) async {
    try {
      final couponResponse = await _supabase
          .from('coupons')
          .select('id')
          .eq('code', couponCode)
          .single();

      final couponId = couponResponse['id'] as String;

      await _supabase.from('user_coupon_usage').insert({
        'user_id': userId,
        'coupon_id': couponId,
        'order_id': orderId,
        'used_at': DateTime.now().toIso8601String(),
      });

      // 쿠폰 사용 횟수 증가
      await _supabase.rpc('increment_coupon_usage', params: {
        'coupon_id': couponId,
      });
    } catch (e) {
      _logger.e('Failed to record coupon usage: $e');
    }
  }

  /// 재고 차감
  Future<void> _updateProductStock(String orderId) async {
    try {
      final orderItems = await _supabase
          .from('order_items')
          .select('product_id, quantity')
          .eq('order_id', orderId);

      for (final item in orderItems) {
        final productId = item['product_id'] as String;
        final quantity = item['quantity'] as int;

        await _supabase.rpc('decrease_product_stock', params: {
          'product_id': productId,
          'quantity': quantity,
        });
      }
    } catch (e) {
      _logger.e('Failed to update product stock: $e');
    }
  }

  /// 재고 복구
  Future<void> _restoreProductStock(String orderId) async {
    try {
      final orderItems = await _supabase
          .from('order_items')
          .select('product_id, quantity')
          .eq('order_id', orderId);

      for (final item in orderItems) {
        final productId = item['product_id'] as String;
        final quantity = item['quantity'] as int;

        await _supabase.rpc('increase_product_stock', params: {
          'product_id': productId,
          'quantity': quantity,
        });
      }
    } catch (e) {
      _logger.e('Failed to restore product stock: $e');
    }
  }

  /// 주문 후 장바구니 정리
  Future<void> _clearCartAfterOrder(String userId, String orderId) async {
    try {
      final orderItems = await _supabase
          .from('order_items')
          .select('product_id')
          .eq('order_id', orderId);

      final productIds = orderItems.map((item) => item['product_id'] as String).toList();

      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId)
          .inFilter('product_id', productIds);
    } catch (e) {
      _logger.e('Failed to clear cart after order: $e');
    }
  }

  /// 주문 항목 조회
  Future<List<Map<String, dynamic>>> _getOrderItems(String orderId) async {
    try {
      final response = await _supabase
          .from('order_items')
          .select('''
            product_id,
            quantity,
            price,
            products(name)
          ''')
          .eq('order_id', orderId);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      _logger.e('Failed to get order items: $e');
      return [];
    }
  }
}
