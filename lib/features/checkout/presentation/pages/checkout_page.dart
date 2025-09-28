import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/payment_service.dart';
import '../../../../core/injection/injection_container.dart';

class CheckoutPage extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> cartItems;
  final Map<String, int> cartTotal;
  final String? appliedCouponCode;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.cartItems,
    required this.cartTotal,
    this.appliedCouponCode,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final PaymentService _paymentService = sl<PaymentService>();
  final _formKey = GlobalKey<FormState>();
  
  // 배송 정보
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 주문 항목 준비
      final orderItems = widget.cartItems.map((item) {
        final product = item['products'] as Map<String, dynamic>;
        final price = product['discount_price'] as int? ?? product['price'] as int;
        
        return {
          'product_id': product['id'],
          'quantity': item['quantity'],
          'price': price,
        };
      }).toList();

      // 배송 주소 정보
      final shippingAddress = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'detail_address': _detailAddressController.text.trim(),
      };

      // 주문 생성
      final orderResult = await _paymentService.createOrder(
        userId: widget.userId,
        orderItems: orderItems,
        shippingAddress: shippingAddress,
        couponCode: widget.appliedCouponCode,
        specialInstructions: _specialInstructionsController.text.trim().isNotEmpty
            ? _specialInstructionsController.text.trim()
            : null,
      );

      if (orderResult['payment_required'] == true) {
        // 결제 처리
        final paymentResult = await _paymentService.processPayment(
          orderId: orderResult['order_id'] as String,
          paymentMethod: _selectedPaymentMethod,
          amount: orderResult['final_price'] as int,
        );

        if (paymentResult['success'] == true) {
          // 결제 성공
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderCompletePage(
                  orderId: orderResult['order_id'] as String,
                  orderNumber: orderResult['order_number'] as String,
                  totalAmount: orderResult['final_price'] as int,
                ),
              ),
            );
          }
        } else {
          // 결제 실패
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(paymentResult['error'] ?? '결제에 실패했습니다.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주문 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문/결제'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 주문 상품 정보
                    _buildOrderItemsSection(),
                    
                    const SizedBox(height: 24),
                    
                    // 배송 정보
                    _buildShippingInfoSection(),
                    
                    const SizedBox(height: 24),
                    
                    // 결제 방법
                    _buildPaymentMethodSection(),
                    
                    const SizedBox(height: 24),
                    
                    // 주문 요약
                    _buildOrderSummarySection(),
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
                    onPressed: _isProcessing ? null : _processOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            '${(widget.cartTotal['total'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원 결제하기',
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주문 상품',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.cartItems.map((item) {
              final product = item['products'] as Map<String, dynamic>;
              final quantity = item['quantity'] as int;
              final price = product['discount_price'] as int? ?? product['price'] as int;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                            product['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원 × $quantity개',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(price * quantity).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
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

  Widget _buildShippingInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '배송 정보',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '받는 분 성함',
                hintText: '받는 분의 성함을 입력하세요',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '받는 분 성함을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '연락처',
                hintText: '010-0000-0000',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '연락처를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '주소',
                hintText: '주소를 입력하세요',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '주소를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailAddressController,
              decoration: const InputDecoration(
                labelText: '상세 주소',
                hintText: '상세 주소를 입력하세요',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialInstructionsController,
              decoration: const InputDecoration(
                labelText: '배송 요청사항 (선택)',
                hintText: '배송 시 요청사항이 있으시면 입력해주세요',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '결제 방법',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('신용카드'),
              subtitle: const Text('신용카드로 결제'),
              value: 'card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('계좌이체'),
              subtitle: const Text('실시간 계좌이체'),
              value: 'bank_transfer',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('카카오페이'),
              subtitle: const Text('카카오페이로 간편결제'),
              value: 'kakaopay',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    final subtotal = widget.cartTotal['subtotal'] ?? 0;
    final discountAmount = widget.cartTotal['discount_amount'] ?? 0;
    final shippingFee = widget.cartTotal['shipping_fee'] ?? 0;
    final total = widget.cartTotal['total'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '결제 금액',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('상품 금액', '${subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원'),
            if (discountAmount > 0)
              _buildSummaryRow('할인 금액', '-${discountAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원', valueColor: Colors.red),
            _buildSummaryRow('배송비', shippingFee > 0 ? '${shippingFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원' : '무료'),
            const Divider(),
            _buildSummaryRow(
              '총 결제 금액',
              '${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? (isTotal ? Theme.of(context).colorScheme.primary : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderCompletePage extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final int totalAmount;

  const OrderCompletePage({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 완료'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                MdiIcons.checkCircle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                '주문이 완료되었습니다!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '주문번호: $orderNumber',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '결제금액: ${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '주문하신 제품은 빠른 시일 내에 배송될 예정입니다.\n배송 상황은 마이페이지에서 확인하실 수 있습니다.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('홈으로 돌아가기'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // 주문 상세 페이지로 이동
                  },
                  child: const Text('주문 상세 보기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
