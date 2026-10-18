import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_card.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StoreListings extends StatelessWidget {
  const StoreListings({super.key});

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            children: [
              Text(
                "${sharedProvider.vendorData!.name}'s",
                style: ptstyle(
                  size: 15,
                  weight: 600,
                  color: ch.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              Text(
                ' listings',
                style: ptstyle(
                  size: 15,
                  weight: 600,
                  color: ch.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(),
            padding: EdgeInsets.only(top: 0),
            itemCount: sharedProvider.vendorData!.products.length,
            itemBuilder: (context, index) {
              final product = sharedProvider.vendorData!.products[index];

              return ProductCard(
                status: product.status,
                imageUrl: product.image,
                productName:
                    "${product.brand.toLowerCase()} ${product.model.toLowerCase()}",
                price: product.price,
                initialDeposit: 0.0,
                onPressed: () async {
                  sharedProvider.getProductDetails(product.id, context);
                  NavigationHelper.push(
                    context,
                    ProductDetailsPage(productId: product.id),
                  );
                },
                colors: product.colors,
                deviceSpecification: '',
              );
            },
          ),
        ),
      ],
    );
  }
}
