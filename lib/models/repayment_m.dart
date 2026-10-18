
import 'package:flexiphones/models/product_m.dart';

/// Root response model
class RepaymentHistoryResponse {
  final String status;
  final String message;
  final RepaymentHistory repaymentHistory;

  RepaymentHistoryResponse({
    required this.status,
    required this.message,
    required this.repaymentHistory,
  });

  factory RepaymentHistoryResponse.fromJson(Map<String, dynamic> json) =>
      RepaymentHistoryResponse(
        status: json['status'] as String,
        message: json['message'] as String,
        repaymentHistory:
            RepaymentHistory.fromJson(json['repayment_history']),
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'repayment_history': repaymentHistory.toJson(),
      };
}

/// Contains the list and pagination metadata
class RepaymentHistory {
  final List<RepaymentEntry> data;
  final String path;
  final int perPage;
  final dynamic nextCursor;
  final dynamic nextPageUrl;
  final dynamic prevCursor;
  final dynamic prevPageUrl;

  RepaymentHistory({
    required this.data,
    required this.path,
    required this.perPage,
    this.nextCursor,
    this.nextPageUrl,
    this.prevCursor,
    this.prevPageUrl,
  });

  factory RepaymentHistory.fromJson(Map<String, dynamic> json) =>
      RepaymentHistory(
        data: (json['data'] as List)
            .map((e) => RepaymentEntry.fromJson(e))
            .toList(),
        path: json['path'] as String,
        perPage: json['per_page'] as int,
        nextCursor: json['next_cursor'],
        nextPageUrl: json['next_page_url'],
        prevCursor: json['prev_cursor'],
        prevPageUrl: json['prev_page_url'],
      );

  Map<String, dynamic> toJson() => {
        'data': data.map((e) => e.toJson()).toList(),
        'path': path,
        'per_page': perPage,
        'next_cursor': nextCursor,
        'next_page_url': nextPageUrl,
        'prev_cursor': prevCursor,
        'prev_page_url': prevPageUrl,
      };
}

/// Individual repayment record
class RepaymentEntry {
  final int id;
  final int customerId;
  final int applicationId;
  final int vendorId;
  final String internalReference;
  final String externalReference;
  final String clientReference;
  final String amountOwed;
  final String before;
  final String amountPaid;
  final String after;
  final DateTime datePaid;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Application application;

  RepaymentEntry({
    required this.id,
    required this.customerId,
    required this.applicationId,
    required this.vendorId,
    required this.internalReference,
    required this.externalReference,
    required this.clientReference,
    required this.amountOwed,
    required this.before,
    required this.amountPaid,
    required this.after,
    required this.datePaid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.application,
  });

  factory RepaymentEntry.fromJson(Map<String, dynamic> json) =>
      RepaymentEntry(
        id: json['id'] as int,
        customerId: json['customer_id'] as int,
        applicationId: json['application_id'] as int,
        vendorId: json['vendor_id'] as int,
        internalReference: json['internal_reference'] as String,
        externalReference: json['external_reference'] as String,
        clientReference: json['client_reference'] as String,
        amountOwed: json['amount_owed'] as String,
        before: json['before'] as String,
        amountPaid: json['amount_paid'] as String,
        after: json['after'] as String,
        datePaid: DateTime.parse(json['date_paid'] as String),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        application: Application.fromJson(json['application']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'application_id': applicationId,
        'vendor_id': vendorId,
        'internal_reference': internalReference,
        'external_reference': externalReference,
        'client_reference': clientReference,
        'amount_owed': amountOwed,
        'before': before,
        'amount_paid': amountPaid,
        'after': after,
        'date_paid': datePaid.toIso8601String().split('T').first,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'application': application.toJson(),
      };
}

/// Associated loan/application details
class Application {
  final int id;
  final dynamic applicationUuid;
  final int productId;
  final int vendorId;
  final int customerId;
  final int productStorageId;
  final dynamic uploadId;
  final String color;
  final String imei;
  final String imei2;
  final dynamic serialNumber;
  final String deviceType;
  final String serviceTenure;
  final int reloadDays;
  final DateTime nextDue;
  final String paymentDuration;
  final String initialPayment;
  final String dailyPayment;
  final String licenseFee;
  final String commission;
  final String deviceFinancing;
  final String totalPayment;
  final String totalPaid;
  final String status;
  final String orderStatus;
  final String deliveryOption;
  final dynamic deliveryAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductModel product;

  Application({
    required this.id,
    this.applicationUuid,
    required this.productId,
    required this.vendorId,
    required this.customerId,
    required this.productStorageId,
    this.uploadId,
    required this.color,
    required this.imei,
    required this.imei2,
    this.serialNumber,
    required this.deviceType,
    required this.serviceTenure,
    required this.reloadDays,
    required this.nextDue,
    required this.paymentDuration,
    required this.initialPayment,
    required this.dailyPayment,
    required this.licenseFee,
    required this.commission,
    required this.deviceFinancing,
    required this.totalPayment,
    required this.totalPaid,
    required this.status,
    required this.orderStatus,
    required this.deliveryOption,
    this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
  });

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        id: json['id'] as int,
        applicationUuid: json['application_uuid'],
        productId: json['product_id'] as int,
        vendorId: json['vendor_id'] as int,
        customerId: json['customer_id'] as int,
        productStorageId: json['product_storage_id'] as int,
        uploadId: json['upload_id'],
        color: json['color'] as String,
        imei: json['imei'] as String,
        imei2: json['imei2'] as String,
        serialNumber: json['serial_number'],
        deviceType: json['device_type'] as String,
        serviceTenure: json['service_tenure'] as String,
        reloadDays: json['reload_days'] as int,
        nextDue: DateTime.parse(json['next_due'] as String),
        paymentDuration: json['payment_duration'] as String,
        initialPayment: json['initial_payment'] as String,
        dailyPayment: json['daily_payment'] as String,
        licenseFee: json['license_fee'] as String,
        commission: json['commission'] as String,
        deviceFinancing: json['device_financing'] as String,
        totalPayment: json['total_payment'] as String,
        totalPaid: json['total_paid'] as String,
        status: json['status'] as String,
        orderStatus: json['order_status'] as String,
        deliveryOption: json['delivery_option'] as String,
        deliveryAddress: json['delivery_address'],
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        product: ProductModel.fromJson(json['product']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'application_uuid': applicationUuid,
        'product_id': productId,
        'vendor_id': vendorId,
        'customer_id': customerId,
        'product_storage_id': productStorageId,
        'upload_id': uploadId,
        'color': color,
        'imei': imei,
        'imei2': imei2,
        'serial_number': serialNumber,
        'device_type': deviceType,
        'service_tenure': serviceTenure,
        'reload_days': reloadDays,
        'next_due': nextDue.toIso8601String().split('T').first,
        'payment_duration': paymentDuration,
        'initial_payment': initialPayment,
        'daily_payment': dailyPayment,
        'license_fee': licenseFee,
        'commission': commission,
        'device_financing': deviceFinancing,
        'total_payment': totalPayment,
        'total_paid': totalPaid,
        'status': status,
        'order_status': orderStatus,
        'delivery_option': deliveryOption,
        'delivery_address': deliveryAddress,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'product': product.toJson(),
      };
}
