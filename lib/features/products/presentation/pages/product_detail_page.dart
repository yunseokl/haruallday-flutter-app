import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/product_service.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../cart/presentation/pages/cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ProductService _productService = sl<ProductService>();
  final CartService _cartService = sl<CartService>();
  final AuthService _authService = sl<AuthService>();
  
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  bool _isAddingToCart = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final product = await _productService.getProductById(widget.productId);
      
      if (product != null) {
        // 상품 조회수 증가
        await _productService.incrementProductViews(widget.productId);
      }
      
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품 정보를 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;
    
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

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final result = await _cartService.addToCart(
        userId: userId,
        productId: widget.productId,
        quantity: _quantity,
      );

      if (mounted) {
        final resultMap = result as Map<String, dynamic>? ?? {};
        if (resultMap['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_product!['name']}이(가) 장바구니에 추가되었습니다.'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '장바구니 보기',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(userId: userId),
                    ),
                  );
                },
              ),
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
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('상품 상세'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('상품 상세'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('상품을 찾을 수 없습니다.'),
            ],
          ),
        ),
      );
    }

    final name = _product!['name']?.toString() ?? '상품명 없음';
    final description = _product!['description']?.toString() ?? '';
    final price = _product!['price'] as num? ?? 0;
    final imageUrl = _product!['image_url']?.toString();
    final discountPercentage = _product!['discount_percentage'] as num? ?? 0;
    final stockQuantity = _product!['stock_quantity'] as int? ?? 0;
    final isOutOfStock = stockQuantity <= 0;
    
    // 할인된 가격 계산
    final discountedPrice = discountPercentage > 0 
        ? price * (1 - discountPercentage / 100)
        : price;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(MdiIcons.shareVariant),
            onPressed: () {
              // TODO: 상품 공유 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('공유 기능은 준비 중입니다.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품 이미지
                  Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[100],
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Icon(
                                MdiIcons.imageOff,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              MdiIcons.packageVariant,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상품명
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 가격 정보
                        Row(
                          children: [
                            if (discountPercentage > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${discountPercentage.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_formatPrice(price)}원',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '${_formatPrice(discountedPrice)}원',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: discountPercentage > 0 
                                    ? Colors.red 
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 재고 정보
                        Row(
                          children: [
                            Icon(
                              MdiIcons.packageVariant,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOutOfStock ? '품절' : '재고 ${stockQuantity}개',
                              style: TextStyle(
                                color: isOutOfStock ? Colors.red : Colors.grey[600],
                                fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 수량 선택
                        if (!isOutOfStock) ...[
                          Row(
                            children: [
                              Text(
                                '수량',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: _quantity > 1 
                                          ? () => setState(() => _quantity--) 
                                          : null,
                                      icon: Icon(MdiIcons.minus),
                                      iconSize: 20,
                                    ),
                                    Container(
                                      width: 50,
                                      alignment: Alignment.center,
                                      child: Text(
                                        _quantity.toString(),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _quantity < stockQuantity 
                                          ? () => setState(() => _quantity++) 
                                          : null,
                                      icon: Icon(MdiIcons.plus),
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                        
                        // 상품 설명
                        if (description.isNotEmpty) ...[
                          Text(
                            '상품 설명',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 하단 버튼
          if (!isOutOfStock)
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
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isAddingToCart ? null : _addToCart,
                  icon: _isAddingToCart 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(MdiIcons.cartPlus),
                  label: Text(
                    _isAddingToCart ? '추가 중...' : '장바구니에 담기',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatPrice(num price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
