import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/models/packages.dart';
import 'package:flexiphones/models/price_model.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StorageCard extends StatefulWidget {
  const StorageCard({
    super.key,
    required this.staticObj,
    required this.tn,
    required this.enabled,
    required this.select,
    this.selectTenure,
    this.selectColor,
    this.colors,
    required this.cl,
    required this.data,

    required this.breakdowns,
  });
  final bool staticObj;
  final int tn;
  final bool enabled;
  final VoidCallback select;
  final dynamic selectTenure;
  final dynamic selectColor;
  final String? colors;
  final String cl;
  final ProductStorage data;
  final Breakdowns? breakdowns;

  @override
  State<StorageCard> createState() => _StorageCardState();
}

class _StorageCardState extends State<StorageCard> {
  //! device ff 0.03 !add to down payment
  dynamic get slMonth => widget.breakdowns!.months["${widget.tn}_months"];

  bool get financeable => widget.breakdowns == null || isFinanceable(slMonth);

  String get initialPayment =>
      widget.breakdowns == null
          ? ""
          : double.parse(
            slMonth["initial_payment"].toString(),
          ).toCommaSeparated(0, decimalPlaces: 2);

  String get totalPayment =>
      widget.breakdowns == null
          ? ""
          : double.parse(
            slMonth["total_price"].toString(),
          ).toCommaSeparated(0, decimalPlaces: 2);

  String get dailyPayment =>
      widget.breakdowns == null
          ? ""
          : double.parse(
            slMonth["daily_payment"].toString(),
          ).toCommaSeparated(0, decimalPlaces: 2);

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    // Clean and split
    List<String> colorNames =
        widget.colors == null
            ? []
            : widget.colors!
                .replaceAll("{", "")
                .replaceAll("}", "")
                .split(",")
                .map((e) => e.trim())
                .toList();
    //  final sharedProvider = Provider.of<SharedProvider>(context);

