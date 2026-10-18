import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/review_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF0071E3);
const _star = Color(0xFFFF9F0A);
const _red = Color(0xFFE5484D);
const _bg = Color(0xFFF2F4F7);

// ===========================================================================
// Summary block for the product and store pages
// ===========================================================================

/// Average, stars, count and the 5→1 bars, a peek at the newest reviews,
/// and the right button: Write a review / Your review / the reason why not.
/// Loads itself. Guests get a sign-in prompt (reviews need an account).
class ReviewsSummary extends StatefulWidget {
  const ReviewsSummary({
    super.key,
    required this.target,
    required this.targetId,
    required this.targetName,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final ReviewTarget target;
  final int targetId;
  final String targetName;
  final EdgeInsetsGeometry padding;

  @override
  State<ReviewsSummary> createState() => _ReviewsSummaryState();
}

class _ReviewsSummaryState extends State<ReviewsSummary> {
  ReviewsPage? _page;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReviewsSummary old) {
    super.didUpdateWidget(old);
    if (old.targetId != widget.targetId) _load();
  }

  Future<void> _load() async {
    final p = Provider.of<SharedProvider>(context, listen: false);
    if (p.userData == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final page = await p.fetchReviews(widget.target, widget.targetId);
    if (!mounted) return;
    setState(() {
      _page = page;
      _loading = false;
    });
  }

  Future<void> _openAll() async {
    await NavigationHelper.push(
      context,
      ReviewsScreen(
        target: widget.target,
        targetId: widget.targetId,
        targetName: widget.targetName,
      ),
    );
    if (mounted) _load();
  }

  Future<void> _write() async {
    final changed = await showReviewEditor(
      context,
      target: widget.target,
      targetId: widget.targetId,
      targetName: widget.targetName,
      existing: _page?.myReview,
    );
    if (changed && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context, listen: false);
    if (p.userData == null) {
      return Padding(
        padding: widget.padding,
        child: _Card(
          child: Row(
            children: [
              const Icon(Icons.reviews_outlined, color: _blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Sign in to read and write reviews.",
                  style: ptstyle(size: 13, weight: 500, color: ch.onSurface),
                ),
              ),
              TextButton(
                onPressed: () => NavigationHelper.push(context, const EmailSignin()),
                child: Text("Sign in", style: ptstyle(size: 13, weight: 700, color: _blue)),
              ),
            ],
          ),
        ),
      );
    }
    if (_loading && _page == null) {
      return Padding(
        padding: widget.padding,
        child: const _Card(
          child: SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    }
    final page = _page;
    if (page == null) {
      return Padding(
        padding: widget.padding,
        child: _Card(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Couldn't load reviews.",
                  style: ptstyle(size: 13, weight: 500, color: ch.onSurfaceVariant),
                ),
              ),
              TextButton(onPressed: _load, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _openAll,
            child: _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RatingHeader(page: page),
                  const SizedBox(height: 14),
                  _ActionArea(page: page, onWrite: _write, onOpenMine: _write),
                ],
              ),
            ),
          ),
          if (page.reviews.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.separated(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                itemCount: page.reviews.take(6).length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder:
                    (_, i) => GestureDetector(
                      onTap: _openAll,
                      child: SizedBox(
                        width: 260,
                        child: ReviewCard(review: page.reviews[i], compact: true),
                      ),
                    ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openAll,
              child: Text(
                page.totalReviews == 0
                    ? "Open reviews"
                    : "See all ${page.totalReviews} review${page.totalReviews == 1 ? "" : "s"}",
                style: ptstyle(size: 13, weight: 600, color: _blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Big average + stars + count on the left, the 5→1 bars on the right.
/// [onBar] makes the bars tappable (filter by stars).
class _RatingHeader extends StatelessWidget {
  const _RatingHeader({required this.page, this.onBar, this.selectedStars});
  final ReviewsPage page;
  final ValueChanged<int>? onBar;
  final int? selectedStars;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final total = page.breakdown.values.fold<int>(0, (s, v) => s + v);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          child: Column(
            children: [
              Text(
                page.totalReviews == 0 ? "–" : page.rating.toStringAsFixed(1),
                style: ptstyle(size: 40, weight: 800, color: ch.onSurface)
                    .copyWith(letterSpacing: -1.5, height: 1),
              ),
              const SizedBox(height: 4),
              Stars(rating: page.rating, size: 14),
              const SizedBox(height: 4),
              Text(
                "${page.totalReviews} review${page.totalReviews == 1 ? "" : "s"}",
                style: ptstyle(size: 11, weight: 500, color: ch.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              for (var s = 5; s >= 1; s--)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBar == null ? null : () => onBar!(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          child: Text(
                            "$s",
                            style: ptstyle(
                              size: 11,
                              weight: selectedStars == s ? 800 : 600,
                              color:
                                  selectedStars == s ? _blue : ch.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Icon(Icons.star_rounded, size: 11, color: _star),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: total == 0 ? 0 : (page.breakdown[s] ?? 0) / total,
                              ),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder:
                                  (_, v, _) => LinearProgressIndicator(
                                    value: v,
                                    minHeight: 7,
                                    color: selectedStars == s ? _blue : _star,
                                    backgroundColor: ch.onSurface.withOpacity(0.07),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 22,
                          child: Text(
                            "${page.breakdown[s] ?? 0}",
                            textAlign: TextAlign.right,
                            style: ptstyle(size: 10.5, weight: 500, color: ch.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Write / Your review / reason. Kept small so it fits the summary card.
class _ActionArea extends StatelessWidget {
  const _ActionArea({
    required this.page,
    required this.onWrite,
    required this.onOpenMine,
  });

  final ReviewsPage page;
  final VoidCallback onWrite;
  final VoidCallback onOpenMine;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    if (page.canReview) {
      return SizedBox(
        height: 46,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onWrite,
          icon: const Icon(Icons.rate_review_rounded, size: 18),
          label: Text("Write a review", style: ptstyle(size: 14, weight: 700)),
        ),
      );
    }
    if (page.myReview != null) {
      return GestureDetector(
        onTap: onOpenMine,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: _blue),
              const SizedBox(width: 8),
              Text("Your review  ", style: ptstyle(size: 13, weight: 700, color: ch.onSurface)),
              Stars(rating: page.myReview!.rating.toDouble(), size: 13),
              const Spacer(),
              Text("Edit", style: ptstyle(size: 13, weight: 700, color: _blue)),
            ],
          ),
        ),
      );
    }
    if ((page.reason ?? "").isNotEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: ch.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              page.reason!,
              style: ptstyle(size: 11.5, weight: 400, color: ch.onSurfaceVariant),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

// ===========================================================================
// Full reviews page
// ===========================================================================

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.target,
    required this.targetId,
    required this.targetName,
  });

  final ReviewTarget target;
  final int targetId;
  final String targetName;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  ReviewsPage? _summary; // first page (carries viewer + breakdown)
  final List<ReviewItem> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  int? _stars;
  String _sort = "newest";
  bool _withComment = false;

  SharedProvider get _p => Provider.of<SharedProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final page = await _p.fetchReviews(
      widget.target,
      widget.targetId,
      stars: _stars,
      sort: _sort,
      withComment: _withComment,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (page != null) {
        _summary = page;
        _items
          ..clear()
          ..addAll(page.reviews.where((r) => !r.isMine));
        _cursor = page.nextCursor;
      }
    });
  }

  Future<void> _more() async {
    if (_cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    final page = await _p.fetchReviews(
      widget.target,
      widget.targetId,
      stars: _stars,
      sort: _sort,
      withComment: _withComment,
      cursor: _cursor,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page != null) {
        final have = _items.map((e) => e.id).toSet();
        _items.addAll(page.reviews.where((r) => !r.isMine && !have.contains(r.id)));
        _cursor = page.nextCursor;
      }
    });
  }

  Future<void> _edit() async {
    final changed = await showReviewEditor(
      context,
      target: widget.target,
      targetId: widget.targetId,
      targetName: widget.targetName,
      existing: _summary?.myReview,
    );
    if (changed && mounted) _load();
  }

  Future<void> _delete(ReviewItem r) async {
    final ok = await confirmDeleteReview(context);
    if (!ok || !mounted) return;
    final err = await _p.deleteReview(r.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(err ?? "Your review was deleted."),
      ),
    );
    if (err == null) _load();
  }

  void _setFilter({int? stars, String? sort, bool? withComment, bool clearStars = false}) {
    HapticFeedback.selectionClick();
    setState(() {
      if (clearStars) _stars = null;
      if (stars != null) _stars = _stars == stars ? null : stars;
      if (sort != null) _sort = sort;
      if (withComment != null) _withComment = withComment;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final s = _summary;
    final mine = s?.myReview;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Reviews",
          style: ptstyle(size: 16, weight: 700, color: ch.onSurface),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 400) _more();
            return false;
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Text(
                  widget.targetName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(size: 24, weight: 800, color: ch.onSurface)
                      .copyWith(letterSpacing: -0.7),
                ),
              ),
              if (s != null)
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RatingHeader(
                        page: s,
                        selectedStars: _stars,
                        onBar: (stars) => _setFilter(stars: stars),
                      ),
                      if (s.canReview) ...[
                        const SizedBox(height: 14),
                        _ActionArea(page: s, onWrite: _edit, onOpenMine: _edit),
                      ] else if (mine == null && (s.reason ?? "").isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ActionArea(page: s, onWrite: _edit, onOpenMine: _edit),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              // Sort / filter row
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_stars != null)
                      _FilterChip(
                        label: "$_stars★ only  ✕",
                        selected: true,
                        onTap: () => _setFilter(clearStars: true),
                      ),
                    for (final (key, label) in const [
                      ("newest", "Newest"),
                      ("highest", "Highest"),
                      ("lowest", "Lowest"),
                      ("oldest", "Oldest"),
                    ])
                      _FilterChip(
                        label: label,
                        selected: _sort == key,
                        onTap: () => _setFilter(sort: key),
                      ),
                    _FilterChip(
                      label: "With comments",
                      selected: _withComment,
                      onTap: () => _setFilter(withComment: !_withComment),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (mine != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    "YOUR REVIEW",
                    style: ptstyle(size: 11, weight: 700, color: ch.onSurfaceVariant)
                        .copyWith(letterSpacing: 1.2),
                  ),
                ),
                ReviewCard(
                  review: mine,
                  highlight: true,
                  onEdit: _edit,
                  onDelete: () => _delete(mine),
                ),
                const SizedBox(height: 18),
              ],
              if (_loading && _items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_items.isEmpty)
                _Card(
                  child: Column(
                    children: [
                      const Icon(Icons.reviews_rounded, size: 38, color: _star),
                      const SizedBox(height: 8),
                      Text(
                        _stars != null || _withComment
                            ? "No reviews match this filter."
                            : "No reviews yet.",
                        style: ptstyle(size: 15, weight: 700, color: ch.onSurface),
                      ),
                      if (s?.canReview ?? false)
                        Text(
                          "Be the first to review.",
                          style: ptstyle(size: 12.5, weight: 400, color: ch.onSurfaceVariant),
                        ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FadeSlideIn(
                      key: ValueKey("rv-${_items[i].id}"),
                      delay: Duration(milliseconds: 30 * (i % 8)),
                      child: ReviewCard(review: _items[i]),
                    ),
                  ),
              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? ch.onSurface : ch.surface,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: ptstyle(
              size: 12.5,
              weight: selected ? 700 : 500,
              color: selected ? ch.surface : ch.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// One review
// ===========================================================================

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.compact = false,
    this.highlight = false,
    this.showTarget = false,
    this.onEdit,
    this.onDelete,
  });

  final ReviewItem review;

  /// For the horizontal preview: comment clipped, no reply box.
  final bool compact;
  final bool highlight;

  /// Show what was reviewed (My reviews).
  final bool showTarget;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final r = review;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ch.surface,
        borderRadius: BorderRadius.circular(20),
        border: highlight ? Border.all(color: _blue.withOpacity(0.5), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (showTarget) ...[
            Row(
              children: [
                Icon(
                  r.target == ReviewTarget.vendor
                      ? Icons.storefront_rounded
                      : Icons.phone_iphone_rounded,
                  size: 14,
                  color: _blue,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    r.targetName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ptstyle(size: 12, weight: 700, color: _blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _avatarColor(r.reviewerInitial).withOpacity(0.15),
                child: Text(
                  r.reviewerInitial,
                  style: ptstyle(
                    size: 13,
                    weight: 800,
                    color: _avatarColor(r.reviewerInitial),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.isMine ? "${r.reviewerName} (you)" : r.reviewerName,
                      style: ptstyle(size: 13, weight: 700, color: ch.onSurface),
                    ),
                    Row(
                      children: [
                        Stars(rating: r.rating.toDouble(), size: 12.5),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            [
                              if (r.createdAt != null)
                                DateFormat("d MMM yyyy").format(r.createdAt!),
                              if (r.edited) "edited",
                            ].join(" · "),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ptstyle(size: 10.5, weight: 400, color: ch.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) => v == "edit" ? onEdit?.call() : onDelete?.call(),
                  itemBuilder:
                      (_) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: "edit",
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.edit_rounded),
                              title: Text("Edit"),
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: "delete",
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.delete_outline_rounded, color: _red),
                              title: Text("Delete", style: TextStyle(color: _red)),
                            ),
                          ),
                      ],
                ),
            ],
          ),
          if (r.comment != null) ...[
            const SizedBox(height: 10),
            compact
                ? Expanded(
                  child: Text(
                    r.comment!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: ptstyle(size: 13, weight: 400, color: ch.onSurface, height: 1.4),
                  ),
                )
                : Text(
                  r.comment!,
                  style: ptstyle(size: 13.5, weight: 400, color: ch.onSurface, height: 1.45),
                ),
          ] else if (compact)
            const Spacer(),
          if (r.reply != null && !compact) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
                border: const Border(left: BorderSide(color: _blue, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 14, color: _blue),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Reply from ${r.reply!.by}",
                          style: ptstyle(size: 12, weight: 700, color: ch.onSurface),
                        ),
                      ),
                      if (r.reply!.repliedAt != null)
                        Text(
                          DateFormat("d MMM").format(r.reply!.repliedAt!),
                          style: ptstyle(size: 10.5, weight: 400, color: ch.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.reply!.text,
                    style: ptstyle(size: 12.5, weight: 400, color: ch.onSurface, height: 1.4),
                  ),
                ],
              ),
            ),
          ] else if (r.reply != null && compact) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.reply_rounded, size: 13, color: _blue),
                const SizedBox(width: 4),
                Text(
                  "Shop replied",
                  style: ptstyle(size: 11, weight: 600, color: _blue),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _avatarColor(String initial) {
    const colors = [
      Color(0xFF0071E3),
      Color(0xFF8E5CFF),
      Color(0xFF30A14E),
      Color(0xFFFF6B00),
      Color(0xFFFF375F),
      Color(0xFF0A9396),
    ];
    return colors[(initial.isEmpty ? 0 : initial.codeUnitAt(0)) % colors.length];
  }
}

/// Five stars filled to [rating] (halves shown).
class Stars extends StatelessWidget {
  const Stars({super.key, required this.rating, this.size = 14});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: rating >= i - 0.5 ? _star : ch.onSurface.withOpacity(0.2),
          ),
      ],
    );
  }
}

// ===========================================================================
// Write / edit
// ===========================================================================

Future<bool> confirmDeleteReview(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Delete your review?"),
          content: const Text("This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Delete", style: TextStyle(color: _red)),
            ),
          ],
        ),
  );
  return ok == true;
}

