import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public pages (no sign-in needed).
class LegalUrls {
  static const terms = "https://flexiphones.app/legal#terms";
  static const privacy = "https://flexiphones.app/legal#privacy";
  static const support = "https://api.flexiphones.app/support";
  static const deleteHelp = "https://api.flexiphones.app/support#delete-account";
}

/// Opens a page in an in-app browser.
Future<void> openLegal(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// What a Google / Apple sign-in through Firebase gives back.
class SocialResult {
  const SocialResult({
    required this.firebaseToken,
    this.googleIdToken,
    this.name,
    this.appleAuthCode,
  });

  /// Firebase ID token: what the FlexiPhones API checks.
  final String firebaseToken;
  final String? googleIdToken;

  /// Apple only gives the name the first time.
  final String? name;

  /// Needed to revoke the Apple link after deleting the account.
  final String? appleAuthCode;
}

class SocialAuth {
  static final GoogleSignIn google = GoogleSignIn(
    // iOS needs its own client id (from GoogleService-Info.plist).
    clientId:
        defaultTargetPlatform == TargetPlatform.iOS
            ? '489413845763-g8dt46psak981ntsrlrq8nqti6gdr54g.apps.googleusercontent.com'
            : null,
    serverClientId:
        '489413845763-k1bdvu40o3n3sqr0ao7574rusa8d98s6.apps.googleusercontent.com',
  );

  /// Google account picker → Firebase. Null when cancelled.
  /// [fresh] signs out first so the person picks the account again.
  static Future<SocialResult?> withGoogle({bool fresh = true}) async {
    if (fresh) {
      try {
        await google.signOut();
      } catch (_) {}
    }
    final account = await google.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    final cred = await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      ),
    );
    final token = await cred.user?.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception("Firebase did not return a sign-in token.");
    }
    return SocialResult(firebaseToken: token, googleIdToken: auth.idToken);
  }

  /// Apple sign-in through Firebase (native sheet on iPhone, a browser
  /// window on Android). Null when cancelled.
  static Future<SocialResult?> withApple() async {
    final provider =
        AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');
    try {
      final cred = await FirebaseAuth.instance.signInWithProvider(provider);
      final token = await cred.user?.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw Exception("Firebase did not return a sign-in token.");
      }
      final profile = cred.additionalUserInfo?.profile ?? const {};
      String? name = cred.user?.displayName;
      if ((name ?? "").trim().isEmpty) {
        final n = profile['name'];
        if (n is Map) {
          name = "${n['firstName'] ?? ''} ${n['lastName'] ?? ''}".trim();
        } else if (n is String) {
          name = n;
        }
      }
      return SocialResult(
        firebaseToken: token,
        name: (name ?? "").trim().isEmpty ? null : name!.trim(),
        appleAuthCode: cred.additionalUserInfo?.authorizationCode,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' ||
          e.code == 'web-context-canceled' ||
          e.code == 'user-cancelled' ||
          (e.message ?? '').contains('1001')) {
        return null;
      }
      rethrow;
    }
  }

  /// Turns a sign-in error into words people understand.
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'operation-not-allowed':
          return "Apple sign-in isn't switched on yet. Please use email or Google for now.";
        case 'network-request-failed':
          return "Check your internet connection and try again.";
        case 'account-exists-with-different-credential':
          return "This email already uses another sign-in method.";
        case 'invalid-credential':
          return "The sign-in could not be verified. Please try again.";
      }
      return e.message ?? "Sign-in failed (${e.code}).";
    }
    return "Sign-in failed. Please try again.";
  }

  /// After the FlexiPhones account is deleted: revoke the Apple link
  /// (Apple requires it), delete the Firebase user and sign out.
  /// Failures are ignored: the account itself is already gone.
  static Future<void> cleanupAfterDelete({String? appleAuthCode}) async {
    if (appleAuthCode != null && appleAuthCode.isNotEmpty) {
      try {
        await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(
          appleAuthCode,
        );
      } catch (_) {}
    }
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {}
    try {
      await google.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  /// Which provider the signed-in Firebase user came from, if any.
  static String? currentProvider() {
    final ids =
        FirebaseAuth.instance.currentUser?.providerData
            .map((e) => e.providerId)
            .toList() ??
        const <String>[];
    if (ids.contains('apple.com')) return 'apple';
    if (ids.contains('google.com')) return 'google';
    return null;
  }
}
