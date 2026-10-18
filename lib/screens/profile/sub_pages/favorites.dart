import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/neu.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// GET /v1/favorites — the phones the customer saved with the heart.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Provider.of<SharedProvider>(context, listen: false).getFavorites(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final list = p.favorites;

    return Scaffold(
      backgroundColor: Neu.bg(context),
      appBar: AppBar(
        backgroundColor: Neu.bg(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Favourites",
          style: ptstyle(size: 14, weight: 400, color: ch.onSurfaceVariant),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => p.getFavorites(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 400 &&
                p.favoritesNextCursor != null &&
                !p.loadingFavorites) {
              p.getFavorites(refresh: false);
            }
            return false;
          },
          child:
              list.isEmpty
                  ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      if (p.loadingFavorites)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 52,
                          color: ch.onSurfaceVariant.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No favourites yet",
                          textAlign: TextAlign.center,
                          style: ptstyle(
                            size: 17,
                            weight: 700,
                            color: ch.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap the heart on any phone to save it here.",
                          textAlign: TextAlign.center,
                          style: ptstyle(
                            size: 13,
                            weight: 400,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  )
                  : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.56,
                        ),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final x = list[i];
                      return ProductTile(
                        product: x,
                        isFavorite: p.isFavorite(x.id),
                        onFavorite: () => p.toggleFavorite(context, x),
                        onTap: () {
                          p.getProductDetails(x.id, context);
                          NavigationHelper.push(
                            context,
                            ProductDetailsPage(productId: x.id),
                          );
                        },
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
