import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/purchase_sheet.dart';
import 'package:flexiphones/screens/cash/cash_checkout.dart';
import 'package:flexiphones/shared_widgets/missed_payment_guard.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flexiphones/screens/order_confirmation/confirm_order.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/screens/store/store.dart';
import 'package:flexiphones/models/review_m.dart';
import 'package:flexiphones/screens/reviews/reviews.dart';
import 'package:flexiphones/screens/reports/reports.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/image_preview.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart';
import 'package:flexiphones/shared_widgets/shop_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Spacing / radius tokens shared by this page.
class _T {
  static const double s4 = 4;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double rCard = 28;
  static const double rTile = 18;
  static const double rPill = 100;
}

const _blue = Color(0xFF0071E3);

/// Splits a product's colours (already normalised from `color_list` by
/// ApiUrls.productColorsText into "{A,B}") into a list. Values keep their
/// exact spelling, because one of them is sent as the order's `color`.
List<String> parseProductColors(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  } catch (_) {}
  return colorNamesOf(raw);
}

/// Cheapest cash price across a phone's storage options, else the product
/// price; null when neither is known.
double? _lowestPrice(List<ProductStorage> storages, double productPrice) {
  final prices =
      storages
          .map((s) => double.tryParse(s.cashPrice) ?? 0)
          .where((p) => p > 0)
          .toList();
  if (prices.isNotEmpty) return prices.reduce((a, b) => a < b ? a : b);
  return productPrice > 0 ? productPrice : null;
}

/// The product page: a tall photo stage with a thumbnail strip, then a
/// white sheet that slides up over it with the name, price, colours,
/// storage, the seller, reviews and similar phones. Price and the two
/// buttons stay pinned at the bottom; both open the configure sheet.
class ProductDetailsPage extends StatefulWidget {
  ProductDetailsPage({
    super.key,
    required this.productId,
    this.fromStor = false,
  });
  final dynamic productId;
  bool fromStor;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int cp = 0;
  final pageController = PageController();
  final _scroll = ScrollController();
  double _offset = 0;
  bool showAll = false;