/// Opens the review sheet. With [existing] it edits that review; without,
/// it posts a new one (a 409 switches to editing the customer's review).
/// Returns true when something was saved.
Future<bool> showReviewEditor(
  BuildContext context, {
  required ReviewTarget target,
  required int targetId,
  required String targetName,
  ReviewItem? existing,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => _ReviewEditor(
          target: target,
          targetId: targetId,
          targetName: targetName,
          existing: existing,
        ),
  );
  return saved == true;
}

class _ReviewEditor extends StatefulWidget {
  const _ReviewEditor({
    required this.target,
    required this.targetId,
    required this.targetName,
    this.existing,
  });

  final ReviewTarget target;
  final int targetId;
  final String targetName;
  final ReviewItem? existing;

  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _comment = TextEditingController(text: widget.existing?.comment ?? "");
  late ReviewItem? _editing = widget.existing;
  bool _busy = false;
  String? _error;

  static const _words = ["", "Terrible", "Poor", "Okay", "Good", "Excellent"];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = "Tap the stars to give a rating.");
      HapticFeedback.heavyImpact();
      return;
    }
    final p = Provider.of<SharedProvider>(context, listen: false);
    setState(() {
      _busy = true;
      _error = null;
    });
    final res =
        _editing != null
            ? await p.updateReview(_editing!.id, _rating, _comment.text)
            : await p.postReview(widget.target, widget.targetId, _rating, _comment.text);
    if (!mounted) return;
    setState(() => _busy = false);

    if (res.status == 200 || res.status == 201) {
      HapticFeedback.mediumImpact();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(res.message)),
      );
      return;
    }
    if (res.status == 409 && _editing == null) {
      // Already reviewed: load it and switch to editing.
      final page = await p.fetchReviews(widget.target, widget.targetId);
      if (!mounted) return;
      final mine = page?.myReview;
      setState(() {
        _error = res.message;
        if (mine != null) _editing = mine;
      });
      return;
    }
    setState(() => _error = res.message);
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final editing = _editing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        decoration: BoxDecoration(
          color: ch.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: ch.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                editing ? "Edit your review" : "Write a review",
                style: ptstyle(size: 22, weight: 800, color: ch.onSurface)
                    .copyWith(letterSpacing: -0.6),
              ),
              Text(
                widget.targetName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ptstyle(size: 13, weight: 500, color: ch.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _rating = i;
                          _error = null;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedScale(
                          scale: i == _rating ? 1.2 : 1,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 44,
                            color: i <= _rating ? _star : ch.onSurface.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _rating == 0 ? "Tap to rate" : _words[_rating],
                  key: ValueKey(_rating),
                  textAlign: TextAlign.center,
                  style: ptstyle(
                    size: 14,
                    weight: 700,
                    color: _rating == 0 ? ch.onSurfaceVariant : _star,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _comment,
                maxLength: 1000,
                maxLines: 5,
                minLines: 3,
                onChanged: (_) => setState(() {}),
                style: ptstyle(size: 14, weight: 400, color: ch.onSurface),
                decoration: InputDecoration(
                  hintText: "Tell others what you think (optional)",
                  hintStyle: ptstyle(size: 13.5, weight: 400, color: ch.onSurfaceVariant),
                  filled: true,
                  fillColor: ch.onSurface.withOpacity(0.04),
                  counterText: "${_comment.text.length} / 1000",
                  counterStyle: ptstyle(size: 11, weight: 500, color: ch.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: _red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: ptstyle(size: 12, weight: 500, color: _red),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _busy ? null : _submit,
                  child:
                      _busy
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                          : Text(
                            editing ? "Save changes" : "Post review",
                            style: ptstyle(size: 15.5, weight: 700),
                          ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Only your first name and initial are shown, like \"Ama M.\".",
                textAlign: TextAlign.center,
                style: ptstyle(size: 11, weight: 400, color: ch.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// My reviews (Profile)
// ===========================================================================

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key, this.highlightId});

  /// From a `review_reply` notification: scroll to and highlight it.
  final int? highlightId;

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final List<ReviewItem> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  final _keys = <int, GlobalKey>{};

  SharedProvider get _p => Provider.of<SharedProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final page = await _p.fetchMyReviews();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (page != null) {
        _items
          ..clear()
          ..addAll(page.reviews);
        _cursor = page.nextCursor;
      }
    });
    final id = widget.highlightId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[id]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            alignment: 0.2,
          );
        }
      });
    }
  }

  Future<void> _more() async {
    if (_cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    final page = await _p.fetchMyReviews(cursor: _cursor);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page != null) {
        _items.addAll(page.reviews);
        _cursor = page.nextCursor;
      }
    });
  }

  Future<void> _edit(ReviewItem r) async {
    final changed = await showReviewEditor(
      context,
      target: r.target,
      targetId: r.targetId,
      targetName: r.targetName,
      existing: r,
    );
    if (changed && mounted) _load();
  }

  Future<void> _delete(ReviewItem r) async {
    if (!await confirmDeleteReview(context) || !mounted) return;
    final err = await _p.deleteReview(r.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(err ?? "Your review was deleted."),
      ),
    );
    if (err == null) _load();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 400) _more();
            return false;
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(
                  "My reviews",
                  style: ptstyle(size: 30, weight: 800, color: ch.onSurface)
                      .copyWith(letterSpacing: -1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Text(
                  "See shop replies, and edit or delete what you wrote.",
                  style: ptstyle(size: 13, weight: 400, color: ch.onSurfaceVariant),
                ),
              ),
              if (_loading && _items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_items.isEmpty)
                _Card(
                  child: Column(
                    children: [
                      const Icon(Icons.rate_review_rounded, size: 40, color: _star),
                      const SizedBox(height: 8),
                      Text(
                        "No reviews yet",
                        style: ptstyle(size: 16, weight: 700, color: ch.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "After you pay a down payment, you can review the phone and the shop.",
                        textAlign: TextAlign.center,
                        style: ptstyle(size: 12.5, weight: 400, color: ch.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                for (final r in _items)
                  Padding(
                    key: _keys.putIfAbsent(r.id, () => GlobalKey()),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReviewCard(
                      review: r,
                      showTarget: true,
                      highlight: r.id == widget.highlightId,
                      onEdit: () => _edit(r),
                      onDelete: () => _delete(r),
                    ),
                  ),
              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
