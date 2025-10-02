import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final int price;
  final int? discountPrice;
  final int discountPercentage;
  final String category;
  final String? imageUrl;
  final int stockQuantity;
  final bool isActive;
  final bool isFeatured;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    this.discountPercentage = 0,
    required this.category,
    this.imageUrl,
    required this.stockQuantity,
    this.isActive = true,
    this.isFeatured = false,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'] as int,
      discountPrice: json['discount_price'] as int?,
      discountPercentage: json['discount_percentage'] as int? ?? 0,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String?,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      viewCount: json['view_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'discount_percentage': discountPercentage,
      'category': category,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
      'is_featured': isFeatured,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 최종 가격 계산 (할인가가 있으면 할인가, 없으면 정가)
  int get finalPrice => discountPrice ?? price;

  /// 할인율이 있는지 확인
  bool get hasDiscount => discountPercentage > 0 || discountPrice != null;

  /// 재고가 있는지 확인
  bool get inStock => stockQuantity > 0;

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    int? discountPrice,
    int? discountPercentage,
    String? category,
    String? imageUrl,
    int? stockQuantity,
    bool? isActive,
    bool? isFeatured,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        discountPrice,
        discountPercentage,
        category,
        imageUrl,
        stockQuantity,
        isActive,
        isFeatured,
        viewCount,
        createdAt,
        updatedAt,
      ];
}
