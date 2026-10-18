import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchP extends StatefulWidget {
  const SearchP({super.key});

  @override
  State<SearchP> createState() => _SearchPState();
}

class _SearchPState extends State<SearchP> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<SharedProvider>(context, listen: false).getRecentSearches();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);

    return Scaffold(
      // drawerScrimColor: ch.onSurface.withOpacity(0.1),

      // key: _scaffoldKey,
      // endDrawer: FilterDrawer(sfc: _scaffoldKey),
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   excludeHeaderSemantics: true,
      //   backgroundColor: ch.surface,
      //   elevation: 0,
      //   scrolledUnderElevation: 0,
      //   title: Text(
      //     "Search",
      //     style: ptstyle(size: 16, weight: 400, color: ch.onSurfaceVariant),
      //   ),
      //   centerTitle: true,
      //   actions: [Container()],
      // ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                // SizedBox(width: 5),
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: FilledInput(
                      label: "",
                      hintText: "Search...",
                      controller: sharedProvider.searchController,
                      suffixIcon:
                          sharedProvider.searchController.text.isNotEmpty
                              ? IconButton(
                                onPressed:
                                    () => setState(() {
                                      sharedProvider.search = false;
                                      sharedProvider.enableSearching();
                                      sharedProvider.clearSearchController();
                                    }),
                                icon: Icon(Icons.close_rounded),
                              )
                              : Icon(Icons.search),
                      onChange: (value) async {
                        sharedProvider.onUpdateSearch();
                        await sharedProvider.getFilteredProducts();
                      },
                    ),
                  ),
                ),
                //  SizedBox(width: 5),
                // SizedBox(
                //   height: 40,
                //   child: IconButton.filled(
                //     onPressed: () {
                //       _scaffoldKey.currentState!.openEndDrawer();
                //     },
                //     style: IconButton.styleFrom(
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadiusGeometry.circular(10),
                //       ),
                //     ),
                //     icon: Icon(
                //       Icons.filter_list,
                //       size: 20,
                //       color: ch.onPrimary,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          SizedBox(height: 10),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (sharedProvider.rMinController.text.isNotEmpty ||
                    sharedProvider.rMaxController.text.isNotEmpty)
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: IconButton(
                      style: IconButton.styleFrom(padding: EdgeInsets.all(1)),
                      onPressed:
                          () async => {
                            sharedProvider.rMinController.clear(),
                            sharedProvider.rMaxController.clear(),

                            await sharedProvider.getFilteredProducts(),
                          },
                      icon: Icon(Icons.refresh),
                    ),
                  ),
                if (sharedProvider.rMinController.text.isNotEmpty ||
                    sharedProvider.rMaxController.text.isNotEmpty)
                  SizedBox(width: 5),
                Expanded(
                  child: FilledInput(
                    label: "",
                    hintText: "Mini. Price",
                    controller: sharedProvider.rMinController,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    onChange:
                        (value) async =>
                            await sharedProvider.getFilteredProducts(),
                  ),
                ),

                SizedBox(width: 10),
                Text("-"),
                SizedBox(width: 10),
                Expanded(
                  child: FilledInput(
                    label: "",
                    hintText: "Max. Price",
                    controller: sharedProvider.rMaxController,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    onChange:
                        (value) async =>
                            await sharedProvider.getFilteredProducts(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          if (sharedProvider.searchController.text.isEmpty &&
              sharedProvider.recentSearches.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(
                    "Recent Searches",
                    style: ptstyle(
                      size: 12,
                      weight: 600,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
                ),

                SizedBox(
                  height: 45,
                  child: ListView(
                    padding: EdgeInsets.only(left: 10),
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var data in sharedProvider.recentSearches)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Chip(
                            label: InkWell(
                              onTap: () => {sharedProvider.setSearchText(data)},
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_outward_rounded, size: 10),
                                  SizedBox(width: 5),
                                  Text(
                                    data,
                                    style: ptstyle(size: 12, weight: 400),
                                  ),
                                ],
                              ),
                            ),
                            padding: EdgeInsets.all(5),
                            backgroundColor: ch.primaryFixed.withOpacity(0.5),
                            side: BorderSide.none,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: 5),
          if (sharedProvider.filteredProducts.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 30),
                    Icon(
                      Icons.error_outline_rounded,
                      color: ch.onSurfaceVariant.withOpacity(0.3),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Not Found!.",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 12,
                        weight: 600,
                        color: ch.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            // Same card as Home (it shows the shop too); the next page of
            // this search loads near the end.
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical &&
                    n.metrics.extentAfter < 500 &&
                    sharedProvider.searchNextCursor != null) {
                  sharedProvider.loadMoreSearch();
                }
                return false;
              },
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                gridDelegate: productGridDelegate,
                itemCount: sharedProvider.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product =
                      sharedProvider.filteredProducts[index].toProductModel();
                  return FadeSlideIn(
                    key: ValueKey("s-${product.id}"),
                    delay: Duration(milliseconds: 40 * (index % 6)),
                    child: ProductTile(
                      product: product,
                      isFavorite: sharedProvider.isFavorite(product.id),
                      onFavorite:
                          sharedProvider.userData == null
                              ? null
                              : () => sharedProvider.toggleFavorite(
                                context,
                                product,
                              ),
                      onTap: () {
                        sharedProvider.getProductDetails(product.id, context);
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
          ),
        ],
      ),
    );
  }
}
