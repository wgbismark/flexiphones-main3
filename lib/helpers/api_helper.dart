import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DS {
  static final storage = FlutterSecureStorage();
  static final sharedStorage = SharedPreferences.getInstance();
}

/// Copy of a sign-in / refresh response with `expires_at` worked out from
/// `expires_in` (seconds left now) on this phone's clock, so a wrong phone
/// clock can't make a token look valid or expired. `expires_in` is dropped
/// so a stored copy is never re-read as "seconds left now".
Map<String, dynamic> stampExpiry(dynamic body) {
  final m = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
  final secs = num.tryParse("${m.remove('expires_in') ?? ''}");
  if (secs != null) {
    m['expires_at'] = DateTime.now()
        .add(Duration(seconds: secs.toInt()))
        .toUtc()
        .toIso8601String();
  }
  return m;
}

class ApiUrls {
  static const base = "https://api.flexiphones.app/api";
  // static const base = "https://portal.flexiphones.app/api";
  // static const base = "http://192.168.100.25:8005/api";
  static const ImageBase = "https://api.flexiphones.app/assets/images/";
  // static const ImageBase = "https://portal.flexiphones.app/assets/images/";
  //?ACCOUNTS — one email can be a customer AND an agent (two accounts,
  // two tokens). /login takes "as": "customer" | "agent".
  static const loginAsPST = "$base/login";
  static const auth = "$base/auth";
  static const googleAuthPST = "$auth/google";
  static const googleCompleteProfilePST = "$auth/google/complete-profile";
  static const appleAuthPST = "$auth/apple";
  static const appVersion = "$base/app-version";
  static const deleteAccountDEL = "$base/account";
  static const cashReservationsPST = "$base/v1/orders/cash-reservations";
  static String cashReservationStatus(String reference) =>
      "$base/v1/orders/cash-reservations/$reference";
  static String vendorLocations(int vendorId) => "$base/v1/get-vendor/$vendorId/locations";
  static const accountRolesPST = "$base/account-roles";
  //?SESSION — tokens last 24h (any role's token works on these)
  static const sessionGET = "$base/session";
  static const tokenRefreshPST = "$base/token/refresh";
  static const logoutPST = "$base/logout";
  //?USER
  static const customer = "$base/customer";
  static const emailVerificationPST = "$customer/email-verification";
  static const otpVerificationPST = "$customer/email-otp-verification";
  static const finalRegistrationPST = "$customer/registration";
  static const loginPST = "$customer/login";
  static const forgotPasswordPST = "$customer/forgot-password";
  static const verifyResetOtpPST = "$customer/verify-reset-otp";
  static const applyPromoCodePST = "$customer/apply-promo-code";
  static const myReferralGET = "$customer/my-referral";
  static const resetPasswordPST = "$customer/create-new-password";
  static const updateGHCard = "$customer/update-ghana-card/";
  static const updateUSER = "$customer/profile/update";
  // Customer referral code + points wallet (friend-to-friend, not the
  // agent promo code above).
  static const referralGET = "$customer/referral";
  static const referralCodePST = "$customer/referral-code";
  static const applyReferralCodePST = "$customer/apply-referral-code";
  static const referralsGET = "$customer/referrals";
  static const pointsGET = "$customer/points";
  static const userNotifications = "$base/v1/notifications";
  static const userUnreadCount = "$base/v1/notifications/unread-count";
  //?Products — same filters/sort on all three lists (see productQuery).
  static const getProducts = "$base/v1/get-products";
  static const getProductsOFF = "$base/v1/products";
  static const brandsGET = "$base/v1/brands";
  static const favoritesGET = "$base/v1/favorites";
  static String favorite(int productId) =>
      "$base/v1/products/$productId/favorite";

  // Signed in: "/v1/get-product/{id}" (also returns product.is_favorite);
  // guests: the public "/v1/product/{id}". Both count one view.
  // getProductDetails() falls back to the public route if the signed-in
  // one fails.
  static const getProductsDetails = "$base/v1/get-product";
  static const getProductsDetailsOFF = "$base/v1/product";

  static const searchProducts = "$base/v1/search";

