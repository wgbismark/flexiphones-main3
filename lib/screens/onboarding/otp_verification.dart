import 'dart:async';

import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key, required this.email, required this.su});
  final String email;
  final bool su;
  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  //var appController = Get.find<AppController>(tag: "ac");

  int _start = 60;
  Timer? _timer;

  void startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_start > 0) {
          _start--;
        } else {
          _timer?.cancel();
          // ✅ When countdown ends
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    startCountdown(); // Start timer on load
  }

  @override
  void dispose() {
    _timer?.cancel(); // Always cancel the timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w600,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ch.onSurfaceVariant.withAlpha(90),
            width: 2,
          ),
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border(bottom: BorderSide(color: ch.primary, width: 2)),
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 40,
      ),
      body: Stack(
        children: [
          Bgw(),
          ListView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            children: [
              Image.asset(
                AssetsHelper.otpImage,
                height: 200,
                width: 200,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 10),

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "OTP Verification",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 25,
                        weight: 700,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Enter the OTP sent to your email",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 12,
                        weight: 300,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ch.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: ptstyle(size: 15, weight: 500),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              Pinput(
                length: 5,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                forceErrorState: !sharedProvider.validOTP,
                keyboardType: TextInputType.number,
                disabledPinTheme: defaultPinTheme.copyWith(
                  textStyle: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: ch.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                onCompleted: (x) async {
                  await sharedProvider.verifyOTP(context, su: widget.su);
                },
                onChanged: (value) => setState(() {}),
                controller: sharedProvider.otpEditingController,
                enabled: !sharedProvider.otpLoading,
              ),
              SizedBox(height: 30),

              SizedBox(
                height: 47,
                child: SmartButton(
                  enabled: sharedProvider.otpEditingController.text.length == 5,
                  loading: sharedProvider.otpLoading,
                  onPressed: () async {
                    await sharedProvider.verifyOTP(context, su: widget.su);
                  },
                  child: Text(
                    "Verify & Proceed",
                    style: ptstyle(size: 12, weight: 500),
                  ),
                ),
              ),
              SizedBox(height: 30),
              if (_start > 1)
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: ch.surfaceContainer.withAlpha(90),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Text(
                      'Resend In $_start seconds',
                      style: ptstyle(
                        size: 12,
                        weight: 400,
                        color: ch.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              if (_start > 1) SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Didn’t receive code?",

                    style: ptstyle(size: 12, weight: 300),
                  ),
                  Opacity(
                    opacity: _start < 1 ? 1 : 0.2,
                    child: AbsorbPointer(
                      absorbing: _start > 1,
                      child: SizedBox(
                        height: 40,
                        child:
                            sharedProvider.emailVerification
                                ? SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Padding(
                                    padding: const EdgeInsets.all(13.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                                : TextButton(
                                  // Resend from the right endpoint: sign-up
                                  // or forgot-password.
                                  onPressed:
                                      () async =>
                                          widget.su
                                              ? sharedProvider.verifyEmail(
                                                context,
                                                ch,
                                              )
                                              : sharedProvider
                                                  .forgottenPassword(
                                                    context,
                                                    ch,
                                                    openOtp: false,
                                                  ),
                                  style: ButtonStyle(
                                    padding: WidgetStatePropertyAll(
                                      EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "Resend",
                                    style: ptstyle(
                                      size: 12,
                                      weight: 500,
                                      color: ch.primary,
                                    ),
                                  ),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
