import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/utils/values.dart';
import 'package:flutter/material.dart';

class PaymentConfirmation extends StatelessWidget {
  const PaymentConfirmation({
    super.key,
    required this.totalAmount,
    required this.referenceId,
  });
  final double totalAmount;
  final String referenceId;
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reference Id: $referenceId',
          style: ptstyle(size: 15, weight: 400),
        ),
        SizedBox(height: 10),

        Text(
          'Total ${GlobalValues.ghCurrency} ${totalAmount.toStringAsFixed(2)}',
          style: ptstyle(size: 25, weight: 600),
        ),
        SizedBox(height: 10),
        Text(
          'Enter Mobile Money Number',
          style: ptstyle(size: 12, weight: 400),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: ch.surfaceContainerLow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("233 7489895"),
              TextButton(onPressed: () {}, child: Text("Change")),
            ],
          ),
        ),
      ],
    );
  }
}