  static const topDeals = "$base/v1/deals/get-top-deals";
  static const topDealsOFF = "$base/v1/deals/top-deals";

  static const hotDeals = "$base/v1/deals/hot-deals";
  static const hotDealsOFF = "$base/v1/deals/hot-deals";
  //? product Rating
  static const rateProduct = "$base/v1/create-product-review";
  // Reviews of vendors and phones (customer token; cursor paged).
  static String vendorReviews(dynamic vendorId) =>
      "$base/v1/get-vendor-reviews/$vendorId";
  static String productReviews(dynamic productId) =>
      "$base/v1/get-product-reviews/$productId";
  static const createVendorReview = "$base/v1/create-vendor-review";
  static const createProductReview = "$base/v1/create-product-review";
  static String review(int id) => "$base/v1/reviews/$id"; // PUT / DELETE
  static const myReviews = "$base/v1/my-reviews";
  //?Vendors
  static const getVendors = "$base/v1/get-vendors";
  static const getVendorDetails = "$base/v1/get-vendor";
  //?orders
  static const addOrders = "$base/v1/orders/create-order";
  static const getOrders = "$base/v1/orders/get-customer-orders";
  static const getOrder = "$base/v1/orders/get-order-by-id";
  static const cancelOrder = "$base/v1/orders/cancel-order";
  static const repaymentCL = "$base/v1/orders/get-repayment-history";
  // In-app repayments (customer paying instalments)
  static String repaymentInfo(int orderId) =>
      "$base/v1/orders/$orderId/repayment-info";
  static String repay(int orderId) => "$base/v1/orders/$orderId/repay";
  static String repayBulk(int orderId) =>
      "$base/v1/orders/$orderId/repay-bulk";
  static const ordersStanding = "$base/v1/orders/standing";
  static const reportReasons = "$base/v1/reports/reasons";
  static const reports = "$base/v1/reports";
  static String orderReceipts(int orderId) =>
      "$base/v1/orders/$orderId/receipts";
  static String repaymentStatus(int orderId, int since) =>
      "$base/v1/orders/$orderId/repayment-status?since=$since";
  // Payment squares: one phone, or all the customer's phones together.
  static String orderPaymentCalendar(int orderId) =>
      "$base/v1/orders/$orderId/payment-calendar";
  static const paymentCalendarGET = "$base/v1/orders/payment-calendar";
  //
  static const priceBrakeDown = "$base/v1/price-breakdown";
  static String pricingBreakdown(dynamic productStorageId) =>
      "$base/v1/products/$productStorageId/pricing-breakdown";

  //?PARTNER (Agent) — mirrors routes/api.php `Route::prefix('partner')`.
  // NOTE: these are NOT under /v1 on the backend.
  static const partner = "$base/partner";
  // auth (public)
  static const partnerEmailVerificationPST = "$partner/email-verification";
  static const partnerOtpVerificationPST = "$partner/email-otp-verification";
  static const partnerRegistrationPST = "$partner/registration";
  static const partnerLoginPST = "$partner/login";
  static const partnerForgotPasswordPST = "$partner/forgot-password";
  static const partnerVerifyResetOtpPST = "$partner/verify-reset-otp";
  static const partnerResetPasswordPST = "$partner/create-new-password";
  // auth:sanctum
  static const partnerUpdateGHCard = "$partner/update-ghana-card/"; // + partnerId
  static const partnerApproval = "$partner/approval";
  static const partnerBecomeCustomer = "$partner/become-customer";
  static const partnerProfile = "$partner/profile";
  static const partnerProfileUpdate = "$partner/profile/update";
  static const partnerPhoto = "$partner/profile/photo";
  static const customerProfileUpdate = "$customer/profile/update";
  static const customerPhoto = "$customer/profile/photo";
  static const partnerOnboardVendorPST = "$partner/onboard-vendor";
  static const partnerVendorsGET = "$partner/my-vendors";
  static String partnerResendInvite(int vendorId) =>
      "$partner/vendors/$vendorId/resend-invite";
  static const partnerMomoDetails = "$partner/momo-details"; // GET/POST/PUT/DELETE
  static const partnerMomoLookupPST = "$partner/momo-details/lookup";
  static const partnerMomoCodePST = "$partner/momo-details/code"; // change number
  static const partnerWalletGET = "$partner/wallet";
  static const partnerTransactionsGET = "$partner/wallet/transactions";
  // Withdrawals: email a code, then confirm with it.
  static const partnerWithdrawalCodePST = "$partner/withdrawals/code";
  static const partnerWithdrawals = "$partner/withdrawals"; // GET list / POST confirm
  static const partnerEarningsGET = "$partner/earnings";
  static const partnerPointsGET = "$partner/points";
  static const partnerNotifications = "$partner/notifications";
  static const partnerUnreadCount = "$partner/notifications/unread-count";
  static const partnerPromoUsageGET = "$partner/promo-usage";
  static const partnerNotificationSettings = "$partner/notification-settings";
  // A signed-in customer becoming an agent (customer token)
  static const customerAgentStatusGET = "$customer/agent-status";
  static const customerBecomeAgentPST = "$customer/become-agent";

