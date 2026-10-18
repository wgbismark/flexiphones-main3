import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';

class PaymentMethod extends StatefulWidget {
  const PaymentMethod({
    super.key,
    required this.selectedPaymentMethod,
    required this.paymentChanged,
  });
  final String selectedPaymentMethod;
  final ValueChanged paymentChanged;
  @override
  State<PaymentMethod> createState() => _PaymentMethodState();
}

class _PaymentMethodState extends State<PaymentMethod> {
  List paymentMethods = [
    {'id': 'mobile-money', 'name': 'Mobile Money', 'icon': AssetsHelper.mmImg},
    {'id': 'card', 'name': 'Credit/Debit Card', 'icon': AssetsHelper.cardImg},
  ];
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return // Step 1: Payment Method Selection
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: ptstyle(size: 16, weight: 400)),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: ch.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            separatorBuilder:
                (context, index) => Divider(
                  height: 1,
                  color: ch.onSurfaceVariant.withOpacity(0.1),
                ),
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              final method = paymentMethods[index];
              return RadioListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Image.asset(method['icon'], width: 30, height: 30),
                    SizedBox(width: 10),
                    Text(method['name'], style: ptstyle(size: 15, weight: 400)),
                  ],
                ),
                value: method['id'],
                groupValue: widget.selectedPaymentMethod,
                onChanged: widget.paymentChanged,
              );
            },
          ),
        ),
      ],
    );
  }
}
