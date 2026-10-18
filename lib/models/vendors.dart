import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/models/product_m.dart';

class VendorsResponse {
  final String status;
  final String message;
  final VendorsData vendors;

  VendorsResponse({
    required this.status,
    required this.message,
    required this.vendors,
  });

  factory VendorsResponse.fromJson(json) {
    return VendorsResponse(
      status: json['status'],
      message: json['message'],
      vendors: VendorsData.fromJson(json['vendors']),
    );
  }
}

class VendorsData {
  final List<Vendor> data;
  final String path;
  final int perPage;
  final String? nextCursor;
  final String? nextPageUrl;
  final String? prevCursor;
  final String? prevPageUrl;

  VendorsData({
    required this.data,
    required this.path,
    required this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory VendorsData.fromJson(json) {
    return VendorsData(
      data: List<Vendor>.from(json['data'].map((x) => Vendor.fromJson(x))),
      path: json['path'],
      perPage: json['per_page'],
      nextCursor: json['next_cursor'],
      nextPageUrl: json['next_page_url'],
      prevCursor: json['prev_cursor'],
      prevPageUrl: json['prev_page_url'],
    );
  }
}

/// int from 1/0, true/false, "1"/"true" or null.
int? _flag(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v ? 1 : 0;
  if (v is num) return v.toInt();
  final s = "$v".toLowerCase();
  if (s == "true") return 1;
  if (s == "false") return 0;
  return int.tryParse(s);
}

/// A cash collection branch (`cash_locations` on the vendor page).
class VendorBranch {
  final int? id;
  final String name;
  final String address;
  final String phone;

  VendorBranch({this.id, required this.name, required this.address, required this.phone});

  factory VendorBranch.fromJson(Map<String, dynamic> json) => VendorBranch(
    id: int.tryParse("${json['id'] ?? ''}"),
    name: json['name']?.toString() ?? "",
    address: json['address']?.toString() ?? "",
    phone: json['phone_number']?.toString() ?? "",
  );
}

class Vendor {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;

  /// The shop picture: `image_url` (a full address, preferred), else the
  /// older `image` path. Null/empty = show the first letter instead.
  final String? image;
  final String location;

  /// NOTE: The backend legitimately returns `null` for these when a vendor
  /// hasn't set business hours yet. These MUST stay nullable.
  final String? openingTime;
  final String? closingTime;

  /// 1 / 0 (the API now sends true/false; both are accepted).
  final int? pickupAvailable;
  final int? deliveryAvailable;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? deletedAt;

  /// Average rating (0 when unknown).
  final double rating;
  final double? latitude;
  final double? longitude;

  /// Active branches, not counting the main shop.
  final int branchCount;
  bool get hasBranches => branchCount > 0;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.image,
    required this.location,
    required this.pickupAvailable,
    required this.deliveryAvailable,
    this.openingTime,
    this.closingTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.rating = 0,
    this.latitude,
    this.longitude,
    this.branchCount = 0,
  });

  bool get hasImage => (image ?? "").isNotEmpty;

  /// Only verified vendors are sent to customers; treat a vendor as
  /// verified unless its status says otherwise.
  bool get isVerified {
    final s = status.toLowerCase();
    return !(s.contains("suspend") || s.contains("inactive") || s.contains("pending") || s.contains("declin"));
  }

  static String? imageOf(Map<String, dynamic> json) {
    final url = json['image_url']?.toString();
    if (url != null && url.isNotEmpty) return url;
    final legacy = ApiUrls.resolveImage(json['image']);
    return legacy.isEmpty ? null : legacy;
  }

  static DateTime _date(dynamic v) =>
      v == null ? DateTime.now() : (DateTime.tryParse("$v") ?? DateTime.now());

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: int.tryParse("${json['id']}") ?? 0,
      name: json['name']?.toString() ?? "",
      email: json['email']?.toString() ?? "",
      phoneNumber: json['phone_number']?.toString() ?? "",
      image: imageOf(json),
      location: json['location']?.toString() ?? "",
      pickupAvailable: _flag(json['pickup_available']),
      deliveryAvailable: _flag(json['delivery_available']),
      branchCount: int.tryParse("${json['branch_count'] ?? ''}") ??
          (json['has_branches'] == true ? 1 : 0),
      openingTime: json['opening_time']?.toString(),
      closingTime: json['closing_time']?.toString(),
      status: json['status']?.toString() ?? "active",
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      deletedAt: json['deleted_at']?.toString(),
      rating: double.tryParse("${json['rating'] ?? ''}") ?? 0,
      latitude: double.tryParse("${json['latitude'] ?? ''}"),
      longitude: double.tryParse("${json['longitude'] ?? ''}"),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'image_url': image,
      'location': location,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'pickup_available': pickupAvailable,
      'delivery_available': deliveryAvailable,
      'status': status,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt,
    };
  }
}

class VendorDetails extends Vendor {
  final List<ProductModel> products;
  final List<Review> reviews;

  /// Branches where cash purchases can be collected.
  final List<VendorBranch> cashLocations;
  final bool cashSalesEnabled;

  VendorDetails({
    required super.id,
    required super.name,
    required super.email,
    required super.phoneNumber,
    super.image,
    required super.location,
    super.openingTime,
    super.closingTime,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.rating,
    super.latitude,
    super.longitude,
    required this.products,
    required this.reviews,
    required super.pickupAvailable,
    required super.deliveryAvailable,
    this.cashLocations = const [],
    this.cashSalesEnabled = false,
  });

  factory VendorDetails.fromJson(Map<String, dynamic> json) {
    final v = Vendor.fromJson(json);
    List<T> list<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
      if (raw is! List) return [];
      final out = <T>[];
      for (final x in raw) {
        if (x is! Map) continue;
        try {
          out.add(f(Map<String, dynamic>.from(x)));
        } catch (_) {
          // One odd item must not hide the whole shop.
        }
      }
      return out;
    }

    return VendorDetails(
      id: v.id,
      name: v.name,
      email: v.email,
      phoneNumber: v.phoneNumber,
      image: v.image,
      location: v.location,
      openingTime: v.openingTime,
      closingTime: v.closingTime,
      status: v.status,
      createdAt: v.createdAt,
      updatedAt: v.updatedAt,
      deletedAt: v.deletedAt,
      rating: v.rating,
      latitude: v.latitude,
      longitude: v.longitude,
      pickupAvailable: v.pickupAvailable,
      deliveryAvailable: v.deliveryAvailable,
      products: list(json['products'], ProductModel.fromJson),
      reviews: list(json['reviews'], Review.fromJson),
      cashLocations: list(json['cash_locations'], VendorBranch.fromJson),
      cashSalesEnabled: json['cash_sales_enabled'] == true,
    );
  }
}
