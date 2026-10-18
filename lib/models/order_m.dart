import 'package:flexiphones/models/standing_m.dart';
import 'package:flexiphones/models/customer_m.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/models/vendors.dart';

class OrderResponse {
  final String status;
  final String mesage;
  final List<Order> orders;

  OrderResponse({
    required this.status,
    required this.mesage,
    required this.orders,
  });

  factory OrderResponse.fromJson( json) {
    return OrderResponse(
      status: json['status'],
      mesage: json['mesage'],
      orders: List<Order>.from(json['orders']['data'].map((x) => Order.fromJson(x))),
    );
  }
}

class Order {
  final int id;
  final String? applicationUuid;
  final int productId;
  final int vendorId; 
  final int customerId;
  final int productStorageId;
  final int? uploadId;
  final String color;
  final String? imei;
  final String? imei2;
  final String? serialNumber;
  final String deviceType;
  final String? serviceTenure;
  final int? reloadDays;
  final String? nextDue;
  final String paymentDuration;
  final String initialPayment;
  final String dailyPayment;
  final String licenseFee;
  final String commission;
  final String deviceFinancing;
  final String totalPayment;
  final String? totalPaid; // ✅ NEW FIELD
  final String status;
  final String? deliveryAddress;
  final String? deliveryOption;
  final String orderStatus;

  /// `unpaid` | `paid` — whether the down payment has been paid.
  final String? paymentStatus;

  /// Stable stage code: placed, in_review, confirmed, shipped, delivered,
  /// cancelled. Use for logic and colours.
  final String? orderStage;

  /// Ready-to-show label from the server. Use as the status text on screen.
  final String? displayStatus;

  /// Device lock state from the server (e.g. active, locked, released).
  final String? deviceStatus;

  /// Where the daily payments stand (server-decided, never from dates).
  final RepaymentStanding? standing;

  /// Where the phone itself is (setting up, ready, locked, yours...).
  final PhoneState? phoneState;

  /// "cash" (reserved, paid in person at the shop) or "installment"
  /// (also when missing, on older orders).
  final String saleMode;
  final String? cashReference;
  final String? cashQrPayload;

  bool get isCash => saleMode == "cash";
  final String createdAt;
  final String updatedAt;
  final Customer customer;
  final Vendor vendor;
  final ProductModel product;
  final ProductStorage productStorage;

  Order({
    required this.id,
    this.applicationUuid,
    required this.productId,
    required this.vendorId,
    required this.customerId,
    required this.productStorageId,
    this.uploadId,
    required this.color,
    this.imei,
    this.imei2,
    this.serialNumber,
    required this.deviceType,
    this.serviceTenure,
    this.reloadDays,
    this.nextDue,
    required this.paymentDuration,
    required this.initialPayment,
    required this.dailyPayment,
    required this.licenseFee,
    required this.commission,
    required this.deviceFinancing,
    required this.totalPayment,
    required this.totalPaid, // ✅ NEW FIELD
    required this.status,
    required this.orderStatus,
    this.paymentStatus,
    this.orderStage,
    this.displayStatus,
    this.deviceStatus,
    this.standing,
    this.phoneState,
    this.saleMode = "installment",
    this.cashReference,
    this.cashQrPayload,
    required this.createdAt,
    required this.deliveryAddress,
    required this.updatedAt,
    required this.deliveryOption,
    required this.customer,
    required this.vendor,
    required this.product,
    required this.productStorage,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      applicationUuid: json['application_uuid'],
      productId: json['product_id'],
      vendorId: json['vendor_id'],
      customerId: json['customer_id'],
      productStorageId: json['product_storage_id'],
      uploadId: json['upload_id'],
      color: json['color'],
      imei: json['imei'],
      imei2: json['imei2'],
      serialNumber: json['serial_number'],
      deviceType: json['device_type'],
      serviceTenure: json['service_tenure'],
      reloadDays: json['reload_days'],
      nextDue: json['next_due'],
      paymentDuration: json['payment_duration'],
      initialPayment: json['initial_payment'],
      dailyPayment: json['daily_payment'],
      licenseFee: json['license_fee'],
      commission: json['commission'],
      deviceFinancing: json['device_financing'],
      deliveryOption: json['delivery_option'],
      deliveryAddress: json['delivery_address'],
        
      totalPayment: json['total_payment'],
      totalPaid: json['total_paid'], // ✅ NEW FIELD
      status: json['status'],
      orderStatus: json['order_status'],
      paymentStatus: json['payment_status']?.toString(),
      orderStage: json['order_stage']?.toString(),
      displayStatus: json['display_status']?.toString(),
      deviceStatus: json['device_status']?.toString(),
      standing: RepaymentStanding.tryParse(json['repayment_standing']),
      phoneState: PhoneState.tryParse(json['phone_state']),
      saleMode: (json['sale_mode']?.toString() ?? "installment").toLowerCase(),
      cashReference: json['cash_checkout_reference']?.toString(),
      cashQrPayload: json['cash_checkout_qr_payload']?.toString(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      customer: Customer.fromJson(json['customer']),
      vendor: Vendor.fromJson(json['vendor']),
      product: ProductModel.fromJson(json['product']),
      productStorage: ProductStorage.fromJson(json['product_storage']),
    );
  }

  // The raw `status` field is the device-lock state and must not drive the
  // UI; these getters fall back to `order_status` for older responses.

  /// Lower-case stage code for logic (placed, in_review, confirmed, ...).
  String get stage => (orderStage ?? orderStatus).toLowerCase();

  bool get isPaid => paymentStatus?.toLowerCase() == "paid";

  /// `device_status` when sent, else the raw device-lock `status`.
  String get deviceState =>
      (deviceStatus ?? status).toString().toLowerCase().trim();

  /// The phone is locked for a missed payment.
  bool get isDeviceLocked => deviceState == "locked" || deviceState == "lock";

  /// Fully paid: released to the customer for good.
  bool get isFullyPaid {
    if (deviceState == "released" || stage == "completed") return true;
    final total = double.tryParse(totalPayment) ?? 0;
    final paid = double.tryParse(totalPaid ?? "") ?? 0;
    return total > 0 && paid >= total;
  }

  /// An installment plan that's live: down payment in, not finished, not
  /// cancelled. Cash reservations never are.
  bool get isRunningPlan =>
      !isCash && isPaid && stage != "cancelled" && !isFullyPaid;

  /// A running plan that's behind: the phone is locked, or the last due
  /// day has passed without payment.
  bool get hasMissedPayment {
    if (!isRunningPlan) return false;
    // The server's answer wins: a few hours late already counts as a day.
    if (standing != null) return standing!.isOwing;
    if (isDeviceLocked) return true;
    final due = DateTime.tryParse(nextDue ?? "");
    if (due == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay.isBefore(today);
  }

  /// Waiting on the customer's down payment — the state worth polling.
  bool get awaitingDownPayment => stage == "in_review" && !isPaid;

  /// Text to show the customer as the order's status.
  String get statusLabel {
    if (displayStatus != null && displayStatus!.isNotEmpty) {
      return displayStatus!;
    }
    final s = orderStatus.replaceAll("_", " ");
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

