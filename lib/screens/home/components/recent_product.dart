import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class RecentlyViewedList extends StatelessWidget {
  const RecentlyViewedList({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    var ch = Theme.of(context).colorScheme;
    return  sharedProvider.recentlyViewedProducts.isEmpty ? SizedBox() : Container(
      height: 200,
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Recently Viewed',
              style: ptstyle(
                size: 15.0,
                weight: 400,
                color: ch.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: 5),
          SizedBox(
            height: 130,
            child:
                sharedProvider.recentlyViewedProducts.isEmpty
                    ? ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 10),
                      children: List.generate(10, (index) => PDShimmer(ch: ch)),
                    )
                    : ListView.separated(
                      padding: EdgeInsets.only(left: 10),
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (context, index) => SizedBox(width: 5),
                      itemCount: sharedProvider.recentlyViewedProducts.length,
                      itemBuilder: (context, index) {
                        final product =
                            sharedProvider.recentlyViewedProducts[index];
                        return RecentProductCard(
                          p: product,

                          onPressed: () async {
                            sharedProvider.getProductDetails(
                              product.id,
                              context,
                            );
                            NavigationHelper.push(
                              context,
                              ProductDetailsPage(productId: product.id),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// Product card widget
class RecentProductCard extends StatelessWidget {
  final ProductModel p;
  final VoidCallback onPressed;

  const RecentProductCard({
    super.key,

    required this.onPressed,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    var imG =
        "${p.image.split("/assets/images/").first}/assets/images/${p.image.split("/assets/images/").last}";
 
    //print(imG);
    var ch = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      child: SizedBox(
        width: 95,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color:
                  AdaptiveTheme.of(context).mode.isDark
                      ? ch.primaryFixed.withOpacity(0.3)
                      : ch.primaryFixed.withOpacity(0.2),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Image.network(
                  imG,
                  height: 70,
                  width: 70,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => Opacity(
                        opacity:
                            AdaptiveTheme.of(context).mode.isDark ? 0.2 : 0.6,
                        child: Image.asset(
                          AssetsHelper.dummyImage,
                          fit: BoxFit.contain,
                          height: 70,
                          width: 70,
                        ),
                      ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              p.fullName.toUpperCase(),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: ptstyle(size: 12, weight: 500, color: ch.onSurfaceVariant),
            ),

            Text(
              p.addedAt!.toAgo(),
              softWrap: true,
              overflow: TextOverflow.ellipsis,

              style: ptstyle(size: 10, weight: 400, color: ch.primary),
            ),
          ],
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
    return Container(
      width: 80,
      margin: EdgeInsets.only(right: 10),
      child: Shimmer.fromColors(
        period: Duration(milliseconds: 1000),
        baseColor: ch.primaryFixed.withOpacity(0.1),
        highlightColor: ch.primaryFixed.withOpacity(0.3),
        child: Column(
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
            Container(height: 10, width: double.infinity, color: Colors.white),
            const SizedBox(height: 10),
            Container(height: 10, width: double.infinity, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
