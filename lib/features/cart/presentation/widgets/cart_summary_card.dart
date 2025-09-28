import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CartSummaryCard extends StatelessWidget {
  final Map<String, int> cartTotal;

  const CartSummaryCard({
    super.key,
    required this.cartTotal,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = cartTotal['subtotal'] ?? 0;
    final discountAmount = cartTotal['discount_amount'] ?? 0;
    final shippingFee = cartTotal['shipping_fee'] ?? 0;
    final total = cartTotal['total'] ?? 0;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Row(
              children: [
                Icon(
                  MdiIcons.calculator,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '주문 요약',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 상품 금액
            _buildSummaryRow(
              label: '상품 금액',
              value: '${subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
              isSubtotal: true,
            ),
            
            // 할인 금액
            if (discountAmount > 0)
              _buildSummaryRow(
                label: '할인 금액',
                value: '-${discountAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                valueColor: Colors.red,
                icon: MdiIcons.tagOutline,
              ),
            
            // 배송비
            _buildSummaryRow(
              label: '배송비',
              value: shippingFee > 0 
                  ? '${shippingFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원'
                  : '무료',
              valueColor: shippingFee > 0 ? null : Colors.green,
              icon: MdiIcons.truck,
            ),
            
            // 무료배송 안내
            if (shippingFee > 0 && subtotal < 30000)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      MdiIcons.informationOutline,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${(30000 - subtotal).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원 더 구매하시면 무료배송!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // 구분선
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            
            const SizedBox(height: 12),
            
            // 총 결제 금액
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 결제 금액',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            // 적립 예정 포인트
            if (total > 0)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      MdiIcons.gift,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '적립 예정 포인트: ${(total * 0.01).round()}P',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
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

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
    bool isSubtotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isSubtotal ? 16 : 14,
                  fontWeight: isSubtotal ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSubtotal ? 16 : 14,
              fontWeight: isSubtotal ? FontWeight.w600 : FontWeight.normal,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
