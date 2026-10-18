/// GET /customer/referral (and the `data` of POST /customer/referral-code):
/// the customer's own friend-referral code and points wallet summary.
class ReferralSummary {
  final String? referralCode;
  final bool hasReferralCode;
  final int points;
  final int referralCount;

  /// Points per friend set by the admin; 0 means the reward is off.
  final int pointsPerReferral;

  /// This customer already used a friend's code (the box is hidden then).
  final bool referredByCustomer;

  ReferralSummary({
    this.referralCode,
    required this.hasReferralCode,
    required this.points,
    required this.referralCount,
    required this.pointsPerReferral,
    required this.referredByCustomer,
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    final code = json['referral_code']?.toString();
    return ReferralSummary(
      referralCode: (code == null || code.isEmpty) ? null : code,
      hasReferralCode: json['has_referral_code'] == true,
      points: _int(json['points']),
      referralCount: _int(json['referral_count']),
      pointsPerReferral: _int(json['points_per_referral']),
      referredByCustomer: json['referred_by_customer'] == true,
    );
  }
}

/// One friend from GET /customer/referrals (first name only).
class ReferredFriend {
  final int id;
  final String name;
  final DateTime? joinedAt;

  ReferredFriend({required this.id, required this.name, this.joinedAt});

  factory ReferredFriend.fromJson(Map<String, dynamic> json) => ReferredFriend(
    id: _int(json['id']),
    name: json['name']?.toString() ?? "",
    joinedAt: DateTime.tryParse("${json['joined_at'] ?? ''}")?.toLocal(),
  );
}

/// One row of the points history from GET /customer/points.
class CustomerPointsEntry {
  final int id;
  final int points;
  final String reason;
  final String description;
  final DateTime? createdAt;

  CustomerPointsEntry({
    required this.id,
    required this.points,
    required this.reason,
    required this.description,
    this.createdAt,
  });

  factory CustomerPointsEntry.fromJson(Map<String, dynamic> json) =>
      CustomerPointsEntry(
        id: _int(json['id']),
        points: _int(json['points']),
        reason: json['reason']?.toString() ?? "",
        description: json['description']?.toString() ?? "",
        createdAt: DateTime.tryParse("${json['created_at'] ?? ''}")?.toLocal(),
      );
}

int _int(dynamic v) => v is int ? v : int.tryParse("${v ?? ""}") ?? 0;
