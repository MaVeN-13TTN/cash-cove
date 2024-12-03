import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final void Function()? onTap;

  const CustomTextField({
    Key? key,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSaved,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      onChanged: onChanged,
      onSaved: onSaved,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}
