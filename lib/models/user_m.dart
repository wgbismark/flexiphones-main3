class LoginResponse {
  final String status;
  final String? message;
  final String? token;
  /// When [token] stops working. Null for sessions saved before the server
  /// sent it (GET /session fills it in).
  final DateTime? expiresAt;
  final UserData data;

  LoginResponse({
    required this.status,
    required this.message,
    required this.token,
    required this.data,
    this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status']?.toString() ?? "Active",
      message: json['message']?.toString(),
      token: json['token']?.toString(),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.tryParse("${json['expires_at']}"),
      data: UserData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'token': token,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'data': data.toJson(),
      };
}


class UserData {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? ghanaCard;
  final String? profilePhoto;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.ghanaCard,
    required this.profilePhoto,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: int.tryParse("${json['id'] ?? json['customer_id'] ?? 0}") ?? 0,
      name: json['name']?.toString() ?? "",
      email: json['email']?.toString() ?? "",
      phone: json['phone']?.toString() ?? "",
      address: json['address']?.toString(),
      ghanaCard: json['ghana_card']?.toString(),
      profilePhoto: (json['photo_url'] ?? json['profile_photo'])?.toString(),
      status: json['status']?.toString() ?? "Active",
      createdAt: json['created_at'] == null ? null : DateTime.tryParse("${json['created_at']}"),
      updatedAt: json['updated_at'] == null ? null : DateTime.tryParse("${json['updated_at']}"),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'ghana_card': ghanaCard,
        'profile_photo': profilePhoto,
        'photo_url': profilePhoto,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
