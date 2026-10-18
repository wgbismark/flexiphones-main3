import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class VerificationSuccess extends StatelessWidget {
  const VerificationSuccess({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            SizedBox(height: 80),

            Center(
              child: Lottie.asset(
                AssetsHelper.checkLottie,
                repeat: false,
                reverse: true,
                height: 250,
                width: 250,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Ghana Card verified",
              textAlign: TextAlign.center,
              style: ptstyle(size: 25, weight: 600),
            ),
            SizedBox(height: 10),
            Text(
              "You have successfully linked your Ghana Card, proceed to make an order now",
              textAlign: TextAlign.center,
              style: ptstyle(
                size: 12,
                weight: 300,
                color: ch.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 50),
            SizedBox(
              height: 47,
              child: SmartButton(
                enabled: true,
                loading: false,
                onPressed: () {
                  NavigationHelper.pushAndRemoveUntil(context, HomePage());
                },
                child: Text("Continue", style: ptstyle(size: 12, weight: 400)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
