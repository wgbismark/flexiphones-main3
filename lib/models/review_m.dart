// Reviews of vendors and phones (GET /v1/get-vendor-reviews/{id},
// /v1/get-product-reviews/{id}, /v1/my-reviews).

enum ReviewTarget { vendor, product }

class ReviewItem {
  final int id;

  /// vendor | product
  final String type;
  final int targetId;
  final String targetName;
  final int rating;
  final String? comment;

  /// Short name only, e.g. "Ama M."; never a phone or email.
  final String reviewerName;
  final String reviewerInitial;
  final DateTime? createdAt;
  final bool edited;
  final ReviewReply? reply;
  final bool isMine;

  ReviewItem({
    required this.id,
    required this.type,
    required this.targetId,
    required this.targetName,
    required this.rating,
    this.comment,
    required this.reviewerName,
    required this.reviewerInitial,
    this.createdAt,
    required this.edited,
    this.reply,
    required this.isMine,
  });

  ReviewTarget get target =>
      type == "product" ? ReviewTarget.product : ReviewTarget.vendor;

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    final r = json['reviewer'] is Map ? json['reviewer'] as Map : const {};
    final name = r['name']?.toString() ?? "Customer";
    final comment = json['comment']?.toString();
    return ReviewItem(
      id: _i(json['id']),
      type: json['type']?.toString() ?? "vendor",
      targetId: _i(json['target_id']),
      targetName: json['target_name']?.toString() ?? "",
      rating: _i(json['rating']).clamp(0, 5),
      comment: (comment == null || comment.trim().isEmpty) ? null : comment,
      reviewerName: name,
      reviewerInitial:
          r['initial']?.toString() ??
          (name.isEmpty ? "?" : name[0].toUpperCase()),
      createdAt: DateTime.tryParse("${json['created_at'] ?? ''}")?.toLocal(),
      edited: json['edited'] == true,
      reply:
          json['reply'] is Map
              ? ReviewReply.fromJson(Map<String, dynamic>.from(json['reply']))
              : null,
      isMine: json['is_mine'] == true,
    );
  }
}

/// The vendor's one public answer under a review.
class ReviewReply {
  final String text;
  final DateTime? repliedAt;
  final String by;

  ReviewReply({required this.text, this.repliedAt, required this.by});

  factory ReviewReply.fromJson(Map<String, dynamic> json) => ReviewReply(
    text: json['text']?.toString() ?? "",
    repliedAt: DateTime.tryParse("${json['replied_at'] ?? ''}")?.toLocal(),
    by: json['by']?.toString() ?? "The shop",
  );
}

/// One page of a vendor's or phone's reviews, with the summary and what
/// the signed-in customer may do.
class ReviewsPage {
  final int totalReviews;
  final double rating;

  /// stars (1..5) -> count
  final Map<int, int> breakdown;
  final bool canReview;
  final String? reason;
  final ReviewItem? myReview;
  final List<ReviewItem> reviews;
  final String? nextCursor;

  ReviewsPage({
    required this.totalReviews,
    required this.rating,
    required this.breakdown,
    required this.canReview,
    this.reason,
    this.myReview,
    required this.reviews,
    this.nextCursor,
  });

  factory ReviewsPage.fromJson(Map<String, dynamic> json) {
    final b = json['breakdown'] is Map ? json['breakdown'] as Map : const {};
    final v = json['viewer'] is Map ? json['viewer'] as Map : const {};
    final page = json['reviews'] is Map ? json['reviews'] as Map : const {};
    return ReviewsPage(
      totalReviews: _i(json['total_reviews']),
      rating: double.tryParse("${json['rating'] ?? 0}") ?? 0,
      breakdown: {for (var s = 1; s <= 5; s++) s: _i(b["$s"])},
      canReview: v['can_review'] == true,
      reason: v['reason']?.toString(),
      myReview:
          v['my_review'] is Map
              ? ReviewItem.fromJson(Map<String, dynamic>.from(v['my_review']))
              : null,
      reviews: _items(page['data']),
      nextCursor: page['next_cursor']?.toString(),
    );
  }

  static List<ReviewItem> _items(dynamic list) =>
      (list is List ? list : const [])
          .whereType<Map>()
          .map((x) => ReviewItem.fromJson(Map<String, dynamic>.from(x)))
          .toList();
}

/// GET /v1/my-reviews page.
class MyReviewsPage {
  final List<ReviewItem> reviews;
  final String? nextCursor;

  MyReviewsPage({required this.reviews, this.nextCursor});

  factory MyReviewsPage.fromJson(dynamic json) {
    // Accept { reviews: {data, next_cursor} } or { data: [...], next_cursor }.
    final root = json is Map ? json : const {};
    final page =
        root['reviews'] is Map
            ? root['reviews'] as Map
            : root['data'] is Map
            ? root['data'] as Map
            : root;
    return MyReviewsPage(
      reviews: ReviewsPage._items(page['data']),
      nextCursor: page['next_cursor']?.toString(),
    );
  }
}

int _i(dynamic v) => v is int ? v : int.tryParse("${v ?? ''}") ?? 0;
