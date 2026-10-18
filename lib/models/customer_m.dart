import 'package:flexiphones/helpers/api_helper.dart';

class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? ghanaCard;
  final String? profilePhoto;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.ghanaCard,
    this.profilePhoto,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      ghanaCard: json['ghana_card'],
      profilePhoto: "${ApiUrls.ImageBase}${json['profile_photo']}" ,
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
