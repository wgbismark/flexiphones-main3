import 'package:flexiphones/models/payment_calendar_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// GitHub-style payment history: one square per day, weeks as columns and
/// weekdays as rows (Sunday on top). Green paid, red missed, amber due
/// today, grey nothing expected. Loads itself; [orderId] null shows every
/// phone together.
///
/// Tap any square to see that day. When [onPayDays] is set, red and amber
/// squares can be picked; a bar then offers to pay for exactly those days.
class PaymentSquares extends StatefulWidget {
  const PaymentSquares({
    super.key,
    this.orderId,
    this.days = 90,
    this.title,
    this.dailyPayment,
    this.onPayDays,
  });

  final int? orderId;
  final int days;
  final String? title;

  /// Used to show the total for the picked days ("3 days · GHS 30").
  final num? dailyPayment;

  /// Called with the picked days, oldest first.
  final void Function(List<DateTime> days)? onPayDays;

  @override
  State<PaymentSquares> createState() => _PaymentSquaresState();
}

class _PaymentSquaresState extends State<PaymentSquares>
    with SingleTickerProviderStateMixin {
  static const _paid = Color(0xFF30A14E);
  static const _missed = Color(0xFFE5484D);
  static const _due = Color(0xFFF5A524);
  static const _cell = 16.0;
  static const _gap = 4.0;

  PaymentCalendar? _data;
  bool _loading = true;
  bool _failed = false;

  PaymentDay? _inspected;
  final Set<DateTime> _picked = {};

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _canPick => widget.onPayDays != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PaymentSquares old) {
    super.didUpdateWidget(old);
    if (old.orderId != widget.orderId) _load();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _picked.clear();
      _inspected = null;
    });
    final p = Provider.of<SharedProvider>(context, listen: false);
    final data = await p.getPaymentCalendar(
      orderId: widget.orderId,
      days: widget.days,
    );
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _failed = data == null;
    });
    _reveal.forward(from: 0);
  }

  bool _pickable(PaymentDay d) =>
      _canPick && (d.status == "missed" || d.status == "due");

  void _tap(PaymentDay d) {
    HapticFeedback.selectionClick();
    setState(() {
      _inspected = d;
      if (_pickable(d)) {
        _picked.contains(d.date!)
            ? _picked.remove(d.date!)
            : _picked.add(d.date!);
      }
    });
  }

  void _pickAllMissed() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final d in _data?.days ?? <PaymentDay>[]) {
        if (_pickable(d)) _picked.add(d.date!);
      }
    });
  }

  Color _colorFor(String status, ColorScheme ch) => switch (status) {
    "paid" => _paid,
    "missed" => _missed,
    "due" => _due,
    _ => ch.onSurface.withOpacity(0.08),
  };

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final missedLeft =
        (_data?.days ?? []).where((d) => _pickable(d)).length - _picked.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ch.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title ?? "Payment history",
                  style: ptstyle(size: 16, weight: 700, color: ch.onSurface),
                ),
              ),
              if (_canPick && missedLeft > 0)
                GestureDetector(
                  onTap: _pickAllMissed,
                  child: Text(
                    "Select missed",
                    style: ptstyle(
                      size: 12,
                      weight: 600,
                      color: const Color(0xFF0071E3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _summaryText(),
            style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const SizedBox(
              height: 7 * (_cell + _gap),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_failed)
            SizedBox(
              height: 7 * (_cell + _gap),
              child: Center(
                child: TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    "Couldn't load. Tap to retry",
                    style: ptstyle(size: 12, weight: 500),
                  ),
                ),
              ),
            )
          else
            _grid(ch),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _detail(ch),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legend("Paid", _paid),
              _legend("Missed", _missed),
              _legend("Due today", _due),
              _legend("No payment", ch.onSurface.withOpacity(0.08)),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: _picked.isEmpty ? const SizedBox(width: double.infinity) : _payBar(ch),
          ),
        ],
      ),
    );
  }

  String _summaryText() {
    final d = _data;
    if (d == null) return "Your daily payments at a glance";
    final parts = [
      "${d.paidDays} day${d.paidDays == 1 ? "" : "s"} paid",
      "${d.missedDays} missed",
      if (d.currentStreak > 0) "${d.currentStreak}-day streak",
      if (d.onTimeRate != null) "${d.onTimeRate}% on time",
    ];
    return parts.join(" · ");
  }

  Widget _detail(ColorScheme ch) {
    final d = _inspected;
    if (d == null) {
      return Text(
        _canPick
            ? "Tap a day to see it. Tap red days to pick the ones to pay."
            : "Tap a day to see what happened.",
        key: const ValueKey("hint"),
        style: ptstyle(size: 11, weight: 400, color: ch.onSurfaceVariant),
      );
    }
    final label = switch (d.status) {
      "paid" => "Paid GHS ${_money(d.paid)}",
      "missed" => "Missed",
      "due" => "Due today",
      _ => "No payment expected",
    };
    return Row(
      key: ValueKey(d.date),
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _colorFor(d.status, ch),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat("EEEE, d MMM").format(d.date!),
          style: ptstyle(size: 12, weight: 600, color: ch.onSurface),
        ),
        Text(
          "  ·  $label",
          style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _payBar(ColorScheme ch) {
    final days = _picked.toList()..sort();
    final n = days.length;
    final total =
        widget.dailyPayment == null ? null : widget.dailyPayment! * n;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          color: ch.onSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$n day${n == 1 ? "" : "s"} selected",
                    style: ptstyle(size: 12, weight: 500, color: ch.surface.withOpacity(0.7)),
                  ),
                  Text(
                    total == null ? "Choose the amount next" : "GHS ${_money(total)}",
                    style: ptstyle(size: 16, weight: 700, color: ch.surface),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(_picked.clear),
              style: TextButton.styleFrom(foregroundColor: ch.surface.withOpacity(0.7)),
              child: Text("Clear", style: ptstyle(size: 12, weight: 500)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0071E3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onPayDays!(days);
              },
              child: Text("Pay", style: ptstyle(size: 13, weight: 600)),
            ),
          ],
        ),
      ),
    );
  }

  String _money(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Widget _grid(ColorScheme ch) {
    final days = _data!.days;
    if (days.isEmpty) {
      return SizedBox(
        height: 7 * (_cell + _gap),
        child: Center(
          child: Text(
            "No payments yet",
            style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
          ),
        ),
      );
    }
    // Sunday on top: DateTime.weekday is Mon=1..Sun=7, so Sunday -> 0.
    final lead = days.first.date!.weekday % 7;
    final cells = <PaymentDay?>[...List.filled(lead, null), ...days];
    final columns = (cells.length / 7).ceil();

    const labels = ["S", "", "T", "", "T", "", "S"];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            for (final l in labels)
              SizedBox(
                height: _cell + _gap,
                width: 14,
                child: Text(
                  l,
                  style: ptstyle(
                    size: 9,
                    weight: 500,
                    color: ch.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // today is on the right and visible first
            child: AnimatedBuilder(
              animation: _reveal,
              builder:
                  (_, _) => Row(
                    children: [
                      for (var c = 0; c < columns; c++)
                        Padding(
                          padding: const EdgeInsets.only(right: _gap),
                          child: Opacity(
                            // Columns ripple in from today backwards.
                            opacity: Curves.easeOut.transform(
                              ((_reveal.value * 1.6) -
                                      (columns - 1 - c) / columns)
                                  .clamp(0.0, 1.0),
                            ),
                            child: Column(
                              children: [
                                for (var r = 0; r < 7; r++)
                                  _square(
                                    ch,
                                    c * 7 + r < cells.length
                                        ? cells[c * 7 + r]
                                        : null,
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _square(ColorScheme ch, PaymentDay? day) {
    if (day == null) {
      return const SizedBox(width: _cell, height: _cell + _gap);
    }
    final picked = _picked.contains(day.date);
    final inspected = _inspected?.date == day.date;
    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: GestureDetector(
        onTap: () => _tap(day),
        child: AnimatedScale(
          scale: picked ? 1.12 : 1,
          duration: const Duration(milliseconds: 160),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: _cell,
            height: _cell,
            decoration: BoxDecoration(
              color: _colorFor(day.status, ch),
              borderRadius: BorderRadius.circular(4.5),
              border:
                  picked
                      ? Border.all(color: ch.onSurface, width: 2)
                      : inspected
                      ? Border.all(color: ch.onSurface.withOpacity(0.5), width: 1.2)
                      : null,
            ),
            child:
                picked
                    ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
                    : null,
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) {
    final ch = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: ptstyle(size: 11, weight: 400, color: ch.onSurfaceVariant),
        ),
      ],
    );
  }
}
