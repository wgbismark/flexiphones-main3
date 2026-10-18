import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OrderPlacedSuccess extends StatelessWidget {
  const OrderPlacedSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          NavigationHelper.pushAndRemoveUntil(context, HomePage(initScreen: 3));
          return false;
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 150),
                Lottie.asset(
                  AssetsHelper.checkLottie,
                  repeat: false,
                  reverse: true,
                  height: 220,
                  width: 250,
                  fit: BoxFit.contain,
                ),
                Center(
                  child: Text(
                    'Order Placed Successful!',
                    textAlign: TextAlign.center,
                    style: ptstyle(size: 25, weight: 600),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: 200,
                  child: Text(
                    'Your order is being reviewed',
                    textAlign: TextAlign.center,
                    style: ptstyle(
                      size: 12,
                      weight: 400,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: SmartButton(
                    enabled: true,
                    loading: false,
                    onPressed: () {
                      NavigationHelper.pushAndRemoveUntil(
                        context,
                        HomePage(initScreen: 3),
                      );
                    },
                    child: Text('View Orders'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
