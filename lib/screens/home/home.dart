import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'dart:math' as math;

import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/hot_sales.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/models/top_deals_m.dart';
import 'package:flexiphones/models/standing_m.dart';
import 'package:flexiphones/screens/orders/sub_pages/pay_now.dart';
import 'package:flexiphones/shared_widgets/quick_pay.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/screens/home/components/top_deals.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_home_shell.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/neu.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart';
import 'package:flexiphones/shared_widgets/pull_to_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// The storefront, in soft UI: everything sits on one soft grey-blue
/// surface and gets its depth from light and shadow. A big title, a
/// pressed-in search well, a glowing featured carousel, three "why
/// FlexiPhones" tiles, app-icon style brand buttons, top deals, recently
/// viewed, then every phone in a grid with a sliding sort switch.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<SharedProvider>(context, listen: false);
      if (p.brands.isEmpty) p.getBrands();
      if (p.userData != null && p.favoriteIds.isEmpty) p.getFavorites();
    });
  }

  /// Pull down to reload everything on the home page from the first page.
  Future<void> _refresh() async {
    final p = Provider.of<SharedProvider>(context, listen: false);
    await Future.wait([
      p.getHotDeals(),
      p.getTopDeals(refresh: true, next: false),
      p.getProducts(context, refresh: true, next: false),
      p.getRecentViewed(),
      p.getBrands(),
      if (p.userData != null) p.getFavorites(),
    ]).timeout(const Duration(seconds: 15), onTimeout: () => []);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final p = Provider.of<SharedProvider>(context, listen: false);
    if (n.metrics.extentAfter < 600 &&
        p.pNextPAGE != null &&
        !p.loadingProducts) {
      p.getProducts(context, refresh: false, next: true);
    }
    return false;
  }

  void _open(SharedProvider p, int id) {
    p.getProductDetails(id, context);
    NavigationHelper.push(context, ProductDetailsPage(productId: id));
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SharedProvider>(context);
    final ch = Theme.of(context).colorScheme;
    final signedIn = p.userData != null;

    return ColoredBox(
      color: Neu.bg(context),
      child: FlexiPullToRefresh(
        onRefresh: _refresh,
        builder:
            (physics) => NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: CustomScrollView(
                physics: physics,
                slivers: [
                  SliverToBoxAdapter(
                    child: FadeSlideIn(child: _Header(signedIn: signedIn)),
                  ),
                  if (signedIn)
                    SliverToBoxAdapter(
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
                          child: _SearchWell(
                            onTap: () {
                              p.getFilteredProducts();
                              p.enableSearching();
                            },
                          ),
                        ),
                      ),
                    ),
                  // An agent on the shopping side without a customer
                  // account: say so, and offer to sign in with the same email.
                  if (!signedIn && p.isAgentAccount)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                        child: _AgentShopperCard(
                          email: p.partnerData?.email ?? "",
                          onSignIn: () {
                            p.emailEditingController.text =
                                p.partnerData?.email ?? "";
                            NavigationHelper.push(context, EmailSignin());
                          },
                          onBack:
                              () => NavigationHelper.push(
                                context,
                                const AgentHomeShell(),
                              ),
                        ),
                      ),
                    ),
                  // One red line when any plan is behind (server-decided).
                  if (signedIn && (p.ordersStanding?.isBehind ?? false))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                        child: _BehindBanner(standing: p.ordersStanding!),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      offset: 30,
                      child: _FeaturedCarousel(
                        deals: p.hotDeals,
                        onOpen: (id) => _open(p, id),
                      ),
                    ),
                  ),
                  if (p.brands.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: "Shop by brand"),
                    ),
                    SliverToBoxAdapter(child: _BrandRow(p: p)),
                  ],
                  if (p.topDeals.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionTitle(
                        title: "Top deals",
                        action: "See all",
                        onAction:
                            () =>
                                NavigationHelper.push(context, TopDealsPage()),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 250,
                        child: ListView.separated(
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                          scrollDirection: Axis.horizontal,
                          itemCount: math.min(p.topDeals.length, 10),
                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                          itemBuilder:
                              (_, i) => _DealCard(
                                deal: p.topDeals[i],
                                onTap: () => _open(p, p.topDeals[i].id),
                              ),
                        ),
                      ),
                    ),
                  ],
                  if (p.recentlyViewedProducts.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: "Pick up where you left off"),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100,
                        child: ListView.separated(
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                          scrollDirection: Axis.horizontal,
                          itemCount: p.recentlyViewedProducts.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final x = p.recentlyViewedProducts[i];
                            return _RecentBubble(
                              product: x,
                              onTap: () => _open(p, x.id),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: _SectionTitle(title: "All phones", big: true),
                  ),
                  SliverToBoxAdapter(child: _SortSwitch(p: p)),
                  _ProductGrid(p: p, onOpen: (id) => _open(p, id)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: Center(
                        child:
                            p.pNextPAGE != null && p.products.isNotEmpty
                                ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ch.onSurfaceVariant,
                                  ),
                                )
                                : Text(
                                  p.products.isEmpty
                                      ? ""
                                      : "You've seen them all",
                                  style: ptstyle(
                                    size: 12,
                                    weight: 500,
                                    color: ch.onSurfaceVariant.withOpacity(0.6),
                                  ),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header + search
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.signedIn});
  final bool signedIn;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context, listen: false);
    final first = (p.userData?.data.name ?? "").trim().split(" ").first;
    final big = ptstyle(
      size: 27,
      weight: 700,
      color: ch.onSurface,
      height: 1.1,
    ).copyWith(letterSpacing: -0.9);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date capsule, plus a status capsule when signed in: red pulsing
          // dot with the days owed, or green "On time".
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Capsule(
                icon: Icons.calendar_today_rounded,
                text: DateFormat("EEE, d MMM").format(DateTime.now()),
              ),
              if (signedIn) _StatusCapsule(p: p),
            ],
          ),
          const SizedBox(height: 12),
          if (signedIn && first.isNotEmpty)
            Text(
              "${_greeting()}, $first",
              style: ptstyle(
                size: 13.5,
                weight: 500,
                color: ch.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "Find your ", style: big),
                TextSpan(
                  text: "next phone.",
                  style: big.copyWith(color: ch.onSurface.withOpacity(0.32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchWell extends StatelessWidget {
  const _SearchWell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 21, color: ch.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Search phones, brands, shops",
                style: ptstyle(
                  size: 14,
                  weight: 400,
                  color: ch.onSurfaceVariant,
                ),
              ),
            ),
            const Icon(Icons.tune_rounded, size: 19, color: Neu.blue),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
    this.big = false,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, big ? 34 : 28, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: ptstyle(
                size: big ? 24 : 19,
                weight: 800,
                color: ch.onSurface,
              ).copyWith(letterSpacing: -0.6),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: Neu.blue,
              ),
              child: Text(action!, style: ptstyle(size: 13, weight: 600)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Featured carousel (hot deals)
// ---------------------------------------------------------------------------

/// Promoted phones: full-photo cards that slide by themselves every few
/// seconds, loop forever, pause while touched, and open the phone on tap.
class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.deals, required this.onOpen});
  final List<HotDeal> deals;
  final ValueChanged<int> onOpen;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  // Start far from 0 so it can loop both ways.
  static const _start = 1000;
  late final PageController _page = PageController(
    viewportFraction: 0.9,
    initialPage: _start,
  );
  Timer? _auto;
  bool _touching = false;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _touching || !_page.hasClients) return;
      _page.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final deals = widget.deals.take(8).toList();
    // Promoted phones first, then our own phone.png slides, so the hero
    // always has something moving.
    final n = deals.length + _BrandSlide.count;
    return Column(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (s) {
            if (s is ScrollStartNotification && s.dragDetails != null) {
              _touching = true;
            } else if (s is ScrollEndNotification) {
              _touching = false;
            }
            return false;
          },
          child: SizedBox(
            height: 208,
            child: PageView.builder(
              controller: _page,
              itemCount: n == 1 ? 1 : null,
              onPageChanged: (i) => setState(() => _current = i % n),
              itemBuilder: (_, i) {
                final k = i % n;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child:
                      k < deals.length
                          ? PressScale(
                            onTap: () => widget.onOpen(deals[k].id),
                            child: _PromoCard(deal: deals[k]),
                          )
                          : _BrandSlide(index: k - deals.length),
                );
              },
            ),
          ),
        ),
        if (n > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < n; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        i == _current
                            ? const Color(0xFF0071E3)
                            : ch.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One promoted phone: the photo fills the card, a soft dark fade at the
/// bottom carries the text.
class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.deal});
  final HotDeal deal;

  @override
  Widget build(BuildContext context) {
    final storage = deal.storages.isEmpty ? null : deal.storages.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFFE9ECF1)),
          if (deal.image.isNotEmpty)
            Image.network(
              deal.image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.35, 1],
                colors: [Colors.transparent, Color(0xD9000000)],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  color: Colors.white.withOpacity(0.25),
                  child: Text(
                    "Promoted",
                    style: ptstyle(
                      size: 10.5,
                      weight: 600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ptstyle(
                          size: 10,
                          weight: 700,
                          color: Colors.white70,
                        ).copyWith(letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        titleCase(
                          deal.model.isEmpty ? deal.fullName : deal.model,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ptstyle(
                          size: 21,
                          weight: 700,
                          color: Colors.white,
                        ).copyWith(letterSpacing: -0.5),
                      ),
                      Text(
                        deal.minPrice > 0
                            ? "From GHS ${deal.minPrice.toCommaSeparated(0, decimalPlaces: 0)} · Pay daily"
                            : (storage == null
                                ? "Pay small, every day"
                                : "$storage · Pay daily"),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ptstyle(
                          size: 12,
                          weight: 400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.p});
  final SharedProvider p;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        scrollDirection: Axis.horizontal,
        children: [
          _BrandBubble(
            label: "All",
            icon: Icons.apps_rounded,
            selected: p.brandFilter.isEmpty,
            onTap: () => p.setBrandFilter(context, null),
          ),
          for (final b in p.brands)
            _BrandBubble(
              label: b.displayName,
              logoUrl: b.logoUrl,
              selected: p.brandFilter.contains(b.name.toLowerCase()),
              onTap:
                  () => p.setBrandFilter(
                    context,
                    p.brandFilter.contains(b.name.toLowerCase())
                        ? null
                        : b.name,
                  ),
            ),
        ],
      ),
    );
  }
}

