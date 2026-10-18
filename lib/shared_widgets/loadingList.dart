import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class LoadingListIndicator extends StatelessWidget {
  const LoadingListIndicator({super.key,});


  @override
  Widget build(BuildContext context) {
      var ch = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(5),
      color: Colors.transparent,
      height: 35,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 22,
            width: 80,
            child: Material(
              color: ch.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: LoadingIndicator(
                  indicatorType: Indicator.ballPulse,
                  colors: [ch.primary, ch.primaryFixed],
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
