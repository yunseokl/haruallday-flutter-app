import 'package:equatable/equatable.dart';

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final String orderNumber;
  final String status;
  final int subtotal;
  final int discountAmount;
  final int shippingFee;
  final int finalPrice;
  final Map<String, dynamic> shippingAddress;
  final String? specialInstructions;
  final String? paymentMethod;
  final String? paymentId;
  final String? couponCode;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingFee,
    required this.finalPrice,
    required this.shippingAddress,
    this.specialInstructions,
    this.paymentMethod,
    this.paymentId,
    this.couponCode,
    required this.createdAt,
    this.paidAt,
    this.cancelledAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      subtotal: json['subtotal'] as int,
      discountAmount: json['discount_amount'] as int,
      shippingFee: json['shipping_fee'] as int,
      finalPrice: json['final_price'] as int,
      shippingAddress: json['shipping_address'] as Map<String, dynamic>,
      specialInstructions: json['special_instructions'] as String?,
      paymentMethod: json['payment_method'] as String?,
      paymentId: json['payment_id'] as String?,
      couponCode: json['coupon_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'status': status,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'shipping_fee': shippingFee,
      'final_price': finalPrice,
      'shipping_address': shippingAddress,
      'special_instructions': specialInstructions,
      'payment_method': paymentMethod,
      'payment_id': paymentId,
      'coupon_code': couponCode,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  bool get isCancellable => status == 'pending' || status == 'paid';
  bool get isCompleted => status == 'delivered';
  bool get isShipping => status == 'shipped';

  OrderModel copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    String? status,
    int? subtotal,
    int? discountAmount,
    int? shippingFee,
    int? finalPrice,
    Map<String, dynamic>? shippingAddress,
    String? specialInstructions,
    String? paymentMethod,
    String? paymentId,
    String? couponCode,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? cancelledAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      finalPrice: finalPrice ?? this.finalPrice,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      couponCode: couponCode ?? this.couponCode,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, orderNumber, status, subtotal, discountAmount, shippingFee, finalPrice, shippingAddress, specialInstructions, paymentMethod, paymentId, couponCode, createdAt, paidAt, cancelledAt];
}
