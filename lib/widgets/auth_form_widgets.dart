import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({
    super.key,
    required this.text,
    this.fontSize = 28,
    this.bottomPadding = 10,
  });

  final String text;
  final double fontSize;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize, 
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.fontSize = 24,
    this.hintFontSize = 24,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final double fontSize;
  final double hintFontSize;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: fontSize,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: hintFontSize,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        suffixIcon: suffixIcon,
        contentPadding: contentPadding,
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
