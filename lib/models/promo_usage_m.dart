/// GET /partner/promo-usage — who used the agent's promo code. Send the
/// last [latestId] back as `after_id` to get only newer people.
class PromoUsage {
  final String? promoCode;
  final bool hasBeenUsed;
  final int timesUsed;
  final int? latestId;

  /// How many are new since `after_id`; null on a first call.
  final int? newSince;
  final List<PromoUser> users;

  PromoUsage({
    this.promoCode,
    required this.hasBeenUsed,
    required this.timesUsed,
    this.latestId,
    this.newSince,
    required this.users,
  });

  factory PromoUsage.fromJson(Map<String, dynamic> json) => PromoUsage(
    promoCode: json['promo_code']?.toString(),
    hasBeenUsed: json['has_been_used'] == true,
    timesUsed: int.tryParse("${json['times_used'] ?? ''}") ?? 0,
    latestId: int.tryParse("${json['latest_id'] ?? ''}"),
    newSince: int.tryParse("${json['new_since'] ?? ''}"),
    users:
        (json['users'] as List? ?? [])
            .whereType<Map>()
            .map((u) => PromoUser.fromJson(Map<String, dynamic>.from(u)))
            .toList(),
  );
}

class PromoUser {
  final int id;
  final String name;
  final DateTime? usedAt;

  PromoUser({required this.id, required this.name, this.usedAt});

  factory PromoUser.fromJson(Map<String, dynamic> json) => PromoUser(
    id: int.tryParse("${json['id']}") ?? 0,
    name: json['name']?.toString() ?? "",
    usedAt: DateTime.tryParse("${json['used_at'] ?? ''}")?.toLocal(),
  );
}
