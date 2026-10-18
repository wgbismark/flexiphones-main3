import 'package:flutter/material.dart';

num _n(dynamic v) => v is num ? v : num.tryParse("${v ?? ""}") ?? 0;
int _i(dynamic v) => v is int ? v : int.tryParse("${v ?? ""}") ?? 0;

/// ok green, info grey, warning amber, danger red.
Color severityColor(String severity) => switch (severity) {
  "ok" => const Color(0xFF30A14E),
  "warning" => const Color(0xFFE08A00),
  "danger" => const Color(0xFFE5484D),
  _ => const Color(0xFF6E6E73),
};

/// Where an order's daily payments stand (`repayment_standing`).
/// Never decide "on time" from dates in the app: use [state] / [isOwing].
class RepaymentStanding {
  /// awaiting_down_payment | getting_ready | on_time | due_today | overdue |
  /// locked | paid_off | cash | cancelled
  final String state;
  final String severity;
  final String label;
  final String detail;
  final bool isLocked;
  final bool isOwing;
  final int missedDays;
  final num amountOverdue;
  final int? daysAhead;
  final DateTime? nextDue;
  final num dailyPayment;
  final num balance;

  RepaymentStanding({
    required this.state,
    required this.severity,
    required this.label,
    required this.detail,
    required this.isLocked,
    required this.isOwing,
    required this.missedDays,
    required this.amountOverdue,
    this.daysAhead,
    this.nextDue,
    required this.dailyPayment,
    required this.balance,
  });

  Color get color => severityColor(severity);

  /// The days that were missed: from when the paid days ran out, one per
  /// day, [missedDays] of them.
  List<DateTime> get missedDates {
    if (missedDays <= 0) return const [];
    final start = nextDue?.toLocal() ?? DateTime.now();
    final d0 = DateTime(start.year, start.month, start.day);
    return List.generate(missedDays, (i) => d0.add(Duration(days: i)));
  }

  static RepaymentStanding? tryParse(dynamic j) {
    if (j is! Map) return null;
    final state = j['state']?.toString() ?? "";
    return RepaymentStanding(
      state: state,
      severity: j['severity']?.toString() ?? "info",
      label: j['label']?.toString() ?? "",
      detail: j['detail']?.toString() ?? "",
      isLocked: j['is_locked'] == true,
      isOwing: j['is_owing'] == true || state == "overdue" || state == "locked",
      missedDays: _i(j['missed_days']),
      amountOverdue: _n(j['amount_overdue']),
      daysAhead: j['days_ahead'] == null ? null : _i(j['days_ahead']),
      nextDue: DateTime.tryParse(j['next_due']?.toString() ?? ""),
      dailyPayment: _n(j['daily_payment']),
      balance: _n(j['balance']),
    );
  }
}

/// Where the phone itself is (`phone_state`).
class PhoneState {
  /// awaiting_payment | preparing | ready | locked | owned | cash | cancelled
  final String key;
  final String severity;
  final String label;
  final String detail;
  final String device;
  final bool isReady;
  final DateTime? activatedAt;

  PhoneState({
    required this.key,
    required this.severity,
    required this.label,
    required this.detail,
    required this.device,
    required this.isReady,
    this.activatedAt,
  });

  Color get color => severityColor(severity);

  static PhoneState? tryParse(dynamic j) {
    if (j is! Map) return null;
    final key = j['key']?.toString() ?? "";
    return PhoneState(
      key: key,
      severity: j['severity']?.toString() ?? "info",
      label: j['label']?.toString() ?? "",
      detail: j['detail']?.toString() ?? "",
      device: j['device']?.toString() ?? "",
      isReady: j['is_ready'] == true || key == "ready" || key == "owned",
      activatedAt: DateTime.tryParse(j['activated_at']?.toString() ?? ""),
    );
  }
}

/// GET /orders/standing: may the customer start another installment plan?
class OrdersStanding {
  final bool canOrderInstallment;
  final bool canBuyCash;
  final String? reason;
  final String message;
  final int totalMissedDays;
  final num totalAmountOverdue;
  final List<OverdueOrder> overdueOrders;

  OrdersStanding({
    required this.canOrderInstallment,
    required this.canBuyCash,
    this.reason,
    required this.message,
    required this.totalMissedDays,
    required this.totalAmountOverdue,
    required this.overdueOrders,
  });

  bool get isBehind => reason == "overdue_plan" || totalMissedDays > 0;

  factory OrdersStanding.fromJson(Map j) => OrdersStanding(
    canOrderInstallment: j['can_order_installment'] != false,
    canBuyCash: j['can_buy_cash'] != false,
    reason: j['reason']?.toString(),
    message: j['message']?.toString() ?? "",
    totalMissedDays: _i(j['total_missed_days']),
    totalAmountOverdue: _n(j['total_amount_overdue']),
    overdueOrders:
        (j['overdue_orders'] is List ? j['overdue_orders'] as List : const [])
            .whereType<Map>()
            .map(OverdueOrder.fromJson)
            .toList(),
  );
}

class OverdueOrder {
  final int orderId;
  final String device;
  final bool isLocked;
  final int missedDays;
  final num amountOverdue;

  OverdueOrder({
    required this.orderId,
    required this.device,
    required this.isLocked,
    required this.missedDays,
    required this.amountOverdue,
  });

  factory OverdueOrder.fromJson(Map j) => OverdueOrder(
    orderId: _i(j['order_id']),
    device: j['device']?.toString() ?? "",
    isLocked: j['is_locked'] == true,
    missedDays: _i(j['missed_days']),
    amountOverdue: _n(j['amount_overdue']),
  );
}