  /// The storage picked on the page (null = the cheapest).
  ProductStorage? _sel;
  SharedProvider? shd;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() => _offset = _scroll.offset));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<SharedProvider>(context, listen: false);
      p.getProductDetails(widget.productId, context);
      // "You may also like" draws from the product list.
      if (p.products.isEmpty)
        p.getProducts(context, refresh: true, next: false);
    });
  }

  @override
  void dispose() {
    shd?.productsVariations = false;
    _scroll.dispose();
    pageController.dispose();
    super.dispose();
  }

  /// Opens another phone from "You may also like". The shared productData
  /// is replaced by that page, so reload this one when coming back.
  Future<void> _openOtherProduct(int id) async {
    final p = Provider.of<SharedProvider>(context, listen: false);
    p.getProductDetails(id, context);
    await NavigationHelper.push(context, ProductDetailsPage(productId: id));
    if (!mounted) return;
    setState(() {
      cp = 0;
      showAll = false;
      _sel = null;
    });
    if (pageController.hasClients) pageController.jumpToPage(0);
    p.getProductDetails(widget.productId, context);
  }

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _goToCheckout(ProductModel product, ProductStorage ps) {
    final p = Provider.of<SharedProvider>(context, listen: false);
    final item = {
      'id': product.id,
      "vendor": product.vendor?.name,
      "productName":
          "${product.brand.toLowerCase()} ${product.model.toLowerCase()}",
      "image": product.image,
      "product_storages": ps.toJson(),
      "quantity": 1,
      "device_type": "smartphone",
      "service_tenure": p.slTenure,
      "color": p.colorSL,
      "isSelected": true,
      "package_id": null,
      "breakdowns": p.breakDownPrice?.breakdowns.toJson(),
    };
    NavigationHelper.push(context, OrderConfirmation(items: [item]));
  }

  void _openSheet({required bool buyNow, ProductStorage? storage}) {
    showPurchaseSheet(
      context,
      buyNow: buyNow,
      initialStorage: storage,
      onBuyNow: _goToCheckout,
    ).then((_) => shd?.togglePV());
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    shd = p;

    final matches =
        p.productData != null &&
        "${p.productData!.id}" == "${widget.productId}";
    if (p.loadingProduct || !matches) {
      if (p.productDetailsError != null && !p.loadingProduct) {
        return _ErrorScreen(
          ch: ch,
          message: p.productDetailsError!,
          onRetry: () => p.getProductDetails(widget.productId, context),
        );
      }
      return const _DetailSkeleton();
    }

    final product = p.productData!;
    final images =
        (product.images ?? [])
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
    if (images.isEmpty && product.image.isNotEmpty) images.add(product.image);
    final storages = product.productStorages ?? [];
    final reviews = product.reviews ?? [];
    final avg =
        reviews.isEmpty
            ? 0.0
            : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;
    final colors = parseProductColors(product.colors);
    final fromPrice = _lowestPrice(storages, product.price);
    double? priceOf(ProductStorage s) {
      final v = double.tryParse(s.cashPrice) ?? 0;
      return v > 0 ? v : null;
    }

    final sel =
        _sel != null && storages.any((s) => identical(s, _sel))
            ? _sel
            : (storages.isEmpty
                ? null
                : storages.reduce(
                  (a, b) =>
                      (priceOf(a) ?? double.infinity) <=
                              (priceOf(b) ?? double.infinity)
                          ? a
                          : b,
                ));
    final selPrice = sel == null ? fromPrice : (priceOf(sel) ?? fromPrice);
    final spec = (product.deviceSpecification ?? "").trim();
    final inBag = p.cartItems.any((x) => x["id"] == product.id);
    final signedIn = p.userData != null;
    final barSolid = _offset > 300;
    final stageH = MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      extendBodyBehindAppBar: true,
      // Own top bar (not AppBar actions) so the buttons keep a fixed size
      // and the bag's count badge is never cut off.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: barSolid ? ch.surface : Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => NavigationHelper.pop(context),
                    ),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: barSolid ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          titleCase(
                            product.model.isEmpty
                                ? product.fullName
                                : product.model,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ptstyle(
                            size: 16,
                            weight: 700,
                            color: ch.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (signedIn) ...[
                      _FavRound(
                        active: p.isFavorite(product.id),
                        onTap: () => p.toggleFavorite(context, product),
                      ),
                      const SizedBox(width: 10),
                    ],
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _RoundIconButton(
                            icon: Icons.shopping_bag_outlined,
                            onTap:
                                () => NavigationHelper.push(
                                  context,
                                  HomePage(initScreen: 2),
                                ),
                          ),
                          if (p.cartItems.isNotEmpty)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(p.cartItems.length),
                                tween: Tween(begin: 0.4, end: 1),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.elasticOut,
                                builder:
                                    (_, s, c) =>
                                        Transform.scale(scale: s, child: c),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 19,
                                  ),
                                  height: 19,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _blue,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    "${p.cartItems.length}",
                                    style: ptstyle(
                                      size: 9.5,
                                      weight: 800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // Sale modes are re-read every time this page loads (never cached).
      bottomNavigationBar: _BuyBar(
        fromPrice: selPrice,
        inBag: inBag,
        signedIn: signedIn,
        cash: product.supportsCash,
        installment: product.supportsInstallment,
        onBag: () => _openSheet(buyNow: false, storage: sel),
        onBuy:
            signedIn
                ? () async {
                  // Behind on a plan? No new phones until they catch up.
                  if (!await ensureNoMissedPayments(context)) return;
                  if (mounted) _openSheet(buyNow: true, storage: sel);
                }
                : () => NavigationHelper.push(context, EmailSignin()),
        onCash:
            signedIn
                // Cash is never blocked by an overdue plan.
                ? () => showCashCheckout(context, product)
                : () => NavigationHelper.push(context, EmailSignin()),
      ),
      body: ListView(
        controller: _scroll,
        padding: EdgeInsets.zero,
        children: [
          // ---------------- Photo stage ----------------
          SizedBox(
            height: stageH,
            child: Stack(
              children: [
                // Soft spotlight
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.1),
                        radius: 0.9,
                        colors: [Colors.white, Color(0xFFF2F4F7)],
                      ),
                    ),
                  ),
                ),
                // The photo fills the stage edge to edge.
                Positioned.fill(
                  bottom: 20,
                  child: Transform.translate(
                    // Gentle parallax as the sheet slides over.
                    offset: Offset(0, _offset * 0.35),
                    child:
                        images.isEmpty
                            ? Opacity(
                              opacity: 0.3,
                              child: Image.asset(AssetsHelper.dummyImage),
                            )
                            : PageView.builder(
                              controller: pageController,
                              itemCount: images.length,
                              onPageChanged: (v) => setState(() => cp = v),
                              itemBuilder:
                                  (_, i) => GestureDetector(
                                    onTap:
                                        () => showImagePreview(
                                          context,
                                          images[i],
                                          title: product.fullName,
                                        ),
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Image.network(
                                        images[i],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder:
                                            (_, _, _) => Opacity(
                                              opacity: 0.3,
                                              child: Image.asset(
                                                AssetsHelper.dummyImage,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                            ),
                  ),
                ),
                // Several photos: swipe, with dots and a "1 / 3" pill.
                if (images.length > 1) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < images.length; i++)
                          GestureDetector(
                            onTap:
                                () => pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: cp == i ? 18 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color:
                                    cp == i
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 36,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "${cp + 1} / ${images.length}",
                        style: ptstyle(
                          size: 11,
                          weight: 600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ---------------- Content sheet ----------------
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(0, _T.s24, 0, _T.s32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Header: tags, name, live price ----
                  FadeSlideIn(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _T.s20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Tag(
                                product.brand.toUpperCase(),
                                color: _blue,
                              ),
                              if (product.createdAt != null &&
                                  DateTime.now()
                                          .difference(product.createdAt!)
                                          .inDays <=
                                      30) ...[
                                const SizedBox(width: 6),
                                const _Tag("NEW", color: Color(0xFFFF6B00)),
                              ],
                              const Spacer(),
                              if (reviews.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: Color(0xFFFF9F0A),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "${avg.toStringAsFixed(1)}  (${reviews.length})",
                                      style: ptstyle(
                                        size: 12,
                                        weight: 600,
                                        color: ch.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            titleCase(
                              product.model.isNotEmpty
                                  ? product.model
                                  : product.fullName,
                            ),
                            style: ptstyle(
                              size: 26,
                              weight: 700,
                              color: ch.onSurface,
                              height: 1.1,
                            ).copyWith(letterSpacing: -0.8),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      transitionBuilder:
                                          (c, a) => FadeTransition(
                                            opacity: a,
                                            child: SlideTransition(
                                              position: Tween(
                                                begin: const Offset(0, 0.3),
                                                end: Offset.zero,
                                              ).animate(a),
                                              child: c,
                                            ),
                                          ),
                                      child: Text(
                                        selPrice == null
                                            ? "See options"
                                            : "GHS ${selPrice.toCommaSeparated(0, decimalPlaces: 0)}",
                                        key: ValueKey(selPrice),
                                        style: ptstyle(
                                          size: 22,
                                          weight: 700,
                                          color: ch.onSurface,
                                        ).copyWith(letterSpacing: -0.5),
                                      ),
                                    ),
                                    Text(
                                      sel == null
                                          ? "Full price"
                                          : "Full price · ${sel.storage}",
                                      style: ptstyle(
                                        size: 11.5,
                                        weight: 400,
                                        color: ch.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (product.supportsInstallment)
                                PressScale(
                                  onTap:
                                      () => _openSheet(
                                        buyNow: false,
                                        storage: sel,
                                      ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _blue.withOpacity(0.09),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 15,
                                          color: _blue,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Pay daily",
                                          style: ptstyle(
                                            size: 12.5,
                                            weight: 600,
                                            color: _blue,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: _blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (product.uniqueViewsCount >= 10) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const _LiveDot(),
                                const SizedBox(width: 8),
                                Text(
                                  "${product.uniqueViewsCount.toCommaSeparated(0, decimalPlaces: 0)} people have looked at this phone",
                                  style: ptstyle(
                                    size: 12,
                                    weight: 500,
                                    color: ch.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ---- Configure: colour + storage in one card ----
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 70),
                    child: _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (colors.isNotEmpty) ...[
                            _Label(
                              "Colour",
                              p.colorSL.isNotEmpty ? titleCase(p.colorSL) : null,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final c in colors)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      p.selectColor(c);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              p.colorSL == c
                                                  ? _blue
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: swatchFor(c),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black.withOpacity(
                                              0.12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                          ],
                          _Label("Storage", null),
                          const SizedBox(height: 10),
                          if (storages.isEmpty)
                            Text(
                              "No storage or pricing options yet.",
                              style: ptstyle(
                                size: 13,
                                weight: 400,
                                color: ch.onSurfaceVariant,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final s in storages)
                                  _StorageChip(
                                    label: s.storage,
                                    price: double.tryParse(s.cashPrice) ?? 0,
                                    selected: identical(s, sel),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _sel = s);
                                    },
                                  ),
                              ],
                            ),
                          if (storages.isNotEmpty &&
                              product.supportsInstallment) ...[
                            const SizedBox(height: 16),
                            PressScale(
                              onTap:
                                  () =>
                                      _openSheet(buyNow: false, storage: sel),
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "See daily plans",
                                      style: ptstyle(
                                        size: 13.5,
                                        weight: 600,
                                        color: ch.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: ch.onSurface,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ---- Seller ----
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: _Card(
                      padding: const EdgeInsets.all(14),
                      onTap:
                          signedIn
                              ? () {
                                final id = product.vendor?.id;
                                if (id == null) return;
                                p.getVendorDetails(id);
                                widget.fromStor
                                    ? NavigationHelper.pop(context)
                                    : NavigationHelper.push(
                                      context,
                                      StoreInfoPage(store_id: id),
                                    );
                              }
                              : () => NavigationHelper.push(
                                context,
                                EmailSignin(),
                              ),
                      child: Row(
                        children: [
                          ShopAvatar(
                            name: product.vendor?.name ?? "Seller",
                            imageUrl: product.vendor?.image,
                            size: 44,
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
                                        product.vendor?.name ?? "Seller",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: ptstyle(
                                          size: 14,
                                          weight: 600,
                                          color: ch.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (product.vendor?.isVerified ?? false) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 15,
                                        color: _blue,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  signedIn
                                      ? [
                                        if ((product.vendor?.closingTime ?? "")
                                            .isNotEmpty)
                                          "Open till ${product.vendor!.closingTime!.toAmPm()}",
                                        "Visit shop",
                                      ].join(" · ")
                                      : "Sign in to contact this shop",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ptstyle(
                                    size: 11.5,
                                    weight: 400,
                                    color: ch.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (signedIn) ...[
                            _CircleAction(
                              icon: Icons.call_rounded,
                              color: _blue,
                              onTap: () {
                                final tel = product.vendor?.phoneNumber ?? "";
                                if (tel.isNotEmpty) {
                                  _launch(Uri(scheme: 'tel', path: tel));
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _CircleAction(
                              icon: Icons.chat_rounded,
                              color: const Color(0xFF25D366),
                              onTap: () {
                                final tel = (product.vendor?.phoneNumber ?? "")
                                    .replaceAll(RegExp(r'[^0-9]'), '');
                                if (tel.isEmpty) return;
                                final wa =
                                    tel.startsWith("233")
                                        ? tel
                                        : "233${tel.startsWith("0") ? tel.substring(1) : tel}";
                                _launch(Uri.parse("https://wa.me/$wa"));
                              },
                            ),
                          ] else
                            Icon(
                              Icons.chevron_right_rounded,
                              color: ch.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ---- Why FlexiPhones: swipeable highlights ----
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 210),
                    child: SizedBox(
                      height: 118,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: _T.s20),
                        children: [
                          if (product.supportsInstallment)
                            const _Highlight(
                              icon: Icons.calendar_month_rounded,
                              colors: [Color(0xFF2E8BFF), Color(0xFF0058C7)],
                              title: "Pay daily",
                              sub: "Small amounts with Mobile Money",
                            ),
                          const _Highlight(
                            icon: Icons.verified_user_rounded,
                            colors: [Color(0xFF34C759), Color(0xFF1E8E3E)],
                            title: "Yours when paid",
                            sub: "Released after the last payment",
                          ),
                          if (product.supportsCash)
                            const _Highlight(
                              icon: Icons.payments_rounded,
                              colors: [Color(0xFFFFB340), Color(0xFFFF7A00)],
                              title: "Or pay cash",
                              sub: "Reserve it, pay at the shop",
                            ),
                          const _Highlight(
                            icon: Icons.storefront_rounded,
                            colors: [Color(0xFFBF5AF2), Color(0xFF7D3CFF)],
                            title: "Trusted shops",
                            sub: "Checked by FlexiPhones",
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- Overview ----
                  if (spec.isNotEmpty) ...[
                    const _AppleTitle("Overview", null),
                    _Card(
                      onTap: () => setState(() => showAll = !showAll),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: Text(
                              spec,
                              maxLines: showAll ? null : 4,
                              overflow:
                                  showAll
                                      ? TextOverflow.visible
                                      : TextOverflow.fade,
                              style: ptstyle(
                                size: 13.5,
                                weight: 400,
                                color: ch.onSurfaceVariant,
                                height: 1.55,
                              ),
                            ),
                          ),
                          if (spec.length > 160) ...[
                            const SizedBox(height: 6),
                            Text(
                              showAll ? "Show less" : "Read more",
                              style: ptstyle(
                                size: 13,
                                weight: 600,
                                color: _blue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (signedIn)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: ch.onSurfaceVariant,
                          ),
                          onPressed:
                              () => showReportSheet(
                                context,
                                target: "product",
                                productId: product.id,
                                subject: titleCase(product.fullName),
                              ),
                          icon: const Icon(Icons.flag_outlined, size: 16),
                          label: Text(
                            "Report this phone",
                            style: ptstyle(size: 12, weight: 500),
                          ),
                        ),
                      ),
                    ),
                  // Reviews (paged, with filters, write / edit / delete)
                  const _AppleTitle("Ratings & reviews", null),
                  ReviewsSummary(
                    target: ReviewTarget.product,
                    targetId: product.id,
                    targetName: titleCase(product.fullName),
                  ),

                  _MoreProducts(current: product, onOpen: _openOtherProduct),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

/// Pinned at the bottom: the starting price, a bag button and Buy now.
/// Pinned at the bottom. What it offers follows the phone's
/// `available_sale_modes`:
/// - daily payments only: price, bag, Buy now;
/// - cash only: price, Buy with cash (no bag; the bag is for daily plans);
/// - both: the price on top, then bag, Pay cash and Buy now.
class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.fromPrice,
    required this.inBag,
    required this.signedIn,
    required this.onBag,
    required this.onBuy,
    required this.onCash,
    required this.cash,
    required this.installment,
  });

  final double? fromPrice;
  final bool inBag;
  final bool signedIn;
  final VoidCallback onBag;
  final VoidCallback onBuy;
  final VoidCallback onCash;
  final bool cash;
  final bool installment;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final both = cash && installment;
    final price = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cash && !installment
              ? "Cash price"
              : both
              ? "From · pay cash or daily"
              : "From",
          style: ptstyle(size: 11, weight: 500, color: ch.onSurfaceVariant),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            fromPrice == null
                ? "—"
                : "GHS ${fromPrice!.toCommaSeparated(0, decimalPlaces: 0)}",
            style: ptstyle(
              size: 17,
              weight: 800,
              color: ch.onSurface,
            ).copyWith(letterSpacing: -0.5),
          ),
        ),
      ],
    );
    final bag = SizedBox(
      width: 54,
      height: 54,
      child: Material(
        color:
            inBag
                ? const Color(0xFF30A14E).withOpacity(0.12)
                : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onBag,
          child: Icon(
            inBag ? Icons.shopping_bag_rounded : Icons.add_shopping_cart_rounded,
            color: inBag ? const Color(0xFF30A14E) : ch.onSurface,
          ),
        ),
      ),
    );
    Widget button({
      required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
    }) => SizedBox(
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: ptstyle(size: 14, weight: 700)),
        ),
      ),
    );
    final buyNow = button(
      label: signedIn ? "Buy now" : "Sign in to buy",
      icon: signedIn ? Icons.bolt_rounded : Icons.login_rounded,
      color: _blue,
      onTap: onBuy,
    );
    final payCash = button(
      label: signedIn ? (both ? "Pay cash" : "Buy with cash") : "Sign in to buy",
      icon: signedIn ? Icons.payments_rounded : Icons.login_rounded,
      color: const Color(0xFF1D1D1F),
      onTap: onCash,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: ch.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child:
          both
              ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  price,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      bag,
                      const SizedBox(width: 10),
                      Expanded(child: payCash),
                      const SizedBox(width: 10),
                      Expanded(child: buyNow),
                    ],
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(child: price),
                  if (installment) ...[bag, const SizedBox(width: 10)],
                  installment ? buyNow : payCash,
                ],
              ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    // Frosted glass over the photo.
    return Center(
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.white.withOpacity(0.72),
            shape: CircleBorder(
              side: BorderSide(color: Colors.white.withOpacity(0.6)),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, size: 18, color: ch.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavRound extends StatelessWidget {
  const _FavRound({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white.withOpacity(0.9),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: SizedBox(
            width: 40,
            height: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder:
                  (c, a) => ScaleTransition(
                    scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
                    child: c,
                  ),
              child: Icon(
                active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(active),
                size: 19,
                color: active ? const Color(0xFFFF375F) : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "You may also like": same brand first, then the same seller, then the
/// rest — drawn with the shared product card.
class _MoreProducts extends StatelessWidget {
  const _MoreProducts({required this.current, required this.onOpen});

  final ProductModel current;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SharedProvider>(context);
    final others = p.products.where((x) => x.id != current.id).toList();
    if (others.isEmpty) return const SizedBox.shrink();

    int rank(ProductModel x) {
      if (x.brand.toLowerCase() == current.brand.toLowerCase()) return 0;
      if (x.vendorId != null && x.vendorId == current.vendorId) return 1;
      return 2;
    }

    others.sort((a, b) => rank(a).compareTo(rank(b)));
    final picks = others.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AppleTitle("You may also like", null),
        SizedBox(
          height: 268,
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(_T.s20, 4, _T.s20, 12),
            scrollDirection: Axis.horizontal,
            itemCount: picks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder:
                (_, i) => SizedBox(
                  width: 144,
                  child: ProductTile(
                    product: picks[i],
                    isFavorite: p.isFavorite(picks[i].id),
                    onFavorite:
                        p.userData == null
                            ? null
                            : () => p.toggleFavorite(context, picks[i]),
                    onTap: () => onOpen(picks[i].id),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.ch,
    required this.message,
    required this.onRetry,
  });
  final ColorScheme ch;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ch.surface,
      appBar: AppBar(
        backgroundColor: ch.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(_T.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F4F7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 34,
                  color: ch.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: _T.s16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: ptstyle(
                  size: 14,
                  weight: 500,
                  color: ch.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: _T.s24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _blue),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Try again"),
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
    return Scaffold(
      backgroundColor: ch.surface,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Product details',
          style: ptstyle(size: 14, weight: 600, color: ch.onSurfaceVariant),
        ),
      ),
      body: Shimmer.fromColors(
        period: const Duration(milliseconds: 900),
        baseColor: ch.surfaceContainerLow,
        highlightColor: ch.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_T.s16, 70, _T.s16, 0),
          child: Column(
            children: [
              // Flexible (not a fixed 320) so the placeholder fits short
              // screens like the M91 instead of overflowing.
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_T.rCard),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _T.s24),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(height: 22, width: 220, color: Colors.white),
              ),
              const SizedBox(height: _T.s24),
              Column(
                children: List.generate(
                  6,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _T.s24),
              Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: _T.s12),
                    child: Container(
                      height: 80,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_T.rTile),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _T.s24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_T.rPill),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_T.rPill),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _T.s24),
            ],
          ),
        ),
      ),
    );
  }
}


/// Section heading.
class _AppleTitle extends StatelessWidget {
  const _AppleTitle(this.lead, this.rest);
  final String lead;
  final String? rest;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_T.s20, 26, _T.s20, 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: lead,
              style: ptstyle(
                size: 17,
                weight: 700,
                color: ch.onSurface,
              ).copyWith(letterSpacing: -0.3),
            ),
            if (rest != null)
              TextSpan(
                text: " $rest",
                style: ptstyle(
                  size: 17,
                  weight: 600,
                  color: ch.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// White rounded card on the light grey page.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _T.s20 - 4),
      child: onTap == null ? card : PressScale(onTap: onTap!, child: card),
    );
  }
}

/// "Colour   Orange" — label with the current choice in grey.
class _Label extends StatelessWidget {
  const _Label(this.text, this.value);
  final String text;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          text,
          style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
        ),
        if (value != null) ...[
          const SizedBox(width: 8),
          Text(
            value!,
            style: ptstyle(size: 13, weight: 400, color: ch.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: ptstyle(
        size: 10,
        weight: 700,
        color: color,
      ).copyWith(letterSpacing: 1),
    ),
  );
}

/// A storage option you pick; the price above follows it.
class _StorageChip extends StatelessWidget {
  const _StorageChip({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _blue.withOpacity(0.07) : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _blue : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: ptstyle(
                size: 13.5,
                weight: 600,
                color: selected ? _blue : ch.onSurface,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              price > 0
                  ? "GHS ${price.toCommaSeparated(0, decimalPlaces: 0)}"
                  : "See plans",
              style: ptstyle(
                size: 11.5,
                weight: 400,
                color: ch.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressScale(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    ),
  );
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon,
    required this.colors,
    required this.title,
    required this.sub,
  });
  final IconData icon;
  final List<Color> colors;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const Spacer(),
          Text(
            title,
            style: ptstyle(size: 13, weight: 700, color: ch.onSurface),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ptstyle(
              size: 11,
              weight: 400,
              color: ch.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pulsing green dot ("people are looking right now").
class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 14,
    height: 14,
    child: AnimatedBuilder(
      animation: _c,
      builder:
          (_, _) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 6 + 8 * _c.value,
                height: 6 + 8 * _c.value,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF34C759,
                  ).withOpacity(0.35 * (1 - _c.value)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
    ),
  );
}

/// Loading state shaped like the real page, with a soft shimmer.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    Widget block(double w, double hh, {double r = 10}) => Container(
      width: w,
      height: hh,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Shimmer.fromColors(
        baseColor: const Color(0xFFE6E9EE),
        highlightColor: const Color(0xFFF7F8FA),
        period: const Duration(milliseconds: 1200),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            block(double.infinity, h * 0.46, r: 0),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      block(70, 20, r: 8),
                      const SizedBox(width: 6),
                      block(44, 20, r: 8),
                    ],
                  ),
                  const SizedBox(height: 14),
                  block(220, 28),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      block(130, 24),
                      const Spacer(),
                      block(104, 36, r: 100),
                    ],
                  ),
                  const SizedBox(height: 24),
                  block(double.infinity, 150, r: 22),
                  const SizedBox(height: 12),
                  block(double.infinity, 72, r: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
