/// GET /v1/orders/{id}/payment-calendar and /v1/orders/payment-calendar:
/// one square per day, oldest first; the last day is today.
class PaymentCalendar {
  final int? orderId;
  final List<PaymentDay> days;
  final int paidDays;
  final int missedDays;
  final int currentStreak;

  /// Null before the first payment day.
  final int? onTimeRate;
  final num amountPaid;
  final Map<String, String> legend;

  PaymentCalendar({
    this.orderId,
    required this.days,
    required this.paidDays,
    required this.missedDays,
    required this.currentStreak,
    this.onTimeRate,
    required this.amountPaid,
    required this.legend,
  });

  factory PaymentCalendar.fromJson(Map<String, dynamic> json) {
    final summary =
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'])
            : <String, dynamic>{};
    final legend =
        json['legend'] is Map
            ? (json['legend'] as Map).map((k, v) => MapEntry("$k", "$v"))
            : <String, String>{};
    return PaymentCalendar(
      orderId: int.tryParse("${json['order_id'] ?? ''}"),
      days:
          (json['days'] as List? ?? [])
              .whereType<Map>()
              .map((d) => PaymentDay.fromJson(Map<String, dynamic>.from(d)))
              .where((d) => d.date != null)
              .toList(),
      paidDays: _int(summary['paid_days']),
      missedDays: _int(summary['missed_days']),
      currentStreak: _int(summary['current_streak']),
      onTimeRate: int.tryParse("${summary['on_time_rate'] ?? ''}"),
      amountPaid: num.tryParse("${summary['amount_paid'] ?? ''}") ?? 0,
      legend: legend,
    );
  }
}

class PaymentDay {
  final DateTime? date;

  /// paid | missed | due | none
  final String status;
  final num paid;

  PaymentDay({this.date, required this.status, required this.paid});

  factory PaymentDay.fromJson(Map<String, dynamic> json) => PaymentDay(
    date: DateTime.tryParse("${json['date'] ?? ''}"),
    status: json['status']?.toString() ?? "none",
    paid: num.tryParse("${json['paid'] ?? ''}") ?? 0,
  );
}

int _int(dynamic v) => v is int ? v : int.tryParse("${v ?? ""}") ?? 0;
