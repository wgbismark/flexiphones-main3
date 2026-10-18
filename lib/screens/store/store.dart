import 'package:flexiphones/screens/reports/reports.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/vendors.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/models/review_m.dart';
import 'package:flexiphones/screens/reviews/reviews.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/neu.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart';
import 'package:flexiphones/shared_widgets/shop_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

/// A shop's page, laid out like a place card in Apple Maps: a big photo
/// that stretches and collapses, the name, open/closed at a glance, three
/// round actions (Call, Chat, Directions), a grouped info list, reviews,
/// then the shop's phones as a grid.
class StoreInfoPage extends StatelessWidget {
  const StoreInfoPage({super.key, required this.store_id});
  final dynamic store_id;

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SharedProvider>(context);
    final store = p.vendorData;
    final ready =
        !p.loadingVendor && store != null && "${store.id}" == "$store_id";

    return Scaffold(
      backgroundColor: Neu.bg(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child:
            ready
                ? _StoreBody(key: ValueKey(store.id), store: store)
                : p.loadingVendor
                ? const _StoreShimmer()
                : _StoreError(onRetry: () => p.getVendorDetails(store_id)),
      ),
    );
  }
}

class _StoreBody extends StatelessWidget {
  const _StoreBody({super.key, required this.store});
  final VendorDetails store;

  static const _blue = Color(0xFF0071E3);

  double? get _avgRating {
    if (store.reviews.isEmpty) return null;
    final sum = store.reviews.fold<int>(0, (s, r) => s + r.rating);
    return sum / store.reviews.length;
  }

  /// "HH:mm:ss" -> minutes since midnight.
  static int? _mins(String? t) {
    if (t == null) return null;
    final parts = t.split(":");
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h == null || m == null ? null : h * 60 + m;
  }

