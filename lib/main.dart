import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flexiphones/helpers/app_update.dart';
import 'package:flexiphones/provider/mixins/session/session.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/init_screen.dart';
import 'package:flexiphones/screens/onboarding/email_phone/phone_signin.dart';
import 'package:flexiphones/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:provider/provider.dart';

//80001fcxvoid
//

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase is only needed for "Continue with Google". If it can't start
  // (bad config, no Play services), the rest of the app must still open.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("!!! Firebase init failed: $e");
  }
  // Version, platform and anonymous device id for every request.
  await AppInfo.load();

  runApp(
    ChangeNotifierProvider(
      create: (context) => SharedProvider(),
      child: const MyApp(),
    ),
  );
  // "Please update" check: first thing on launch (signed in or not) and
  // again whenever the app comes back.
  AppUpdate.start();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: lightTH,
      dark: darkTH,
      initial: AdaptiveThemeMode.light,
      overrideMode: AdaptiveThemeMode.light,
      builder:
          (theme, darkTheme) => MaterialApp(
            navigatorKey: sessionNavigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Flexi Phones',
            theme: theme,

            builder: (context, child) {
              final MediaQueryData data = MediaQuery.of(context);
              return MediaQuery(
                data: data.copyWith(
                  textScaler: TextScaler.noScaling,
                ), // Use TextScaler.noScaling for Flutter 3.29+
                child: child!,
              );
            },
            home:  InitScreen(),
          ),
    );
  }


}

var lightTH = ThemeData(
  useMaterial3: true,
  pageTransitionsTheme: _slideTransitions,

  splashColor: Colors.lightBlueAccent.withOpacity(0.1), // Remove splash ripple
  highlightColor: Colors.blueAccent[50], // Remove highlight on tap
  hoverColor: Colors.transparent,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    primary: AppColors.primaryColor,
    surface: const Color.fromARGB(255, 253, 254, 255),
  ),
);

final ThemeData darkTH = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  pageTransitionsTheme: _slideTransitions,

  // General Colors
  primaryColor: AppColors.primaryColor,
  scaffoldBackgroundColor: const Color(0xFF121212),
  canvasColor: const Color(0xFF1E1E1E),
  cardColor: const Color(0xFF1C1C1C),
  dividerColor: Colors.grey[700],
  disabledColor: Colors.grey[600],
  focusColor: const Color.fromARGB(255, 4, 45, 78).withOpacity(0.12),
  hoverColor: Colors.transparent,

  // Ripple and interaction effects
  splashColor: Colors.lightBlueAccent.withOpacity(0.1),
  highlightColor: const Color.fromARGB(255, 17, 29, 48),

  // AppBar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),

  // Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor),
  ),

  // Input Decoration Theme (TextFields)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E1E1E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primaryColor),
    ),
    labelStyle: const TextStyle(color: Colors.white70),
    hintStyle: const TextStyle(color: Colors.white38),
  ),

  // Text Theme
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    bodySmall: TextStyle(color: Colors.white60),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    labelLarge: TextStyle(color: Colors.white),
  ),

  // Icon Theme
  iconTheme: const IconThemeData(color: Colors.white70),

  // SnackBar Theme
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF2E2E2E),
    contentTextStyle: TextStyle(color: Colors.white),
    actionTextColor: Colors.blueAccent,
    behavior: SnackBarBehavior.floating,
  ),

  // Floating Action Button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: Colors.white,
  ),

  // Color Scheme
  colorScheme: ColorScheme.fromSeed(
    primaryFixed: const Color.fromARGB(255, 35, 44, 51),
    seedColor: Colors.blue,
    brightness: Brightness.dark,
    primary: AppColors.primaryColor,
    onPrimary: Colors.white,
    secondary: Colors.blueAccent,
    onSecondary: Colors.white,
    background: const Color(0xFF121212),
    onBackground: Colors.white,
    surface: const Color(0xFF121212),
    onSurface: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
  ),
);

/// iOS-style slide (with swipe-back) for every MaterialPageRoute too.
const _slideTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);
