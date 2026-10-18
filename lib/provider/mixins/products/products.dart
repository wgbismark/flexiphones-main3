// ignore_for_file: use_build_context_synchronously

import 'package:flexiphones/helpers/app_update.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/helpers/snackbar_helper.dart';
import 'package:flexiphones/models/hot_sales.dart';
import 'package:flexiphones/models/notifications_m.dart';
import 'package:flexiphones/models/order_m.dart';
import 'package:flexiphones/models/packages.dart';
import 'package:flexiphones/models/price_model.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/models/review_m.dart';
import 'package:flexiphones/models/top_deals_m.dart';
import 'package:flexiphones/models/user_m.dart';
import 'package:flexiphones/models/vendors.dart';
import 'package:flexiphones/screens/init_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin Products on ChangeNotifier {
  /// Every request carries the app version, platform and device id;
  /// an HTTP 426 anywhere opens the Update screen.
  Dio dio = Dio()..interceptors.add(AppHeadersInterceptor());
  LoginResponse? userData;
  Order? orderData;
  Package? orderDataPackages;
  BreakdownResponse? breakDownPrice;
  ProductStorage? selectedStorage;
  List<ProductModel> products = [];
  List<ProductModel> recentlyViewedProducts = [];

  List<Vendor> vendors = [];
  List<Deal> topDeals = [];
  List<HotDeal> hotDeals = [];

  List<NotificationData> notifications = [];

  /// `unread_count` from GET /notifications — covers every page, not just
  /// the loaded one. Null until the server sends it.
  int? unreadCount;

  /// Count for the bell badge.
  int get unreadBadge => unreadCount ?? unreadNTF.length;

  List<NotificationData> get unreadNTF => notifications
      .where((element) => element.isUnread)
      .toList();
  List<NotificationData> get readNTF => notifications
      .where((element) => !element.isUnread)
      .toList();

  ProductModel? productData;
  Package? productDataPackages;
  VendorDetails? vendorData;
  bool productsVariations = false;
  bool loadingProduct = true;
  bool loadingVendor = false;
  bool loadingPBD = false;
  int slTenure = 3;

  /// Surfaced to the UI so a genuinely failed fetch can show something
  /// other than an endless shimmer.
  String? productDetailsError;

  String? pNextPAGE;
  String? vNextPAGE;
  String? tdNextPAGE;
  String? pPrevPAGE;
  String? vPrevPAGE;
  String? tdPrevPAGE;

  var commentController = TextEditingController();

  String colorSL = "";
  void selectColor(String t) {
    colorSL = t;
    notifyListeners();
  }

  void selectTenure(int t) {
    slTenure = t;
    notifyListeners();
  }

  void selectStorage(ProductStorage stg) async {
    await getProductPB(stg.id);
    selectedStorage = stg;
    notifyListeners();
  }

  void togglePV() {
    productsVariations = !productsVariations;
  }

  // ------------------------------------------------------------------
  // Product list filters. GET /v1/products (guest), /v1/get-products
  // (signed in) and /v1/search share them; the server orders
  // "recommended" itself, so the app never re-sorts.
  // ------------------------------------------------------------------
  ProductSort productSort = ProductSort.recommended;
  Set<String> brandFilter = {};
  bool loadingProducts = false;

  /// The filters the current cursor belongs to (sent again with it).
  Map<String, String> productListParams = {};

  Map<String, String> productQuery() => {
    if (productSort != ProductSort.recommended) 'sort': productSort.value,
    if (brandFilter.isNotEmpty) 'brand': brandFilter.join(","),
    'per_page': '20',
  };

  Future<void> setProductSort(BuildContext context, ProductSort sort) async {
    if (sort == productSort) return;
    productSort = sort;
    await getProducts(context, refresh: true, next: false);
  }

  /// One brand at a time from the Home chips; null shows every brand.
  Future<void> setBrandFilter(BuildContext context, String? brand) async {
    final want = brand == null ? <String>{} : {brand.toLowerCase()};
    if (want.length == brandFilter.length && want.containsAll(brandFilter)) {
      return;
    }
    brandFilter = want;
    await getProducts(context, refresh: true, next: false);
  }

  Options get productRequestOptions => Options(
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (userData != null) 'Authorization': 'Bearer ${userData?.token}',
    },
    validateStatus: (status) => true,
  );

  Future<void> getProducts(
    BuildContext context, {
    required bool refresh,
    required bool next,
  }) async {
    bool ofl = userData == null;
    if (next && pNextPAGE == null) {
      return;
    }
    if (!next) productListParams = productQuery();
    final params = {
      ...productListParams,
      if (next) 'cursor': "$pNextPAGE",
    };

    loadingProducts = true;
    notifyListeners();
    try {
      var response = await dio.get(
        ofl ? ApiUrls.getProductsOFF : ApiUrls.getProducts,
        queryParameters: params,
        options: productRequestOptions,
      );
      // If /v1/get-products is missing or answers oddly, use the public
      // list (same filters; only is_favorite is lost).
      if (!ofl &&
          (response.statusCode != 200 ||
              response.data is! Map ||
              response.data['products'] == null)) {
        response = await dio.get(
          ApiUrls.getProductsOFF,
          queryParameters: params,
          options: productRequestOptions,
        );
      }

      if (response.data.toString().toLowerCase().contains("<html")) {
        await DS.storage.deleteAll();
        await (await SharedPreferences.getInstance()).clear();
        NavigationHelper.pushAndRemoveUntil(context, InitScreen());
        return;
      }

      if (response.statusCode == 200) {
        var newD = ProductResponseModel.fromJson(response.data).products!;
        if (refresh || !next) {
          products = newD.data;
        } else {
          final have = products.map((p) => p.id).toSet();
          products.addAll(newD.data.where((p) => !have.contains(p.id)));
        }
        noteFavorites(newD.data);
        DS.storage.write(key: "products", value: '');
        pNextPAGE = newD.nextCursor;
        pPrevPAGE = newD.prevCursor;
      }
    } catch (e) {
      debugPrint("!!! [getProducts] $e");
    } finally {
      loadingProducts = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // Brands (GET /v1/brands, public)
  // ------------------------------------------------------------------
  List<Brand> brands = [];

  Future<void> getBrands({bool retry = true}) async {
    try {
      final r = await dio.get(ApiUrls.brandsGET, options: productRequestOptions);
      if (r.statusCode == 200 && r.data is Map && r.data['brands'] is List) {
        brands =
            (r.data['brands'] as List)
                .whereType<Map>()
                .map((b) => Brand.fromJson(Map<String, dynamic>.from(b)))
                .where((b) => b.productsCount > 0)
                .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("!!! [getBrands] $e");
      // A blip on a weak connection: try once more.
      if (retry) {
        await Future.delayed(const Duration(seconds: 2));
        return getBrands(retry: false);
      }
    }
  }

  // ------------------------------------------------------------------
  // Favourites (customer token)
  // ------------------------------------------------------------------
  /// Saved product ids, kept in step across every list on screen.
  Set<int> favoriteIds = {};
  List<ProductModel> favorites = [];
  String? favoritesNextCursor;
  bool loadingFavorites = false;

  bool isFavorite(int productId) => favoriteIds.contains(productId);

  void noteFavorites(Iterable<ProductModel> list) {
    if (userData == null) return;
    for (final p in list) {
      p.isFavorite ? favoriteIds.add(p.id) : favoriteIds.remove(p.id);
    }
  }

  /// Flips the heart at once and undoes it if the call fails.
  Future<void> toggleFavorite(BuildContext context, ProductModel p) async {
    if (userData == null) return;
    final id = p.id;
    final save = !isFavorite(id);
    void apply(bool on) {
      on ? favoriteIds.add(id) : favoriteIds.remove(id);
      for (final x in [
        ...products,
        ...favorites,
        ...recentlyViewedProducts,
        if (productData != null) productData!,
      ]) {
        if (x.id == id) x.isFavorite = on;
      }
      if (!on) favorites.removeWhere((x) => x.id == id);
      if (on && !favorites.any((x) => x.id == id)) favorites.insert(0, p);
      notifyListeners();
    }

    apply(save);
    try {
      final r =
          save
              ? await dio.post(ApiUrls.favorite(id), options: productRequestOptions)
              : await dio.delete(ApiUrls.favorite(id), options: productRequestOptions);
      if (r.statusCode == 200 || r.statusCode == 201) return;
      apply(!save);
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Not saved",
          message:
              (r.data is Map ? r.data['message']?.toString() : null) ??
              "Could not update your favourites.",
        );
      }
    } catch (_) {
      apply(!save);
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
    }
  }

  /// GET /v1/favorites — cursor paged like the home list.
  Future<void> getFavorites({bool refresh = true}) async {
    if (userData == null) return;
    if (!refresh && favoritesNextCursor == null) return;
    loadingFavorites = true;
    notifyListeners();
    try {
      final r = await dio.get(
        ApiUrls.favoritesGET,
        queryParameters: {
          'per_page': '20',
          if (!refresh) 'cursor': "$favoritesNextCursor",
        },
        options: productRequestOptions,
      );
      if (r.statusCode == 200 && r.data is Map && r.data['products'] != null) {
        final page = ProductListData.fromJson(r.data['products']);
        for (final p in page.data) {
          p.isFavorite = true;
        }
        favorites = refresh ? page.data : [...favorites, ...page.data];
        favoritesNextCursor = page.nextCursor?.toString();
        if (refresh) favoriteIds = favorites.map((p) => p.id).toSet();
        favoriteIds.addAll(page.data.map((p) => p.id));
      }
    } catch (e) {
      debugPrint("!!! [getFavorites] $e");
    } finally {
      loadingFavorites = false;
      notifyListeners();
    }
  }

  Future<void> getVendors({required bool refresh, required bool next}) async {
    if (next && vNextPAGE == null) {
      return;
    }
    var response = await dio.get(
      next ? "${ApiUrls.getVendors}?cursor=$vNextPAGE" : ApiUrls.getVendors,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      ),
    );

    if (response.statusCode == 200) {
      var newV = VendorsResponse.fromJson(response.data).vendors;
      if (refresh) {
        vendors = newV.data;
      } else {
        vendors.addAll(newV.data);
      }
      vNextPAGE = newV.nextCursor;
      vPrevPAGE = newV.prevCursor;
      DS.storage.write(key: "vendors", value: '');
    }
  }

  Future<void> getTopDeals({required bool refresh, required bool next}) async {
    bool ofl = userData == null;
    if (next && tdNextPAGE == null) {
      return;
    }
    var response = await dio.get(
      next
          ? "${ofl ? ApiUrls.topDealsOFF : ApiUrls.topDeals}?cursor=$tdNextPAGE"
          : (ofl ? ApiUrls.topDealsOFF : ApiUrls.topDeals),
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      ),
    );

    if (response.statusCode == 200) {
      var newV = TopDealsResponse.fromJson(response.data).topDeals;
      if (refresh) {
        topDeals = newV.data;
      } else {
        topDeals.addAll(newV.data);
      }
      tdNextPAGE = newV.nextCursor;
      tdPrevPAGE = newV.prevCursor;
      DS.storage.write(key: "topDeals", value: '');
    }
  }

  Future<void> getHotDeals() async {
    bool ofl = userData == null;
    var response = await dio.get(
      ofl ? ApiUrls.hotDealsOFF : ApiUrls.hotDeals,
      // New app versions send per_page and get a cursor page (first page is
      // enough for the home carousel).
      queryParameters: {"per_page": 10},
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      ),
    );

    if (response.statusCode == 200) {
      hotDeals = PromotedProductsResponse.fromJson(response.data).hotDeals;
      DS.storage.write(key: "hotDeals", value: '');
      notifyListeners();
    }
  }

  /// THE FIX: previously any exception thrown while parsing the response
  /// (e.g. a null `opening_time`, a null `packages`, an empty
  /// `productStorages`) propagated straight out of this function BEFORE
  /// `loadingProduct = false` ran — so the UI stayed on its loading shimmer
  /// forever with no error, no crash log the user would see, nothing.
  /// Wrapping the parse in try/catch/finally guarantees loadingProduct
  /// always resolves, and a real failure now surfaces as a message instead
  /// of an infinite spinner.
  Future<void> getProductDetails(int id, BuildContext context) async {
    bool ofl = userData == null;
    loadingProduct = true;
    productDetailsError = null;
    notifyListeners();

    try {
      // Opening the page counts one view (server de-dupes per 30 min).
      var response = await dio.get(
        ofl
            ? "${ApiUrls.getProductsDetailsOFF}/$id"
            : "${ApiUrls.getProductsDetails}/$id",
        options: productRequestOptions,
      );
      if (!ofl &&
          (response.statusCode != 200 ||
              response.data is! Map ||
              response.data["product"] == null)) {
        response = await dio.get(
          "${ApiUrls.getProductsDetailsOFF}/$id",
          options: productRequestOptions,
        );
      }

      if (response.data.toString().toLowerCase().contains("<html")) {
        await DS.storage.deleteAll();
        await (await SharedPreferences.getInstance()).clear();
        NavigationHelper.pushAndRemoveUntil(context, InitScreen());
        return;
      }

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data["product"] != null) {
        productDataPackages = response.data["packages"] == null
            ? null
            : Package.fromJson(response.data["packages"]);

        productData = ProductModel.fromJson(response.data["product"]);
        // The public route never knows the heart; keep what we know.
        if (isFavorite(productData!.id)) productData!.isFavorite = true;
        noteFavorites([productData!]);

        final storages = productData?.productStorages;
        selectedStorage = (storages != null && storages.isNotEmpty)
            ? storages.first
            : null;

        addRecentViewed(productData!);
      } else {
        productDetailsError =
            (response.data is Map ? response.data["message"] : null) ??
                "Failed to load product (status ${response.statusCode})";
      }
    } catch (e) {
      productDetailsError = "Something went wrong loading this product: $e";
    } finally {
      loadingProduct = false;
      notifyListeners();
    }
  }

  /// True when the last shop asked for no longer exists (404).
  bool vendorNotFound = false;

  Future<void> getVendorDetails(int id) async {
    vendorNotFound = false;
    loadingVendor = true;
    notifyListeners();
    try {
      var response = await dio.get(
        "${ApiUrls.getVendorDetails}/$id",
        options: Options(
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer ${userData?.token}',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        vendorData = VendorDetails.fromJson(response.data["vendor"]);
      } else if (response.statusCode == 404) {
        vendorNotFound = true;
      }
    } catch (_) {
    } finally {
      loadingVendor = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // Reviews of vendors and phones (customer token). Results are returned
  // to the calling screen rather than held here.
  // ------------------------------------------------------------------

  /// GET /v1/get-{vendor|product}-reviews/{id}. [sort]: newest | oldest |
  /// highest | lowest. Null on failure.
  Future<ReviewsPage?> fetchReviews(
    ReviewTarget target,
    int id, {
    int? stars,
    String sort = "newest",
    bool withComment = false,
    String? cursor,
  }) async {
    try {
      final r = await dio.get(
        target == ReviewTarget.vendor
            ? ApiUrls.vendorReviews(id)
            : ApiUrls.productReviews(id),
        queryParameters: {
          "sort": sort,
          "per_page": 20,
          if (stars != null) "rating": stars,
          if (withComment) "with_comment": 1,
          if (cursor != null) "cursor": cursor,
        },
        options: productRequestOptions,
      );
      if (r.statusCode == 200 && r.data is Map) {
        return ReviewsPage.fromJson(Map<String, dynamic>.from(r.data));
      }
    } catch (e) {
      debugPrint("!!! [fetchReviews] $e");
    }
    return null;
  }

  /// POST create-{vendor|product}-review. `status` 201 = posted,
  /// 409 = already reviewed (edit instead), 403 = not allowed yet.
  Future<({int status, String message, ReviewItem? review})> postReview(
    ReviewTarget target,
    int id,
    int rating,
    String? comment,
  ) async {
    try {
      final r = await dio.post(
        target == ReviewTarget.vendor
            ? ApiUrls.createVendorReview
            : ApiUrls.createProductReview,
        data: {
          target == ReviewTarget.vendor ? "vendor_id" : "product_id": id,
          "rating": rating,
          if (comment != null && comment.trim().isNotEmpty)
            "comment": comment.trim(),
        },
        options: productRequestOptions,
      );
      return reviewResultOf(r, "Couldn't post your review.");
    } catch (_) {
      return (status: 0, message: "Check your internet connection and try again.", review: null);
    }
  }

  /// PUT /v1/reviews/{id}: change my review (null comment removes it).
  Future<({int status, String message, ReviewItem? review})> updateReview(
    int reviewId,
    int rating,
    String? comment,
  ) async {
    try {
      final r = await dio.put(
        ApiUrls.review(reviewId),
        data: {
          "rating": rating,
          "comment":
              comment == null || comment.trim().isEmpty ? null : comment.trim(),
        },
        options: productRequestOptions,
      );
      return reviewResultOf(r, "Couldn't save your changes.");
    } catch (_) {
      return (status: 0, message: "Check your internet connection and try again.", review: null);
    }
  }

  /// DELETE /v1/reviews/{id}. Null on success, else the message.
  Future<String?> deleteReview(int reviewId) async {
    try {
      final r = await dio.delete(
        ApiUrls.review(reviewId),
        options: productRequestOptions,
      );
      if (r.statusCode == 200) return null;
      return (r.data is Map ? r.data['message']?.toString() : null) ??
          "Couldn't delete your review.";
    } catch (_) {
      return "Check your internet connection and try again.";
    }
  }

  /// GET /v1/my-reviews (cursor paged). Null on failure.
  Future<MyReviewsPage?> fetchMyReviews({String? cursor}) async {
    try {
      final r = await dio.get(
        ApiUrls.myReviews,
        queryParameters: {"per_page": 20, if (cursor != null) "cursor": cursor},
        options: productRequestOptions,
      );
      if (r.statusCode == 200) return MyReviewsPage.fromJson(r.data);
    } catch (e) {
      debugPrint("!!! [myReviews] $e");
    }
    return null;
  }

  ({int status, String message, ReviewItem? review}) reviewResultOf(
    Response r,
    String fallback,
  ) {
    final body = r.data is Map ? r.data as Map : const {};
    String message = body['message']?.toString() ?? fallback;
    final errors = body['errors'];
    if (r.statusCode == 422 && errors is Map && errors.isNotEmpty) {
      final v = errors.values.first;
      message = v is List && v.isNotEmpty ? "${v.first}" : message;
    }
    final review =
        body['review'] is Map
            ? ReviewItem.fromJson(Map<String, dynamic>.from(body['review']))
            : null;
    return (status: r.statusCode ?? 0, message: message, review: review);
  }

  Future<void> rateProduct(int rate, BuildContext context) async {
    var data = {
      "product_id": orderData!.product.id,
      "rating": rate.toString(),
      "comment": commentController.text.trim(),
    };
    var response = await dio.post(
      ApiUrls.rateProduct,
      data: data,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      SnackbarHelper.success(
        context: context,
        title: "Product Rated!",
        message: "Your review has been added successfully",
      );
      commentController.clear();
      NavigationHelper.pop(context);
    } else {
      SnackbarHelper.danger(
        context: context,
        title: "Failed To Rate Product",
        message: "Unable to add review",
      );
    }
  }

  /// The selected term's entry from the price breakdown, or null.
  dynamic get selectedTerm =>
      breakDownPrice?.breakdowns.months["${slTenure}_months"];

  /// False when the selected term can't be financed (nothing to order).
  bool get selectedFinanceable => isFinanceable(selectedTerm);

  /// GET /v1/products/{productStorageId}/pricing-breakdown. Falls back to
  /// the older /v1/price-breakdown/{id} while the new route isn't deployed.
  Future<void> getProductPB(id) async {
    loadingPBD = true;
    breakDownPrice = null; // never show another storage's numbers
    notifyListeners();
    try {
      final options = Options(
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      );
      var response = await dio.get(
        ApiUrls.pricingBreakdown(id),
        options: options,
      );
      if (response.statusCode == 404) {
        response = await dio.get(
          "${ApiUrls.priceBrakeDown}/$id",
          options: options,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        breakDownPrice = BreakdownResponse.fromJson(response.data);
      }
    } catch (_) {
    } finally {
      loadingPBD = false;
      notifyListeners();
    }
  }

  Future<void> addRecentViewed(ProductModel p) async {
    recentlyViewedProducts.removeWhere((x) => x.id == p.id);
    var mpData = p.toJson();
    mpData["addedAt"] = DateTime.now().toIso8601String();
    recentlyViewedProducts.insert(0, ProductModel.fromJson(mpData));
    var data = jsonEncode(
      recentlyViewedProducts.take(20).map((x) => x.toJson()).toList(),
    );
    var str = await DS.sharedStorage;
    str.setString("recent_viewed", data);
    await getRecentViewed();
  }

  Future<void> getRecentViewed() async {
    var str = await DS.sharedStorage;
    try {
      recentlyViewedProducts =
          (jsonDecode(str.getString("recent_viewed") ?? "[]") as List)
              .map((x) => ProductModel.fromJson(x))
              .toList();
    } catch (_) {
      recentlyViewedProducts = [];
    }
    notifyListeners();
  }
}