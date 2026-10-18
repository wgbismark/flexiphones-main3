import 'package:flexiphones/extensions/value_formating.dart';

class NotificationResponse {
  final List<NotificationData> data;
  final Pagination pagination;
  final int? unreadCount;

  NotificationResponse({
    required this.data,
    required this.pagination,
    this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      data:
          (json['data'] as List)
              .map((e) => NotificationData.fromJson(e))
              .toList(),
      pagination: Pagination.fromJson(json['pagination']),
      unreadCount: int.tryParse("${json['unread_count'] ?? ""}"),
    );
  }
}

class NotificationData {
  final String id;
  final String notifiableType;
  final int notifiableId;
  final String type;
  final NotificationContent data;
  final String status;
  final String? channel;
  final String? readAt;
  final String createdAt;
  final String updatedAt;

  NotificationData({
    required this.id,
    required this.notifiableType,
    required this.notifiableId,
    required this.type,
    required this.data,
    required this.status,
    this.channel,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// `read_at` is null while unread; read state is shared with the vendor
  /// portal, so it can change from outside the app.
  bool get isUnread =>
      status.toLowerCase() == "unread" ||
      (readAt == null && status.toLowerCase() != "read");

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      notifiableType: json['notifiable_type'],
      notifiableId: json['notifiable_id'],
      type: json['type'],
      data: NotificationContent.fromJson(json['data']),
      status: json['status'],
      channel: json['channel'],
      readAt: json['read_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class NotificationContent {
  final String title;
  final String message;
  final String status;

  /// Set on order notifications (e.g. "Down payment received"); tapping
  /// the notification opens this order.
  final int? orderId;
  final String? applicationUuid;
  final String? orderStage;

  /// order_status_changed | down_payment_received | payment_completed |
  /// repayment_reminder | device_locked | plan_completed | account_notice |
  /// null (e.g. "New Order Placed"). Unknown kinds show title + message.
  final String? kind;

  /// For repayment_reminder: due_tomorrow, due_today, missed_1, missed_3,
  /// missed_7.
  final String? reminderStage;

  /// For review_reply: the review the shop answered.
  final int? reviewId;

  /// For app_update: the store page and whether old versions are blocked.
  final String? androidUrl;
  final String? iosUrl;
  final bool updateRequired;

  NotificationContent({
    required this.title,
    required this.message,
    required this.status,
    this.orderId,
    this.applicationUuid,
    this.orderStage,
    this.kind,
    this.reminderStage,
    this.reviewId,
    this.androidUrl,
    this.iosUrl,
    this.updateRequired = false,
  });

  bool get isDownPayment =>
      kind == "down_payment_received" ||
      title.toLowerCase() == "down payment received";

  bool get isRepaymentReminder => kind == "repayment_reminder";

  bool get isPaymentCompleted => kind == "payment_completed";

  /// A missed day locked the phone; Pay now unlocks it.
  bool get isDeviceLocked => kind == "device_locked";

  /// The last instalment was paid: the phone is the customer's for good.
  bool get isPlanCompleted => kind == "plan_completed";

  bool get isAccountNotice => kind == "account_notice";

  /// A shop answered the customer's review.
  bool get isReviewReply => kind == "review_reply";

  /// A new app version is out.
  bool get isAppUpdate => kind == "app_update";

  /// Any notification about an order — the order should be refreshed.
  bool get isOrderUpdate => orderId != null || applicationUuid != null;

  factory NotificationContent.fromJson(Map<String, dynamic> json) {
    return NotificationContent(
      title: json['title']?.toString() ?? "",
      message: (json['message'] ?? "").toString().toSentenceCase(),
      status: json['status']?.toString() ?? "",
      orderId: int.tryParse("${json['order_id'] ?? ""}"),
      applicationUuid: json['application_uuid']?.toString(),
      orderStage: json['order_stage']?.toString(),
      kind: json['kind']?.toString(),
      reminderStage: json['reminder_stage']?.toString(),
      reviewId: int.tryParse("${json['review_id'] ?? ""}"),
      androidUrl: json['android_url']?.toString(),
      iosUrl: json['ios_url']?.toString(),
      updateRequired: json['required'] == true,
    );
  }
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }
}
