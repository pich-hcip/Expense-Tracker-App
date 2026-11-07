import 'package:flutter/material.dart';

const Color kPrimaryBlue = Color(0xFF2458C6);
const Color kErrorRed = Color(0xFFFF4D4D);

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hintText,
    this.enabled = true,
    this.autofillHints,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final bool enabled;
  final Iterable<String>? autofillHints;
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillColor = isDark
        ? colorScheme.surfaceContainerHigh
        : const Color(0xFFFAFBFD);
    final borderColor = isDark
        ? colorScheme.outline.withOpacity(0.5)
        : const Color(0xFFE1E6EF);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: c, width: w),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          scrollPadding: const EdgeInsets.only(bottom: 32),
          enabled: enabled,
          autofillHints: autofillHints,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: kPrimaryBlue, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            enabledBorder: border(borderColor),
            focusedBorder: border(kPrimaryBlue, 1.4),
            errorBorder: border(kErrorRed),
            focusedErrorBorder: border(kErrorRed, 1.4),
          ),
        ),
      ],
    );
  }
}