  /// Null when the shop hasn't set its hours.
  bool? get _openNow {
    final o = _mins(store.openingTime);
    final c = _mins(store.closingTime);
    if (o == null || c == null) return null;
    final now = TimeOfDay.now();
    final n = now.hour * 60 + now.minute;
    return c > o ? (n >= o && n < c) : (n >= o || n < c);
  }

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String get _waNumber {
    final d = store.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith("233")) return d;
    if (d.startsWith("0")) return "233${d.substring(1)}";
    return "233$d";
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final open = _openNow;
    final rating = store.rating > 0 ? store.rating : _avgRating;
    final hasImage = (store.image ?? "").isNotEmpty;
    final products = store.products;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          stretch: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Neu.bg(context),
          surfaceTintColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _GlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => NavigationHelper.pop(context),
            ),
          ),
          flexibleSpace: LayoutBuilder(
            builder: (context, box) {
              final top = MediaQuery.of(context).padding.top;
              final collapsed = box.maxHeight <= kToolbarHeight + top + 20;
              return FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                centerTitle: true,
                title: AnimatedOpacity(
                  opacity: collapsed ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    store.name,
                    style: ptstyle(size: 16, weight: 600, color: ch.onSurface),
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? Image.network(
                          store.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _Backdrop(name: store.name),
                        )
                        : _Backdrop(name: store.name),
                    // Soft fade into the page below.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.55, 1],
                          colors: [
                            Colors.black.withOpacity(0.25),
                            Colors.transparent,
                            Neu.bg(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Name, status, rating
        SliverToBoxAdapter(
          child: FadeSlideIn(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // The shop's picture (or its letter when none is set).
                      ShopAvatar(
                        name: store.name,
                        imageUrl: store.image,
                        size: 64,
                        border: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          store.name,
                          style: ptstyle(
                            size: 26,
                            weight: 700,
                            color: ch.onSurface,
                          ).copyWith(letterSpacing: -0.8, height: 1.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: ch.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          store.location.isEmpty
                              ? "Location not set"
                              : store.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ptstyle(
                            size: 13,
                            weight: 400,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (open != null)
                        _Pill(
                          color: open ? const Color(0xFF30A14E) : const Color(0xFFE5484D),
                          text:
                              open
                                  ? "Open · Closes ${store.closingTime?.toAmPm() ?? ""}"
                                  : "Closed · Opens ${store.openingTime?.toAmPm() ?? ""}",
                        ),
                      if (rating != null)
                        _Pill(
                          color: const Color(0xFFFF9F0A),
                          icon: Icons.star_rounded,
                          text:
                              "${rating.toStringAsFixed(1)} (${store.reviews.length})",
                        ),
                      if (store.status.toLowerCase() == "active")
                        const _Pill(
                          color: _blue,
                          icon: Icons.verified_rounded,
                          text: "Verified shop",
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Actions
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.phone_rounded,
                      label: "Call",
                      primary: true,
                      onTap:
                          store.phoneNumber.isEmpty
                              ? null
                              : () => _launch(
                                Uri(scheme: 'tel', path: store.phoneNumber),
                              ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.chat_bubble_rounded,
                      label: "Chat",
                      onTap:
                          store.phoneNumber.isEmpty
                              ? null
                              : () => _launch(
                                Uri.parse("https://wa.me/$_waNumber"),
                              ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.directions_rounded,
                      label: "Directions",
                      onTap:
                          store.location.isEmpty
                              ? null
                              : () => _launch(
                                Uri.parse(
                                  store.latitude != null && store.longitude != null
                                      ? "https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}"
                                      : "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("${store.name} ${store.location}")}",
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Info list
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _Group(
                children: [
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: "Hours",
                    value:
                        store.openingTime == null || store.closingTime == null
                            ? "Not set"
                            : "${store.openingTime!.toAmPm()} – ${store.closingTime!.toAmPm()}",
                  ),
                  _InfoRow(
                    icon: Icons.storefront_rounded,
                    label: "Pick up in store",
                    value: store.pickupAvailable == 1 ? "Available" : "Not offered",
                    good: store.pickupAvailable == 1,
                  ),
                  _InfoRow(
                    icon: Icons.local_shipping_rounded,
                    label: "Delivery",
                    value:
                        store.deliveryAvailable == 1 ? "Available" : "Not offered",
                    good: store.deliveryAvailable == 1,
                  ),
                  if (store.email.isNotEmpty)
                    _InfoRow(
                      icon: Icons.mail_outline_rounded,
                      label: "Email",
                      value: store.email,
                      onTap: () => _launch(Uri(scheme: "mailto", path: store.email)),
                    ),
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: "Report this shop",
                    value: "",
                    onTap:
                        () => showReportSheet(
                          context,
                          target: "vendor",
                          vendorId: store.id,
                          subject: store.name,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Every place the shop sells from (main shop first), loaded fresh.
        SliverToBoxAdapter(child: _Locations(vendorId: store.id)),

        // Reviews (paged, with filters, write / edit / delete)
        const SliverToBoxAdapter(
          child: _SectionHeader(title: "Ratings & Reviews"),
        ),
        SliverToBoxAdapter(
          child: ReviewsSummary(
            target: ReviewTarget.vendor,
            targetId: store.id,
            targetName: store.name,
          ),
        ),

        // Phones
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: "Phones at this shop",
            trailing: "${products.length}",
          ),
        ),
        if (products.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _Group(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Text(
                      "This shop has no phones listed right now.",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 13,
                        weight: 400,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 16,
                childAspectRatio: 0.56,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                final x = products[i];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 160 + 50 * (i % 6)),
                  child: ProductTile(
                    product: x,
                    isFavorite: p.isFavorite(x.id),
                    onFavorite:
                        p.userData == null
                            ? null
                            : () => p.toggleFavorite(context, x),
                    onTap: () {
                      p.getProductDetails(x.id, context);
                      NavigationHelper.push(
                        context,
                        ProductDetailsPage(productId: x.id, fromStor: true),
                      );
                    },
                  ),
                );
              }, childCount: products.length),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D1D1F), Color(0xFF0B2A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? "" : name.trim()[0].toUpperCase(),
        style: ptstyle(
          size: 110,
          weight: 800,
          color: Colors.white.withOpacity(0.12),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Center(
      child: Material(
        color: ch.surface.withOpacity(0.85),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 17, color: ch.onSurface),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.text, this.icon});
  final Color color;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(text, style: ptstyle(size: 12, weight: 600, color: color)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? const Color(0xFF0071E3) : Neu.bg(context);
    final fg = primary ? Colors.white : const Color(0xFF0071E3);
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            boxShadow:
                primary
                    ? [
                      BoxShadow(
                        color: const Color(0xFF0071E3).withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : Neu.raised(context, distance: 5, blur: 12),
          ),
          child: Column(
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(height: 4),
              Text(label, style: ptstyle(size: 12, weight: 600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Neu.bg(context),
        boxShadow: Neu.raised(context, distance: 5, blur: 13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 52,
                color: ch.outlineVariant.withOpacity(0.35),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.good,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool? good;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: ch.onSurfaceVariant),
            const SizedBox(width: 16),
            Text(label, style: ptstyle(size: 14, weight: 500, color: ch.onSurface)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ptstyle(
                  size: 13,
                  weight: 400,
                  color:
                      good == null
                          ? ch.onSurfaceVariant
                          : good!
                          ? const Color(0xFF30A14E)
                          : ch.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: ptstyle(
                size: 21,
                weight: 700,
                color: ch.onSurface,
              ).copyWith(letterSpacing: -0.5),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 3),
              child: Text(
                trailing!,
                style: ptstyle(size: 14, weight: 500, color: ch.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreError extends StatelessWidget {
  const _StoreError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _GlassButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => NavigationHelper.pop(context),
              ),
            ),
          ),
          const Spacer(),
          Icon(Icons.storefront_outlined, size: 52, color: ch.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            Provider.of<SharedProvider>(context, listen: false).vendorNotFound
                ? "This shop is no longer available"
                : "Couldn't load this shop",
            style: ptstyle(size: 17, weight: 700, color: ch.onSurface),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text("Try again")),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _StoreShimmer extends StatelessWidget {
  const _StoreShimmer();

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    Widget box(double h, {double? w, double r = 14}) => Container(
      height: h,
      width: w ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    return Shimmer.fromColors(
      baseColor: ch.onSurface.withOpacity(0.05),
      highlightColor: ch.onSurface.withOpacity(0.1),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          box(260, r: 0),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(30, w: 220),
                const SizedBox(height: 10),
                box(14, w: 160),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: box(64)),
                    const SizedBox(width: 10),
                    Expanded(child: box(64)),
                    const SizedBox(width: 10),
                    Expanded(child: box(64)),
                  ],
                ),
                const SizedBox(height: 22),
                box(180, r: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Locations": the main shop and each branch, with Call and Directions.
/// Loaded every time the page opens (branches can be switched off).
/// Hidden when the shop has only its main place.
class _Locations extends StatefulWidget {
  const _Locations({required this.vendorId});
  final int vendorId;

  @override
  State<_Locations> createState() => _LocationsState();
}

class _LocationsState extends State<_Locations> {
  List<Map<String, dynamic>> _list = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = Provider.of<SharedProvider>(context, listen: false);
      final l = await p.fetchVendorLocations(context, widget.vendorId);
      if (mounted) setState(() => _list = l);
    });
  }

  Future<void> _go(Uri u) async {
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    if (_list.length <= 1) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Locations", trailing: "${_list.length}"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _list.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0071E3,
                            ).withOpacity(_list[i]['is_main'] == true ? 1 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 18,
                            color:
                                _list[i]['is_main'] == true
                                    ? Colors.white
                                    : const Color(0xFF0071E3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_list[i]['name'] ?? ''}".isNotEmpty
                                    ? "${_list[i]['name']}"
                                    : (_list[i]['is_main'] == true
                                        ? "Main shop"
                                        : "Branch"),
                                style: ptstyle(
                                  size: 13.5,
                                  weight: 600,
                                  color: ch.onSurface,
                                ),
                              ),
                              if ("${_list[i]['address'] ?? ''}".isNotEmpty)
                                Text(
                                  "${_list[i]['address']}",
                                  maxLines: 2,
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
                        if ("${_list[i]['phone_number'] ?? ''}".isNotEmpty)
                          IconButton(
                            tooltip: "Call",
                            onPressed:
                                () => _go(
                                  Uri(
                                    scheme: 'tel',
                                    path: "${_list[i]['phone_number']}",
                                  ),
                                ),
                            icon: const Icon(
                              Icons.call_rounded,
                              size: 19,
                              color: Color(0xFF0071E3),
                            ),
                          ),
                        if ("${_list[i]['address'] ?? ''}".isNotEmpty)
                          IconButton(
                            tooltip: "Directions",
                            onPressed:
                                () => _go(
                                  Uri.parse(
                                    "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("${_list[i]['address']}")}",
                                  ),
                                ),
                            icon: const Icon(
                              Icons.directions_rounded,
                              size: 20,
                              color: Color(0xFF0071E3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (i < _list.length - 1)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 60,
                      color: Colors.black.withOpacity(0.08),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
