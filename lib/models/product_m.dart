
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/models/customer_m.dart';
import 'package:flexiphones/models/vendors.dart';

class ProductResponseModel {
  final String? status;
  final String message;
  final ProductListData? products;
  final ProductModel? product;

  ProductResponseModel({
    required this.status,
    required this.message,
    this.products,
    this.product,
  });

  factory ProductResponseModel.fromJson(json) {
    return ProductResponseModel(
      status: json['status'],
      message: json['message'],
      products: json['products'] != null
          ? ProductListData.fromJson(json['products'])
          : null,
      product:
          json['product'] != null ? ProductModel.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        if (products != null) 'products': products!.toJson(),
        if (product != null) 'product': product!.toJson(),
      };
}

class ProductListData {
  final List<ProductModel> data;
  final String path;
  final int perPage;
  final dynamic nextCursor;
  final dynamic nextPageUrl;
  final dynamic prevCursor;
  final dynamic prevPageUrl;

  ProductListData({
    required this.data,
    required this.path,
    required this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory ProductListData.fromJson(json) {
    return ProductListData(
      data: List<ProductModel>.from(
        (json['data'] as List).map((x) => ProductModel.fromJson(x)),
      ),
      path: json['path'] ?? "",
      perPage: json['per_page'] ?? 20,
      nextCursor: json['next_cursor'],
      nextPageUrl: json['next_page_url'],
      prevCursor: json['prev_cursor'],
      prevPageUrl: json['prev_page_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'data': data.map((x) => x.toJson()).toList(),
        'path': path,
        'per_page': perPage,
        'next_cursor': nextCursor,
        'next_page_url': nextPageUrl,
        'prev_cursor': prevCursor,
        'prev_page_url': prevPageUrl,
      };
}

class ProductModel {
  final int id;
  final int? vendorId;
  final String brand;
  final double price;

  final String fullName;
  final String model;
  final String colors;
  final String? deviceSpecification;
  final String image;
  final List<dynamic>? images;
  final String status;
  final List<String> availableSaleModes;
  final DateTime? addedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ProductStorage>? productStorages;
  final Vendor? vendor;
  final List<Review>? reviews;

  /// Lowest cash price across storages ("From GHS 1,000"); 0 when unknown.
  final double minPrice;

  /// The server is authoritative here. Cash-only products can be hidden when
  /// `available_sale_modes` does not include 'cash'.
  bool get supportsCash => availableSaleModes.any((mode) => mode.toLowerCase() == 'cash');
  /// No modes sent (older server or cached data): installment only, as before.
  bool get supportsInstallment =>
      availableSaleModes.isEmpty ||
      availableSaleModes.any((mode) => mode.toLowerCase() == 'installment');
  bool get cashOnly => supportsCash && !supportsInstallment;

  /// Saved by the signed-in customer. Mutable so the heart can flip at
  /// once and roll back if the call fails.
  bool isFavorite;
  final int viewsCount;

  /// Different people who opened this phone (server counted).
  final int uniqueViewsCount;

  /// A vendor is paying to push this phone to the front (not a discount).
  final bool isPromoted;

  /// Cash price to show: `min_price`, else the cheapest storage, else price.
  double get fromPrice {
    if (minPrice > 0) return minPrice;
    final cash =
        (productStorages ?? [])
            .map((s) => double.tryParse(s.cashPrice) ?? 0)
            .where((v) => v > 0)
            .toList();
    if (cash.isNotEmpty) return cash.reduce((a, b) => a < b ? a : b);
    return price;
  }

  ProductModel({
    this.minPrice = 0,
    this.isFavorite = false,
    this.viewsCount = 0,
    this.uniqueViewsCount = 0,
    this.isPromoted = false,
    required this.id,
    required this.vendorId,
    required this.brand,
    required this.model,
    required this.price,
    required this.colors,
    required this.deviceSpecification,
    required this.image,
    required this.images,
    required this.status,
    required this.availableSaleModes,
    required this.createdAt,
    required this.updatedAt,
    required this.addedAt,
    required this.productStorages,
    required this.vendor,
    required this.fullName,
    required this.reviews,
  });

  factory ProductModel.fromJson(json) {
    // main_image_url / image_urls are ready-made full addresses (up to 8
    // photos, main first); the legacy `image` path is only a fallback.
    final mainImage = ApiUrls.productMainImage(json);
    final gallery = ApiUrls.productImageUrls(json);

    return ProductModel(
      minPrice: double.tryParse("${json['min_price'] ?? ''}") ?? 0,
      isFavorite: json['is_favorite'] == true,
      viewsCount: int.tryParse("${json['views_count'] ?? ''}") ?? 0,
      uniqueViewsCount:
          int.tryParse("${json['unique_views_count'] ?? ''}") ?? 0,
      isPromoted:
          json['is_promoted'] == true || "${json['is_promoted']}" == "1",
      id: json['id'],
      vendorId: json['vendor_id'],
      price: json['price'] == null ? 0.0 : double.parse("${json['price']}"),
      brand: json['brand'] ?? "",
      fullName: "${json['brand'] ?? ''} ${json['model'] ?? ''}".trim(),
      model: json['model'] ?? "",
      colors: ApiUrls.productColorsText(json),
      deviceSpecification: json['device_specification'],
      image: mainImage,
      images: gallery,
      status: json['status'] ?? "",
      availableSaleModes: (json['available_sale_modes'] is List)
          ? (json['available_sale_modes'] as List)
                .map((e) => e.toString())
                .toList()
          : const <String>[],
      addedAt: json['addedAt'] is DateTime
          ? json['addedAt']
          : (json['addedAt'] == null
              ? DateTime.now()
              : DateTime.tryParse(json['addedAt'].toString()) ?? DateTime.now()),
      createdAt:
          json['created_at'] == null ? null : DateTime.tryParse(json['created_at']),
      updatedAt:
          json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at']),
      productStorages: json['product_storages'] == null
          ? null
          : List<ProductStorage>.from(
              (json['product_storages'] as List)
                  .map((x) => ProductStorage.fromJson(x)),
            ),
      vendor: json['vendor'] == null ? null : Vendor.fromJson(json['vendor']),
      reviews: json['reviews'] == null
          ? null
          : List<Review>.from(
              (json['reviews'] as List).map((x) => Review.fromJson(x)),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor_id': vendorId,
        'brand': brand,
        'model': model,
        'colors': colors,
        'color_list': ApiUrls.productColorList({'colors': colors}),
        'device_specification': deviceSpecification,
        'image': image,
        'main_image_url': image.isEmpty ? null : image,
        'image_urls': images ?? [],
        'status': status,
        'available_sale_modes': availableSaleModes,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'product_storages': productStorages?.map((x) => x.toJson()).toList(),
        'vendor': vendor?.toJson(),
        'reviews': reviews,
        'min_price': minPrice,
        'is_favorite': isFavorite,
        'views_count': viewsCount,
        'unique_views_count': uniqueViewsCount,
      };
}

/// GET /v1/brands — only brands the admin allows.
class Brand {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final int productsCount;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.productsCount,
  });

  /// "SAMSUNG" -> "Samsung".
  String get displayName =>
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1).toLowerCase();

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: int.tryParse("${json['id']}") ?? 0,
    name: json['name']?.toString() ?? "",
    slug: json['slug']?.toString() ?? "",
    logoUrl:
        (json['logo_url']?.toString().isNotEmpty ?? false)
            ? json['logo_url'].toString()
            : null,
    productsCount: int.tryParse("${json['products_count'] ?? ''}") ?? 0,
  );
}

/// The `sort=` values the product lists accept.
enum ProductSort {
  recommended("recommended", "For you"),
  newest("newest", "Newest"),
  popular("popular", "Popular"),
  priceAsc("price_asc", "Price: low"),
  priceDesc("price_desc", "Price: high"),
  rating("rating", "Top rated");

  const ProductSort(this.value, this.label);
  final String value;
  final String label;
}

class ProductStorage {
  final int id;
  final int productId;
  final String storage;
  final String cashPrice;
  final String interestRate;
  final String threeMonthPrice;
  final String fourMonthPrice;
  final String fiveMonthPrice;
  final String sixMonthPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductStorage({
    required this.id,
    required this.productId,
    required this.storage,
    required this.cashPrice,
    required this.interestRate,
    required this.threeMonthPrice,
    required this.fourMonthPrice,
    required this.fiveMonthPrice,
    required this.sixMonthPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductStorage.fromJson(Map<String, dynamic> json) {
    return ProductStorage(
      id: json['id'],
      productId: json['product_id'],
      storage: json['storage'] ?? "",
      cashPrice: "${json['cash_price'] ?? '0'}",
      interestRate: "${json['interest_rate'] ?? '0'}",
      threeMonthPrice: "${json['three_month_price'] ?? '0'}",
      fourMonthPrice: "${json['four_month_price'] ?? '0'}",
      fiveMonthPrice: "${json['five_month_price'] ?? '0'}",
      sixMonthPrice: "${json['six_month_price'] ?? '0'}",
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'storage': storage,
        'cash_price': cashPrice,
        'interest_rate': interestRate,
        'three_month_price': threeMonthPrice,
        'four_month_price': fourMonthPrice,
        'five_month_price': fiveMonthPrice,
        'six_month_price': sixMonthPrice,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class Review {
  final int id;
  final int customerId;
  final String reviewableType;
  final int reviewableId;
  final String comment;
  final int rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Customer? customer;

  Review({
    required this.id,
    required this.customerId,
    required this.reviewableType,
    required this.reviewableId,
    required this.comment,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    required this.customer,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: int.tryParse("${json['id']}") ?? 0,
      customerId: int.tryParse("${json['customer_id'] ?? ''}") ?? 0,
      reviewableType: json['reviewable_type'] ?? "",
      reviewableId: json['reviewable_id'] ?? 0,
      comment: json['comment'] ?? "",
      rating: double.tryParse("${json['rating']}")?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      customer:
          json['customer'] == null ? null : Customer.fromJson(json['customer']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'reviewable_type': reviewableType,
        'reviewable_id': reviewableId,
        'comment': comment,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'customer': customer?.toJson(),
      };
}