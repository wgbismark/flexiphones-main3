import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/models/search_products.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin Search on BaseNotifier {
  bool search = false;
  final searchController = TextEditingController();
  final rMinController = TextEditingController();
  final rMaxController = TextEditingController();
  Set<String> selectedDurations = {};

  List<SearchProduct> filteredProducts = [];
  List<String> recentSearches = [];
  bool searchingProduct = false;
  String locationS = "All";

  void toggleDuration(String duration) {
    if (selectedDurations.contains(duration)) {
      selectedDurations.remove(duration);
    } else {
      selectedDurations.add(duration);
    }

    notifyListeners();
  }

  void setSearchText(kw) {
    searchController.text = kw;
    notifyListeners();
  }

  void clearSearchController() {
    getFilteredProducts();
    searchController.clear();
  }

  void enableSearching({bool? change}) {
    if (change != null) {
      search = change;
    } else {
      search = !search;
    }
    notifyListeners();
  }

  void onUpdateSearch() {
    notifyListeners();
  }

  List<String> get locations => [];
  // products
  //     .map((product) => product['store'])
  //     .fold<Map<int, Map>>({}, (map, store) {
  //       map[store['id']] = store; // overwrite duplicates by ID
  //       return map;
  //     })
  //     .values
  //     .map((e) => e["address"] as String)
  //     .toList();

  Future<void> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches = prefs.getStringList("recent_search") ?? [];
    notifyListeners();
  }

  Future<void> addSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList("recent_search") ?? [];

    // Remove if already exists to avoid duplicates
    searches.remove(query);

    // Insert at the beginning
    searches.insert(0, query);

    // Keep only the latest 10
    if (searches.length > 10) {
      searches = searches.sublist(0, 10);
    }

    await prefs.setStringList("recent_search", searches);
    await getRecentSearches();
  }

  Timer? srcT;
  Future<void> getFilteredProducts() async {
    srcT?.cancel();
    searchingProduct = true;
    notifyListeners();
    final query = searchController.text.trim();

    final minText = rMinController.text.trim();
    final maxText = rMaxController.text.trim();

    int? min = int.tryParse(minText);
    int? max = int.tryParse(maxText);

    // Swap if min is greater than max
    if (min != null && max != null && min > max) {
      final temp = min;
      min = max;
      max = temp;
    }

    // Start building query parameters
    Map<String, String> params = {'query': query};

    if (min != null && min > 0) {
      params['min_price'] = min.toString();
    }
    if (max != null && max > 0) {
      params['max_price'] = max.toString();
    }

    params['per_page'] = "20";

    // A new search starts from page 1; the cursor is only ever used with
    // the same filters it came from.
    _searchParams = params;
    searchNextCursor = null;

    final response = await _searchRequest(params);

    if (response.statusCode == 200) {
      final page = SearchResult.fromJson(response.data).data;
      filteredProducts = page.products;
      searchNextCursor = page.nextCursor;

      srcT = Timer(Duration(seconds: 1), () async {
        query.isEmpty ? null : await addSearch(query);
      });
    } else {}

    // if (reset) {
    //   locationS = "All";
    //   rMinController.text = "0";
    //   rMaxController.text = "0";
    //   // filteredProducts = products;
    //   searchingProduct = false;
    //   notifyListeners();
    //   return;
    // }

    // filteredProducts =
    //     products!.products!.data.where((product) {
    //       final double price = product. ?? 0;
    //       final String name = "${product.brand.toLowerCase()} ${product.model.toLowerCase()}";
    //       final String storeName =
    //           product['store']?['name']?.toLowerCase() ?? '';
    //       final String storeAddress =
    //           product['store']?['address']?.toLowerCase() ?? '';
    //       final String installment =
    //           product['installment']?.toLowerCase() ?? '';

    //       final bool matchesPrice = price >= minPrice && price <= maxPrice;
    //       final bool matchesLocation =
    //           location.isEmpty ||
    //           location == "All" ||
    //           storeAddress.contains(location.toLowerCase());

    //       final bool matchesDuration =
    //           paymentDuration.isEmpty ||
    //           paymentDuration.any(
    //             (duration) => installment.contains(duration.toLowerCase()),
    //           );

    //       final bool matchesWord =
    //           word.isEmpty ||
    //           name.contains(word.toLowerCase()) ||
    //           storeName.contains(word.toLowerCase());

    //       return matchesPrice &&
    //           matchesLocation &&
    //           matchesDuration &&
    //           matchesWord;
    //     }).toList();

    searchingProduct = false;
    notifyListeners();
  }

  // Cursor paging for search: the next page reuses the exact filters of
  // the search that produced the cursor.
  Map<String, String> _searchParams = {};
  String? searchNextCursor;
  bool loadingMoreSearch = false;

  Future<Response> _searchRequest(Map<String, String> params) {
    final uri = Uri.parse(
      ApiUrls.searchProducts,
    ).replace(queryParameters: params);
    return dio.get(
      uri.toString(),
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (_) => true,
      ),
    );
  }

  /// Loads the next page of the current search (call near the list end).
  Future<void> loadMoreSearch() async {
    final cursor = searchNextCursor;
    if (cursor == null || loadingMoreSearch || searchingProduct) return;
    loadingMoreSearch = true;
    notifyListeners();
    try {
      final params = {..._searchParams, 'cursor': cursor};
      final response = await _searchRequest(params);
      if (response.statusCode == 200 && searchNextCursor == cursor) {
        final page = SearchResult.fromJson(response.data).data;
        filteredProducts = [...filteredProducts, ...page.products];
        searchNextCursor = page.nextCursor;
      }
    } catch (e) {
      debugPrint("!!! [loadMoreSearch] $e");
    } finally {
      loadingMoreSearch = false;
      notifyListeners();
    }
  }
}
