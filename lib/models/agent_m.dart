double _d(dynamic v) => double.tryParse("$v") ?? 0.0;

DateTime _dt(dynamic v) =>
    v == null ? DateTime.now() : (DateTime.tryParse("$v") ?? DateTime.now());

bool _b(dynamic v) => v == true || v == 1 || "$v" == "1" || "$v" == "true";

int _i(dynamic v) => v is int ? v : (num.tryParse("${v ?? ""}")?.toInt() ?? 0);

/// Partner (agent) account — mirrors the `partners` table / Partner model.
///
/// Accepts both response shapes the backend produces:
///  - login / registration: { status, message, token, expires_at, data: {...} }
///  - the stored session (same shape, written by [toJson])
class PartnerData {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String region;
  final String address;
  final String? ghanaCard;
  final String status; // Active | Inactive
  final String? promoCode;
  final String? momoNetwork;
  final String? momoNumber;
  final String? momoAccountName;
  final bool momoVerified;
  final String? token;
  final DateTime? expiresAt;
  final String? company;
  final String? photoUrl;
  final bool isApproved;

  PartnerData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.region,
    required this.address,
    this.ghanaCard,
    required this.status,
    this.promoCode,
    this.momoNetwork,
    this.momoNumber,
    this.momoAccountName,
    this.momoVerified = false,
    this.token,
    this.expiresAt,
    this.company,
    this.photoUrl,
    this.isApproved = true,
  });

  bool get isActive => status.toLowerCase() == "active";
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory PartnerData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : json;

    return PartnerData(
      id: data['id'] is int ? data['id'] : int.tryParse("${data['id']}") ?? 0,
      name: data['name']?.toString() ?? "",
      email: data['email']?.toString() ?? "",
      phone: data['phone']?.toString() ?? "",
      region: data['region']?.toString() ?? "",
      address: data['address']?.toString() ?? "",
      ghanaCard: data['ghana_card']?.toString(),
      status: data['status']?.toString() ?? "Inactive",
      promoCode: data['promo_code']?.toString(),
      momoNetwork: data['momo_network']?.toString(),
      momoNumber: data['momo_number']?.toString(),
      momoAccountName: data['momo_account_name']?.toString(),
      momoVerified: _b(data['momo_verified']),
      company: data['company']?.toString(),
      photoUrl:
          (data['photo_url'] ?? data['google_photo'])?.toString(),
      isApproved: data['is_approved'] == null ? true : _b(data['is_approved']),
      token: json['token']?.toString(),
      // A fresh sign-in/refresh response has `expires_in` (seconds left
      // now), which doesn't depend on the phone's clock; a stored session
      // only has `expires_at`.
      expiresAt: num.tryParse("${json['expires_in'] ?? ''}") != null
          ? DateTime.now().add(
              Duration(seconds: num.parse("${json['expires_in']}").toInt()),
            )
          : json['expires_at'] == null
          ? null
          : DateTime.tryParse("${json['expires_at']}"),
    );
  }

  /// Session format (what gets stored in secure storage).
  Map<String, dynamic> toJson() => {
        'token': token,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'data': {
          'id': id,
          'name': name,
          'email': email,
          'phone': phone,
          'region': region,
          'address': address,
          'ghana_card': ghanaCard,
          'status': status,
          'promo_code': promoCode,
          'company': company,
          'photo_url': photoUrl,
          'is_approved': isApproved,
          'momo_network': momoNetwork,
          'momo_number': momoNumber,
          'momo_account_name': momoAccountName,
          'momo_verified': momoVerified,
        },
      };
}

/// Vendor a partner onboarded — GET /partner/my-vendors returns raw Vendor rows.
class PartnerVendor {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final String location;
  final String status;
  final DateTime createdAt;

  /// Invitation state; replaced in place after a resend.
  VendorInvite? invite;

  PartnerVendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.status,
    required this.createdAt,
    this.invite,
  });

  /// `pending` means two different waits: on the vendor (set a password —
  /// resending helps) or on FlexiPhones (verification — nothing to resend).
  bool get awaitingVendor => invite?.awaitingResponse ?? false;

  factory PartnerVendor.fromJson(Map<String, dynamic> json) => PartnerVendor(
        id: json['id'] is int ? json['id'] : int.tryParse("${json['id']}") ?? 0,
        name: json['name']?.toString() ?? "",
        email: json['email']?.toString() ?? "",
        phoneNumber: json['phone_number']?.toString() ?? "",
        location: json['location']?.toString() ?? "",
        status: json['status']?.toString() ?? "pending",
        createdAt: _dt(json['created_at']),
        invite: json['invite'] is Map
            ? VendorInvite.fromJson(Map<String, dynamic>.from(json['invite']))
            : null,
      );
}

