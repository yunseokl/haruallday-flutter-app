import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/product_service.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/product_card.dart';
import '../widgets/product_search_bar.dart';

class ProductsPage extends StatefulWidget {
  final String? category;
  
  const ProductsPage({super.key, this.category});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with TickerProviderStateMixin {
  final ProductService _productService = sl<ProductService>();
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = '전체';
  String _sortBy = 'newest'; // newest, popular, price_low, price_high
  
  late TabController _tabController;
  
  final List<String> _categories = [
    '전체', '사료', '간식', '장난감', '용품', '건강관리', '의류'
  ];
  
  final List<Map<String, String>> _sortOptions = [
    {'key': 'newest', 'label': '최신순'},
    {'key': 'popular', 'label': '인기순'},
    {'key': 'price_low', 'label': '낮은 가격순'},
    {'key': 'price_high', 'label': '높은 가격순'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // 카테고리가 지정된 경우 해당 탭으로 이동
    if (widget.category != null) {
      final categoryIndex = _categories.indexOf(widget.category!);
      if (categoryIndex != -1) {
        _selectedCategory = widget.category!;
        _tabController.index = categoryIndex;
      }
    }
    
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> products;
      
      if (_selectedCategory == '전체') {
        products = await _productService.getAllProducts();
      } else {
        products = await _productService.getProductsByCategory(_selectedCategory);
      }
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
      
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품을 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_products);
    
    // 검색 필터 적용
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final name = product['name']?.toString().toLowerCase() ?? '';
        final description = product['description']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }
    
    // 정렬 적용
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) {
          final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          return bDate.compareTo(aDate);
        });
        break;
      case 'popular':
        filtered.sort((a, b) {
          final aViews = a['view_count'] as int? ?? 0;
          final bViews = b['view_count'] as int? ?? 0;
          return bViews.compareTo(aViews);
        });
        break;
      case 'price_low':
        filtered.sort((a, b) {
          final aPrice = a['price'] as num? ?? 0;
          final bPrice = b['price'] as num? ?? 0;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'price_high':
        filtered.sort((a, b) {
          final aPrice = a['price'] as num? ?? 0;
          final bPrice = b['price'] as num? ?? 0;
          return bPrice.compareTo(aPrice);
        });
        break;
    }
    
    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _onCategoryChanged(int index) {
    setState(() {
      _selectedCategory = _categories[index];
    });
    _loadProducts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFiltersAndSort();
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _applyFiltersAndSort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category != null ? '${widget.category} 상품' : '전체 상품'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(MdiIcons.sort),
            onSelected: _onSortChanged,
            itemBuilder: (context) => _sortOptions.map((option) {
              return PopupMenuItem<String>(
                value: option['key'],
                child: Row(
                  children: [
                    if (_sortBy == option['key'])
                      Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
                    if (_sortBy == option['key']) const SizedBox(width: 8),
                    Text(option['label']!),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        bottom: widget.category == null ? TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: _onCategoryChanged,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ) : null,
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16),
            child: ProductSearchBar(
              onSearchChanged: _onSearchChanged,
              hintText: '상품명이나 설명을 검색하세요',
            ),
          ),
          
          // 상품 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            MdiIcons.packageVariantClosed,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? '검색 결과가 없습니다'
                : '등록된 상품이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '다른 검색어를 시도해보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return ProductCard(
            product: product,
            onTap: () {
              context.push('${AppRouter.productDetail}/${product['id']}');
            },
          );
        },
      ),
    );
  }
}
