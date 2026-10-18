import 'dart:async';
import 'dart:ui';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/shared_widgets/receipt_card.dart';
import 'package:flexiphones/shared_widgets/order_status_chips.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart' show titleCase;
import 'package:flexiphones/screens/reports/reports.dart';
import 'package:flexiphones/extensions/ui_values.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/helpers/snackbar_helper.dart';
import 'package:flexiphones/helpers/st_values.dart';
import 'package:flexiphones/models/order_m.dart';
import 'package:flexiphones/models/repayment_info_m.dart';
import 'package:flexiphones/screens/cash/cash_checkout.dart' show CashReservationScreen;
import 'package:flexiphones/screens/orders/sub_pages/pay_now.dart';
import 'package:flexiphones/screens/orders/sub_pages/plan_completed.dart';
import 'package:flexiphones/shared_widgets/payment_squares.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/bonus_c.dart';
import 'package:flexiphones/screens/orders/components/call_details.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/screens/orders/sub_pages/order_rating.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/confirmation_dialogue.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsWidget extends StatefulWidget {
  const OrderDetailsWidget({super.key});

  @override
  State<OrderDetailsWidget> createState() => _OrderDetailsWidgetState();
}

class _OrderDetailsWidgetState extends State<OrderDetailsWidget>
    with WidgetsBindingObserver {
  // The down payment completes asynchronously (~30-60s after the customer
  // approves on their phone), so while the order is awaiting it we poll
  // get-order-by-id every 5s, for at most 4 minutes.
  static const _pollEvery = Duration(seconds: 5);
  static const _pollFor = Duration(minutes: 4);

  late final SharedProvider _provider;
  Timer? _pollTimer;
  DateTime? _pollStartedAt;
  bool _pollGaveUp = false;
  bool _polling = false;
  int? _awaitingOrderId;

  // repayment-info for paid orders: drives the overdue banner and whether
  // the Pay now button shows.
  RepaymentInfo? _repayInfo;
  int? _repayInfoFor;

  Future<void> _loadRepayInfo(int orderId) async {
    _repayInfoFor = orderId;
    final result = await _provider.getRepaymentInfo(orderId);
    if (!mounted || _provider.orderData?.id != orderId) return;
    setState(() => _repayInfo = result.info);
  }

  /// [days]: squares picked on the payment calendar; their total is
  /// pre-filled (days x daily payment).
  Future<void> _openPayNow(int orderId, {List<DateTime> days = const []}) async {
    final daily = _repayInfo?.dailyPayment;
    await NavigationHelper.push(
      context,
      PayNowScreen(
        orderId: orderId,
        selectedDays: days,
        initialAmount:
            days.isEmpty || daily == null || daily <= 0
                ? null
                : daily * days.length,
      ),
    );
    if (mounted) _loadRepayInfo(orderId);
  }

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<SharedProvider>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    _provider.addListener(_watchPayment);
    _pollTimer = Timer.periodic(_pollEvery, (_) => _pollTick());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _provider.removeListener(_watchPayment);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final id = _provider.orderData?.id;
    if (id == null || _provider.loadingOrder) return;
    await _provider.getOrder(id, silent: true);
  }

  Future<void> _pollTick() async {
    final order = _provider.orderData;
    if (_polling || _pollGaveUp || _provider.loadingOrder) return;
    if (order == null || !order.awaitingDownPayment) return;

    _pollStartedAt ??= DateTime.now();
    if (DateTime.now().difference(_pollStartedAt!) > _pollFor) {
      _pollGaveUp = true;
      if (!mounted) return;
      SnackbarHelper.info(
        context: context,
        title: "Still Waiting",
        message: "We will notify you when your down payment is done",
        ch: Theme.of(context).colorScheme,
      );
      return;
    }

    _polling = true;
    await _refresh();
    _polling = false;
  }

  /// Fires on every provider change, so a payment confirmed by polling,
  /// pull-to-refresh, app resume or the "Down payment received"
  /// notification all show the same success message.
  int? _readyChecked;

  void _watchPayment() {
    final order = _provider.orderData;
    if (order == null) return;
    if (!order.isCash && order.isPaid && order.stage != "cancelled" && _repayInfoFor != order.id) {
      _loadRepayInfo(order.id);
    }
    // "Your phone is ready", once per order.
    if (order.phoneState?.key == "ready" && _readyChecked != order.id) {
      _readyChecked = order.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) maybeShowPhoneReady(context, order);
      });
    }
    if (order.awaitingDownPayment) {
      _awaitingOrderId = order.id;
      return;
    }
    if (_awaitingOrderId == order.id && order.isPaid) {
      _awaitingOrderId = null;
      _pollStartedAt = null;
      if (!mounted) return;
      SnackbarHelper.success(
        context: context,
        title: "Down Payment Received",
        message: "Your order is confirmed",
      );
      // Show the down payment receipt (the newest one).
      final id = order.id;
      _provider.getOrderReceipts(id).then((list) {
        if (!mounted || list.isEmpty) return;
        showReceiptSheet(context, list.first);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);

    if (!sharedProvider.loadingOrder && sharedProvider.orderData == null) {
      return _OrderNotFound(ch: ch);
    }

    final stageColor =
        sharedProvider.orderData == null
            ? ch.onSurfaceVariant
            : STV.getOrderStageColor(sharedProvider.orderData!.stage, ch);

    related() =>
        sharedProvider.orders
            .where(
              (x) =>
                  x.applicationUuid ==
                      sharedProvider.orderData!.applicationUuid &&
                  x.id != sharedProvider.orderData!.id &&
                  x.stage == "placed",
            )
            .toList()
            .map((x) => x.product.fullName)
            .toList();
    var deliveryOption =
        sharedProvider.loadingOrder
            ? ""
            : (sharedProvider.orderData?.deliveryOption ?? "pickup")
                .toUpperCase();

    final status = sharedProvider.orderData?.stage ?? '';
    final address = sharedProvider.orderData?.deliveryAddress ?? '...';
    final vendor = sharedProvider.orderData?.vendor.name;
    final pickup = deliveryOption.toLowerCase() == 'pickup';

    final message =
        pickup
            ? "${status == 'delivered' ? "You've received" : "Pickup"} your device at $vendor"
            : "Your device ${status == 'delivered' ? "has been delivered" : "will be delivered"} to you at $address by $vendor";

    return Scaffold(
      backgroundColor: ch.surface,
      appBar: AppBar(
        flexibleSpace:
            sharedProvider.loadingOrder
                ? null
                : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        stageColor.withOpacity(0.5),
                        stageColor.withOpacity(0.2),
                        stageColor.withOpacity(0.01),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
        excludeHeaderSemantics: true,
        backgroundColor: ch.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Order Details",
          style: ptstyle(size: 14, weight: 400, color: ch.onSurfaceVariant),
        ),
        centerTitle: true,

        actions:
            sharedProvider.loadingOrder
                ? []
                : [
                  Container(
                    constraints: BoxConstraints(maxWidth: 190),
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: stageColor,
                    ),
                    child: Text(
                      "• ${sharedProvider.orderData!.statusLabel} ",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ptstyle(
                        size: 12,
                        weight: 600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
      ),
      body:
          sharedProvider.loadingOrder
              ? PDShimmer(ch: ch)
              : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 10),
                  _buildProductCard(
                    context,
                    ch,
                    sharedProvider.orderData!,
                    sharedProvider,
                  ),
                  const SizedBox(height: 12),
                  // The phone's own status and where the payments stand.
                  OrderStatusChips(order: sharedProvider.orderData!),
                  const SizedBox(height: 12),
                  if (sharedProvider.orderDataPackages != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: BonusAdWidget(isFromDetails: false),
                    ),
                    SDivider(),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Delivery Option:",
                              style: ptstyle(
                                size: 10,
                                color: ch.onSurfaceVariant,
                                weight: 400,
                              ),
                            ),
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: stageColor.withOpacity(0.08),
                                ),
                                child: Text(
                                  deliveryOption,
                                  textAlign: TextAlign.end,
                                  style: ptstyle(
                                    size: 10,
                                    weight: 600,
                                    color: stageColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: stageColor.withOpacity(0.05),
                          ),
                          child: Text(
                            status == "cancelled"
                                ? '"You will not be receiving this device..."'
                                : message,
                            softWrap: true,

                            style: ptstyle(
                              size: 10,
                              weight: 500,
                              color:
                                  status == "cancelled"
                                      ? Colors.red
                                      : ch.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SDivider(),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 5),
                  //   child: StorageCard(
                  //     staticObj: true,
                  //     tn: int.parse(
                  //       sharedProvider.orderData?.serviceTenure ?? "0",
                  //     ),
                  //     enabled: false,
                  //     select: () {},
                  //     cl: "",
                  //     data: sharedProvider.orderData!.productStorage,
                  //   ),
                  // ),
                  // Cash: no plan, no repayments, no locking — just the
                  // reservation to show at the shop.
                  if (sharedProvider.orderData!.isCash)
                    _buildCashCard(ch, sharedProvider.orderData!)
                  else if (sharedProvider.orderData!.isPaid &&
                      status != "cancelled")
                    _buildPaySection(ch, sharedProvider.orderData!)
                  else if (status != "cancelled")
                    _buildDownPaymentHint(ch, sharedProvider.orderData!),
                  // Report a problem (more visible when the phone is locked
                  // or still being set up).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                    child: Builder(
                      builder: (_) {
                        final o = sharedProvider.orderData!;
                        final key = o.phoneState?.key ?? "";
                        final strong = key == "locked" || key == "preparing";
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  strong
                                      ? const Color(0xFFE5484D).withOpacity(0.08)
                                      : null,
                              foregroundColor:
                                  strong
                                      ? const Color(0xFFE5484D)
                                      : ch.onSurfaceVariant,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                () => showReportSheet(
                                  context,
                                  target: "order",
                                  orderId: o.id,
                                  subject: titleCase(o.product.fullName),
                                ),
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: Text(
                              "Report a problem",
                              style: ptstyle(size: 12.5, weight: 600),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SDivider(),
                  if (status == "delivered")
                    Container(
                      color: Colors.green.withOpacity(0.1),
                      width: double.infinity,
                      height: 55,
                      child: Stack(
                        children: [
                          Bgw3(),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 50.w.toDouble(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Love it? Rate us!",
                                        textAlign: TextAlign.left,
                                        style: ptstyle(
                                          size: 14,
                                          weight: 600,
                                          color: ch.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.green.withOpacity(0.1),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                  ),
                                              child: Text(
                                                "5.0 ",
                                                textAlign: TextAlign.left,
                                                style: ptstyle(
                                                  size: 10,
                                                  weight: 600,
                                                  color: ch.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            for (int i = 0; i < 5; i++)
                                              Icon(
                                                Icons.star,
                                                color:
                                                    i == 4
                                                        ? Colors
                                                            .deepOrangeAccent
                                                            .withOpacity(0.5)
                                                        : Colors
                                                            .deepOrangeAccent,
                                                size: 15,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                FilledButton.icon(
                                  onPressed: () {
                                    sharedProvider.getProductDetails(
                                      sharedProvider.orderData!.product.id,
                                      context,
                                    );

                                    NavigationHelper.push(
                                      context,
                                      OrderRating(),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      68,
                                      175,
                                      100,
                                    ),
                                  ),
                                  icon: Icon(Icons.reviews_rounded, size: 12),
                                  label: Text(
                                    "Leave A Review",
                                    style: ptstyle(size: 10, weight: 600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 10),
                  _buildOrderInfoSection(
                    ch,
                    context,
                    sharedProvider.orderData!,
                    sharedProvider,
                  ),
                  SDivider(),
                  _buildStatusSection(context),
                  if (status == "placed")
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Opacity(
                        opacity: sharedProvider.orderLoading ? 0.3 : 1,
                        child: AbsorbPointer(
                          absorbing: sharedProvider.orderLoading,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Opacity(
                                opacity: related().isEmpty ? 0.3 : 1,
                                child: AbsorbPointer(
                                  absorbing: related().isEmpty,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),

                                      backgroundColor:
                                          AdaptiveTheme.of(context).mode.isDark
                                              ? ch.primaryFixed
                                              : const Color.fromARGB(
                                                255,
                                                255,
                                                249,
                                                249,
                                              ),
                                    ),
                                    onPressed: () async {
                                      showConfirmationDialog(
                                        context: context,
                                        title: "Are you sure?",
                                        content:
                                            "Your order(s) including ${related().toString().replaceAll("[", "").replaceAll("]", "")}... will be cancelled as well.",
                                        confirmText: "Yes, Cancel All",
                                        cancelText: "No",
                                        confirm:
                                            () => sharedProvider.removeOrder(
                                              sharedProvider
                                                  .orderData!
                                                  .applicationUuid!,
                                              context,
                                              allOrder: true,
                                            ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.remove_shopping_cart_outlined,
                                      color: Colors.red,
                                    ),
                                    label: Text(
                                      "Cancel Group Order",
                                      style: ptstyle(
                                        size: 10,
                                        weight: 400,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color:
                                          AdaptiveTheme.of(context).mode.isDark
                                              ? ch.primaryFixed
                                              : const Color.fromARGB(
                                                255,
                                                255,
                                                213,
                                                210,
                                              ),
                                      width: 1,
                                    ),
                                  ),

                                  // surfaceTintColor: Colors.redAccent,
                                  // overlayColor: Colors.redAccent,
                                  backgroundColor:
                                      AdaptiveTheme.of(context).mode.isDark
                                          ? ch.primaryFixed
                                          : const Color.fromARGB(
                                            255,
                                            255,
                                            242,
                                            241,
                                          ),
                                ),
                                onPressed: () async {
                                  showConfirmationDialog(
                                    context: context,
                                    title: "Are you sure?",
                                    content:
                                        "Your ${sharedProvider.orderData!.product.model} order will be cancelled.",
                                    confirmText: "Yes, Cancel",
                                    cancelText: "No",
                                    confirm:
                                        () => sharedProvider.removeOrder(
                                          sharedProvider.orderData!.id,
                                          context,
                                        ),
                                  );
                                },
                                icon: Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red,
                                ),
                                label: Text(
                                  "Cancel Order",
                                  style: ptstyle(
                                    size: 10,
                                    weight: 500,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                ],
                ),
              ),
    );
  }

  Widget _buildCashCard(ColorScheme ch, Order order) {
    final collected = order.isPaid;
    final ref = order.cashReference ?? "";
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D1F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  collected ? Icons.check_circle_rounded : Icons.payments_rounded,
                  color: collected ? const Color(0xFF34C759) : const Color(0xFFFFB340),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    collected
                        ? "Paid in cash and collected"
                        : "Cash purchase: pay GHS ${order.totalPayment} at the shop",
                    style: ptstyle(size: 14, weight: 700, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              collected
                  ? "This phone is yours outright: no daily payments, no locking."
                  : "Show your QR code at the shop, pay in cash and take your phone. Nothing is paid in the app.",
              style: ptstyle(size: 12, weight: 400, color: Colors.white70),
            ),
            if (ref.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1D1D1F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed:
                      () => NavigationHelper.push(
                        context,
                        CashReservationScreen(reference: ref),
                      ),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text(
                    collected ? "View receipt QR" : "Show reservation QR",
                    style: ptstyle(size: 14, weight: 700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Unpaid down payment: the vendor can't set the phone up yet.
  Widget _buildDownPaymentHint(ColorScheme ch, Order order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          border: Border.all(color: Colors.orange.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Pay your down payment of GHS ${order.initialPayment} to get your phone set up. It is the first part of the phone's price, not an extra fee: it comes off the total, and the rest is paid as GHS ${order.dailyPayment} a day.",
                style: ptstyle(size: 12, weight: 500, color: ch.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaySection(ColorScheme ch, Order order) {
    final orderId = order.id;
    final info = _repayInfo;
    final overdue = info?.isOverdue == true;
    final allowed = info?.repaymentAllowed ?? true;
    final locked = order.isDeviceLocked;
    final completed =
        order.isFullyPaid || (info != null && info.balance <= 0 && !allowed);

    if (completed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap:
                  () => NavigationHelper.push(
                    context,
                    PlanCompletedScreen(productName: order.product.fullName),
                  ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  border: Border.all(color: Colors.green.withOpacity(0.35)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        info?.reason ??
                            "This order is fully paid. The phone is yours for good. Thank you!",
                        style: ptstyle(
                          size: 12,
                          weight: 600,
                          color: ch.onSurface,
                        ),
                      ),
                    ),
                    const Icon(Icons.celebration_rounded, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            PaymentSquares(orderId: orderId),
            OrderReceipts(key: ValueKey("r$orderId"), orderId: orderId),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (locked) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.45)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      info != null && info.catchUpAmount > 0
                          ? "Locked: pay GHS ${info.catchUpAmount.toStringAsFixed(2)} to unlock your phone."
                          : "Your phone is locked for a missed payment. Pay now to unlock it.",
                      style: ptstyle(
                        size: 12,
                        weight: 600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else if (overdue) ...[
            OverdueBanner(
              daysOverdue: info!.daysOverdue,
              catchUpAmount: info.catchUpAmount,
            ),
            const SizedBox(height: 8),
          ],
          if (!allowed)
            Text(
              info?.reason ?? "",
              textAlign: TextAlign.center,
              style: ptstyle(size: 11, weight: 500, color: ch.onSurfaceVariant),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: overdue || locked ? Colors.red : ch.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _openPayNow(orderId),
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: Text(
                info == null
                    ? "Pay Now"
                    : "Pay Now · Balance GHS ${info.balance.toStringAsFixed(2)}",
                style: ptstyle(size: 12, weight: 600),
              ),
            ),
          const SizedBox(height: 12),
          PaymentSquares(
            orderId: orderId,
            dailyPayment:
                info?.dailyPayment ?? num.tryParse(order.dailyPayment),
            onPayDays: allowed ? (days) => _openPayNow(orderId, days: days) : null,
          ),
          OrderReceipts(key: ValueKey("r$orderId"), orderId: orderId),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ColorScheme ch,
    Order data,
    sharedProvider,
  ) {
    return InkWell(
      onTap: () {
        sharedProvider.getProductDetails(data.productId, context);

        NavigationHelper.push(
          context,
          ProductDetailsPage(productId: data.productId),
        );
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(
                  height: 65, // 25% height
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        data.product.image,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Image.asset(
                              "assets/dummy.png",
                              fit: BoxFit.cover,
                            ),
                      ),
                      // Blur layer
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ch.surface, // dark overlay
                              ch.surface, // dark overlay
                              ch.surface.withOpacity(0.2), // fade out
                              ch.surface,
                              ch.surface,
                            ],
                          ),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    data.product.image,
                    width: 80,
                    height: 70,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => Opacity(
                          opacity: 0.3,
                          child: Image.asset(
                            AssetsHelper.dummyImage,
                            fit: BoxFit.contain,
                            width: 80,
                            height: 70,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.product.fullName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: ptstyle(size: 14, weight: 600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            data.serviceTenure ?? "~",
                            softWrap: true,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ptstyle(
                              size: 10,
                              weight: 600,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '  |  Months Service tenure',
                            softWrap: true,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ptstyle(
                              size: 10,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: ch.surfaceContainerLowest.withOpacity(0.8),
                          border: Border.all(
                            color: ch.onSurfaceVariant.withOpacity(0.2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data.color,
                          style: ptstyle(
                            size: 10,
                            weight: 400,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoSection(
    ColorScheme ch,
    BuildContext context,
    Order data,
    SharedProvider sharedProvider,
  ) {
    final vendorDetails = [
      {"name": data.vendor.name, "contact": data.vendor.phoneNumber},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: ch.surfaceVariant.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order Status:",
                    style: ptstyle(
                      size: 10,
                      color: ch.onSurfaceVariant,
                      weight: 400,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: STV
                            .getOrderStageColor(data.stage, ch)
                            .withOpacity(0.1),
                      ),
                      child: Text(
                        data.statusLabel,
                        textAlign: TextAlign.end,
                        style: ptstyle(
                          size: 10,
                          weight: 600,
                          color: STV.getOrderStageColor(data.stage, ch),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              // Cash orders have no plan, device lock or IMEI step.
              if (data.isCash) ...[
                _infoRow("Bought with", "Cash, paid at the shop", ch),
                _infoRow("Price", "GHS ${data.totalPayment}", ch),
                _infoRow(
                  "Status",
                  data.isPaid ? "Paid & collected" : "Reserved, pay at the shop",
                  ch,
                ),
                SDivider(),
              ] else ...[
              if (data.paymentStatus != null)
                _infoRow(
                  "Down Payment",
                  data.isPaid ? "Paid" : "Not paid yet",
                  ch,
                ),
              _infoRow("Device Type", data.deviceType, ch),

              SDivider(),
              _infoRow("IMEI", data.imei ?? "~", ch),
              _infoRow("IMEI 2", data.imei2 ?? "~", ch),
              _infoRow("Serial Number", data.serialNumber ?? "~", ch),
              SDivider(),
              _infoRow(
                "Service Tenure (Months)",
                data.serviceTenure ?? "-",
                ch,
              ),
              _infoRow("Reload Days", data.reloadDays?.toString() ?? "-", ch),
              SDivider(),
              _infoRow("Payment Duration", data.paymentDuration, ch),
              _infoRow("Initial Payment", "GHS ${data.initialPayment}", ch),

              _infoRow("Daily Payment", "GHS ${data.dailyPayment}", ch),
              SDivider(),
              // _infoRow("License Fee", "GHS ${data.licenseFee}", ch),
              // _infoRow("Commission", "GHS ${data.commission}", ch),
              // SDivider(),
              _infoRow("Total Payment", "GHS ${data.totalPayment}", ch),
              _infoRow("Total Paid", "GHS ${data.totalPaid}", ch),
              SDivider(),
              _infoRow("Next Due", data.nextDue ?? "-", ch),
              ],
              _infoRow(
                "Ordered On",
                DateTime.parse(data.createdAt).formatDateNoTime(),
                ch,
              ),
              _infoRow(
                "Updated On",
                DateTime.parse(data.updatedAt).formatDate(),
                ch,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        SDivider(),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ch.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Image.network(
                data.vendor.image ?? "",
                fit: BoxFit.cover,
                width: 60,
                height: 60,

                errorBuilder:
                    (context, error, stackTrace) => Opacity(
                      opacity: 0.5,
                      child: Image.asset(
                        AssetsHelper.dummy2Image,
                        fit: BoxFit.cover,
                        width: 60,
                        alignment: Alignment.centerLeft,
                        height: 60,
                      ),
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vendor",
                      style: ptstyle(
                        size: 10,
                        color: ch.onSurfaceVariant,
                        weight: 400,
                      ),
                    ),

                    Text(
                      data.vendor.name,
                      style: ptstyle(size: 14, weight: 600),
                    ),
                    const SizedBox(height: 4),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_city_rounded,
                          color: ch.onSurfaceVariant.withOpacity(0.5),
                          size: 18,
                        ),
                        SizedBox(width: 3),
                        Text(
                          data.vendor.location,
                          style: ptstyle(
                            size: 10,
                            weight: 400,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.chat_outlined, size: 18),
                onPressed: () async {
                  final Uri whatssAppContact = Uri.parse(
                    "https://wa.me/233${data.vendor.phoneNumber}",
                  );

                  if (await canLaunchUrl(whatssAppContact)) {
                    await launchUrl(whatssAppContact);
                  } else {
                    throw 'Could not launch $whatssAppContact';
                  }
                },
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                icon: const Icon(Icons.phone_outlined, size: 18),
                onPressed: () {
                  showVendorBottomSheet(context, vendorDetails);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return SizedBox();
    //   final List<dynamic> timeline = order['statusTimeline'];
    //   var ch = Theme.of(context).colorScheme;

    //   // Determine active step index
    //   int activeStep = 0;
    //   for (var i = 0; i < timeline.length; i++) {
    //     if (!timeline[i]['completed']) {
    //       activeStep = i;
    //       break;
    //     }
    //   }

    //   // Convert timeline to StepperData
    //   final List<StepperData> stepperData =
    //       timeline.map<StepperData>((step) {
    //         return StepperData(
    //           title: StepperText(
    //             step['title'],
    //             textStyle: ptstyle(
    //               size: 15,
    //               weight: 600,
    //               height: 1,
    //               color: ch.onSurfaceVariant,
    //             ),
    //           ),
    //           subtitle: StepperText(
    //             step['subtitle'], // Replace with dynamic timestamp
    //             textStyle: ptstyle(
    //               size: 12,
    //               weight: 400,
    //               color: ch.onSurfaceVariant,
    //               height: 1,
    //             ),
    //           ),
    //           iconWidget: Container(
    //             height: 30,
    //             decoration: BoxDecoration(
    //               borderRadius: BorderRadius.circular(80),
    //               color:
    //                   step['completed']
    //                       ? Colors.green
    //                       : ch.onSurfaceVariant.withOpacity(0.3),
    //             ),
    //             child: Icon(Icons.check_rounded, color: Colors.white, size: 15),
    //           ),
    //         );
    //       }).toList();

    //   return Container(
    //     padding: const EdgeInsets.symmetric(horizontal: 10.0),
    //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(
    //           "Order Status",
    //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    //         ),

    //         AnotherStepper(
    //           stepperList: stepperData,
    //           activeIndex: activeStep,

    //           iconWidth: 25,
    //           iconHeight: 25,
    //           barThickness: 5,
    //           verticalGap: 20,
    //           activeBarColor: Colors.green,
    //           inActiveBarColor:
    //               timeline.where((x) => x["completed"] == false).isEmpty
    //                   ? Colors.green
    //                   : ch.onSurfaceVariant.withOpacity(0.3),
    //           stepperDirection: Axis.vertical,
    //         ),
    //       ],
    //     ),
    //   );
  }

  Widget _infoRow(String label, String value, ColorScheme ch) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: ptstyle(size: 10, color: ch.onSurfaceVariant, weight: 400),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: ptstyle(size: 10, weight: 600, color: ch.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when get-order-by-id returns 404 (e.g. another customer's order)
/// or the order otherwise can't be loaded, instead of a blank screen.
class _OrderNotFound extends StatelessWidget {
  const _OrderNotFound({required this.ch});

  final ColorScheme ch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ch.surface,
      appBar: AppBar(
        backgroundColor: ch.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Order Details",
          style: ptstyle(size: 14, weight: 400, color: ch.onSurfaceVariant),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 40,
                color: ch.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                "Order not found",
                style: ptstyle(size: 15, weight: 600, color: ch.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                "This order doesn't exist or isn't linked to your account.",
                textAlign: TextAlign.center,
                style: ptstyle(
                  size: 12,
                  weight: 400,
                  color: ch.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => NavigationHelper.pop(context),
                child: Text("Go Back", style: ptstyle(size: 12, weight: 600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PDShimmer extends StatelessWidget {
  const PDShimmer({super.key, required this.ch});

  final ColorScheme ch;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: Duration(milliseconds: 500),
      baseColor: ch.primaryFixed.withOpacity(0.1),
      highlightColor: ch.primaryFixed.withOpacity(0.3),
      // Taller than most screens; scroll-wrapped so it clips instead of
      // throwing an overflow error.
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Image Placeholder
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 10),

            // Title + Price
            Container(height: 100, width: double.infinity, color: Colors.white),
            const SizedBox(height: 10),

            // Specifications (3-4 lines)
            Column(
              children: List.generate(
                10,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Pricing options
            Column(
              children: List.generate(
                8,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
