import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/top_deals_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flexiphones/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Screen with Product List (using Map instead of model)
class TopDealsScreen extends StatelessWidget {
  const TopDealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);

    return SizedBox(
      child: Column(
        children: [
          SDivider(),
          CategoryHeader(
            title: 'Top Deals',
            onPressed: () => NavigationHelper.push(context, TopDealsPage()),
          ),
          for (var product in sharedProvider.topDeals.take(
            sharedProvider.recentlyViewedProducts.isEmpty ? 4 : 3,
          ))
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TopDealsProductCard(
                    onPressed: () async {
                      sharedProvider.getProductDetails(product.id, context);
                      NavigationHelper.push(
                        context,
                        ProductDetailsPage(productId: product.id),
                      );
                    },
                    deal: product, // You can customize this
                  ),
                ),
                SDivider(),
              ],
            ),
        ],
      ),
    );
  }
}
// Header Widget for Category

// Reusable Product Card Widget
class TopDealsProductCard extends StatelessWidget {
  final Deal deal;

  final VoidCallback onPressed;

  const TopDealsProductCard({
    super.key,
    e,

    required this.onPressed,
    required this.deal,
  });

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      splashColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              color:
                  AdaptiveTheme.of(context).mode.isDark
                      ? ch.primaryFixed.withOpacity(0.5)
                      : ch.primaryFixed.withOpacity(0.2),
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  deal.image,
                  width: 70,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Opacity(
                          opacity:
                              AdaptiveTheme.of(context).mode.isDark ? 0.2 : 0.6,
                          child: Image.asset(
                            AssetsHelper.dummyImage,
                            fit: BoxFit.contain,
                            width: 70,
                            height: 70,
                          ),
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${deal.brand.toLowerCase()} ${deal.model.toLowerCase()} "
                        .toUpperCase(),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: ptstyle(
                      size: 12,
                      weight: 600,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(maxWidth: 170),
                    child: Text(
                      deal.deviceSpecification,

                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: ptstyle(
                        size: 10,
                        weight: 400,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              deal.status.toLowerCase().contains("available")
                                  ? Colors.green.withOpacity(0.1)
                                  : ch.surfaceContainerLow,

                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          deal.status,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: ptstyle(
                            size: 10,
                            weight: 600,
                            color:
                                deal.status.toLowerCase().contains("available")
                                    ? Colors.green
                                    : ch.onSurfaceVariant,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 30,
                        child: FilledButton.tonal(
                          onPressed: onPressed,
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.transparent,
                            overlayColor: ch.primaryFixed.withOpacity(0.5),
                            backgroundColor: ch.primaryFixed.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(10),
                            ),
                          ),
                          child: Text(
                            'View',
                            style: ptstyle(size: 11, weight: 400),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Rate: ${double.parse(deal.rating).toStringAsFixed(1)} ',
                        style: ptstyle(
                          size: 10,
                          weight: 300,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.deepOrangeAccent.withOpacity(0.05),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < 5; i++)
                              Icon(
                                Icons.star,
                                color:
                                    i < double.parse(deal.rating)
                                        ? Colors.deepOrangeAccent
                                        : ch.onSurfaceVariant.withOpacity(0.5),
                                size: 15,
                              ),
                          ],
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

class CategoryHeader extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const CategoryHeader({
    super.key,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: ptstyle(size: 15.0, weight: 400, color: ch.onSurfaceVariant),
          ),
          SizedBox(
            height: 40,
            child: TextButton.icon(
              onPressed: onPressed,
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.blue,
              ),
              iconAlignment: IconAlignment.end,
              label: Text(
                'See all',
                style: ptstyle(
                  size: 12,
                  weight: 300,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopDealsPage extends StatefulWidget {
  const TopDealsPage({super.key});

  @override
  State<TopDealsPage> createState() => _TopDealsPageState();
}

class _TopDealsPageState extends State<TopDealsPage> {
  final List<String> categories = ["All", "Samsung", "Itel", "Tecno"];

  List<Deal> tpDeals = [];
  int catSw = 0;

  List<Deal> get samsung =>
      tpDeals
          .where(
            (x) =>
                x.model.toString().toLowerCase().contains("samsung") ||
                x.brand.toString().toLowerCase().contains("samsung"),
          )
          .toList();

  List<Deal> get itel =>
      tpDeals
          .where(
            (x) =>
                x.model.toString().toLowerCase().contains("itel") |
                x.brand.toString().toLowerCase().contains("itel"),
          )
          .toList();

  List<Deal> get tecno =>
      tpDeals
          .where(
            (x) =>
                x.model.toString().toLowerCase().contains("tecno") ||
                x.brand.toString().toLowerCase().contains("tecno"),
          )
          .toList();

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    tpDeals = sharedProvider.topDeals;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ch.primaryFixed.withOpacity(0.5),
                ch.primaryFixed.withOpacity(0.2),
                ch.primaryFixed.withOpacity(0.05),
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

        title: Text("Top Deals", style: ptstyle(size: 15, weight: 400)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            // Categories
            SizedBox(
              height: 40,
              child: ListView.separated(
                separatorBuilder: (context, index) => SizedBox(width: 10),
                padding: EdgeInsets.all(5),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder:
                    (context, index) => buildCategoryChip(
                      categories[index],
                      () {
                        setState(() {
                          catSw = index;
                        });
                      },
                      catSw == index,
                      ch,
                    ),
              ),
            ),
            SizedBox(height: 20),
            // Deals Grid
            Expanded(
              child:
                  (catSw == 0
                              ? sharedProvider.topDeals
                              : catSw == 1
                              ? samsung
                              : catSw == 2
                              ? itel
                              : tecno)
                          .isEmpty
                      ? SizedBox(
                        child: Column(
                          children: [
                            Icon(
                              Icons.list_rounded,
                              size: 80,
                              color: ch.primaryFixed.withOpacity(0.5),
                            ),
                            Text(
                              "No  Deals",
                              style: ptstyle(
                                size: 20,
                                weight: 600,
                                color: ch.primaryFixed,
                              ),
                            ),
                          ],
                        ),
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 40),
                        gridDelegate: productGridDelegate,
                        itemCount:
                            (catSw == 0
                                    ? sharedProvider.topDeals
                                    : catSw == 1
                                    ? samsung
                                    : catSw == 2
                                    ? itel
                                    : tecno)
                                .length,
                        itemBuilder: (context, index) {
                          final product =
                              (catSw == 0
                                  ? sharedProvider.topDeals
                                  : catSw == 1
                                  ? samsung
                                  : catSw == 2
                                  ? itel
                                  : tecno)[index];
                          final model = product.toProductModel();
                          return ProductTile(
                            product: model,
                            isFavorite: sharedProvider.isFavorite(model.id),
                            onFavorite:
                                sharedProvider.userData == null
                                    ? null
                                    : () => sharedProvider.toggleFavorite(
                                      context,
                                      model,
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
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryChip(
    String category,
    VoidCallback onPressed,
    bool active,
    ColorScheme ch,
  ) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor:
            active ? ch.primaryFixed : ch.primaryFixed.withOpacity(0.2),
        shadowColor: Colors.transparent,
      ),
      onPressed: onPressed,
      child: Text(
        category,
        style: ptstyle(size: 12, weight: active ? 600 : 400, color: ch.primary),
      ),
    );
  }

  // Widget buildDealCard(Deal deal) {
  //   return Card(
  //     color: ,
  //     elevation: 8,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //     margin: EdgeInsets.all(8),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Stack(
  //           children: [
  //             ClipRRect(
  //               borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
  //               child: Image.network(
  //                 deal.,
  //                 height: 150,
  //                 width: double.infinity,
  //                 fit: BoxFit.cover,
  //               ),
  //             ),
  //             Positioned(
  //               top: 8,
  //               right: 8,
  //               child: Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //                 child: Text(
  //                   "${deal['discount']}% OFF",
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.all(12.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 deal['title'],
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //               SizedBox(height: 4),
  //               Text(
  //                 "\$${deal['originalPrice']}",
  //                 style: TextStyle(
  //                   decoration: TextDecoration.lineThrough,
  //                   color: Colors.grey,
  //                 ),
  //               ),
  //               Text(
  //                 "\$${deal['discountedPrice']}",
  //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //               ),
  //               Align(
  //                 alignment: Alignment.centerRight,
  //                 child: ElevatedButton.icon(
  //                   onPressed: () {},
  //                   icon: Icon(Icons.add_shopping_cart, size: 16),
  //                   label: Text("Cart"),
  //                   style: ElevatedButton.styleFrom(
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(20),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
