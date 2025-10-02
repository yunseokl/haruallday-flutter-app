import 'package:equatable/equatable.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/models/product_model.dart';

/// 상품 목록 상태
abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

/// 로딩 중
class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

/// 로드 성공
class ProductsLoaded extends ProductsState {
  final List<ProductModel> products;
  final String? category;

  const ProductsLoaded({
    required this.products,
    this.category,
  });

  @override
  List<Object?> get props => [products, category];
}

/// 로드 실패
class ProductsError extends ProductsState {
  final AppError error;

  const ProductsError(this.error);

  @override
  List<Object> get props => [error];
}
