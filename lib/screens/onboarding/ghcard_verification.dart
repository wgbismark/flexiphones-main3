import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/init_screen.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/ghana_card_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GHCardVerification extends StatefulWidget {
  const GHCardVerification({super.key, this.lateVerification = false});
  final bool lateVerification;
  @override
  State<GHCardVerification> createState() => _GHCardVerificationState();
}

class _GHCardVerificationState extends State<GHCardVerification> {
  //  var appController = Get.find<AppController>(tag: "ac");

  @override
  void initState() {
    super.initState();
    // Start empty and in step with the single field below.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<SharedProvider>(context, listen: false);
      p.ghCardEditingController.clear();
      p.ghCardEditingController2.clear();
      p.ghCardValidation = false;
    });
  }

  @override
  void dispose() {
    _cardInput.dispose();
    super.dispose();
  }

  FocusNode ghCardFocusNode = FocusNode();
  FocusNode ghCardFocusNode2 = FocusNode();
  final _cardInput = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 40,
        actionsPadding: EdgeInsets.only(right: 10),
        // automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed:
                () =>
                    widget.lateVerification
                        ? NavigationHelper.pop(context)
                        : NavigationHelper.pushAndRemoveUntil(
                          context,
                          InitScreen(),
                        ),
            child: Text(
              "Skip",
              style: ptstyle(
                size: 12,
                weight: 300,
                color: ch.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Bgw(),
          ListView(
            padding: EdgeInsets.all(20),
            children: [
              SizedBox(height: 20),
              Image.asset(
                AssetsHelper.ghcImage,
                height: 250,
                width: 200,
                fit: BoxFit.contain,
              ),

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Link Your Ghana Card",
                      textAlign: TextAlign.center,
                      style: ptstyle(size: 25, weight: 600),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Enter your Ghana Card number to proceed",
                      textAlign: TextAlign.center,
                      style: ptstyle(size: 12, weight: 300),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              // One field: type the 10 digits; "GHA-" and the dash are
              // added automatically.
              GhanaCardField(
                controller: _cardInput,
                enabled: !sharedProvider.ghCardVrLoading,
                onChanged: (value, complete) {
                  final digits = value.replaceAll('-', '');
                  // Keep the two values validateGHC() sends.
                  sharedProvider.ghCardEditingController.text =
                      digits.length > 9 ? digits.substring(0, 9) : digits;
                  sharedProvider.ghCardEditingController2.text =
                      digits.length > 9 ? digits.substring(9) : "";
                  setState(() {
                    sharedProvider.ghCardValidation =
                        digits.isNotEmpty && !complete;
                  });
                  if (complete) FocusScope.of(context).unfocus();
                },
              ),
              SizedBox(height: 30),

              SizedBox(
                height: 47,
                child: SmartButton(
                  enabled:
                      !sharedProvider.ghCardValidation &&
                      sharedProvider.ghCardEditingController.text.isNotEmpty,
                  loading: sharedProvider.ghCardVrLoading,
                  onPressed: () => sharedProvider.validateGHC(context),
                  child: Text("Verify", style: ptstyle(size: 12, weight: 400)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
