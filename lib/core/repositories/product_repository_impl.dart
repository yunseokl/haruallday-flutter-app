import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_error.dart';
import '../error/error_handler.dart';
import '../models/product_model.dart';
import 'product_repository.dart';

/// 상품 Repository 구현
class ProductRepositoryImpl implements ProductRepository {
  final SupabaseClient _supabaseClient;

  ProductRepositoryImpl(this._supabaseClient);

  @override
  Future<Either<AppError, List<ProductModel>>> getAllProducts() async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(products);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<AppError, List<ProductModel>>> getProductsByCategory(
      String category) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('category', category)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(products);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<AppError, List<ProductModel>>> getFeaturedProducts() async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('is_featured', true)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(6);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(products);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<AppError, ProductModel>> getProductById(
      String productId) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('id', productId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return const Left(NotFoundError(message: '상품을 찾을 수 없습니다.'));
      }

      final product = ProductModel.fromJson(response as Map<String, dynamic>);
      return Right(product);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<AppError, List<ProductModel>>> searchProducts(
      String query) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(products);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<AppError, List<ProductModel>>> getPopularProducts() async {
    try {
      // RPC 함수 호출 시도
      final response = await _supabaseClient
          .rpc('get_popular_products', params: {'limit_count': 10});

      if (response != null) {
        final products = (response as List)
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(products);
      }

      // RPC 함수가 없으면 추천 상품으로 대체
      return getFeaturedProducts();
    } catch (e) {
      // 에러 시 추천 상품으로 대체
      return getFeaturedProducts();
    }
  }

  @override
  Future<Either<AppError, List<ProductModel>>> getNewProducts() async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(10);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(products);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<AppError, List<ProductModel>>> getDiscountedProducts() async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('*')
          .gt('discount_percentage', 0)
          .eq('is_active', true)
          .order('discount_percentage', ascending: false);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(products);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<AppError, bool>> checkProductStock(
      String productId, int quantity) async {
    try {
      final result = await getProductById(productId);

      return result.fold(
        (error) => Left(error),
        (product) => Right(product.stockQuantity >= quantity),
      );
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<AppError, void>> incrementProductViews(
      String productId) async {
    try {
      await _supabaseClient.rpc('increment_product_views', params: {
        'product_id': productId,
      });

      return const Right(null);
    } catch (e) {
      // 조회수 증가 실패는 치명적이지 않으므로 에러를 무시
      return const Right(null);
    }
  }
}