/// The `invite` object on each vendor from /partner/my-vendors and in every
/// resend-invite response (success and errors).
class VendorInvite {
  final bool awaitingResponse;
  final int invitesSent;
  final DateTime? lastInvitedAt;
  final bool canResend;
  final DateTime? nextResendAt;
  final bool resendLimitReached;

  VendorInvite({
    required this.awaitingResponse,
    required this.invitesSent,
    this.lastInvitedAt,
    required this.canResend,
    this.nextResendAt,
    required this.resendLimitReached,
  });

  factory VendorInvite.fromJson(Map<String, dynamic> json) => VendorInvite(
    awaitingResponse: _b(json['awaiting_response']),
    invitesSent: _i(json['invites_sent']),
    lastInvitedAt:
        json['last_invited_at'] == null
            ? null
            : DateTime.tryParse("${json['last_invited_at']}"),
    canResend: _b(json['can_resend']),
    nextResendAt:
        json['next_resend_at'] == null
            ? null
            : DateTime.tryParse("${json['next_resend_at']}"),
    resendLimitReached: _b(json['resend_limit_reached']),
  );
}

/// GET /partner/wallet -> data: { balance, total_credits, total_debits }
/// GET /partner/wallet. [balance] is all the money in the wallet;
/// [withdrawable] is what can be taken out now (earnings older than
/// [holdHours]); [maturing] is still waiting. Never compute these on the
/// phone — always use the server's numbers.
class PartnerWallet {
  final double balance;
  final double totalCredits;
  final double totalDebits;
  final double withdrawable;
  final double maturing;
  final int holdHours;

  /// When the next maturing amount becomes withdrawable; null when nothing
  /// is waiting.
  final DateTime? nextReleaseAt;

  PartnerWallet({
    required this.balance,
    required this.totalCredits,
    required this.totalDebits,
    required this.withdrawable,
    required this.maturing,
    required this.holdHours,
    this.nextReleaseAt,
  });

  factory PartnerWallet.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : json;
    final balance = _d(data['balance']);
    // Older servers had no withdrawable split: treat it all as available.
    final withdrawable =
        data.containsKey('withdrawable') ? _d(data['withdrawable']) : balance;
    return PartnerWallet(
      balance: balance,
      totalCredits: _d(data['total_credits']),
      totalDebits: _d(data['total_debits']),
      withdrawable: withdrawable,
      maturing:
          data.containsKey('maturing')
              ? _d(data['maturing'])
              : (balance - withdrawable).clamp(0, double.infinity).toDouble(),
      holdHours: int.tryParse("${data['hold_hours'] ?? 0}") ?? 0,
      nextReleaseAt:
          DateTime.tryParse("${data['next_release_at'] ?? ''}")?.toLocal(),
    );
  }
}

/// One row of GET /partner/withdrawals.
class Withdrawal {
  final String reference;
  final double amount;
  final String phone;
  final String network;

  /// pending | processing | success | failed
  final String status;
  final DateTime? createdAt;

  Withdrawal({
    required this.reference,
    required this.amount,
    required this.phone,
    required this.network,
    required this.status,
    this.createdAt,
  });

  bool get isPending => status == "pending" || status == "processing";
  bool get isPaid => status == "success";
  bool get isFailed => status == "failed";

  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
    reference: json['reference']?.toString() ?? "",
    amount: _d(json['amount']),
    phone: json['phone']?.toString() ?? "",
    network: json['network']?.toString() ?? "",
    status: (json['status']?.toString() ?? "pending").toLowerCase(),
    createdAt: DateTime.tryParse("${json['created_at'] ?? ''}")?.toLocal(),
  );
}

/// One row of GET /partner/wallet/transactions (paginator item).
class WalletTransaction {
  final int id;
  final double amount;
  final String effect; // credit | debit (backend column `effect`)
  final String description;
  final String status;
  final String? customerName;
  final String? vendorName;
  final DateTime createdAt;

