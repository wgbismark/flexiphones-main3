import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/st_values.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';

class SumCard extends StatelessWidget {
  const SumCard({
    super.key,
    required this.ch,
    required this.value,
    required this.title,
    this.onTap,
    this.enable = false,
    this.clk = false,
  });

  final ColorScheme ch;
  final String value, title;
  final bool enable;
  final bool clk;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: enable ? ch.primary.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
            color: ch.surfaceContainerLow.withOpacity(0.5),
          ),

          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                Text(
                  value.toHumanReadable(),
                  style: ptstyle(
                    size: clk ? 10 : 12,
                    weight: 600,
                    color: ch.onSurfaceVariant,
                  ),
                ),
                Text(
                  title,
                  style: ptstyle(
                    size: clk ? 10 : 10,
                    weight: 400,
                    color:
                        clk
                            ? STV.getDeliveryStatusColor(title, ch)
                            : ch.onSurfaceVariant,
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
