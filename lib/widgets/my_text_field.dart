import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final String hintText;
  final bool obSecure;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  
  const MyTextfield({
    super.key,
    required this.hintText,
    required this.obSecure,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        fillColor: theme.colorScheme.surface,
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(153)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      obscureText: obSecure,
      style: TextStyle(color: theme.colorScheme.onSurface),
    );
  }
}
