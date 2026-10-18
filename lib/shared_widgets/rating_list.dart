import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flutter/material.dart';

class ReviewList extends StatelessWidget {
  const ReviewList({super.key, required this.reviews});
  final List<Review> reviews;
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reviews',
                style: ptstyle(
                  size: 16,
                  weight: 600,
                  color: ch.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              Text(
                'Reviews are from valid purchased users',
                style: ptstyle(
                  size: 12,
                  weight: 400,
                  color: ch.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),

        SDivider(),
        if (reviews.isEmpty)
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.list,
                  size: 40,
                  color: ch.onSurface.withOpacity(0.2),
                ),
                Text(
                  "No Reviews Yet",
                  style: ptstyle(
                    size: 12,
                    weight: 600,
                    color: ch.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        for (var review in reviews)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _buildReviewCard(
                  name:
                      review.customer?.name ??
                      "User**${review.createdAt.hashCode}",
                  date: review.createdAt.formatDate(),
                  rating: review.rating,
                  comment: review.comment,
                  ch: ch,
                ),
              ),
              SDivider(),
            ],
          ),
      ],
    );
  }
}

Widget _buildReviewCard({
  required String name,
  required String date,
  required int rating,
  required String comment,
  required ColorScheme ch,
}) {
  return Container(
    width: double.infinity,

    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.toUpperCase(),
          style: ptstyle(size: 12, weight: 600, color: ch.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              child: Text(
                comment,

                style: ptstyle(
                  size: 15,
                  weight: 400,
                  color: ch.onSurfaceVariant,
                ),
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
                          i < rating
                              ? Colors.deepOrangeAccent
                              : ch.onSurfaceVariant.withOpacity(0.5),
                      size: 15,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          date,
          style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
        ),
      ],
    ),
  );
}
