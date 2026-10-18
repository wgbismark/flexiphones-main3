import 'package:flexiphones/models/report_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF0071E3);
const _red = Color(0xFFE5484D);

/// Opens the small "Report a problem" sheet.
/// [target] is vendor | order | product | app; pass the matching id.
Future<void> showReportSheet(
  BuildContext context, {
  required String target,
  int? orderId,
  int? vendorId,
  int? productId,
  String? subject,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => _ReportSheet(
          target: target,
          orderId: orderId,
          vendorId: vendorId,
          productId: productId,
          subject: subject,
        ),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.target,
    this.orderId,
    this.vendorId,
    this.productId,
    this.subject,
  });
  final String target;
  final int? orderId;
  final int? vendorId;
  final int? productId;
  final String? subject;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _text = TextEditingController();
  ReportTarget? _kind;
  bool _loading = true;
  String? _reason;
  bool _sending = false;
  String? _error;
  Report? _sent;
  String? _sentMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = Provider.of<SharedProvider>(context, listen: false);
    final all = await p.getReportReasons();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _kind = all.where((t) => t.target == widget.target).firstOrNull;
    });
  }

  Future<void> _send() async {
    if (_reason == null || _sending) return;
    if (_reason == "other" && _text.text.trim().isEmpty) {
      setState(() => _error = "Please tell us what happened.");
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    final p = Provider.of<SharedProvider>(context, listen: false);
    final r = await p.sendReport({
      "target": widget.target,
      "reason": _reason,
      if (_text.text.trim().isNotEmpty) "message": _text.text.trim(),
      if (widget.orderId != null) "order_id": widget.orderId,
      if (widget.vendorId != null) "vendor_id": widget.vendorId,
      if (widget.productId != null) "product_id": widget.productId,
    });
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.code == 201 || r.code == 200) {
      HapticFeedback.mediumImpact();
      setState(() {
        _sent = r.report;
        _sentMessage = r.message;
      });
    } else if (r.code == 409) {
      setState(() {
        _sent = r.report;
        _sentMessage =
            "You already reported this${r.report != null ? ". Reference ${r.report!.reference}" : ""}. We're looking into it.";
      });
    } else if (r.code == 429) {
      setState(
        () =>
            _error =
                "You've sent a lot of reports today. Please wait until tomorrow, or contact support.",
      );
    } else if (r.code == 404) {
      setState(() => _error = "We couldn't find that.");
    } else {
      setState(
        () =>
            _error = r.message.isEmpty ? "Couldn't send. Try again." : r.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: ch.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ch.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_sent != null || _sentMessage != null)
                _done(ch)
              else ...[
                Text(
                  _kind?.label.isNotEmpty == true
                      ? "Report: ${_kind!.label.toLowerCase()}"
                      : "Report a problem",
                  style: ptstyle(size: 18, weight: 700, color: ch.onSurface),
                ),
                if ((widget.subject ?? "").isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.subject!,
                      style: ptstyle(
                        size: 12.5,
                        weight: 400,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_kind == null)
                  Text(
                    "Couldn't load the options. Check your internet and try again.",
                    style: ptstyle(
                      size: 13,
                      weight: 400,
                      color: ch.onSurfaceVariant,
                    ),
                  )
                else ...[
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < _kind!.reasons.length; i++) ...[
                          InkWell(
                            onTap:
                                () => setState(() {
                                  _reason = _kind!.reasons[i].key;
                                  _error = null;
                                }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _kind!.reasons[i].label,
                                      style: ptstyle(
                                        size: 13.5,
                                        weight: 500,
                                        color: ch.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _reason == _kind!.reasons[i].key
                                              ? _blue
                                              : Colors.transparent,
                                      border: Border.all(
                                        color:
                                            _reason == _kind!.reasons[i].key
                                                ? _blue
                                                : ch.onSurface.withOpacity(0.25),
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        _reason == _kind!.reasons[i].key
                                            ? const Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (i < _kind!.reasons.length - 1)
                            Divider(
                              height: 0.5,
                              thickness: 0.5,
                              indent: 14,
                              color: Colors.black.withOpacity(0.08),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _text,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText:
                          _reason == "other"
                              ? "Tell us what happened (needed)"
                              : "Anything else? (optional)",
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: ptstyle(size: 12.5, weight: 600, color: _red),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        disabledBackgroundColor: _blue.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _reason == null || _sending ? null : _send,
                      child:
                          _sending
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                "Send report",
                                style: ptstyle(
                                  size: 15,
                                  weight: 700,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _done(ColorScheme ch) => Column(
    children: [
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF30A14E).withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF30A14E),
          size: 32,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        "Report sent",
        style: ptstyle(size: 19, weight: 700, color: ch.onSurface),
      ),
      const SizedBox(height: 6),
      Text(
        _sentMessage ?? "",
        textAlign: TextAlign.center,
        style: ptstyle(
          size: 13,
          weight: 400,
          color: ch.onSurfaceVariant,
          height: 1.45,
        ),
      ),
      if (_sent != null) ...[
        const SizedBox(height: 10),
        SelectableText(
          _sent!.reference,
          style: ptstyle(
            size: 13,
            weight: 700,
            color: ch.onSurface,
          ).copyWith(letterSpacing: 0.6),
        ),
      ],
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Done",
            style: ptstyle(size: 15, weight: 700, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}

/// "My reports": status, and FlexiPhones' answer when there is one.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  static void open(BuildContext context) => Navigator.of(
    context,
  ).push(CupertinoPageRoute(builder: (_) => const MyReportsScreen()));

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<Report>? _list;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = Provider.of<SharedProvider>(context, listen: false);
    final l = await p.getMyReports();
    if (mounted) setState(() => _list = l);
  }

  Color _statusColor(Report r) => switch (r.status) {
    "resolved" => const Color(0xFF30A14E),
    "reviewing" => const Color(0xFFE08A00),
    "dismissed" => const Color(0xFF6E6E73),
    _ => _blue,
  };

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final list = _list;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        scrolledUnderElevation: 0,
        title: Text("My reports", style: ptstyle(size: 16, weight: 600)),
        actions: [
          IconButton(
            tooltip: "Report a problem with the app",
            onPressed: () async {
              await showReportSheet(context, target: "app");
              _load();
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body:
          list == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _load,
                child:
                    list.isEmpty
                        ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Icon(
                              Icons.flag_outlined,
                              size: 48,
                              color: ch.onSurfaceVariant.withOpacity(0.4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "No reports yet",
                              textAlign: TextAlign.center,
                              style: ptstyle(
                                size: 15,
                                weight: 600,
                                color: ch.onSurface,
                              ),
                            ),
                          ],
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final r = list[i];
                            final c = _statusColor(r);
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          r.reasonLabel,
                                          style: ptstyle(
                                            size: 13.5,
                                            weight: 600,
                                            color: ch.onSurface,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: c.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Text(
                                          r.statusLabel,
                                          style: ptstyle(
                                            size: 11,
                                            weight: 600,
                                            color: c,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      r.targetLabel,
                                      if ((r.subject ?? "").isNotEmpty)
                                        r.subject!,
                                      if (r.createdAt != null)
                                        DateFormat(
                                          "d MMM",
                                        ).format(r.createdAt!.toLocal()),
                                      r.reference,
                                    ].join(" · "),
                                    style: ptstyle(
                                      size: 11.5,
                                      weight: 400,
                                      color: ch.onSurfaceVariant,
                                    ),
                                  ),
                                  if (r.response != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _blue.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "From FlexiPhones",
                                            style: ptstyle(
                                              size: 11,
                                              weight: 700,
                                              color: _blue,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            r.response!,
                                            style: ptstyle(
                                              size: 12.5,
                                              weight: 400,
                                              color: ch.onSurface,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}
