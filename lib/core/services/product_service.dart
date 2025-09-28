import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabaseClient;

  ProductService(this._supabaseClient);

  // 모든 활성 상품 가져오기
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }

  // 카테고리별 상품 가져오기
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('category', category)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  // 추천 상품 가져오기 (featured 상품들)
  Future<List<Map<String, dynamic>>> getFeaturedProducts() async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('is_featured', true)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(6);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting featured products: $e');
      // 오류 시 기본 상품 데이터 반환
      return _getDefaultProducts();
    }
  }

  // 상품 상세 정보 가져오기
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('id', productId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting product by id: $e');
      return null;
    }
  }

  // 상품 검색
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // 인기 상품 가져오기 (주문 수 기준)
  Future<List<Map<String, dynamic>>> getPopularProducts() async {
    try {
      // 주문 아이템과 조인하여 인기 상품 조회
      final response = await _supabaseClient
          .rpc('get_popular_products', params: {'limit_count': 10});

      if (response != null) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error getting popular products: $e');
      // 오류 시 일반 상품 목록 반환
      return getFeaturedProducts();
    }
  }

  // 신상품 가져오기
  Future<List<Map<String, dynamic>>> getNewProducts() async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting new products: $e');
      return [];
    }
  }

  // 할인 상품 가져오기
  Future<List<Map<String, dynamic>>> getDiscountedProducts() async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .gt('discount_percentage', 0)
          .eq('is_active', true)
          .order('discount_percentage', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting discounted products: $e');
      return [];
    }
  }

  // 상품 재고 확인
  Future<bool> checkProductStock(String productId, int quantity) async {
    try {
      final product = await getProductById(productId);
      if (product == null) return false;

      final currentStock = product['stock_quantity'] as int? ?? 0;
      return currentStock >= quantity;
    } catch (e) {
      print('Error checking product stock: $e');
      return false;
    }
  }

  // 상품 재고 업데이트
  Future<bool> updateProductStock(String productId, int newQuantity) async {
    try {
      await _supabaseClient
          .from('products')
          .update({
            'stock_quantity': newQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      return true;
    } catch (e) {
      print('Error updating product stock: $e');
      return false;
    }
  }

  // 상품 조회수 증가
  Future<void> incrementProductViews(String productId) async {
    try {
      await _supabaseClient.rpc('increment_product_views', params: {
        'product_id': productId,
      });
    } catch (e) {
      print('Error incrementing product views: $e');
    }
  }

  // 기본 상품 데이터 (오류 시 사용)
  List<Map<String, dynamic>> _getDefaultProducts() {
    return [
      {
        'id': 'default-1',
        'name': '프리미엄 강아지 사료',
        'description': '영양가 높은 프리미엄 강아지 사료입니다.',
        'price': 45000,
        'image_url': 'https://via.placeholder.com/300x300?text=Dog+Food',
        'category': '사료',
        'stock_quantity': 50,
        'is_featured': true,
        'discount_percentage': 0,
      },
      {
        'id': 'default-2',
        'name': '강아지 장난감 세트',
        'description': '안전한 소재로 만든 강아지 장난감 세트입니다.',
        'price': 25000,
        'image_url': 'https://via.placeholder.com/300x300?text=Dog+Toys',
        'category': '장난감',
        'stock_quantity': 30,
        'is_featured': true,
        'discount_percentage': 10,
      },
      {
        'id': 'default-3',
        'name': '강아지 건강 간식',
        'description': '건강에 좋은 천연 재료로 만든 강아지 간식입니다.',
        'price': 15000,
        'image_url': 'https://via.placeholder.com/300x300?text=Dog+Treats',
        'category': '간식',
        'stock_quantity': 100,
        'is_featured': true,
        'discount_percentage': 5,
      },
    ];
  }
}
