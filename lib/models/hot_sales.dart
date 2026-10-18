import 'package:flexiphones/helpers/api_helper.dart';

class PromotedProductsResponse {
  final String status;
  final String message;
  final List<HotDeal> hotDeals;

  PromotedProductsResponse({
    required this.status,
    required this.message,
    required this.hotDeals,
  });

  /// `hot_deals` is a plain list without `per_page`/`cursor` (old apps),
  /// and a cursor page object ({data, next_cursor, ...}) when `per_page` is
  /// sent — which this app now does. Both are accepted.
  factory PromotedProductsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['hot_deals'];
    final items = raw is Map ? (raw['data'] as List? ?? []) : (raw as List? ?? []);
    return PromotedProductsResponse(
      status: json['status']?.toString() ?? "",
      message: json['message']?.toString() ?? "",
      hotDeals: List<HotDeal>.from(items.map((x) => HotDeal.fromJson(x))),
    );
  }
}

class HotDeal {
  final int id;
  final int vendorId;
  final String brand;
  final String model;
  final String fullName;
  final String colors;
  final String deviceSpecification;
  final String deviceType;
  final String image;
  final String status;
  final String rating;
  final String createdAt;
  final String updatedAt;
  final List<String> storages;

  /// Cheapest cash price (`min_price`), 0 when not sent.
  final double minPrice;

  HotDeal({
    required this.id,
    required this.vendorId,
    required this.brand,
    required this.model,
    required this.fullName,
    required this.colors,
    required this.deviceSpecification,
    required this.deviceType,
    required this.image,
    required this.status,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    required this.storages,
    this.minPrice = 0,
  });

  /// Tolerant: list answers are now lighter (no storages, rating, type...),
  /// so every field has a safe default.
  factory HotDeal.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? "";
    final rawStorages = json['product_storages'];
    final storages = <String>[
      if (rawStorages is List)
        for (final x in rawStorages)
          if (x is Map && (x['storage'] ?? '').toString().isNotEmpty)
            x['storage'].toString(),
    ];
    return HotDeal(
      id: int.tryParse(s(json['id'])) ?? 0,
      vendorId: int.tryParse(s(json['vendor_id'])) ?? 0,
      brand: s(json['brand']),
      model: s(json['model']),
      colors: ApiUrls.productColorsText(json),
      fullName: "${s(json['brand'])} ${s(json['model'])}".trim(),
      deviceSpecification: s(json['device_specification']),
      deviceType: s(json['device_type']),
      image: ApiUrls.productMainImage(json),
      status: s(json['status']),
      rating: s(json['rating']).isEmpty ? "0" : s(json['rating']),
      createdAt: s(json['created_at']),
      updatedAt: s(json['updated_at']),
      storages: storages,
      minPrice: double.tryParse(s(json['min_price'])) ?? 0,
    );
  }
}
