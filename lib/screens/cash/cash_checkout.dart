import 'dart:async';

import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart'
    show colorNamesOf, swatchFor, titleCase;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _ink = Color(0xFF1D1D1F);
const _green = Color(0xFF30A14E);
const _amber = Color(0xFFFF9F0A);
const _red = Color(0xFFE5484D);
const _bg = Color(0xFFF2F4F7);

String _ghs(num v) => "GHS ${v.toDouble().toCommaSeparated(0, decimalPlaces: 2)}";

/// "Buy with cash": pick storage, colour and (when the shop has branches)
/// where to collect, then reserve. Nothing is paid in the app — the
/// customer pays the shop in cash when collecting the phone.
Future<void> showCashCheckout(BuildContext context, ProductModel product) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CashSheet(product: product),
  );
}

class _CashSheet extends StatefulWidget {
  const _CashSheet({required this.product});
  final ProductModel product;

  @override
  State<_CashSheet> createState() => _CashSheetState();
}

class _CashSheetState extends State<_CashSheet> {
  late final List<ProductStorage> _storages =
      (widget.product.productStorages ?? [])
          .where((s) => (double.tryParse(s.cashPrice) ?? 0) > 0)
          .toList();
  late ProductStorage? _storage = _storages.isEmpty ? null : _storages.first;
  late final List<String> _colors = colorNamesOf(widget.product.colors);
  late String? _color = _colors.isEmpty ? null : _colors.first;

  List<Map<String, dynamic>> _locations = [];
  bool _loadingLocations = true;
  Map<String, dynamic>? _location; // null id = main shop
  bool _reserving = false;
  String? _error;