  /// down_payment_commission | repayment_commission | null (e.g. a payout)
  final String? kind;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.effect,
    required this.description,
    required this.status,
    this.customerName,
    this.vendorName,
    required this.createdAt,
    this.kind,
  });

  /// Short label for the row, from `kind`.
  String? get kindLabel {
    switch (kind) {
      case "down_payment_commission":
        return "Down payment commission";
      case "repayment_commission":
        return "Repayment commission";
      case "initial_deduction":
        return "Down payment share";
      default:
        return isCredit ? null : "Payout";
    }
  }

  bool get isCredit => !{"debit", "out", "withdraw", "withdrawal"}
      .contains(effect.toLowerCase());

  String get title {
    if (description.trim().isNotEmpty) return description;
    return vendorName ?? customerName ?? "Transaction";
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] is int ? json['id'] : int.tryParse("${json['id']}") ?? 0,
      amount: _d(json['amount']),
      effect: json['effect']?.toString() ?? "credit",
      description: json['description']?.toString() ?? "",
      status: json['status']?.toString() ?? "",
      customerName:
          json['customer'] is Map ? json['customer']['name']?.toString() : null,
      vendorName:
          json['vendor'] is Map ? json['vendor']['name']?.toString() : null,
      createdAt: _dt(json['created_at']),
      kind: json['kind']?.toString(),
    );
  }
}

/// GET /partner/earnings — the agent's earnings home. Rates are set by the
/// admin and change, so they are always read from here, never hard-coded.
class PartnerEarnings {
  final String? promoCode;
  final int points;
  final double downPaymentCommissionPercent;
  final double repaymentCommissionPercent;
  final int pointsPerReferral;
  final double earnedDownPayment;
  final double earnedRepayment;
  final int referredCustomers;

  PartnerEarnings({
    this.promoCode,
    required this.points,
    required this.downPaymentCommissionPercent,
    required this.repaymentCommissionPercent,
    required this.pointsPerReferral,
    required this.earnedDownPayment,
    required this.earnedRepayment,
    required this.referredCustomers,
  });

  double get earnedTotal => earnedDownPayment + earnedRepayment;

  /// All zero means the admin hasn't set the rates yet.
  bool get hasRates =>
      downPaymentCommissionPercent > 0 ||
      repaymentCommissionPercent > 0 ||
      pointsPerReferral > 0;

  /// e.g. "Earn 10% of every down payment, 2% of every repayment and
  /// 50 points per referral."
  String get ratesSentence {
    if (!hasRates) {
      return "Commission and referral rates will show here once FlexiPhones sets them.";
    }
    String pct(double v) =>
        v == v.roundToDouble() ? "${v.toInt()}%" : "${v.toStringAsFixed(1)}%";
    return "Earn ${pct(downPaymentCommissionPercent)} of every down payment, "
        "${pct(repaymentCommissionPercent)} of every repayment and "
        "$pointsPerReferral points per referral.";
  }

  factory PartnerEarnings.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    final rates = data['rates'] is Map ? data['rates'] as Map : const {};
    final earned = data['earned'] is Map ? data['earned'] as Map : const {};
    return PartnerEarnings(
      promoCode: data['promo_code']?.toString(),
      points: _i(data['points']),
      downPaymentCommissionPercent: _d(rates['down_payment_commission_percent']),
      repaymentCommissionPercent: _d(rates['repayment_commission_percent']),
      pointsPerReferral: _i(rates['points_per_referral']),
      earnedDownPayment: _d(earned['down_payment_commission']),
      earnedRepayment: _d(earned['repayment_commission']),
      referredCustomers: _i(data['referred_customers']),
    );
  }
}

/// One row of GET /partner/points -> data.history (Laravel paginator).
class PointsEntry {
  final int id;
  final int points;
  final String reason;
  final String description;
  final String? customerName;
  final DateTime createdAt;

  PointsEntry({
    required this.id,
    required this.points,
    required this.reason,
    required this.description,
    this.customerName,
    required this.createdAt,
  });

  /// Unknown reasons fall back to the server's description.
  String get title =>
      description.isNotEmpty
          ? description
          : reason == "referral"
          ? "Referral${customerName == null ? "" : ": $customerName"}"
          : reason;

  factory PointsEntry.fromJson(Map<String, dynamic> json) => PointsEntry(
    id: _i(json['id']),
    points: _i(json['points']),
    reason: json['reason']?.toString() ?? "",
    description: json['description']?.toString() ?? "",
    customerName:
        json['customer'] is Map ? json['customer']['name']?.toString() : null,
    createdAt: _dt(json['created_at']),
  );
}

/// One item of GET /partner/notifications.
/// kinds: vendor_decision (decision approved|declined|suspended),
/// vendor_order_placed, vendor_down_payment (commission_earned).
/// Unknown kinds just show title + message.
class AgentNotification {
  final String id;
  final String? readAt;
  final DateTime createdAt;
  final String title;
  final String message;
  final String? kind;
  final String? decision;
  final String? vendorName;
  final double? commissionEarned;

