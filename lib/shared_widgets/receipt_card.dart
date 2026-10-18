import 'package:flexiphones/models/repayment_info_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

const _blue = Color(0xFF0071E3);
const _green = Color(0xFF30A14E);

String _money(num v) =>
    NumberFormat("#,##0.00").format(v);

String _days(num d) =>
    "${d == d.roundToDouble() ? d.toInt() : d} day${d == 1 ? "" : "s"}";

/// The small receipt: ✓ Paid GHS 20.00, what it was for, when, how, what's
/// left, the reference; Share sends the server's plain-text version.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.receipt, this.onDone});
  final Receipt receipt;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final r = receipt;
    final sub = [
      r.title,
      if (!r.isDownPayment && r.daysPaid != null) _days(r.daysPaid!),
      if (r.device.isNotEmpty) r.device,
    ].join(" · ");
    final when = [
      if (r.paidAt != null) DateFormat("d MMM yyyy, HH:mm").format(r.paidAt!),
      if ((r.paidWith ?? "").isNotEmpty) r.paidWith!,
    ].join(" · ");
    final due = DateTime.tryParse(r.nextDue ?? "");

    Widget line(String text, {Color? color, double size = 12.5, int w = 400}) =>
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: ptstyle(
              size: size,
              weight: w,
              color: color ?? ch.onSurfaceVariant,
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, s, c) => Transform.scale(scale: s, child: c),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: _green, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "Paid  ",
                style: ptstyle(size: 15, weight: 500, color: ch.onSurfaceVariant),
              ),
              TextSpan(
                text: "${r.currency} ${_money(r.amount)}",
                style: ptstyle(
                  size: 24,
                  weight: 700,
                  color: ch.onSurface,
                ).copyWith(letterSpacing: -0.5),
              ),
            ],
          ),
        ),
        line(sub, color: ch.onSurface, w: 500),
        if (when.isNotEmpty) line(when),
        if (r.balanceAfter != null)
          line(
            r.fullyPaid
                ? "Fully paid. Thank you!"
                : "Left to pay  ${r.currency} ${_money(r.balanceAfter!)}"
                    "${due != null ? " · next due ${DateFormat("d MMM").format(due)}" : ""}",
            color: r.fullyPaid ? _green : null,
            w: r.fullyPaid ? 600 : 400,
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            "Ref ${r.reference}",
            style: ptstyle(
              size: 11.5,
              weight: 600,
              color: ch.onSurfaceVariant,
            ).copyWith(letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black.withOpacity(0.12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed:
                      r.shareText.isEmpty
                          ? null
                          : () => SharePlus.instance.share(
                            ShareParams(text: r.shareText),
                          ),
                  icon: Icon(Icons.ios_share_rounded, size: 18, color: ch.onSurface),
                  label: Text(
                    "Share",
                    style: ptstyle(size: 14, weight: 600, color: ch.onSurface),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onDone ?? () => Navigator.of(context).pop(),
                  child: Text(
                    "Done",
                    style: ptstyle(size: 14, weight: 600, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Opens a receipt in a small bottom sheet.
Future<void> showReceiptSheet(BuildContext context, Receipt receipt) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(top: false, child: ReceiptCard(receipt: receipt)),
        ),
  );
}

/// "Receipts" on the order screen: one row per payment, newest first;
/// tap to open the receipt. The oldest is the down payment.
class OrderReceipts extends StatefulWidget {
  const OrderReceipts({super.key, required this.orderId});
  final int orderId;

  @override
  State<OrderReceipts> createState() => _OrderReceiptsState();
}

class _OrderReceiptsState extends State<OrderReceipts> {
  List<Receipt>? _list;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = Provider.of<SharedProvider>(context, listen: false);
    final list = await p.getOrderReceipts(widget.orderId);
    if (mounted) setState(() => _list = list);
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final list = _list;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(
            "Receipts",
            style: ptstyle(size: 15, weight: 700, color: ch.onSurface),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                InkWell(
                  onTap: () => showReceiptSheet(context, list[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          list[i].isDownPayment
                              ? Icons.flag_rounded
                              : Icons.receipt_long_rounded,
                          size: 18,
                          color: list[i].isDownPayment ? _green : _blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            [
                              if (list[i].paidAt != null)
                                DateFormat("d MMM").format(list[i].paidAt!),
                              list[i].title,
                              if (!list[i].isDownPayment &&
                                  list[i].daysPaid != null)
                                _days(list[i].daysPaid!),
                            ].join(" · "),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ptstyle(
                              size: 13,
                              weight: 500,
                              color: ch.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          "GHS ${_money(list[i].amount)}",
                          style: ptstyle(
                            size: 13,
                            weight: 600,
                            color: ch.onSurface,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: ch.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < list.length - 1)
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: 44,
                    color: Colors.black.withOpacity(0.08),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
