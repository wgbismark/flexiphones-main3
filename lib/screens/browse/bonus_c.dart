import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BonusAdWidget extends StatelessWidget {
  const BonusAdWidget({super.key, required this.isFromDetails});
  final bool isFromDetails;
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return Stack(
      children: [
        Container(
          margin:
              isFromDetails
                  ? const EdgeInsets.only(top: 15.0)
                  : EdgeInsets.zero,
          height: 95,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AdaptiveTheme.of(context).mode.isDark
                    ? Color.fromARGB(255, 17, 39, 59)
                    : isFromDetails
                    ? Color.fromARGB(255, 123, 191, 255)
                    : Color.fromARGB(
                      255,
                      195,
                      220,
                      255,
                    ).withOpacity(0.5), // Blue
                AdaptiveTheme.of(context).mode.isDark
                    ? Color.fromARGB(255, 61, 29, 42)
                    : isFromDetails
                    ? Color.fromARGB(255, 255, 155, 197)
                    : Color.fromARGB(
                      255,
                      255,
                      190,
                      190,
                    ).withOpacity(0.5), // Purple
              ],
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: BonusPackageCard(
                  title: 'Initial Package',
                  dataAmount:
                      '${isFromDetails ? sharedProvider.productDataPackages?.formattedDataAllocation : sharedProvider.orderDataPackages?.formattedDataAllocation} Data',
                  callMinutesIN:
                      '+ ${isFromDetails ? sharedProvider.productDataPackages?.formattedOnnet : sharedProvider.orderDataPackages?.formattedOnnet} OnNet Calls',
                  callMinutesOUT:
                      '+ ${isFromDetails ? sharedProvider.productDataPackages?.formattedOffnet : sharedProvider.orderDataPackages?.formattedOffnet} OffNet Calls',
                  frequency: 'For 6 Months!',
                  isFromDetails: isFromDetails,
                ),
              ),
              SizedBox(
                height: 100,
                child: VerticalDivider(
                  color: Colors.white.withOpacity(0.2),
                  thickness: 4,
                  width: 30,
                ),
              ),
              Expanded(
                child: BonusPackageCard(
                  title: 'Daily Package',
                  dataAmount:
                      '${isFromDetails ? sharedProvider.productDataPackages?.formattedDailyData : sharedProvider.orderDataPackages?.formattedDailyData} Data',
                  callMinutesIN:
                      '+ ${isFromDetails ? sharedProvider.productDataPackages?.formattedDailyOnnet : sharedProvider.orderDataPackages?.formattedDailyOnnet} OnNet Calls',
                  callMinutesOUT:
                      '+ ${isFromDetails ? sharedProvider.productDataPackages?.formattedDailyOffnet : sharedProvider.orderDataPackages?.formattedDailyOffnet} OffNet Calls ',
                  frequency: 'Every Day!',
                  isFromDetails: isFromDetails,
                ),
              ),
            ],
          ),
        ),
        if (isFromDetails)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 3.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(55.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AdaptiveTheme.of(context).mode.isDark
                      ? Color.fromARGB(255, 16, 66, 124)
                      : Color.fromARGB(255, 54, 148, 255), // Blue
                  AdaptiveTheme.of(context).mode.isDark
                      ? Color.fromARGB(255, 92, 35, 68)
                      : Color.fromARGB(255, 255, 126, 201), // Purple
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '🎁 Calls & Data Package',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class BonusPackageCard extends StatelessWidget {
  final String title; // e.g. '🎁 BONUS PACKAGE!'
  final String dataAmount; // e.g. '1000MB Data'
  final String callMinutesIN; // e.g. '+ 296 Minutes Call'
  final String callMinutesOUT; // e.g. '+ 296 Minutes Call'
  final String frequency; // e.g. 'Every Month!'
  final bool isFromDetails;
  const BonusPackageCard({
    super.key,
    required this.title,
    required this.dataAmount,
    required this.callMinutesIN,
    required this.callMinutesOUT,
    required this.frequency,
    required this.isFromDetails,
  });

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.card_giftcard,
              color: isFromDetails ? Colors.white : ch.onSurfaceVariant,
              size: 10.0,
            ),
            SizedBox(width: 5.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.0,
                color: isFromDetails ? Colors.white : ch.onSurfaceVariant,
                // fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Title
        SizedBox(height: 3.0),
        // Data Amount
        Text(
          dataAmount,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
            color: isFromDetails ? Colors.white : ch.onSurfaceVariant,
          ),
        ),
        // Call Minutes
        Container(
          margin: const EdgeInsets.only(top: 3.0),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.0),
            color: Colors.white.withOpacity(0.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                callMinutesOUT,
                style: TextStyle(
                  fontSize: 10.0,
                  color: isFromDetails ? Colors.white : ch.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2),
              Text(
                callMinutesIN,
                style: TextStyle(
                  fontSize: 10.0,
                  color: isFromDetails ? Colors.white : ch.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
