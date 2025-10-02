import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/repositories/product_repository.dart';
import 'products_state.dart';

/// 상품 목록 Cubit
class ProductsCubit extends Cubit<ProductsState> {
  final ProductRepository _productRepository;

  ProductsCubit(this._productRepository) : super(const ProductsInitial());

  /// 모든 상품 로드
  Future<void> loadAllProducts() async {
    emit(const ProductsLoading());

    final result = await _productRepository.getAllProducts();

    result.fold(
      (error) => emit(ProductsError(error)),
      (products) => emit(ProductsLoaded(products: products)),
    );
  }

  /// 카테고리별 상품 로드
  Future<void> loadProductsByCategory(String category) async {
    emit(const ProductsLoading());

    final result = await _productRepository.getProductsByCategory(category);

    result.fold(
      (error) => emit(ProductsError(error)),
      (products) => emit(ProductsLoaded(products: products, category: category)),
    );
  }

  /// 추천 상품 로드
  Future<void> loadFeaturedProducts() async {
    emit(const ProductsLoading());

    final result = await _productRepository.getFeaturedProducts();

    result.fold(
      (error) => emit(ProductsError(error)),
      (products) => emit(ProductsLoaded(products: products)),
    );
  }

  /// 상품 검색
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return loadAllProducts();
    }

    emit(const ProductsLoading());

    final result = await _productRepository.searchProducts(query);

    result.fold(
      (error) => emit(ProductsError(error)),
      (products) => emit(ProductsLoaded(products: products)),
    );
  }

  /// 인기 상품 로드
  Future<void> loadPopularProducts() async {
    emit(const ProductsLoading());

    final result = await _productRepository.getPopularProducts();

    result.fold(
      (error) => emit(ProductsError(error)),
      (products) => emit(ProductsLoaded(products: products)),
    );
  }

  /// 신상품 로드
  Future<void> loadNewProducts() async {
    emit(const ProductsLoading());

    final result = await _productRepository.getNewProducts();

    result.fold(
      (error) => emit(ProductsError(error)),
      (products) => emit(ProductsLoaded(products: products)),
    );
  }

  /// 할인 상품 로드
  Future<void> loadDiscountedProducts() async {
    emit(const ProductsLoading());

    final result = await _productRepository.getDiscountedProducts();

    result.fold(
      (error) => emit(ProductsError(error)),
      (products) => emit(ProductsLoaded(products: products)),
    );
  }
}