class _BrandBubble extends StatelessWidget {
  const _BrandBubble({
    required this.label,
    required this.selected,
    required this.onTap,
    this.logoUrl,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? logoUrl;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final fg = selected ? Neu.blue : ch.onSurface;
    final initial = Text(
      label.isEmpty ? "?" : label[0],
      style: ptstyle(size: 22, weight: 800, color: fg),
    );
    final inner = SizedBox(
      width: 60,
      height: 60,
      child: Center(
        child:
            icon != null
                ? Icon(icon, color: fg, size: 26)
                : logoUrl == null
                ? initial
                : Padding(
                  padding: const EdgeInsets.all(14),
                  child: Image.network(
                    logoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => initial,
                  ),
                ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? Neu.blue : Colors.black.withOpacity(0.06),
                  width: selected ? 1.8 : 1,
                ),
              ),
              child: inner,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: ptstyle(
                size: 11.5,
                weight: selected ? 700 : 500,
                color: selected ? Neu.blue : ch.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal, required this.onTap});
  final Deal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final rating = double.tryParse(deal.rating) ?? 0;
    // Same look as the product card: the photo fills its box.
    return NeuBox(
      radius: 24,
      padding: const EdgeInsets.all(6),
      onTap: onTap,
      child: SizedBox(
        width: 146,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Image.network(
                    deal.image,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, _, _) => Opacity(
                          opacity: 0.4,
                          child: Image.asset(AssetsHelper.dummyImage),
                        ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 9, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ptstyle(
                      size: 9,
                      weight: 700,
                      color: const Color(0xFF0071E3),
                    ).copyWith(letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    titleCase(deal.model),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ptstyle(size: 13, weight: 600, color: ch.onSurface)
                        .copyWith(letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFF9F0A),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating > 0 ? rating.toStringAsFixed(1) : "New",
                        style: ptstyle(
                          size: 11,
                          weight: 600,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                    ],
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

/// "Pick up where you left off": a small card with the photo filling a
/// rounded square, then the name, brand and starting price.
class _RecentBubble extends StatelessWidget {
  const _RecentBubble({required this.product, required this.onTap});
  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final price = product.fromPrice;
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 214,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2A4A).withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, _, _) => Container(
                        color: const Color(0xFFF2F4F7),
                        padding: const EdgeInsets.all(10),
                        child: Opacity(
                          opacity: 0.4,
                          child: Image.asset(AssetsHelper.dummyImage),
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ptstyle(
                      size: 9,
                      weight: 700,
                      color: const Color(0xFF0071E3),
                    ).copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    titleCase(
                      product.model.isEmpty ? product.fullName : product.model,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ptstyle(size: 13, weight: 600, color: ch.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price > 0
                        ? "From GHS ${price.toCommaSeparated(0, decimalPlaces: 0)}"
                        : "See options",
                    style: ptstyle(
                      size: 11.5,
                      weight: 500,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ch.onSurfaceVariant.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// All phones: sort switch + grid
// ---------------------------------------------------------------------------

/// A pressed-in track with a raised thumb on the chosen sort.
class _SortSwitch extends StatelessWidget {
  const _SortSwitch({required this.p});
  final SharedProvider p;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final s in ProductSort.values)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  p.setProductSort(context, s);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color:
                        p.productSort == s
                            ? Neu.bg(context)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow:
                        p.productSort == s
                            ? Neu.raised(context, distance: 3, blur: 7)
                            : const [],
                  ),
                  child: Text(
                    s.label,
                    style: ptstyle(
                      size: 12.5,
                      weight: p.productSort == s ? 700 : 500,
                      color:
                          p.productSort == s ? Neu.blue : ch.onSurfaceVariant,
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

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.p, required this.onOpen});
  final SharedProvider p;
  final ValueChanged<int> onOpen;

  static const _delegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 18,
    crossAxisSpacing: 16,
    childAspectRatio: 0.56,
  );

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    if (p.products.isEmpty && p.loadingProducts) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        sliver: SliverGrid(
          gridDelegate: _delegate,
          delegate: SliverChildBuilderDelegate(
            (_, _) => Shimmer.fromColors(
              baseColor: ch.onSurface.withOpacity(0.04),
              highlightColor: ch.onSurface.withOpacity(0.09),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            childCount: 4,
          ),
        ),
      );
    }
    if (p.products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: NeuBox(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                Icon(
                  Icons.phone_iphone_rounded,
                  size: 40,
                  color: ch.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 10),
                Text(
                  "No phones match this filter yet.",
                  style: ptstyle(
                    size: 13,
                    weight: 500,
                    color: ch.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final signedIn = p.userData != null;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      sliver: SliverGrid(
        gridDelegate: _delegate,
        delegate: SliverChildBuilderDelegate((_, i) {
          final x = p.products[i];
          return FadeSlideIn(
            key: ValueKey("tile-${x.id}"),
            delay: Duration(milliseconds: 50 * (i % 6)),
            offset: 26,
            child: ProductTile(
              product: x,
              isFavorite: p.isFavorite(x.id),
              onFavorite: signedIn ? () => p.toggleFavorite(context, x) : null,
              onTap: () => onOpen(x.id),
            ),
          );
        }, childCount: p.products.length),
      ),
    );
  }
}

/// "You have 4 missed days (GHS 88.00). Catch up now" — taps straight
/// into Pay for the worst plan, with Catch up selected.
class _BehindBanner extends StatelessWidget {
  const _BehindBanner({required this.standing});
  final OrdersStanding standing;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE5484D);
    final n = standing.totalMissedDays;
    final worst =
        standing.overdueOrders.isEmpty ? null : standing.overdueOrders.first;
    final locked = standing.overdueOrders.any((o) => o.isLocked);
    return PressScale(
      onTap: () {
        if (worst != null) {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => PayNowScreen(orderId: worst.orderId),
            ),
          );
        } else {
          QuickPayButton.open(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: red.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(
              locked ? Icons.lock_rounded : Icons.error_outline_rounded,
              color: red,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n > 0
                        ? "You have $n missed day${n == 1 ? "" : "s"} · GHS ${standing.totalAmountOverdue.toStringAsFixed(2)}"
                        : "You're behind on a payment",
                    style: ptstyle(size: 13.5, weight: 700, color: red),
                  ),
                  Text(
                    locked
                        ? "Paying unlocks your phone straight away."
                        : "Catch up now to keep your phone running.",
                    style: ptstyle(
                      size: 11.5,
                      weight: 400,
                      color: red.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: red,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                "Catch up",
                style: ptstyle(size: 12, weight: 700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown to an agent browsing the shop without a customer account:
/// one short line and two rounded pill buttons.
class _AgentShopperCard extends StatelessWidget {
  const _AgentShopperCard({
    required this.email,
    required this.onSignIn,
    required this.onBack,
  });
  final String email;
  final VoidCallback onSignIn;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    const blue = Color(0xFF0071E3);
    Widget pill(String label, IconData icon, VoidCallback onTap, bool solid) =>
        Expanded(
          child: PressScale(
            onTap: onTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient:
                    solid
                        ? const LinearGradient(
                          colors: [Color(0xFF2E8BFF), Color(0xFF0058C7)],
                        )
                        : null,
                color: solid ? null : blue.withOpacity(0.08),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: solid ? Colors.white : blue),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ptstyle(
                        size: 13,
                        weight: 700,
                        color: solid ? Colors.white : blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 18,
                color: Color(0xFFC9871A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Signed in as an agent",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              pill("Shop", Icons.shopping_bag_rounded, onSignIn, true),
              const SizedBox(width: 10),
              pill("Agent", Icons.arrow_back_rounded, onBack, false),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small white capsule: icon + text.
class _Capsule extends StatelessWidget {
  const _Capsule({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Colourful but calm: a blue-to-violet gradient pill.
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 4, right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E8BFF), Color(0xFF7B5CFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B6CFF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            maxLines: 1,
            style: ptstyle(size: 12, weight: 700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// "● 4 days owed" (red, pulsing, tap to pay) or "● On time" (green).
/// Hidden when there's no plan running.
class _StatusCapsule extends StatefulWidget {
  const _StatusCapsule({required this.p});
  final SharedProvider p;

  @override
  State<_StatusCapsule> createState() => _StatusCapsuleState();
}

class _StatusCapsuleState extends State<_StatusCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // Created up front so dispose never has to create it.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SharedProvider>(context);
    final plans = p.orders.where((o) => o.isRunningPlan).toList();
    if (plans.isEmpty) return const SizedBox.shrink();
    final standing = p.ordersStanding;
    var missed = standing?.totalMissedDays ?? 0;
    if (missed == 0) {
      for (final o in plans) {
        missed += o.standing?.missedDays ?? 0;
      }
    }
    final behind = missed > 0 || plans.any((o) => o.hasMissedPayment);
    final color = behind ? const Color(0xFFE5484D) : const Color(0xFF30A14E);
    final label =
        behind
            ? (missed > 0
                ? "$missed day${missed == 1 ? "" : "s"} owed"
                : "Payment due")
            : "On time";
    return GestureDetector(
      onTap: behind ? () => QuickPayButton.open(context) : null,
      child: Container(
        height: 30,
        padding: const EdgeInsets.only(left: 8, right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: AnimatedBuilder(
                animation: _pulse,
                builder:
                    (_, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        if (behind)
                          Container(
                            width: 6 + 8 * _pulse.value,
                            height: 6 + 8 * _pulse.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.4 * (1 - _pulse.value)),
                            ),
                          ),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: ptstyle(size: 12, weight: 700, color: color),
            ),
            if (behind) ...[
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 15, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

/// Our own hero slides made from phone.png: a slow zoom and drift (so
/// the picture is never still) with a different line on each slide.
class _BrandSlide extends StatefulWidget {
  const _BrandSlide({required this.index});
  final int index;

  static const count = 2;
  static const _copy = [
    ("Get the phone you want today.", "Small down payment, then a little every day."),
    ("Top brands. Trusted shops.", "Samsung, Tecno, Infinix, Redmi and more."),
  ];
  static const _focus = [Alignment(-0.2, -0.35), Alignment(0.3, 0.25)];

  @override
  State<_BrandSlide> createState() => _BrandSlideState();
}

class _BrandSlideState extends State<_BrandSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.index % _BrandSlide.count;
    final copy = _BrandSlide._copy[i];
    final focus = _BrandSlide._focus[i];
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.white),
          AnimatedBuilder(
            animation: _drift,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(_drift.value);
              return Transform.scale(
                scale: 1.15 + 0.12 * t,
                alignment: focus,
                child: Transform.translate(
                  offset: Offset((i == 0 ? -1 : 1) * 14 * t, -6 * t),
                  child: child,
                ),
              );
            },
            child: Image.asset(
              AssetsHelper.phonesIMG,
              fit: BoxFit.cover,
              alignment: focus,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.25, 0.65, 1],
                colors: [
                  Colors.transparent,
                  Color(0x88000000),
                  Color(0xE6000000),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.$1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(
                    size: 19,
                    weight: 700,
                    color: Colors.white,
                  ).copyWith(letterSpacing: -0.4),
                ),
                const SizedBox(height: 2),
                Text(
                  copy.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(size: 12, weight: 400, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
