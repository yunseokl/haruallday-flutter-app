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
  String _selectedCategory = '?꾩껜';
  String _sortBy = 'newest'; // newest, popular, price_low, price_high
  
  late TabController _tabController;
  
  final List<String> _categories = [
    '?꾩껜', '?щ즺', '媛꾩떇', '?λ궃媛?, '?⑺뭹', '嫄닿컯愿由?, '?섎쪟'
  ];
  
  final List<Map<String, String>> _sortOptions = [
    {'key': 'newest', 'label': '理쒖떊??},
    {'key': 'popular', 'label': '?멸린??},
    {'key': 'price_low', 'label': '??? 媛寃⑹닚'},
    {'key': 'price_high', 'label': '?믪? 媛寃⑹닚'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // 移댄뀒怨좊━媛 吏?뺣맂 寃쎌슦 ?대떦 ??쑝濡??대룞
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
      
      if (_selectedCategory == '?꾩껜') {
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
            content: Text('?곹뭹??遺덈윭?ㅻ뒗 以??ㅻ쪟媛 諛쒖깮?덉뒿?덈떎: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_products);
    
    // 寃???꾪꽣 ?곸슜
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final name = product['name']?.toString().toLowerCase() ?? '';
        final description = product['description']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }
    
    // ?뺣젹 ?곸슜
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
        title: Text(widget.category != null ? '${widget.category} ?곹뭹' : '?꾩껜 ?곹뭹'),
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
          // 寃?됰컮
          Padding(
            padding: const EdgeInsets.all(16),
            child: ProductSearchBar(
              onSearchChanged: _onSearchChanged,
              hintText: '?곹뭹紐낆씠???ㅻ챸??寃?됲븯?몄슂',
            ),
          ),
          
          // ?곹뭹 紐⑸줉
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
                ? '寃??寃곌낵媛 ?놁뒿?덈떎'
                : '?깅줉???곹뭹???놁뒿?덈떎',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '?ㅻⅨ 寃?됱뼱瑜??쒕룄?대낫?몄슂',
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
              context.pushNamed(
                'productDetail',
                pathParameters: {'id': product['id'].toString()},
              );
            },
          );
        },
      ),
    );
  }
}
