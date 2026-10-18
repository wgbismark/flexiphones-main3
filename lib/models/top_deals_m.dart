import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/helpers/api_helper.dart';

class TopDealsResponse {
  final String status;
  final String message;
  final TopDeals topDeals;

  TopDealsResponse({
    required this.status,
    required this.message,
    required this.topDeals,
  });

  factory TopDealsResponse.fromJson(Map<String, dynamic> json) =>
      TopDealsResponse(
        status: json['status'] as String,
        message: json['message'] as String,
        topDeals: TopDeals.fromJson(json['top_deals'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'top_deals': topDeals.toJson(),
  };
}

class TopDeals {
  final List<Deal> data;
  final String path;
  final int perPage;
  final String? nextCursor;
  final String? nextPageUrl;
  final String? prevCursor;
  final String? prevPageUrl;

  TopDeals({
    required this.data,
    required this.path,
    required this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory TopDeals.fromJson(Map<String, dynamic> json) => TopDeals(
    data:
        (json['data'] as List<dynamic>)
            .map((e) => Deal.fromJson(e as Map<String, dynamic>))
            .toList(),
    path: json['path'] as String,
    perPage: json['per_page'] as int,
    nextCursor: json['next_cursor'] as String?,
    nextPageUrl: json['next_page_url'] as String?,
    prevCursor: json['prev_cursor'] as String?,
    prevPageUrl: json['prev_page_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'data': data.map((e) => e.toJson()).toList(),
    'path': path,
    'per_page': perPage,
    'next_cursor': nextCursor,
    'next_page_url': nextPageUrl,
    'prev_cursor': prevCursor,
    'prev_page_url': prevPageUrl,
  };
}

class Deal {
  final int id;
  final int vendorId;
  final String brand;
  final String model;
  final String colors;
  final String deviceSpecification;
  final String deviceType;
  final String image;
  final String status;
  final String rating;
  final List<String> availableSaleModes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int reviewsCount;
  final int applicationsCount;
  final double? reviewsAvgRating;

  Deal({
    required this.id,
    required this.vendorId,
    required this.brand,
    required this.model,
    required this.colors,
    required this.deviceSpecification,
    required this.deviceType,
    required this.image,
    required this.status,
    required this.rating,
    required this.availableSaleModes,
    required this.createdAt,
    required this.updatedAt,
    required this.reviewsCount,
    required this.applicationsCount,
    this.reviewsAvgRating,
  });

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
    id: json['id'] as int,
    vendorId: json['vendor_id'] as int,
    brand: json['brand'] as String,
    model: json['model'] as String,
    colors: ApiUrls.productColorsText(json),
    deviceSpecification: json['device_specification'] as String,
    deviceType: json['device_type'] as String,
    image: ApiUrls.productMainImage(json),
    status: json['status'] as String,
    rating: json['rating'] as String,
    availableSaleModes: (json['available_sale_modes'] is List)
        ? (json['available_sale_modes'] as List)
              .map((e) => e.toString())
              .toList()
        : const <String>[],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    reviewsCount: json['reviews_count'] as int,
    applicationsCount: json['applications_count'] as int,
    reviewsAvgRating:
        json['reviews_avg_rating'] != null
            ? double.tryParse(json['reviews_avg_rating'] as String)
            : null,
  );

  /// As a ProductModel, so deals use the shared product card.
  ProductModel toProductModel() => ProductModel(
    id: id,
    vendorId: vendorId,
    brand: brand,
    model: model,
    price: 0,
    colors: colors,
    deviceSpecification: deviceSpecification,
    image: image,
    images: image.isEmpty ? [] : [image],
    status: status,
    availableSaleModes: availableSaleModes,
    createdAt: createdAt,
    updatedAt: updatedAt,
    addedAt: null,
    productStorages: null,
    vendor: null,
    fullName: "$brand $model".trim(),
    reviews: null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'vendor_id': vendorId,
    'brand': brand,
    'model': model,
    'colors': colors,
    'device_specification': deviceSpecification,
    'device_type': deviceType,
    'image': image,
    'status': status,
    'rating': rating,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'reviews_count': reviewsCount,
    'applications_count': applicationsCount,
    'reviews_avg_rating': reviewsAvgRating?.toString(),
  };
}
