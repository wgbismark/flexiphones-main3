import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/orders/orders.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/rating_list.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class OrderRating extends StatefulWidget {
  const OrderRating({super.key});

  @override
  State<OrderRating> createState() => _OrderRatingState();
}

class _OrderRatingState extends State<OrderRating> {
  int rate = 3;

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          excludeHeaderSemantics: true,
          backgroundColor: ch.surface,
          elevation: 0,
          scrolledUnderElevation: 0,

          surfaceTintColor: Colors.transparent,

          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 255, 123, 0).withOpacity(0.3),
                  const Color.fromARGB(255, 255, 123, 0).withOpacity(0.1),
                  const Color.fromARGB(255, 255, 123, 0).withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: Text(
            "Rate & Review",
            style: ptstyle(size: 16, weight: 400, color: ch.onSurfaceVariant),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 0),
          children: [
            OrderCard(item: sharedProvider.orderData!),
            SDivider(),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.deepOrangeAccent.withOpacity(0.1),
                ),
                child: Text(
                  "Rate ($rate/5)",
                  style: ptstyle(
                    size: 12,
                    weight: 600,
                    color: ch.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.deepOrangeAccent.withOpacity(0.05),
                ),
                child: RatingBar.builder(
                  initialRating: 3,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  glow: false,
                  itemSize: 30,

                  itemCount: 5,
                  itemPadding: EdgeInsets.symmetric(horizontal: 5),
                  itemBuilder:
                      (context, _) => Icon(
                        Icons.star,
                        color: Colors.deepOrangeAccent,
                        size: 20,
                      ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      rate = rating.toInt();
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: FilledInput(
                hintText: "Comment..",
                label: "",
                controller: sharedProvider.commentController,
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    onPressed: () => NavigationHelper.pop(context),
                    child: Text("Cancel"),
                  ),
                  SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 123, 0),
                    ),
                    onPressed:
                        () async =>
                            await sharedProvider.rateProduct(rate, context),
                    child: Text("Submit Review"),
                  ),
                ],
              ),
            ),

            SizedBox(
              child:
                  sharedProvider.loadingProduct
                      ? PDShimmerV(ch: ch)
                      : sharedProvider.productData!.reviews!.isEmpty
                      ? SizedBox(
                        child: Column(
                          children: [
                            SizedBox(height: 50),
                            Icon(
                              Icons.line_weight_sharp,
                              size: 50,
                              color: ch.primaryFixed.withOpacity(0.9),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "No Reviews Yet!...",
                              style: ptstyle(
                                size: 15,
                                weight: 500,
                                color: ch.primary.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ReviewList(
                          reviews: sharedProvider.productData!.reviews!,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class PDShimmerV extends StatelessWidget {
  const PDShimmerV({super.key, required this.ch});

  final ColorScheme ch;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: Duration(milliseconds: 500),
      baseColor: ch.primaryFixed.withOpacity(0.1),
      highlightColor: ch.primaryFixed.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Column(
          children: [
            // Specifications (3-4 lines)
            Column(
              children: List.generate(
                20,
                (index) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