  SharedProvider get _p => Provider.of<SharedProvider>(context, listen: false);
  int? get _vendorId => widget.product.vendor?.id ?? widget.product.vendorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocations());
  }

  Future<void> _loadLocations() async {
    final id = _vendorId;
    if (id == null) {
      setState(() => _loadingLocations = false);
      return;
    }
    setState(() => _loadingLocations = true);
    final list = await _p.fetchVendorLocations(context, id);
    if (!mounted) return;
    setState(() {
      _locations = list;
      _loadingLocations = false;
      // Keep the choice if it still exists, else the main shop.
      final keep =
          _location == null
              ? null
              : list.where((l) => l['id'] == _location!['id']).firstOrNull;
      _location =
          keep ?? list.where((l) => l['is_main'] == true).firstOrNull ?? list.firstOrNull;
    });
  }

  double get _price => double.tryParse(_storage?.cashPrice ?? "") ?? 0;

  Future<void> _reserve() async {
    if (_storage == null || _reserving) return;
    setState(() {
      _reserving = true;
      _error = null;
    });
    final locationId =
        _locations.length > 1 && _location != null ? _location!['id'] : null;
    final body = await _p.createCashReservation(
      context,
      products: [
        {
          "product_id": widget.product.id,
          "product_storage_id": _storage!.id,
          if (_color != null) "color": _color,
          if (locationId != null) "vendor_location_id": locationId,
        },
      ],
      vendorLocationId: null,
    );
    if (!mounted) return;
    setState(() => _reserving = false);
    final orders = body?['orders'];
    if (orders is List && orders.isNotEmpty && orders.first is Map) {
      HapticFeedback.heavyImpact();
      final order = Map<String, dynamic>.from(orders.first as Map);
      final nav = Navigator.of(context);
      nav.pop();
      NavigationHelper.push(
        nav.context,
        CashReservationScreen(
          reference: "${order['cash_checkout_reference'] ?? ''}",
          initialOrder: order,
          location: _locations.length > 1 ? _location : null,
        ),
      );
      _p.getOrders(refresh: true, next: false);
      return;
    }
    final message = "${body?['message'] ?? 'The phone could not be reserved. Please try again.'}";
    setState(() => _error = message);
    if (message.toLowerCase().contains("location")) _loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final pr = widget.product;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: Container(
        decoration: BoxDecoration(
          color: ch.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: ch.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      pr.image,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, _, _) => Opacity(
                            opacity: 0.4,
                            child: Image.asset(AssetsHelper.dummyImage),
                          ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Buy with cash",
                          style: ptstyle(size: 19, weight: 800, color: ch.onSurface)
                              .copyWith(letterSpacing: -0.4),
                        ),
                        Text(
                          titleCase(pr.fullName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ptstyle(size: 12.5, weight: 500, color: ch.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(backgroundColor: ch.onSurface.withOpacity(0.06)),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                children: [
                  // How it works
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "No payment in the app",
                          style: ptstyle(size: 13.5, weight: 800, color: ch.onSurface),
                        ),
                        const SizedBox(height: 8),
                        for (final (i, t) in [
                          (1, "Reserve the phone here, it's held for you."),
                          (2, "Go to the shop and show your QR code."),
                          (3, "Pay the shop in cash and take your phone."),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: _green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "$i",
                                    style: ptstyle(size: 10.5, weight: 800, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t,
                                    style: ptstyle(size: 12.5, weight: 500, color: ch.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label(ch, "Storage"),
                  if (_storages.isEmpty)
                    Text(
                      "No cash price is set for this phone yet.",
                      style: ptstyle(size: 12.5, weight: 500, color: _red),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final s in _storages)
                          _Choice(
                            selected: _storage?.id == s.id,
                            title: s.storage,
                            subtitle: _ghs(double.tryParse(s.cashPrice) ?? 0),
                            onTap: () => setState(() => _storage = s),
                          ),
                      ],
                    ),
                  if (_colors.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _label(ch, "Colour"),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in _colors)
                          _Choice(
                            selected: _color == c,
                            title: titleCase(c),
                            dot: swatchFor(c),
                            onTap: () => setState(() => _color = c),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  _label(ch, _locations.length > 1 ? "Collect from" : "Where you collect"),
                  if (_loadingLocations)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (_locations.isEmpty)
                    _ShopCard(
                      name: pr.vendor?.name ?? "The shop",
                      address: pr.vendor?.location ?? "",
                      phone: pr.vendor?.phoneNumber ?? "",
                      selected: true,
                    )
                  else
                    for (final l in _locations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ShopCard(
                          name: "${l['name'] ?? ''}",
                          address: "${l['address'] ?? ''}",
                          phone: "${l['phone_number'] ?? ''}",
                          main: l['is_main'] == true,
                          selected: _location == l || _locations.length == 1,
                          onTap:
                              _locations.length > 1
                                  ? () => setState(() => _location = l)
                                  : null,
                        ),
                      ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: _red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: ptstyle(size: 12.5, weight: 500, color: _red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Pinned: amount to bring + Reserve
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: ch.surface,
                border: Border(top: BorderSide(color: ch.onSurface.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bring in cash",
                          style: ptstyle(size: 11, weight: 500, color: ch.onSurfaceVariant),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _price > 0 ? _ghs(_price) : "—",
                            style: ptstyle(size: 20, weight: 800, color: ch.onSurface)
                                .copyWith(letterSpacing: -0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        disabledBackgroundColor: ch.onSurface.withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed:
                          _storage == null || _reserving || _loadingLocations ? null : _reserve,
                      icon:
                          _reserving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                              : const Icon(Icons.qr_code_2_rounded, size: 20),
                      label: Text("Reserve", style: ptstyle(size: 15, weight: 700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ColorScheme ch, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: ptstyle(size: 15, weight: 700, color: ch.onSurface)),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.dot,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final Color? dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.fromLTRB(dot == null ? 14 : 8, 10, 14, 10),
        decoration: BoxDecoration(
          color: selected ? _ink.withOpacity(0.04) : ch.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _ink : ch.onSurface.withOpacity(0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  border: Border.all(color: ch.onSurface.withOpacity(0.15)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: ptstyle(size: 14, weight: 700, color: ch.onSurface)),
                if (subtitle != null)
                  Text(subtitle!, style: ptstyle(size: 11, weight: 600, color: _green)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.name,
    required this.address,
    required this.phone,
    this.selected = false,
    this.main = false,
    this.onTap,
  });

  final String name;
  final String address;
  final String phone;
  final bool selected;
  final bool main;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _ink.withOpacity(0.04) : ch.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _ink : ch.onSurface.withOpacity(0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (main ? _green : _amber).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.storefront_rounded, color: main ? _green : _amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                        ),
                      ),
                      if (main) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text("Main", style: ptstyle(size: 9.5, weight: 800, color: _green)),
                        ),
                      ],
                    ],
                  ),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
                    ),
                  if (phone.isNotEmpty)
                    Text(
                      phone,
                      style: ptstyle(size: 12, weight: 500, color: ch.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.check_circle_rounded, color: _ink),
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Reservation: QR, amount, where to go, live status
// ===========================================================================

class CashReservationScreen extends StatefulWidget {
  const CashReservationScreen({
    super.key,
    required this.reference,
    this.initialOrder,
    this.location,
  });

  final String reference;

  /// The order from the reservation response (shown until the first
  /// status call returns).
  final Map<String, dynamic>? initialOrder;
  final Map<String, dynamic>? location;

  @override
  State<CashReservationScreen> createState() => _CashReservationScreenState();
}

class _CashReservationScreenState extends State<CashReservationScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _data;
  Timer? _poll;
  bool _wasPaid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    // Every 20 seconds while this screen is open.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (widget.reference.isEmpty) return;
    final p = Provider.of<SharedProvider>(context, listen: false);
    final body = await p.getCashReservationStatus(context, widget.reference);
    if (!mounted || body == null) return;
    final d = body['data'] is Map ? Map<String, dynamic>.from(body['data']) : null;
    if (d == null) return;
    setState(() => _data = d);
    if (_paid && !_wasPaid) {
      _wasPaid = true;
      _poll?.cancel();
      HapticFeedback.heavyImpact();
      p.getOrders(refresh: true, next: false);
    }
  }

  bool get _paid => _data?['paid'] == true && _data?['handed_over_at'] != null;

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final o = widget.initialOrder ?? const {};
    final d = _data ?? const {};
    final qr = "${d['qr_payload'] ?? o['cash_checkout_qr_payload'] ?? 'flexiphones://cash-order/${widget.reference}'}";
    final amount = num.tryParse("${d['amount_due'] ?? o['total_payment'] ?? 0}") ?? 0;
    final product = "${d['product'] ?? o['product_name'] ?? ''}";
    final vendor = d['vendor'] is Map ? d['vendor'] as Map : const {};
    final loc =
        d['location'] is Map
            ? d['location'] as Map
            : (widget.location ?? const <String, dynamic>{});
    final shopName = "${loc['name'] ?? vendor['name'] ?? o['vendor_name'] ?? 'The shop'}";
    final address = "${loc['address'] ?? ''}";
    final phone = "${loc['phone_number'] ?? vendor['phone'] ?? o['vendor_phone'] ?? ''}";
    final handed = DateTime.tryParse("${d['handed_over_at'] ?? ''}")?.toLocal();
    final paid = _paid;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Cash reservation",
          style: ptstyle(size: 16, weight: 700, color: ch.onSurface),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            // Status
            FadeSlideIn(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: paid ? _green : _amber,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Icon(
                      paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paid ? "Completed" : "Reserved, pay at the shop",
                            style: ptstyle(size: 17, weight: 800, color: Colors.white),
                          ),
                          Text(
                            paid
                                ? "Paid and collected${handed == null ? "" : " on ${DateFormat("d MMM, HH:mm").format(handed)}"}. Enjoy your phone!"
                                : "Show this QR code at the shop, then pay in cash.",
                            style: ptstyle(size: 12.5, weight: 500, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // QR
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: ch.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      product.isEmpty ? "Your phone" : titleCase(product),
                      textAlign: TextAlign.center,
                      style: ptstyle(size: 18, weight: 800, color: ch.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ("${o['storage'] ?? ''}".isNotEmpty) "${o['storage']}",
                        if ("${o['color'] ?? ''}".isNotEmpty) titleCase("${o['color']}"),
                      ].join(" · "),
                      style: ptstyle(size: 12.5, weight: 500, color: ch.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    AnimatedOpacity(
                      opacity: paid ? 0.25 : 1,
                      duration: const Duration(milliseconds: 400),
                      child: QrImageView(
                        data: qr,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: _ink,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "BRING IN CASH",
                      style: ptstyle(size: 10.5, weight: 700, color: ch.onSurfaceVariant)
                          .copyWith(letterSpacing: 1.4),
                    ),
                    Text(
                      _ghs(amount),
                      style: ptstyle(size: 30, weight: 800, color: ch.onSurface)
                          .copyWith(letterSpacing: -1),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.reference));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Reference copied")),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                "Ref ${widget.reference.length > 8 ? widget.reference.substring(0, 8).toUpperCase() : widget.reference}",
                                style: ptstyle(size: 12, weight: 600, color: ch.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.copy_rounded, size: 13, color: ch.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Where to go
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ch.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "COLLECT FROM",
                      style: ptstyle(size: 10.5, weight: 700, color: ch.onSurfaceVariant)
                          .copyWith(letterSpacing: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(shopName, style: ptstyle(size: 17, weight: 800, color: ch.onSurface)),
                    if (address.isNotEmpty)
                      Text(address, style: ptstyle(size: 13, weight: 400, color: ch.onSurfaceVariant)),
                    if (phone.isNotEmpty)
                      Text(phone, style: ptstyle(size: 13, weight: 500, color: ch.onSurfaceVariant)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (phone.isNotEmpty)
                          Expanded(
                            child: _ActionPill(
                              icon: Icons.call_rounded,
                              label: "Call",
                              onTap: () => _launch(Uri(scheme: "tel", path: phone)),
                            ),
                          ),
                        if (phone.isNotEmpty) const SizedBox(width: 10),
                        Expanded(
                          child: _ActionPill(
                            icon: Icons.directions_rounded,
                            label: "Directions",
                            onTap:
                                () => _launch(
                                  Uri.parse(
                                    "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("$shopName $address")}",
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ch.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: ch.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Only pay the shop in person, after you've checked the phone. FlexiPhones never asks for cash payments in the app. A cash phone is yours outright, with no daily payments and no locking.",
                      style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: ptstyle(size: 13.5, weight: 700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
