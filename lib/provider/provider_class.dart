// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/no_internet.dart';
import 'package:flexiphones/provider/mixins/agent/agent.dart';
import 'package:flexiphones/provider/mixins/cart/cart.dart';
import 'package:flexiphones/provider/mixins/notify/notify.dart';
import 'package:flexiphones/provider/mixins/orders/orders.dart';
import 'package:flexiphones/provider/mixins/products/products.dart';
import 'package:flexiphones/provider/mixins/search/search.dart';
import 'package:flexiphones/provider/mixins/session/session.dart';
import 'package:flexiphones/provider/mixins/user/user.dart';
import 'package:flexiphones/screens/onboarding/init_ob/stepsPage.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages

enum RefreshParam { orders, products, vendors }

abstract class BaseNotifier extends ChangeNotifier with Products, Cart, Notify  {
  bool dialogueLoading = false;
  bool thmMode = false;

  Future<void> enDM(BuildContext context) async {
    thmMode = !thmMode;
    var sp = await DS.sharedStorage;
    sp.setBool("th", thmMode);

    await initTHM(context);
  }

  Future<void> initTHM(BuildContext context) async {
    var sp = await DS.sharedStorage;
    thmMode = sp.getBool("th") ?? true;
    notifyListeners();
    if (!thmMode) {
      AdaptiveTheme.of(context).setDark();
    } else {
      AdaptiveTheme.of(context).setLight();
    }
  }
}

class SharedProvider extends BaseNotifier
    with Cart, Products, Search, User, Orders, Agent, Session {
  SharedProvider() {
    installSession();
  }

  /// "Log Out": cancels both tokens on the server, then wipes everything
  /// the account left on this phone (see [clearLocalUserData]).
  Future<void> signOutCompletely() async {
    await logoutEverywhere();
    await clearLocalUserData();
  }

  /// Forgets the signed-in person entirely: tokens, saved data and every
  /// list held in memory (orders, bag, notifications, favourites, points,
  /// searches…). Only device settings (theme, intro seen) are kept.
  Future<void> clearLocalUserData() async {
    userData = null;
    await agentSignOut();
    // Orders & payments
    orders = [];
    repaymentCL = [];
    orderData = null;
    oNextPAGE = null;
    rNextPAGE = null;
    showP = 0;
    // Notifications
    notifications = [];
    unreadCount = null;
    notified.clear();
    notificationsPage = 1;
    notificationsHasMore = false;
    // Bag, favourites, recently viewed
    cartItems = [];
    cartsToRemove.clear();
    selectAll = false;
    favorites = [];
    favoriteIds = {};
    favoritesNextCursor = null;
    for (final p in products) {
      p.isFavorite = false;
    }
    recentlyViewedProducts = [];
    // Referral, promo, points
    referral = null;
    referredFriends = [];
    customerPoints = [];
    customerPointsBalance = null;
    hasReferrer = null;
    myReferrerName = null;
    myReferrerCode = null;
    promoUsage = null;
    promoUsers = [];
    // Search + details held from the last session
    search = false;
    filteredProducts = [];
    recentSearches = [];
    searchController.clear();
    vendors = [];
    vendorData = null;
    // Forms
    for (final c in [
      emailEditingController,
      passwordController,
      rePasswordController,
      fullNameController,
      phoneController,
      locationController,
      otpEditingController,
      referralCodeController,
    ]) {
      c.clear();
    }
    // Forget the Google account too, so the next sign-in asks again.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await DS.storage.deleteAll();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final introSeen = prefs.getBool("fts");
      final theme = prefs.getBool("th");
      // MoMo number-change waits must survive sign-out, or signing out and
      // back in would skip them.
      final momoLocks = {
        for (final k in prefs.getKeys().where((k) => k.startsWith("momo_lock_")))
          k: prefs.getInt(k),
      };
      await prefs.clear();
      if (introSeen != null) await prefs.setBool("fts", introSeen);
      if (theme != null) await prefs.setBool("th", theme);
      for (final e in momoLocks.entries) {
        if (e.value != null) await prefs.setInt(e.key, e.value!);
      }
    } catch (_) {}
    notifyListeners();
  }

  final ScrollController listScrollControllerP = ScrollController();
  final ScrollController listScrollControllerV = ScrollController();
  final ScrollController listScrollControllerO = ScrollController();
  bool connecting = false;
  bool refreshing_ = false;

  String connMSG = "Please check your connection and try again.";

  /// Same as [User.getNotifications], but when a new order notification
  /// arrives ("Down payment received" or "Order status updated") the orders
  /// and the open order are refreshed so the new state shows without a
  /// manual reload.
  @override
  Future<void> getNotifications() async {
    final seenBefore = notified.length;
    await super.getNotifications();
    if (notified.length == seenBefore) return;

    final fresh = notified.skip(seenBefore).toSet();
    final updates =
        notifications
            .where((n) => fresh.contains(n.id) && n.data.isOrderUpdate)
            .toList();
    if (updates.isEmpty || userData == null) return;

    try {
      await getOrders(refresh: true, next: false);
      final open = orderData;
      if (open != null &&
          updates.any(
            (n) =>
                n.data.orderId == open.id ||
                (n.data.applicationUuid != null &&
                    n.data.applicationUuid == open.applicationUuid),
          )) {
        await getOrder(open.id, silent: true);
      }
    } catch (e) {
      debugPrint("!!! [getNotifications] order refresh failed: $e");
    }
  }

Future<bool> hasInternetConnection(bool first, BuildContext context) async {
    connMSG = "Please check your connection and try again.";
    Timer(Duration(seconds: 15), () {
      if (connecting != false) {
        connMSG = "Failed to connect to the internet.";
      }
      connecting = false;
      notifyListeners();
    });
    connecting = true;
    notifyListeners();
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.first.name == "none") {
      connecting = false;
      notifyListeners();
      connMSG =
          "Please 'ON' your data connection or 'CONNECT' to a Wifi for internet access";
      notifyListeners();
      first ? NavigationHelper.push(context, NoInternetPage()) : null;
      return false;
    }

    connMSG = "Connection Available";
    notifyListeners();
    first ? null : NavigationHelper.pop(context);
    await Future.delayed(Duration(seconds: 3), () {});
    connecting = false;
    notifyListeners();
    return true;
  }
  Future<void> moreData({
    required RefreshParam type,
    required BuildContext context, refresh = false
  }) async {
    if (refreshing_) return;

    switch (type) {
      case RefreshParam.orders:
        if (oNextPAGE == null && refresh == false) return;
        refreshing_ = true;
        notifyListeners();
        await getOrders(refresh: refresh, next: refresh ? false: true);

        break;
      case RefreshParam.products:
        if (pNextPAGE == null && refresh == false) return;
        refreshing_ = true;
        notifyListeners();
        await getProducts(context, refresh: refresh, next: refresh ? false: true);

        break;
      case RefreshParam.vendors:
        if (vNextPAGE == null && refresh == false) return;
        refreshing_ = true;
        notifyListeners();
        await getVendors(refresh: refresh, next: refresh ? false: true);

        break;
    }
    Timer(Duration(seconds: 2), () {
      refreshing_ ? {refreshing_ = false, notifyListeners()} : null;
    });
  }


    Future<void> checkINIT(context) async {
    final prefs = (await SharedPreferences.getInstance());


    bool ft = prefs.getBool("fts") ?? false;
    if (!ft) {

      showDialog(
        context: context,
        barrierDismissible :false,
        builder: (context) {
          return StepsPage(nit: true,);
        },
      );
    prefs.setBool("fts", true);

    }

  }

}