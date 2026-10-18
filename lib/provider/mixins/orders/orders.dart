// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/helpers/snackbar_helper.dart';
import 'package:flexiphones/models/order_m.dart';
import 'package:flexiphones/models/packages.dart';
import 'package:flexiphones/models/payment_calendar_m.dart';
import 'package:flexiphones/models/repayment_info_m.dart';
import 'package:flexiphones/models/repayment_m.dart';
import 'package:flexiphones/models/standing_m.dart';
import 'package:flexiphones/models/report_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/order_confirmation/sub_pages/order_success.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/screens/onboarding/ghcard_verification.dart';
import 'package:flexiphones/screens/orders/sub_pages/pay_now.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin Orders on BaseNotifier {
  List<Order> orders = [];
  List<RepaymentEntry> repaymentCL = [];

  DateTime selectedData = DateTime.now();
  bool loadingOrder = false;
  int showP = 0;
  //
  String? oNextPAGE;
  String? oPrevPAGE;
  String? rNextPAGE;
  String? rPrevPAGE;
  bool orderLoading = false;

  bool orderNotFound = false;

  List<Order> get ordersStatusPlaced =>
      orders.where((element) => element.stage == "placed").toList();
  List<Order> get ordersStatusCancelled =>
      orders.where((element) => element.stage == "cancelled").toList();

  List get ordersStatusDelivered =>
      orders.where((element) => element.stage == "delivered").toList();

  Future<void> selectDate(DateTime v) async {
    selectedData = v;
    notifyListeners();
  }

  Future<void> switchOrders(int v) async {
    showP = v;
    notifyListeners();
  }

  /// FIX + DEBUG LOGGING:
  /// - Wrapped in try/catch so a DioException (timeout, connection error,
  ///   or an upstream failure like get-customer-orders/{phoneNumber}
  ///   cascading) doesn't crash silently — it now surfaces a Snackbar and
  ///   a console log instead.
  /// - `orderLoading` is reset to false BEFORE navigation, and in a
  ///   `finally` block, so the button never gets stuck.
  /// - `context.mounted` checked after every await before touching context.
  /// - Full request/response logging so you can see exactly what's sent
  ///   for a multi-device order and exactly what the backend returns.
  Future<Map<String, dynamic>?> createCashReservation(
    BuildContext context, {
    required List<Map<String, dynamic>> products,
    String deliveryOption = "pickup",
    int? vendorLocationId,
    String? deliveryAddress,
  }) async {
    if (userData?.token == null || userData!.token!.isEmpty) {
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Sign in required",
          message: "Please sign in again to continue with cash checkout.",
        );
      }
      return null;
    }

    final payload = <String, dynamic>{
      "products": products,
      if (deliveryOption.trim().isNotEmpty) "delivery_option": deliveryOption,
      if (vendorLocationId != null) "vendor_location_id": vendorLocationId,
      if ((deliveryAddress ?? '').trim().isNotEmpty)
        "delivery_address": deliveryAddress!.trim(),
    };

    try {
      final response = await dio.post(
        ApiUrls.cashReservationsPST,
        data: payload,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer ${userData!.token}",
          },
          validateStatus: (status) => true,
        ),
      );

      final status = response.statusCode ?? 0;
      final body = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      if (status >= 200 && status < 300) {
        return body;
      }

      final message = body['message'] ?? "Cash reservation could not be created.";
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Cash reservation failed",
          message: message.toString(),
        );
      }
      return body;
    } catch (e) {
      debugPrint("!!! [createCashReservation] ERROR: $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Unable to create cash reservation right now.",
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCashReservationStatus(
    BuildContext context,
    String reference,
  ) async {
    if (reference.trim().isEmpty) return null;
    if (userData?.token == null || userData!.token!.isEmpty) return null;

    try {
      final response = await dio.get(
        ApiUrls.cashReservationStatus(reference),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer ${userData!.token}",
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        return body;
      }

      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Reservation status unavailable",
          message: "The cash reservation status could not be loaded.",
        );
      }
      return null;
    } catch (e) {
      debugPrint("!!! [getCashReservationStatus] ERROR: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchVendorLocations(
    BuildContext context,
    int vendorId,
  ) async {
    if (userData?.token == null || userData!.token!.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    try {
      final response = await dio.get(
        ApiUrls.vendorLocations(vendorId),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer ${userData!.token}",
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        return const <Map<String, dynamic>>[];
      }

      final body = response.data is Map ? response.data as Map : const {};
      if (body['locations'] is List) {
        return (body['locations'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint("!!! [fetchVendorLocations] ERROR: $e");
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> addOrder(
    List products,
    String location,
    bool pickup,
    BuildContext context,
  ) async {
    orderLoading = true;
    notifyListeners();

    var data = {
      "products": products,
      "delivery_option": "pickup", // pickup ? "pickup" : "delivery",
      "delivery_address": location,
    };

    debugPrint("=== [addOrder] REQUEST ===");
    debugPrint("URL: ${ApiUrls.addOrders}");
    debugPrint("Item count: ${products.length}");
    debugPrint("Data: ${jsonEncode(data)}");
    debugPrint("Token present: ${userData?.token != null && userData!.token!.isNotEmpty}");
    debugPrint("===========================");

    try {
      var response = await dio.post(
        ApiUrls.addOrders,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer ${userData?.token}',
          },
          validateStatus: (status) => true,
        ),
      );

      debugPrint("=== [addOrder] RESPONSE ===");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.data}");
      debugPrint("============================");

      orderLoading = false;

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        debugPrint(">>> [addOrder] SUCCESS — refreshing order list");
        try {
          await getOrders(refresh: true, next: false);
        } catch (e) {
          // Order already succeeded — don't let a refresh failure
          // (e.g. get-customer-orders lookup) block the success screen.
          debugPrint("!!! [addOrder] getOrders() refresh failed after successful order: $e");
        }

        await removeSelectedItems();

        if (!context.mounted) {
          debugPrint("!!! [addOrder] context unmounted before navigation, aborting nav");
          return;
        }
        NavigationHelper.push(context, OrderPlacedSuccess());
      } else {
        String message = "Something went wrong. Please try again.";
        final body = response.data;
        if (body is Map && body["message"] != null) {
          message = "${body["message"]}";
        } else if (body is String && body.isNotEmpty) {
          message = body;
        }

        debugPrint(">>> [addOrder] FAILED — status ${response.statusCode}, message: $message");

        if (!context.mounted) return;
        // 422 code "not_financeable": the down payment covers the whole
        // price, so there is nothing to finance. message is plain text.
        final notFinanceable =
            body is Map && body["code"] == "not_financeable";
        final code = body is Map ? "${body["code"] ?? ""}" : "";
        // No Ghana Card on file: add it, then order again.
        if (code == "ghana_card_required") {
          SnackbarHelper.danger(
            context: context,
            title: "Ghana Card Needed",
            message: message,
          );
          NavigationHelper.push(
            context,
            GHCardVerification(lateVerification: true),
          );
          return;
        }
        // An overdue / locked plan: pay it first.
        if (code == "overdue_plan") {
          SnackbarHelper.danger(
            context: context,
            title: "Catch Up First",
            message: message,
          );
          await getOrders(refresh: true, next: false);
          if (!context.mounted) return;
          final behind = orders.where((o) => o.hasMissedPayment).toList();
          NavigationHelper.push(
            context,
            behind.isEmpty
                ? const HomePage(initScreen: 3)
                : PayNowScreen(orderId: behind.first.id),
          );
          return;
        }
        SnackbarHelper.danger(
          context: context,
          title: notFinanceable ? "Can't Be Financed" : "Failed To Create Order",
          message: message,
        );
      }
    } on DioException catch (e) {
      debugPrint("!!! [addOrder] DioException");
      debugPrint("!!! URL: ${e.requestOptions.uri}");
      debugPrint("!!! Status: ${e.response?.statusCode}");
      debugPrint("!!! Body: ${e.response?.data}");
      debugPrint("!!! Message: ${e.message}");

      orderLoading = false;
      if (!context.mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Failed To Create Order",
        message: e.response?.data is Map
            ? "${e.response?.data["message"] ?? e.message}"
            : "${e.message ?? "Network error, please try again."}",
      );
    } finally {
      orderLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeOrder(
    dynamic id,
    BuildContext context, {
    bool allOrder = false,
  }) async {
    dialogueLoading = true;
    notifyListeners();

    debugPrint("=== [removeOrder] REQUEST ===");
    debugPrint("URL: ${ApiUrls.cancelOrder}");
    debugPrint("Data: ${allOrder ? {"application_uuid": id} : {"application_id": id}}");
    debugPrint("==============================");

    var response = await dio.post(
      ApiUrls.cancelOrder,
      data: allOrder ? {"application_uuid": id} : {"application_id": id},
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      ),
    );

    debugPrint("=== [removeOrder] RESPONSE ===");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Body: ${response.data}");
    debugPrint("===============================");

    await getOrders(refresh: true, next: false);
    if (response.statusCode == 200) {
      SnackbarHelper.success(
        context: context,
        title: "Order Canceled",
        message: "You've cancelled your order(s) successfully",
      );
      NavigationHelper.push(context, HomePage(initScreen: 3));
    } else {
      SnackbarHelper.danger(
        context: context,
        title: "Order Failed To Canceled",
        message: "Failed to process order request",
      );
      NavigationHelper.pop(context);
    }
    //
    dialogueLoading = false;
    notifyListeners();
  }

  Future<void> getOrders({required bool refresh, required bool next}) async {
    if (next && oNextPAGE == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();

    final url = next ? "${ApiUrls.getOrders}?cursor=$oNextPAGE" : ApiUrls.getOrders;

    debugPrint("=== [getOrders] REQUEST ===");
    debugPrint("URL: $url");
    debugPrint("============================");

    var response = await dio.get(
      url,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      ),
    );

    debugPrint("=== [getOrders] RESPONSE ===");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Body: ${response.data}");
    debugPrint("=============================");

    if (response.statusCode == 200) {
      if (refresh) {
        orders = OrderResponse.fromJson(response.data).orders;
      } else {
        orders.addAll(OrderResponse.fromJson(response.data).orders);
      }
      orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      prefs.setString("orders", jsonEncode(response.data));
      oNextPAGE = response.data['orders']["next_cursor"];
      oPrevPAGE = response.data['orders']["prev_cursor"];
    } else {
      debugPrint("!!! [getOrders] FAILED with status ${response.statusCode}");
    }

    notifyListeners();
  }

  Future<void> getRepaymentCL({
    required bool refresh,
    required bool next,
  }) async {
    if (next && rNextPAGE == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();

    final url = next
        ? "${ApiUrls.repaymentCL}?cursor=$rNextPAGE"
        : ApiUrls.repaymentCL;

    debugPrint("=== [getRepaymentCL] REQUEST ===");
    debugPrint("URL: $url");
    debugPrint("=================================");

    var response = await dio.get(
      url,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      ),
    );

    debugPrint("=== [getRepaymentCL] RESPONSE ===");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Body: ${response.data}");
    debugPrint("==================================");

    if (response.statusCode == 200) {
      var nw =
          RepaymentHistoryResponse.fromJson(
            response.data,
          ).repaymentHistory.data;
      if (refresh) {
        repaymentCL = nw;
      } else {
        repaymentCL.addAll(nw);
      }
      prefs.setString("repayments", jsonEncode(response.data));
      rNextPAGE = response.data['repayment_history']["next_cursor"];
      rPrevPAGE = response.data['repayment_history']["prev_cursor"];
    }

    notifyListeners();
  }

  /// Loads one order into [orderData]. With [silent] the loading shimmer is
  /// skipped and the current data is kept on failure — used for polling and
  /// background refreshes. Returns the fresh order, or null.
  Future<Order?> getOrder(int id, {bool silent = false}) async {
    if (!silent) {
      loadingOrder = true;
      orderNotFound = false;
      notifyListeners();
    }

    final url = "${ApiUrls.getOrder}/$id";
    debugPrint("=== [getOrder] REQUEST ===");
    debugPrint("URL: $url");
    debugPrint("===========================");

    Order? fresh;
    try {
      var response = await dio.get(
        url,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            'Authorization': 'Bearer ${userData?.token}',
          },
          validateStatus: (status) => true,
        ),
      );

      debugPrint("=== [getOrder] RESPONSE ===");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.data}");
      debugPrint("============================");

      if (response.statusCode == 200) {
        orderDataPackages =
            response.data["orders"]["partner_package"] == null
                ? null
                : Package.fromJson(response.data["orders"]["partner_package"]);

        fresh = Order.fromJson(response.data["orders"]);
        // The full body is truncated in logcat, so log the status fields alone.
        debugPrint(
          "[getOrder] id=${fresh.id} order_status=${fresh.orderStatus} "
          "order_stage=${fresh.orderStage} payment_status=${fresh.paymentStatus} "
          "display_status=${fresh.displayStatus}",
        );
        orderData = fresh;
        orderNotFound = false;
        _replaceInList(fresh);
      } else if (response.statusCode == 404) {
        // The API now only returns the signed-in customer's own orders.
        orderData = null;
        orderNotFound = true;
      } else if (!silent) {
        orderData = null;
        orderNotFound = true;
      }
    } catch (e) {
      debugPrint("!!! [getOrder] ERROR: $e");
      if (!silent) {
        orderData = null;
        orderNotFound = true;
      }
    }

    loadingOrder = false;
    notifyListeners();
    return fresh;
  }

  Map<String, String> get _authHeaders => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    'Authorization': 'Bearer ${userData?.token}',
  };

  String _messageOf(dynamic body, String fallback) =>
      body is Map && body["message"] != null ? "${body["message"]}" : fallback;

  /// GET repayment-info. Returns the info, or an error message to show.
  Future<({RepaymentInfo? info, String? error})> getRepaymentInfo(
    int orderId,
  ) async {
    final url = ApiUrls.repaymentInfo(orderId);
    debugPrint("=== [repaymentInfo] GET $url");
    try {
      final response = await dio.get(
        url,
        options: Options(headers: _authHeaders, validateStatus: (_) => true),
      );
      debugPrint(
        "=== [repaymentInfo] ${response.statusCode}: ${response.data}",
      );
      if (response.statusCode == 200 && response.data is Map) {
        return (
          info: RepaymentInfo.fromJson(
            Map<String, dynamic>.from(response.data),
          ),
          error: null,
        );
      }
      if (response.statusCode == 404) {
        return (info: null, error: "Order not found");
      }
      return (
        info: null,
        error: _messageOf(response.data, "Could not load payment details"),
      );
    } catch (e) {
      debugPrint("!!! [repaymentInfo] ERROR: $e");
      return (info: null, error: "Check your internet connection and try again");
    }
  }

  /// Payment squares: one order's days, or every order together when
  /// [orderId] is null. [days] is 7..366. Null on any failure.
  Future<PaymentCalendar?> getPaymentCalendar({
    int? orderId,
    int days = 90,
  }) async {
    try {
      final response = await dio.get(
        orderId == null
            ? ApiUrls.paymentCalendarGET
            : ApiUrls.orderPaymentCalendar(orderId),
        queryParameters: {"days": days.clamp(7, 366)},
        options: Options(headers: _authHeaders, validateStatus: (_) => true),
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (response.statusCode == 200 && data is Map) {
        return PaymentCalendar.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      debugPrint("!!! [paymentCalendar] $e");
    }
    return null;
  }

  /// POST repay. `httpStatus` 202 = accepted, 409 = one already running,
  /// 422 = refused (show `message`), 404 = not the customer's order.
  Future<
    ({int httpStatus, String state, String message, int? startedAt})
  >
  startRepayment(
    int orderId,
    num amount,
    String? phone, {
    int? days,
    bool catchUp = false,
  }) async {
    // Days / catch-up go to repay-bulk (the server works out and caps the
    // amount); an exact amount goes to repay.
    final bulk = catchUp || (days != null && days > 0);
    final url = bulk ? ApiUrls.repayBulk(orderId) : ApiUrls.repay(orderId);
    final data = {
      if (catchUp) "catch_up": true else if (bulk) "days": days else "amount": amount,
      if (phone != null && phone.isNotEmpty) "phone_number": phone,
    };
    debugPrint("=== [repay] POST $url $data");
    try {
      final response = await dio.post(
        url,
        data: data,
        options: Options(headers: _authHeaders, validateStatus: (_) => true),
      );
      debugPrint("=== [repay] ${response.statusCode}: ${response.data}");
      final body = response.data;
      final map = body is Map ? body : const {};
      return (
        httpStatus: response.statusCode ?? 0,
        state: map["state"]?.toString() ?? "",
        message: _messageOf(body, "Payment could not be started"),
        startedAt: int.tryParse("${map["started_at"] ?? ""}"),
      );
    } catch (e) {
      debugPrint("!!! [repay] ERROR: $e");
      return (
        httpStatus: 0,
        state: "failed",
        message: "Check your internet connection and try again",
        startedAt: null,
      );
    }
  }

  /// One poll of repayment-status. Null on a network error (keep polling).
  Future<RepaymentStatus?> getRepaymentStatus(int orderId, int since) async {
    try {
      final response = await dio.get(
        ApiUrls.repaymentStatus(orderId, since),
        options: Options(headers: _authHeaders, validateStatus: (_) => true),
      );
      debugPrint(
        "=== [repaymentStatus] ${response.statusCode}: ${response.data}",
      );
      if (response.data is Map) {
        return RepaymentStatus.fromJson(
          Map<String, dynamic>.from(response.data),
        );
      }
    } catch (e) {
      debugPrint("!!! [repaymentStatus] ERROR: $e");
    }
    return null;
  }

  /// GET orders/standing: may they start another installment plan?
  /// Refreshed on open, on resume and after every payment.
  OrdersStanding? ordersStanding;

  Future<OrdersStanding?> getOrdersStanding() async {
    try {
      final r = await dio.get(
        ApiUrls.ordersStanding,
        options: Options(headers: _authHeaders, validateStatus: (_) => true),
      );
      debugPrint("=== [standing] ${r.statusCode}: ${r.data}");
      if (r.statusCode == 200 && r.data is Map) {
        ordersStanding = OrdersStanding.fromJson(r.data as Map);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("!!! [standing] $e");
    }
    return ordersStanding;
  }

  // ---------------- Reports ----------------

  /// GET reports/reasons: what can be reported, drawn as the form.
  Future<List<ReportTarget>> getReportReasons() async {
    try {
      final r = await dio.get(
        ApiUrls.reportReasons,
        options: Options(headers: _authHeaders, validateStatus: (_) => true),
      );
      final list = r.data is Map ? r.data["targets"] : null;
      if (r.statusCode == 200 && list is List) {
        return list.whereType<Map>().map(ReportTarget.fromJson).toList();
      }
    } catch (e) {
      debugPrint("!!! [reportReasons] $e");
    }
    return [];
  }

  /// POST reports. Returns the HTTP status, message and the report.
  Future<({int code, String message, Report? report, String? errCode})>
  sendReport(Map<String, dynamic> body) async {
    try {
      final r = await dio.post(
        ApiUrls.reports,
        data: body,
        options: Options(headers: _authHeaders, validateStatus: (_) => true),
      );
      debugPrint("=== [report] ${r.statusCode}: ${r.data}");
      final m = r.data is Map ? r.data as Map : const {};
      String msg = m["message"]?.toString() ?? "";
      final errs = m["errors"];
      if (errs is Map && errs.isNotEmpty) {
        final first = errs.values.first;
        msg = first is List && first.isNotEmpty ? "${first.first}" : msg;
      }
      return (
        code: r.statusCode ?? 0,
        message: msg,
        report: m["report"] is Map ? Report.fromJson(m["report"] as Map) : null,
        errCode: m["code"]?.toString(),
      );
    } catch (e) {
      return (
        code: 0,
        message: "Check your internet connection and try again",
        report: null,
        errCode: null,
      );
    }
  }

  /// GET reports: my reports, newest first.
  Future<List<Report>> getMyReports() async {
    try {
      final r = await dio.get(
        ApiUrls.reports,
        queryParameters: {"per_page": 50},
        options: Options(headers: _authHeaders, validateStatus: (_) => true),
      );
      final box = r.data is Map ? (r.data["reports"] ?? r.data["data"]) : null;
      final list = box is Map ? box["data"] : box;
      if (r.statusCode == 200 && list is List) {
        return list.whereType<Map>().map(Report.fromJson).toList();
      }
    } catch (e) {
      debugPrint("!!! [reports] $e");
    }
    return [];
  }

  /// GET orders/{id}/receipts: newest first (the last one is the down
  /// payment). Empty on any failure.
  Future<List<Receipt>> getOrderReceipts(int orderId) async {
    try {
      final r = await dio.get(
        ApiUrls.orderReceipts(orderId),
        queryParameters: {"per_page": 50},
        options: Options(headers: _authHeaders, validateStatus: (_) => true),
      );
      debugPrint("=== [receipts] ${r.statusCode}");
      final box = r.data is Map ? r.data["receipts"] : null;
      final list =
          box is Map ? box["data"] : (box is List ? box : null);
      if (r.statusCode == 200 && list is List) {
        return list
            .whereType<Map>()
            .map((e) => Receipt.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint("!!! [receipts] $e");
    }
    return [];
  }

  /// Keeps the orders list in step with a freshly fetched order.
  void _replaceInList(Order fresh) {
    final i = orders.indexWhere((o) => o.id == fresh.id);
    if (i != -1) orders[i] = fresh;
  }
}