    return Stack(
      children: [
        InkWell(
          onTap: widget.select,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 400),
            margin:
                widget.staticObj
                    ? null
                    : EdgeInsets.only(left: 0, right: 0, top: 12, bottom: 0),
            padding:
                widget.staticObj
                    ? null
                    : EdgeInsets.symmetric(horizontal: 3, vertical: 5),
            decoration: BoxDecoration(
              color: ch.surface,
              border:
                  widget.staticObj
                      ? Border.all(
                        color:
                            widget.enabled
                                ? ch.primary
                                : ch.onSurfaceVariant.withOpacity(0.1),
                        width: 1,
                      )
                      : Border.all(
                        color:
                            widget.enabled
                                ? ch.primary
                                : ch.surfaceContainerHigh,
                        width: 1,
                      ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.staticObj && !financeable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: Text(
                      notFinanceableText,
                      style: ptstyle(
                        size: 12,
                        weight: 600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                if (!widget.staticObj && financeable)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Initial Payment',
                                style: ptstyle(
                                  size: 10,
                                  weight: 400,
                                  color:
                                      widget.enabled
                                          ? const Color.fromARGB(
                                            255,
                                            102,
                                            134,
                                            160,
                                          )
                                          : ch.onSurfaceVariant.withOpacity(
                                            0.8,
                                          ),
                                ),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(
                                    "GHS ",

                                    style: ptstyle(
                                      size: 18,
                                      weight: 700,
                                      color: ch.onSurfaceVariant.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    initialPayment,
                                    style: ptstyle(
                                      size: 18,
                                      weight: 700,
                                      color:
                                          widget.enabled
                                              ? ch.primary
                                              : ch.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 10,
                          height: 25,
                          child: VerticalDivider(
                            color: ch.onSurfaceVariant.withOpacity(0.15),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Payment',
                                style: ptstyle(
                                  size: 10,
                                  weight: 400,
                                  color:
                                      widget.enabled
                                          ? const Color.fromARGB(
                                            255,
                                            102,
                                            134,
                                            160,
                                          )
                                          : ch.onSurfaceVariant.withOpacity(
                                            0.8,
                                          ),
                                ),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(
                                    "GHS ",

                                    style: ptstyle(
                                      size: 18,
                                      weight: 700,
                                      color: ch.onSurfaceVariant.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    dailyPayment,
                                    style: ptstyle(
                                      size: 18,
                                      weight: 700,
                                      color:
                                          widget.enabled
                                              ? ch.primary
                                              : ch.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Divider(color: ch.onSurfaceVariant.withOpacity(0.1), height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    widget.staticObj
                        ? PSSide(
                          staticObj: widget.staticObj,
                          enabled: widget.enabled,
                          ch: ch,
                          data: widget.data,

                          price: "",
                        )
                        : Expanded(
                          child: PSSide(
                            staticObj: widget.staticObj,
                            enabled: widget.enabled,
                            ch: ch,
                            data: widget.data,

                            price: totalPayment,
                          ),
                        ),
                    !widget.staticObj
                        ? Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSpecItem(
                                  '3-Months from',
                                  (double.parse(
                                    widget.data.threeMonthPrice,
                                  )).toString(),
                                  "GHS",
                                  widget.enabled,
                                  3 == widget.tn || widget.tn == 7,
                                  ch,
                                ),
                                _buildSpecItem(
                                  '4-Months from',
                                  (double.parse(
                                    widget.data.fourMonthPrice,
                                  )).toString(),
                                  "GHS",
                                  widget.enabled,
                                  4 == widget.tn || widget.tn == 7,
                                  ch,
                                ),
                                _buildSpecItem(
                                  '5-Months from',
                                  (double.parse(
                                    widget.data.fiveMonthPrice,
                                  )).toString(),
                                  "GHS",
                                  widget.enabled,
                                  5 == widget.tn || widget.tn == 7,
                                  ch,
                                ),
                                _buildSpecItem(
                                  '6-Months from',
                                  (double.parse(
                                    widget.data.sixMonthPrice,
                                  )).toString(),
                                  "GHS",
                                  widget.enabled,
                                  6 == widget.tn || widget.tn == 7,
                                  ch,
                                ),
                              ],
                            ),
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 35,
                                width: 35,
                                child: Icon(
                                  Icons.sd_storage,
                                  size: 20,
                                  color: ch.onSurfaceVariant.withOpacity(0.5),
                                ),
                              ),
                              Icon(
                                Icons.sd_storage,
                                size: 20,
                                color: ch.onSurfaceVariant.withOpacity(0.2),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!widget.staticObj)
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            margin: EdgeInsets.only(left: 10),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: widget.enabled ? ch.primary : ch.surfaceContainerHigh,

              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Selected Option",
              style: ptstyle(
                size: 10,
                weight: 600,
                color: widget.enabled ? ch.onPrimary : ch.onSurface,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecItem(
    String title,
    String value,
    String symbol,
    bool selected,
    bool us,
    ColorScheme ch,
  ) {
    return Opacity(
      opacity: us ? 1 : 0.3,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: ptstyle(
                size: us ? 11 : 10,
                weight: 400,
                color: ch.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Divider(color: ch.surfaceContainerLow.withOpacity(0.8)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (symbol.isNotEmpty)
                  Text(
                    symbol,
                    style: ptstyle(
                      size: us ? 11 : 10,
                      weight: 400,
                      color: ch.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                SizedBox(width: 5),
                Text(
                  double.parse(value).toCommaSeparated(0, decimalPlaces: 2),
                  style: ptstyle(
                    size: us ? 12 : 10,
                    weight: 600,
                    color: selected ? ch.primary : ch.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PSSide extends StatelessWidget {
  const PSSide({
    super.key,
    required this.staticObj,
    required this.enabled,
    required this.ch,
    required this.data,
    required this.price,
  });

  final bool staticObj;
  final bool enabled;
  final ColorScheme ch;
  final ProductStorage data;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          staticObj
              ? EdgeInsets.only(left: 10.0, right: 10.0, bottom: 8)
              : EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!staticObj) ...[
            Text(
              "Price",
              style: ptstyle(
                size: 10,
                weight: 400,
                color:
                    enabled
                        ? const Color.fromARGB(255, 102, 134, 160)
                        : ch.onSurfaceVariant.withOpacity(0.8),
              ),
            ),

            AnimatedContainer(
              duration: Duration(milliseconds: 400),
              constraints: BoxConstraints(maxWidth: 150),
              child: Row(
                children: [
                  Text(
                    "GHS ",
                    maxLines: enabled ? null : 2,
                    overflow: enabled ? null : TextOverflow.ellipsis,
                    style: ptstyle(
                      size: 18,
                      weight: 700,
                      color: ch.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    price,

                    maxLines: enabled ? null : 2,
                    overflow: enabled ? null : TextOverflow.ellipsis,
                    style: ptstyle(
                      size: 18,
                      weight: 700,
                      color: enabled ? ch.primary : ch.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3),
          ],
          Text(
            "Storage",
            style: ptstyle(
              size: 10,
              weight: 400,
              color:
                  enabled
                      ? const Color.fromARGB(255, 118, 160, 190)
                      : ch.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 5),
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            constraints: BoxConstraints(maxWidth: 150),
            child: Text(
              data.storage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ptstyle(
                size: 14,
                weight: 600,
                color: enabled ? ch.primary : ch.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
