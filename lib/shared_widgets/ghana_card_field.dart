import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps only digits (max 10) and adds the dash after the 9th:
/// "1234567891" -> "123456789-1". Pasting "GHA-123456789-1" works too.
class GhanaCardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final text =
        digits.length > 9
            ? "${digits.substring(0, 9)}-${digits.substring(9)}"
            : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// One field for a Ghana Card number. People type only the 10 digits on a
/// number pad; "GHA-" is shown in front and the dash appears by itself.
/// A live card preview underneath shows the full number as it's typed.
///
/// [onChanged] gets the part after "GHA-" ("123456789-1") and whether it's
/// complete.
class GhanaCardField extends StatefulWidget {
  const GhanaCardField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.showPreview = true,
  });

  /// Holds the part after "GHA-", e.g. "123456789-1".
  final TextEditingController controller;
  final void Function(String value, bool complete) onChanged;
  final bool enabled;
  final bool autofocus;
  final bool showPreview;

  static bool isComplete(String v) => RegExp(r'^[0-9]{9}-[0-9]$').hasMatch(v);

  @override
  State<GhanaCardField> createState() => _GhanaCardFieldState();
}

class _GhanaCardFieldState extends State<GhanaCardField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final v = widget.controller.text;
    final complete = GhanaCardField.isComplete(v);
    final digits = v.replaceAll('-', '');
    // "123456789-1" with the not-yet-typed part shown as dots.
    final preview =
        "${digits.padRight(9, '•').substring(0, 9)}-${digits.length > 9 ? digits[9] : '•'}";
    const blue = Color(0xFF0071E3);
    const green = Color(0xFF30A14E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: ch.onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  complete
                      ? green
                      : _focus.hasFocus
                      ? blue
                      : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: ch.onSurface.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "GHA-",
                  style: ptstyle(size: 16, weight: 800, color: ch.onSurfaceVariant)
                      .copyWith(letterSpacing: 1),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [GhanaCardFormatter()],
                  style: ptstyle(size: 19, weight: 700, color: ch.onSurface)
                      .copyWith(letterSpacing: 1.6),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "123456789-1",
                    hintStyle: ptstyle(
                      size: 19,
                      weight: 500,
                      color: ch.onSurfaceVariant.withOpacity(0.35),
                    ).copyWith(letterSpacing: 1.6),
                  ),
                  onChanged: (x) {
                    setState(() {});
                    widget.onChanged(x, GhanaCardField.isComplete(x));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child:
                      complete
                          ? const Icon(Icons.check_circle_rounded, color: green, key: ValueKey(1))
                          : Text(
                            "${digits.length}/10",
                            key: const ValueKey(0),
                            style: ptstyle(size: 11, weight: 600, color: ch.onSurfaceVariant),
                          ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showPreview) ...[
          const SizedBox(height: 14),
          // A small ID-card look with the number as it will be saved.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF0B3D2E), Color(0xFF1E6B4E), Color(0xFFC9A227)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8C766),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.memory_rounded, color: Color(0xFF8A6D1A), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "GHANA CARD",
                        style: ptstyle(size: 10, weight: 700, color: Colors.white70)
                            .copyWith(letterSpacing: 1.4),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "GHA-$preview",
                          style: ptstyle(size: 18, weight: 800, color: Colors.white)
                              .copyWith(letterSpacing: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
