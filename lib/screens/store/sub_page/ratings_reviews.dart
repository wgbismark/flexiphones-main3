import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/rating_list.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key, required this.reviews});
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        excludeHeaderSemantics: true,
        backgroundColor: ch.surface,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: Text(
          'Revives & Ratings ',
          style: ptstyle(size: 15, weight: 400),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildSummaryCard(ch, reviews),
                SizedBox(width: 10),
                Expanded(child: _buildRatingDistribution(ch, reviews)),
              ],
            ),
          ),

          SDivider(),
          ReviewList(reviews: reviews),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme ch, List<Review> reviews) {
    int total = reviews.length;
    int totalRatingValue =
        total == 0 ? 0 : reviews.fold(0, (sum, review) => sum + review.rating);
    double averageRating = total == 0 ? 0.0 : totalRatingValue / total;

    return Container(
      width: 120,

      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: ch.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: ptstyle(size: 42, weight: 600),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    if (index < averageRating.floor()) {
                      // Full star
                      return Icon(
                        Icons.star,
                        color: Colors.orangeAccent,
                        size: 18,
                      );
                    } else if (index < averageRating &&
                        averageRating - index >= 0.5) {
                      // Half star
                      return Icon(
                        Icons.star_half,
                        color: Colors.orangeAccent,
                        size: 18,
                      );
                    } else {
                      // Empty star
                      return Icon(
                        Icons.star_border,
                        color: Colors.orangeAccent,
                        size: 18,
                      );
                    }
                  }),
                ),
              ),
              Text(
                '$total REVIEWS',
                style: ptstyle(
                  size: 12,
                  weight: 400,
                  color: ch.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(ColorScheme ch, List rating) {
    int total = reviews.length;
    int oneReviewsCalc =
        total == 0
            ? 0
            : ((reviews.where((x) => x.rating == 1).length / total) * 100)
                .toInt();
    int twoReviewsCalc =
        total == 0
            ? 0
            : ((reviews.where((x) => x.rating == 2).length / total) * 100)
                .toInt();

    int threeReviewsCalc =
        total == 0
            ? 0
            : ((reviews.where((x) => x.rating == 3).length / total) * 100)
                .toInt();

    int fourReviewsCalc =
        total == 0
            ? 0
            : ((reviews.where((x) => x.rating == 4).length / total) * 100)
                .toInt();

    int fiveReviewsCalc =
        total == 0
            ? 0
            : ((reviews.where((x) => x.rating == 5).length / total) * 100)
                .toInt();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildRatingBar('5', fiveReviewsCalc, ch),
          _buildRatingBar('4', fourReviewsCalc, ch),
          _buildRatingBar('3', threeReviewsCalc, ch),
          _buildRatingBar('2', twoReviewsCalc, ch),
          _buildRatingBar('1', oneReviewsCalc, ch),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String stars, int count, ColorScheme ch) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$stars ',
          style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
        ),
        Icon(Icons.star, color: Colors.orangeAccent, size: 15),
        Text(
          ' ($count)',
          style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
        ),
        SizedBox(width: 10),
        Expanded(
          child: StepProgressIndicator(
            totalSteps: 100,
            currentStep: count,
            size: 5,

            padding: 0,
            selectedColor: Colors.orangeAccent,
            unselectedColor: ch.surfaceContainerHigh,
            roundedEdges: Radius.circular(10),
          ),
        ),
      ],
    );
  }
}
