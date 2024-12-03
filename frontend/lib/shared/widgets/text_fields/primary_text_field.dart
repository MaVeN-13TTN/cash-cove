import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimaryTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String hintText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const PrimaryTextField({
    Key? key,
    this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType,
    this.maxLength,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      validator: validator,
      style: theme.textTheme.bodyLarge,
    );
  }
}