  /// For app_update: the Play Store page.
  final String? androidUrl;

  AgentNotification({
    required this.id,
    this.readAt,
    required this.createdAt,
    required this.title,
    required this.message,
    this.kind,
    this.decision,
    this.vendorName,
    this.commissionEarned,
    this.androidUrl,
  });

  bool get isUnread => readAt == null;

  factory AgentNotification.fromJson(Map<String, dynamic> json) {
    final d = json['data'] is Map ? json['data'] as Map : const {};
    return AgentNotification(
      id: json['id']?.toString() ?? "",
      readAt: json['read_at']?.toString(),
      createdAt: _dt(json['created_at']),
      title: d['title']?.toString() ?? "",
      message: d['message']?.toString() ?? "",
      kind: d['kind']?.toString(),
      decision: d['decision']?.toString(),
      vendorName: d['vendor_name']?.toString(),
      commissionEarned:
          d['commission_earned'] == null ? null : _d(d['commission_earned']),
      androidUrl: d['android_url']?.toString(),
    );
  }
}

/// One row of GET/PUT /partner/notification-settings. `key` matches the
/// notification `kind`. Built from the server list — never hard-coded.
class AgentNotificationSetting {
  final String key;
  final String label;
  final String description;
  final bool app;
  final bool email;

  AgentNotificationSetting({
    required this.key,
    required this.label,
    required this.description,
    required this.app,
    required this.email,
  });

  factory AgentNotificationSetting.fromJson(Map<String, dynamic> json) =>
      AgentNotificationSetting(
        key: json['key']?.toString() ?? "",
        label: json['label']?.toString() ?? "",
        description: json['description']?.toString() ?? "",
        app: _b(json['app']),
        email: _b(json['email']),
      );
}

/// POST /account-roles, and the `roles` object in /login responses.
class AccountRoles {
  final bool customer;
  final bool agent;
  final bool customerVerified;

  /// false (with agent false) = verified as an agent but never finished
  /// sign-up: they must sign up again, not sign in or reset.
  final bool agentSignupFinished;

  AccountRoles({
    required this.customer,
    required this.agent,
    required this.customerVerified,
    required this.agentSignupFinished,
  });

  bool get both => customer && agent;

  factory AccountRoles.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    return AccountRoles(
      customer: _b(data['customer']),
      agent: _b(data['agent']),
      customerVerified: _b(data['customer_verified']),
      agentSignupFinished:
          data['agent_signup_finished'] == null
              ? true
              : _b(data['agent_signup_finished']),
    );
  }
}

/// GET /customer/agent-status (customer token).
class AgentStatus {
  final bool isAgent;
  final bool canBecomeAgent;
  final String? promoCode;

  AgentStatus({
    required this.isAgent,
    required this.canBecomeAgent,
    this.promoCode,
  });

  factory AgentStatus.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    return AgentStatus(
      isAgent: _b(data['is_agent']),
      canBecomeAgent: _b(data['can_become_agent']),
      promoCode: data['promo_code']?.toString(),
    );
  }
}

/// GET/POST/PUT /partner/momo-details
class MomoDetails {
  final String? network;
  final String? number;
  final String? accountName;
  final bool verified;

  MomoDetails({this.network, this.number, this.accountName, this.verified = false});

  bool get isSet => number != null && number!.isNotEmpty;

  factory MomoDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : json;
    return MomoDetails(
      network: data['momo_network']?.toString(),
      number: data['momo_number']?.toString(),
      accountName: data['momo_account_name']?.toString(),
      verified: _b(data['momo_verified']),
    );
  }
}
/// GET /partner/approval: is this agent approved, and what to tell them.
/// Information only for now: nothing is locked on it.
class AgentApproval {
  final bool approved;

  /// needs_ghana_card | under_review | approved | blocked
  final String state;
  final String title;
  final String message;
  final bool ghanaCardLinked;
  final bool canLinkGhanaCard;

  AgentApproval({
    required this.approved,
    required this.state,
    required this.title,
    required this.message,
    required this.ghanaCardLinked,
    required this.canLinkGhanaCard,
  });

  factory AgentApproval.fromJson(Map j) => AgentApproval(
    approved: j['approved'] == true,
    state: j['state']?.toString() ?? "",
    title: j['title']?.toString() ?? "",
    message: j['message']?.toString() ?? "",
    ghanaCardLinked: j['ghana_card_linked'] == true,
    canLinkGhanaCard: j['can_link_ghana_card'] == true,
  );
}
