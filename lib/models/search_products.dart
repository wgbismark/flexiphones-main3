import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/models/vendors.dart';

class SearchResult {
  final SearchData data;

  SearchResult({required this.data});

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(data: SearchData.fromJson(json['data']));
  }
}

class SearchData {
  final List<SearchProduct> products;
  final String path;
  final int perPage;
  final String? nextCursor;
  final String? nextPageUrl;
  final String? prevCursor;
  final String? prevPageUrl;

  SearchData({
    required this.products,
    required this.path,
    required this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory SearchData.fromJson(Map<String, dynamic> json) {
    return SearchData(
      products: List<SearchProduct>.from(
        json['data'].map((x) => SearchProduct.fromJson(x)),
      ),
      path: json['path'],
      perPage: json['per_page'],
      nextCursor: json['next_cursor'],
      nextPageUrl: json['next_page_url'],
      prevCursor: json['prev_cursor'],
      prevPageUrl: json['prev_page_url'],
    );
  }
}

class SearchProduct {
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
  final Vendor vendor;
  final List<ProductStorage> productStorages;

  SearchProduct({
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
    required this.vendor,
    required this.productStorages,
  });

  factory SearchProduct.fromJson(Map<String, dynamic> json) {
    return SearchProduct(
      id: json['id'],
      vendorId: json['vendor_id'],
      brand: json['brand'],
      model: json['model'],
      colors: ApiUrls.productColorsText(json),
      deviceSpecification: json['device_specification'],
      deviceType: json['device_type'],
      image: ApiUrls.productMainImage(json),
      status: json['status'],
      rating: json['rating'],
      availableSaleModes: (json['available_sale_modes'] is List)
          ? (json['available_sale_modes'] as List)
                .map((e) => e.toString())
                .toList()
          : const <String>[],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      vendor: Vendor.fromJson(json['vendor']),
      productStorages: List<ProductStorage>.from(
        json['product_storages'].map((x) => ProductStorage.fromJson(x)),
      ),
    );
  }

  /// As a ProductModel, so search results use the shared product card.
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
    productStorages: productStorages,
    vendor: vendor,
    fullName: "$brand $model".trim(),
    reviews: null,
  );
}
