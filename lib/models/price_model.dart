/// Shown instead of the instalments when a term can't be financed.
const notFinanceableText = "This phone can't be financed at its current price.";

/// Whether one term entry (e.g. breakdowns["3_months"]) can be financed.
/// Uses the server's `financing_available`; responses from before that
/// field existed count as not financeable when nothing is left to finance
/// (`amount_financed` 0 or less).
bool isFinanceable(dynamic term) {
  if (term is! Map) return true;
  final flag = term['financing_available'];
  if (flag is bool) return flag;
  if (flag != null) return flag == 1 || "$flag" == "1" || "$flag" == "true";
  final financed = num.tryParse("${term['amount_financed'] ?? ''}");
  return financed == null || financed > 0;
}

class BreakdownResponse {
  final String status;
  final Breakdowns breakdowns;

  BreakdownResponse({required this.status, required this.breakdowns});

  factory BreakdownResponse.fromJson(Map<String, dynamic> json) {
    return BreakdownResponse(
      status: json['status'] ?? '',
      breakdowns: Breakdowns.fromJson(json['breakdowns'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'breakdowns': breakdowns.toJson()};
  }
}

class Breakdowns {
  final Map<String, dynamic> months;

  Breakdowns({required this.months});

  factory Breakdowns.fromJson(Map<String, dynamic> json) {
    final map = <String, dynamic>{};

    json.forEach((key, value) {
      map[key] = value;
    });

    return Breakdowns(months: map);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    months.forEach((key, value) {
      map[key] = value;
    });

    return map;
  }
}
