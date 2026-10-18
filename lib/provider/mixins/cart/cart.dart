import 'dart:convert';

import 'package:flexiphones/models/price_model.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin Cart on ChangeNotifier {

  List cartItems = [];
  List<int> cartsToRemove = [];
  bool selectAll = false;
  int get selectedCount =>
      cartItems.isEmpty
          ? 0
          : cartItems.where((item) => item["isSelected"] == true).length;

  bool get checked =>
      cartItems.isEmpty
          ? false
          : cartItems.where((x) => x["isSelected"] == true).isNotEmpty;
  List get selectedItems =>
      cartItems.where((x) => x["isSelected"] == true).toList();


  // double get totalCost => cartItems.fold(
  //   0.0,
  //   (total, item) =>
  //       item["isSelected"] ? total + item["price"] * item["quantity"] : total,
  // );
  int get deviceUnit => cartItems.fold(
    0,
    (total, item) =>
        item["isSelected"] ? total + (item["quantity"] as int) : total,
  );

  /// THE FIX (typing): `breakDownPrice` is now explicitly typed as
  /// `BreakdownResponse?` instead of implicit `dynamic` — see earlier fix
  /// for why (a Map was previously passed here by mistake and it wasn't
  /// caught until runtime).
  ///
  /// THE FIX (null vendor): `v.vendor!.name` used to force-unwrap the
  /// product's vendor. The backend can legitimately return a product with
  /// no vendor attached, which crashed every add-to-cart attempt for that
  /// product with "Null check operator used on a null value". Falls back
  /// to a placeholder label instead of crashing.
  Future<void> addToCart(
    ProductModel v,
    ProductStorage ps,
    int tenure,
    String color,
    int? packageId,
    BreakdownResponse? breakDownPrice,
  ) async {
    if (breakDownPrice == null) {
      // Pricing hasn't loaded for the selected storage/tenure yet — bail
      // out instead of crashing. The UI should ideally disable the confirm
      // button until this is non-null (see StorageOMD's SmartButton).
      return;
    }

    dynamic newProduct = {
      'id': v.id,
      "vendor": v.vendor?.name ?? "Unknown Vendor",
      "productName": v.fullName,
      "image": v.image,
      "product_storages": ps.toJson(),
      "service_tenure": tenure,
      "device_type": "smartphone",
      "color": color,
      "quantity": 1,
      "isSelected": true,
      "package_id": packageId,
      "breakdowns": breakDownPrice.breakdowns.toJson(),
    };

    cartItems.add(newProduct);
    await saveCartItems();
  }

  Future<void> removeCartItem(int value) async {
    cartItems.removeAt(value);
    await saveCartItems();
  }

  Future<void> updateCartItem(int index, bool isIncrement) async {
    if (isIncrement) {
      cartItems[index]["quantity"]++;
    } else {
      if (cartItems[index]["quantity"] > 1) {
        cartItems[index]["quantity"]--;
      }
    }
    await saveCartItems();
  }

  Future<void> selectCartItem(index) async {
    cartItems[index]["isSelected"] = !cartItems[index]["isSelected"];
    if (cartItems[index]["isSelected"] == true) {
      cartsToRemove.contains(index) ? null : cartsToRemove.add(index);
    } else {
      cartsToRemove.remove(index);
    }
    await saveCartItems();
  }

  Future<void> selectAllCartItem() async {
    selectAll = !selectAll;

    cartsToRemove.clear();

    for (int i = 0; i < cartItems.length; i++) {
      cartItems[i]["isSelected"] = selectAll;
      if (cartItems[i]["isSelected"]) {
        if (!cartsToRemove.contains(i)) {
          cartsToRemove.add(i);
        }
      } else {
        cartsToRemove.remove(i);
      }
    }
    await saveCartItems();
  }

  Future<void> removeSelectedItem() async {
    for (int value in cartsToRemove) {
      cartItems.removeAt(value);
    }
      
    await saveCartItems();
  }

  Future<void> removeSelectedItems() async {
    for (int i = cartItems.length - 1; i >= 0; i--) {
      if (cartItems[i]["isSelected"] == true) {
        cartItems.removeAt(i);
      }
    }
    await saveCartItems();
  }

  

  Future<void> clearCart() async {
    cartItems.clear();
    await saveCartItems();
  }

  Future<void> saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(cartItems);
    await prefs.setString('cart_items', encoded);

    notifyListeners();
  }

  Future<void> loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cart_items');
    if (data != null) {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        cartItems = decoded;
      }
    }

    notifyListeners();
  }
}