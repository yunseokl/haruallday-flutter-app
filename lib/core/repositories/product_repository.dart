import 'package:dartz/dartz.dart';

import '../error/app_error.dart';
import '../models/product_model.dart';

/// 상품 Repository 인터페이스
abstract class ProductRepository {
  /// 모든 활성 상품 조회
  Future<Either<AppError, List<ProductModel>>> getAllProducts();

  /// 카테고리별 상품 조회
  Future<Either<AppError, List<ProductModel>>> getProductsByCategory(String category);

  /// 추천 상품 조회
  Future<Either<AppError, List<ProductModel>>> getFeaturedProducts();

  /// 상품 상세 정보 조회
  Future<Either<AppError, ProductModel>> getProductById(String productId);

  /// 상품 검색
  Future<Either<AppError, List<ProductModel>>> searchProducts(String query);

  /// 인기 상품 조회
  Future<Either<AppError, List<ProductModel>>> getPopularProducts();

  /// 신상품 조회
  Future<Either<AppError, List<ProductModel>>> getNewProducts();

  /// 할인 상품 조회
  Future<Either<AppError, List<ProductModel>>> getDiscountedProducts();

  /// 상품 재고 확인
  Future<Either<AppError, bool>> checkProductStock(String productId, int quantity);

  /// 상품 조회수 증가
  Future<Either<AppError, void>> incrementProductViews(String productId);
}
