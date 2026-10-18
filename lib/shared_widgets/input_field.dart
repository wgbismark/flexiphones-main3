import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';

class OutlineInput extends StatelessWidget {
  final String label;
  final int? maxLength;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool error;
  final FocusNode? focusNode;
  final bool enabled;
  final bool showBlueBorder;
  final ValueChanged<String>? onchange;

  const OutlineInput({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.maxLength,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.showBlueBorder = false,
    this.prefixIcon,
    this.validator,
    this.onchange,
    this.error = false,
    this.enabled = true,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return TextFormField(
      focusNode: focusNode,
      enabled: enabled,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onchange,
      maxLength: maxLength,
      textAlignVertical: TextAlignVertical.top,
      textAlign: TextAlign.start,
      buildCounter: (
        context, {
        required currentLength,
        required isFocused,
        required maxLength,
      }) {
        return SizedBox();
      },
      decoration: InputDecoration(
        fillColor: ch.surfaceContainerLow,
        filled: true,
        labelText: label.isEmpty ? null : label,
        labelStyle: ptstyle(
          size: 12,
          weight: 400,
          color: error ? Colors.redAccent : ch.onSurfaceVariant.withAlpha(90),
        ),
        hintText: hintText,

        hintStyle: ptstyle(
          size: 12,
          weight: 300,
          color: ch.onSurfaceVariant.withOpacity(0.7),
        ),
        suffixIcon:
            suffixIcon != null
                ? Opacity(opacity: 0.8, child: suffixIcon)
                : null,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              showBlueBorder
                  ? BorderSide(width: 1, color: ch.primary.withOpacity(0.8))
                  : BorderSide.none,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              showBlueBorder
                  ? BorderSide(width: 1, color: ch.primary.withOpacity(0.8))
                  : BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 1,
            color: error ? Colors.redAccent : ch.primary,
          ),
        ),
      ),
    );
  }
}


class FilledInput extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final bool obscureText, filled;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool error;
  final bool enabled;
  final TextAlign? textAlign;
  final TextStyle? style;
  final EdgeInsetsGeometry? contentPadding;
  final int lines, maxLength;
  final ValueChanged<String>? onChange;
  final ValueChanged<String>? onSubmitted;
  const FilledInput({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength = 1000,
    this.validator,
    this.contentPadding,
    this.textAlign,
    this.onChange,
    this.onSubmitted,
    this.style,
    this.lines = 1,
    this.error = false,
    this.enabled = true,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return TextFormField(
      enabled: enabled,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChange,
      focusNode: focusNode,
      minLines: lines,
      maxLines: lines,
          onFieldSubmitted: onSubmitted,
      maxLength: maxLength,
      buildCounter: (
        context, {
        required currentLength,
        required isFocused,
        required maxLength,
      }) {
        return SizedBox();
      },
      textAlignVertical: TextAlignVertical.top,
      textAlign: textAlign ?? TextAlign.start,
      style: style,
      decoration: InputDecoration(

        contentPadding: contentPadding,
        fillColor: ch.surfaceContainerLow,
            filled: filled,

        labelText: label.isEmpty ? null : label,
        // color: error ? Colors.redAccent : ch.onSurfaceVariant.withAlpha(90),
        labelStyle: ptstyle(
          size: 12,
          weight: 400,
          color:
              error ? Colors.redAccent : ch.onSurfaceVariant.withOpacity(0.9),
        ),
        hintText: hintText,
        hintStyle: ptstyle(
          size: 12,
          weight: 300,
          color: ch.onSurfaceVariant.withOpacity(0.7),
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon:
            suffixIcon != null
                ? Opacity(opacity: 0.5, child: suffixIcon)
                : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              error
                  ? BorderSide(width: 1, color: Colors.redAccent)
                  : BorderSide.none,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              error
                  ? BorderSide(width: 1, color: Colors.redAccent)
                  : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              error
                  ? BorderSide(width: 1, color: Colors.redAccent)
                  : BorderSide.none,
        ),
      ),
    );
  }
}
