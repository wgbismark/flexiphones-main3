import 'package:flexiphones/extensions/ui_values.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/screens/profile/vendor_ad.dart';
import 'package:flexiphones/screens/store/store.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/loadingList.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flexiphones/shared_widgets/store_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:animation_list/animation_list.dart';

class Browse extends StatefulWidget {
  const Browse({super.key});

  @override
  State<Browse> createState() => _BrowseState();
}

@override
class _BrowseState extends State<Browse> with SingleTickerProviderStateMixin {
  TabController? tabController;
  @override
  void initState() {
    tabController = TabController(initialIndex: 0, length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    var ch = Theme.of(context).colorScheme;
    return Scaffold(
      appBar:
          sharedProvider.userData == null
              ? null
              : AppBar(
                toolbarHeight: 40,
                leadingWidth: 80.w,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Text(
                          'Devices',
                          style: ptstyle(size: 12, weight: 400),
                        ),
                      ),

                      Tab(
                        child: Text(
                          'Vendors',
                          style: ptstyle(size: 12, weight: 400),
                        ),
                      ),
                    ],
                    controller: tabController,
                  ),
                ),
              ),
      bottomNavigationBar:
          sharedProvider.refreshing_ ? LoadingListIndicator() : null,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child:
                sharedProvider.products.isEmpty ||
                        (sharedProvider.vendors.isEmpty &&
                            sharedProvider.userData != null)
                    ? Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ListView(
                        children: List.generate(
                          10,
                          (index) => PDShimmer(ch: ch),
                        ),
                      ),
                    )
                    : TabBarView(
                      controller: tabController,
                      physics:
                          sharedProvider.userData == null
                              ? const NeverScrollableScrollPhysics()
                              : null,

                      children: [
                        // Same card as Home; loads the next page near the end.
                        NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.axis == Axis.vertical &&
                                n.metrics.extentAfter < 500 &&
                                sharedProvider.pNextPAGE != null &&
                                !sharedProvider.loadingProducts) {
                              sharedProvider.getProducts(
                                context,
                                refresh: false,
                                next: true,
                              );
                            }
                            return false;
                          },
                          child: GridView.builder(
                            controller: sharedProvider.listScrollControllerP,
                            padding: EdgeInsets.fromLTRB(
                              6,
                              sharedProvider.userData == null ? 10 : 16,
                              6,
                              40,
                            ),
                            gridDelegate: productGridDelegate,
                            itemCount: sharedProvider.products.length,
                            itemBuilder: (context, index) {
                              final product = sharedProvider.products[index];
                              return FadeSlideIn(
                                key: ValueKey("b-${product.id}"),
                                delay: Duration(milliseconds: 40 * (index % 6)),
                                child: ProductTile(
                                  product: product,
                                  isFavorite: sharedProvider.isFavorite(
                                    product.id,
                                  ),
                                  onFavorite:
                                      sharedProvider.userData == null
                                          ? null
                                          : () => sharedProvider.toggleFavorite(
                                            context,
                                            product,
                                          ),
                                  onTap: () {
                                    sharedProvider.getProductDetails(
                                      product.id,
                                      context,
                                    );
                                    NavigationHelper.push(
                                      context,
                                      ProductDetailsPage(productId: product.id),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        // Guests have no Vendors tab (and can.t swipe to it),
                        // but the controller still needs two pages.
                        AnimationList(
                            animationDirection: AnimationDirection.vertical,
                            duration: 200,
                            reBounceDepth: 0,
                            controller: sharedProvider.listScrollControllerV,
                            // children: (context, index) => SDivider(),
                            padding: EdgeInsets.only(top: 10),
                            //    itemCount: sharedProvider.vendors.length,
                            children: List.generate(
                              sharedProvider.vendors.length + 1,
                              (index) {
                                if (sharedProvider.vendors.length == index) {
                                  return Center(
                                    child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: IconButton.filledTonal(
                                        style: IconButton.styleFrom(
                                          backgroundColor: ch.primaryFixed
                                              .withOpacity(0.2),
                                          padding: EdgeInsets.all(0),
                                        ),
                                        onPressed:
                                            () => sharedProvider.moreData(
                                              type: RefreshParam.vendors,
                                              context: context,
                                              refresh: true,
                                            ),
                                        icon: Icon(
                                          Icons.refresh_rounded,
                                          size: 24,
                                          color: ch.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final store = sharedProvider.vendors[index];
                                return VisibilityDetector(
                                  onVisibilityChanged: (info) {
                                    if (index ==
                                            sharedProvider.vendors.length - 1 &&
                                        !sharedProvider.refreshing_) {
                                      sharedProvider.moreData(
                                        type: RefreshParam.vendors,
                                        context: context,
                                      );
                                    }
                                  },
                                  key: UniqueKey(),
                                  child: StoreCard(
                                    name: store.name,
                                    image: store.image ?? "",
                                    address: store.location,
                                    state: store.status,
                                    // FIX: closingTime is nullable (vendors may
                                    // not have set business hours yet — see
                                    // Vendor model). Use a null-aware call so
                                    // this no longer fails to compile, and
                                    // fall back to a placeholder when a vendor
                                    // has no closing time set.
                                    locations: store.branchCount + 1,
                                    closing:
                                        store.closingTime?.toAmPm() ?? "N/A",
                                    onPressed: () async {
                                      await sharedProvider.getVendorDetails(
                                        store.id,
                                      );
                                      NavigationHelper.push(
                                        context,
                                        StoreInfoPage(store_id: store.id),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
          ),

          AnimatedSwitcher(
            duration: Duration(milliseconds: 400),

            child:
                sharedProvider.adSeenThisWeek
                    ? SizedBox.shrink()
                    : VendorBanner(
                      title: 'Earn more as a FlexiPhones vendor',
                      subtitle:
                          'List your devices, offer flexible payment plans, and connect with buyers ready to purchase. Our platform helps vendors increase sales while keeping transactions simple.',
                      close: () async => await sharedProvider.markAdAsShown(),
                    ),
          ),
        ],
      ),
    );
  }
}

class PDShimmer extends StatelessWidget {
  const PDShimmer({super.key, required this.ch});

  final ColorScheme ch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Shimmer.fromColors(
            period: Duration(milliseconds: 1000),
            baseColor: ch.primaryFixed.withOpacity(0.1),
            highlightColor: ch.primaryFixed.withOpacity(0.3),
            child: Row(
              children: [
                // Image Placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 10),

                // Title + Price
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 10, width: 200, color: Colors.white),
                      const SizedBox(height: 10),
                      Container(height: 10, width: 150, color: Colors.white),

                      const SizedBox(height: 10),
                      Container(height: 10, width: 150, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SDivider(),
        ],
      ),
    );
  }
}