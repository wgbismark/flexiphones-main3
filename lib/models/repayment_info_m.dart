import 'package:flexiphones/models/standing_m.dart';

/// GET /v1/orders/{id}/repayment-info — everything the "Pay now" screen needs.
class RepaymentInfo {
  final int orderId;
  final bool repaymentAllowed;
  final String? reason;
  final num totalPayment;
  final num totalPaid;
  final num balance;
  final num dailyPayment;
  final String? nextDue;
  final int daysOverdue;
  final bool isOverdue;
  final num catchUpAmount;
  final num minimumAmount;
  final num maximumAmount;
  final List<SuggestedAmount> suggestedAmounts;
  final String? defaultPhone;
  final bool inProgress;
  final String? displayStatus;

  /// Daily payments missed (0 when on time or ahead).
  final int missedDays;

  /// Custom stepper: whole days from [minDays] to [maxDays], each [dayPrice].
  final num dayPrice;
  final int minDays;
  final int maxDays;

  /// Same object as the order's `repayment_standing`.
  final RepaymentStanding? standing;

  RepaymentInfo({
    required this.orderId,
    required this.repaymentAllowed,
    this.reason,
    required this.totalPayment,
    required this.totalPaid,
    required this.balance,
    required this.dailyPayment,
    this.nextDue,
    required this.daysOverdue,
    required this.isOverdue,
    required this.catchUpAmount,
    required this.minimumAmount,
    required this.maximumAmount,
    required this.suggestedAmounts,
    this.defaultPhone,
    required this.inProgress,
    this.displayStatus,
    this.missedDays = 0,
    this.dayPrice = 0,
    this.minDays = 1,
    this.maxDays = 60,
    this.standing,
  });

  factory RepaymentInfo.fromJson(Map<String, dynamic> json) {
    return RepaymentInfo(
      orderId: _int(json['order_id']),
      repaymentAllowed: json['repayment_allowed'] == true,
      reason: json['reason']?.toString(),
      totalPayment: _num(json['total_payment']),
      totalPaid: _num(json['total_paid']),
      balance: _num(json['balance']),
      dailyPayment: _num(json['daily_payment']),
      nextDue: json['next_due']?.toString(),
      daysOverdue: _int(json['days_overdue']),
      isOverdue: json['is_overdue'] == true,
      catchUpAmount: _num(json['catch_up_amount']),
      minimumAmount: _num(json['minimum_amount'], fallback: 1),
      maximumAmount: _num(json['maximum_amount']),
      suggestedAmounts:
          (json['suggested_amounts'] as List? ?? [])
              .whereType<Map>()
              .map((e) => SuggestedAmount.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
      defaultPhone: json['default_phone']?.toString(),
      inProgress: json['in_progress'] == true,
      displayStatus: json['display_status']?.toString(),
      missedDays: _int(json['missed_days'] ?? json['days_overdue']),
      dayPrice: _num(
        (json['day_options'] is Map ? json['day_options']['daily'] : null) ??
            json['daily_payment'],
      ),
      minDays: json['day_options'] is Map
          ? _int(json['day_options']['min_days']).clamp(1, 365)
          : 1,
      maxDays: json['day_options'] is Map
          ? _int(json['day_options']['max_days']).clamp(1, 365)
          : 60,
      standing: RepaymentStanding.tryParse(
        json['repayment_standing'] ?? json['standing'],
      ),
    );
  }
}

class SuggestedAmount {
  /// catch_up | catch_up_today | days_N | full_balance (older servers: "").
  final String key;
  final String label;
  final num amount;

  /// Days this chip pays for (0 when the server didn't say).
  final int days;

  SuggestedAmount({
    required this.label,
    required this.amount,
    this.key = "",
    this.days = 0,
  });

  bool get isCatchUp => key == "catch_up";

  factory SuggestedAmount.fromJson(Map<String, dynamic> json) =>
      SuggestedAmount(
        key: json['key']?.toString() ?? "",
        label: json['label']?.toString() ?? "",
        amount: _num(json['amount']),
        days: _int(json['days']),
      );
}

/// One payment's receipt (down payment or repayment).
class Receipt {
  final String reference;
  final String type;
  final String title;
  final String status;
  final num amount;
  final String currency;
  final DateTime? paidAt;
  final num? daysPaid;
  final String device;
  final int? orderId;
  final String? orderRef;
  final String? paidWith;
  final num? balanceBefore;
  final num? balanceAfter;
  final String? nextDue;
  final String shareText;

  Receipt({
    required this.reference,
    required this.type,
    required this.title,
    required this.status,
    required this.amount,
    required this.currency,
    this.paidAt,
    this.daysPaid,
    required this.device,
    this.orderId,
    this.orderRef,
    this.paidWith,
    this.balanceBefore,
    this.balanceAfter,
    this.nextDue,
    required this.shareText,
  });

  bool get isDownPayment => type == "down_payment";
  bool get fullyPaid => balanceAfter != null && balanceAfter! <= 0;

  factory Receipt.fromJson(Map<String, dynamic> j) => Receipt(
    reference: j['reference']?.toString() ?? "",
    type: j['type']?.toString() ?? "",
    title: j['title']?.toString() ?? "Payment",
    status: j['status']?.toString() ?? "",
    amount: _num(j['amount']),
    currency: j['currency']?.toString() ?? "GHS",
    paidAt: DateTime.tryParse(j['paid_at']?.toString() ?? "")?.toLocal(),
    daysPaid: j['days_paid'] == null ? null : _num(j['days_paid']),
    device: j['device']?.toString() ?? "",
    orderId: j['order_id'] == null ? null : _int(j['order_id']),
    orderRef: j['order_ref']?.toString(),
    paidWith: j['paid_with']?.toString(),
    balanceBefore: j['balance_before'] == null ? null : _num(j['balance_before']),
    balanceAfter: j['balance_after'] == null ? null : _num(j['balance_after']),
    nextDue: j['next_due']?.toString(),
    shareText: j['share_text']?.toString() ?? "",
  );
}

/// GET /v1/orders/{id}/repayment-status?since=... — one poll result.
class RepaymentStatus {
  /// queued | awaiting_approval | processing | paid | failed | none
  final String state;
  final String message;
  final bool done;
  final String? reference;
  final num? totalPaid;
  final num? balance;
  final String? nextDue;

  /// Set once the payment is paid.
  final Receipt? receipt;

  RepaymentStatus({
    required this.state,
    required this.message,
    required this.done,
    this.reference,
    this.totalPaid,
    this.balance,
    this.nextDue,
    this.receipt,
  });

  bool get isPaid => state == "paid";
  bool get isFailed => state == "failed";

  factory RepaymentStatus.fromJson(Map<String, dynamic> json) {
    final order = json['order'] is Map ? json['order'] as Map : const {};
    return RepaymentStatus(
      state: json['state']?.toString() ?? "none",
      message: json['message']?.toString() ?? "",
      done: json['done'] == true,
      reference: json['reference']?.toString(),
      totalPaid: order['total_paid'] == null ? null : _num(order['total_paid']),
      balance: order['balance'] == null ? null : _num(order['balance']),
      nextDue: order['next_due']?.toString(),
      receipt:
          json['receipt'] is Map
              ? Receipt.fromJson(Map<String, dynamic>.from(json['receipt']))
              : null,
    );
  }
}

// The API mixes numbers and numeric strings ("400.00"), so parse both.
num _num(dynamic v, {num fallback = 0}) =>
    v is num ? v : num.tryParse("${v ?? ""}") ?? fallback;

int _int(dynamic v) => v is int ? v : int.tryParse("${v ?? ""}") ?? 0;
