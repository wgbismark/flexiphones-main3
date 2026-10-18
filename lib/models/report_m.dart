/// One kind of thing that can be reported, with its reasons
/// (from GET /reports/reasons, never hard-coded).
class ReportTarget {
  final String target;
  final String label;
  final List<ReportReason> reasons;

  ReportTarget({
    required this.target,
    required this.label,
    required this.reasons,
  });

  factory ReportTarget.fromJson(Map j) => ReportTarget(
    target: j['target']?.toString() ?? "",
    label: j['label']?.toString() ?? "",
    reasons:
        (j['reasons'] is List ? j['reasons'] as List : const [])
            .whereType<Map>()
            .map(
              (r) => ReportReason(
                key: r['key']?.toString() ?? "",
                label: r['label']?.toString() ?? "",
              ),
            )
            .toList(),
  );
}

class ReportReason {
  final String key;
  final String label;
  ReportReason({required this.key, required this.label});
}

/// A sent report and where it is.
class Report {
  final String reference;
  final String target;
  final String targetLabel;
  final String reasonLabel;
  final String message;

  /// open | reviewing | resolved | dismissed
  final String status;
  final String statusLabel;
  final bool isClosed;

  /// FlexiPhones' answer, once written.
  final String? response;
  final String? subject;
  final DateTime? createdAt;

  Report({
    required this.reference,
    required this.target,
    required this.targetLabel,
    required this.reasonLabel,
    required this.message,
    required this.status,
    required this.statusLabel,
    required this.isClosed,
    this.response,
    this.subject,
    this.createdAt,
  });

  factory Report.fromJson(Map j) {
    final vendor = j['vendor'] is Map ? j['vendor'] as Map : null;
    final order = j['order'] is Map ? j['order'] as Map : null;
    final product = j['product'] is Map ? j['product'] as Map : null;
    return Report(
      reference: j['reference']?.toString() ?? "",
      target: j['target']?.toString() ?? "",
      targetLabel: j['target_label']?.toString() ?? "",
      reasonLabel: j['reason_label']?.toString() ?? "",
      message: j['message']?.toString() ?? "",
      status: j['status']?.toString() ?? "open",
      statusLabel: j['status_label']?.toString() ?? "Open",
      isClosed: j['is_closed'] == true,
      response:
          (j['response']?.toString() ?? "").trim().isEmpty
              ? null
              : j['response'].toString(),
      subject:
          order?['device']?.toString() ??
          vendor?['name']?.toString() ??
          product?['name']?.toString(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ""),
    );
  }
}
