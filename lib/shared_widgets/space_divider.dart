import 'package:flutter/material.dart';

class SDivider extends StatelessWidget {
  const SDivider({super.key});

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Divider(
        color: ch.primaryFixed.withOpacity(0.1),
        thickness: 10,
        height: 20,
      ),
    );
  }
}