  /// Some endpoints (e.g. product detail) return a full absolute image
  /// URL already (e.g. placeholder.com links), while others return a
  /// bare filename that needs [ImageBase] prefixed. Blindly prefixing
  /// an already-absolute URL produces a broken doubled-up link — this
  /// resolves both cases safely.
  static String resolveImage(dynamic path) {
    if (path == null) return "";
    final p = path.toString();
    if (p.isEmpty) return "";
    if (p.startsWith("http://") || p.startsWith("https://")) return p;
    return "$ImageBase$p";
  }

  /// A product's main photo. Prefers the ready-made `main_image_url`, then
  /// the first of `image_urls`, then the legacy `image` field (a path, or a
  /// list of paths). "" when the phone has no photo (show a placeholder).
  static String productMainImage(dynamic json) {
    if (json is! Map) return "";
    final main = json['main_image_url'];
    if (main is String && main.isNotEmpty) return main;
    final urls = json['image_urls'];
    if (urls is List) {
      return urls.isEmpty ? "" : resolveImage(urls.first);
    }
    var raw = json['image'];
    if (raw is List) raw = raw.isNotEmpty ? raw.first : null;
    return resolveImage(raw);
  }

  /// A product's colours as the "{A,B}" text every screen already reads.
  /// Prefers the new `color_list` (a plain list like ["BLACK","SKY BLUE"]);
  /// falls back to the legacy `colors` text ("{BLACK, SKY BLUE}" or a
  /// JSON-array string) for older responses and cached data.
  static String productColorsText(dynamic json) {
    if (json is! Map) return "{}";
    final list = json['color_list'];
    if (list is List) {
      return "{${list.map((c) => "$c".trim()).where((c) => c.isNotEmpty).join(",")}}";
    }
    final raw = json['colors'];
    if (raw == null) return "{}";
    var s = raw.toString().trim();
    if (s.isEmpty) return "{}";
    if (s.startsWith("[")) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) return "{${decoded.map((e) => "$e".trim()).join(",")}}";
      } catch (_) {
        s = s.replaceAll("[", "").replaceAll("]", "").replaceAll('"', "");
        return "{$s}";
      }
    }
    return s.startsWith("{") ? s : "{$s}";
  }

  /// The colours as a list, e.g. for order `color` values.
  static List<String> productColorList(dynamic json) => productColorsText(json)
      .replaceAll("{", "")
      .replaceAll("}", "")
      .split(",")
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();

  /// All of a product's photos in display order (main first), from
  /// `image_urls`; falls back to the legacy `images` / `image` fields for
  /// older responses and cached data. Empty = no photos.
  static List<String> productImageUrls(dynamic json) {
    if (json is! Map) return [];
    final urls = json['image_urls'];
    if (urls is List) {
      return urls.map(resolveImage).where((u) => u.isNotEmpty).toList();
    }
    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      return images
          .map((x) => resolveImage(x is Map ? x["image_path"] : x))
          .where((u) => u.isNotEmpty)
          .toList();
    }
    final main = productMainImage(json);
    return main.isEmpty ? [] : [main];
  }
}