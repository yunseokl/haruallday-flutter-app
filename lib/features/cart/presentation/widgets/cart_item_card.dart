import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CartItemCard extends StatelessWidget {
  final Map<String, dynamic> cartItem;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = cartItem['products'] as Map<String, dynamic>;
    final quantity = cartItem['quantity'] as int;
    final price = product['discount_price'] as int? ?? product['price'] as int;
    final originalPrice = product['price'] as int;
    final hasDiscount = product['discount_price'] != null;
    final stockQuantity = product['stock_quantity'] as int? ?? 0;
    final isOutOfStock = stockQuantity < quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제품 이미지
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['image_url'] as String? ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          MdiIcons.package,
                          size: 32,
                          color: Colors.grey[400],
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 제품 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제품명
                      Text(
                        product['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // 제품 설명
                      if (product['description'] != null)
                        Text(
                          product['description'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // 가격
                      Row(
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              '${originalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasDiscount ? Colors.red : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      
                      // 재고 부족 경고
                      if (isOutOfStock)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            '재고 부족 (재고: $stockQuantity개)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // 삭제 버튼
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    MdiIcons.close,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 수량 조절 및 총 가격
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 수량 조절
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
                            icon: Icon(
                              MdiIcons.minus,
                              size: 16,
                              color: quantity > 1 ? Colors.black : Colors.grey[400],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: quantity < stockQuantity ? () => onQuantityChanged(quantity + 1) : null,
                            icon: Icon(
                              MdiIcons.plus,
                              size: 16,
                              color: quantity < stockQuantity ? Colors.black : Colors.grey[400],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // 총 가격
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '총 ${(price * quantity).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    if (hasDiscount)
                      Text(
                        '${((originalPrice - price) * quantity).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원 할인',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
