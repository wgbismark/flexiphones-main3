import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/snackbar_helper.dart';
import 'package:flexiphones/models/packages.dart';
import 'package:flexiphones/models/price_model.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/missed_payment_guard.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_storage_card.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderConfirmation extends StatefulWidget {
  final List items;

  const OrderConfirmation({super.key, required this.items});

  @override
  OrderConfirmationState createState() => OrderConfirmationState();
}

class OrderConfirmationState extends State<OrderConfirmation> {
  final String _currentLocation = '';
  double delivery = 6;

  final String _deliveryMethod = 'delivery';

  int get totalQuantity {
    int total = 0;
    for (var item in widget.items) {
      total += item["quantity"] as int;
    }
    return total;
  }

  Future<void> _submitOrder(SharedProvider sharedProvider) async {
    var products =
        widget.items
            .map(
              (x) => {
                'product_id': x['id'],
                // Null-aware: a cart item without storage info used to throw
                // here before any request was made.
                'product_storage_id': x['product_storages']?["id"],
                "device_type": "smartphone",
                "service_tenure": x["service_tenure"].toString(),
                'quantity': x['quantity'],
                "color": x["color"],
                "package_id": x["package_id"],
              },
            )
            .toList();

    // DEBUG: confirm every selected item made it into the payload,
    // especially for multi-device orders.
    debugPrint("=== [placeOrder] DEBUG ===");
    debugPrint("widget.items.length: ${widget.items.length}");
    debugPrint("products.length: ${products.length}");
    for (var i = 0; i < products.length; i++) {
      debugPrint("Product[$i]: ${products[i]}");
    }
    debugPrint("===========================");

    if (products.any((p) => p['product_storage_id'] == null)) {
      debugPrint("!!! [placeOrder] item(s) missing product_storage_id");
      if (!mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Storage Not Selected",
        message: "Remove the item and add it again with a storage option",
      );
      return;
    }

    // Customers who never saved an address have a null address; the
    // old `address!` crashed here. Orders are pickup, so send it empty.
    final location =
        _currentLocation.isNotEmpty
            ? _currentLocation
            : (sharedProvider.userData?.data.address ?? "");

    if (!mounted) return;

    // Behind on a running plan? No new phones until they catch up.
    if (!await ensureNoMissedPayments(context) || !mounted) return;

    await sharedProvider.addOrder(
      products,
      location,
      _deliveryMethod == "pickup",
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;

    final sharedProvider = Provider.of<SharedProvider>(context);

    void placeOrder() async {
      // Anything thrown here used to escape silently, so tapping
      // "Place Order" looked like it did nothing.
      try {
        await _submitOrder(sharedProvider);
      } catch (e, st) {
        debugPrint("!!! [placeOrder] ERROR: $e\n$st");
        if (!mounted) return;
        SnackbarHelper.danger(
          context: context,
          title: "Failed To Create Order",
          message: "Something went wrong preparing your order. Please try again.",
        );
      }
    }

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
        title: Text('Confirm Order', style: ptstyle(size: 13, weight: 400)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => SDivider(),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    decoration: BoxDecoration(
                      color: ch.surface,
                      border: Border.all(
                        color: ch.onSurfaceVariant.withOpacity(0.1),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.network(
                                  item["image"],

                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) => Opacity(
                                        opacity: 0.3,
                                        child: Image.asset(
                                          AssetsHelper.dummyImage,
                                          fit: BoxFit.contain,
                                          width: 80,
                                          height: 80,
                                        ),
                                      ),
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item["productName"]
                                          .toString()
                                          .toUpperCase(),
                                      softWrap: true,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: ptstyle(
                                        size: 18,
                                        weight: 600,
                                        color: ch.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: 5),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${item["service_tenure"]}',
                                          softWrap: true,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: ptstyle(
                                            size: 12,
                                            weight: 600,
                                            color: ch.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '  |  Months Service tenure',
                                          softWrap: true,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: ptstyle(
                                            size: 12,
                                            weight: 400,
                                            color: ch.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),

                                    Row(
                                      children: [
                                        Container(
                                          constraints: BoxConstraints(
                                            maxWidth: 100,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ch.surfaceContainerLowest,
                                            border: Border.all(
                                              color: ch.onSurfaceVariant
                                                  .withOpacity(0.2),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '${item["color"]}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: ptstyle(
                                              size: 12,
                                              weight: 400,
                                              color: ch.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        if (item["package_id"].runtimeType ==
                                            int) ...[
                                          SizedBox(width: 5),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(90),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AdaptiveTheme.of(
                                                        context,
                                                      ).mode.isDark
                                                      ? Color.fromARGB(
                                                        255,
                                                        17,
                                                        39,
                                                        59,
                                                      )
                                                      : Color.fromARGB(
                                                        255,
                                                        195,
                                                        220,
                                                        255,
                                                      ).withOpacity(
                                                        0.5,
                                                      ), // Blue
                                                  AdaptiveTheme.of(
                                                        context,
                                                      ).mode.isDark
                                                      ? Color.fromARGB(
                                                        255,
                                                        61,
                                                        29,
                                                        42,
                                                      )
                                                      : Color.fromARGB(
                                                        255,
                                                        255,
                                                        190,
                                                        190,
                                                      ).withOpacity(
                                                        0.5,
                                                      ), // Purple
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              "+ Bonus",
                                              style: ptstyle(
                                                size: 13,
                                                weight: 500,
                                                color: const Color.fromARGB(
                                                  255,
                                                  255,
                                                  4,
                                                  130,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SDivider(),
                        SizedBox(
                          child: StorageCard(
                            data: ProductStorage.fromJson(
                              item["product_storages"],
                            ),

                            enabled: false,
                            staticObj: false,
                            tn: item["service_tenure"],
                            colors: null,
                            selectTenure: (x) {},
                            cl: "",
                            selectColor: (x) {},
                            select: () {},
                            breakdowns: Breakdowns.fromJson(
                              item["breakdowns"],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,

                    child: SmartButton(
                      loading: sharedProvider.orderLoading,
                      enabled:
                          _deliveryMethod.isNotEmpty &&
                          widget.items.isNotEmpty &&
                          widget.items.every(
                            (item) => isFinanceable(
                              (item["breakdowns"] is Map
                                  ? item["breakdowns"]
                                  : const {})["${item["service_tenure"]}_months"],
                            ),
                          ),
                      onPressed: () => placeOrder(),
                      child: Text('Place Order'),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}