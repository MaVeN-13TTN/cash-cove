import 'package:flutter/material.dart';

class DropdownField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool required;
  final bool enabled;
  final Widget? prefix;
  final EdgeInsets? contentPadding;

  const DropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.prefix,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefix,
        contentPadding: contentPadding,
      ),
      style: enabled ? null : TextStyle(color: theme.disabledColor),
      validator: required && value == null
          ? (_) => 'Please select an option'
          : null,
      icon: const Icon(Icons.arrow_drop_down),
      isExpanded: true,
    );
  }
}

class DropdownItem<T> extends StatelessWidget {
  final T value;
  final String label;
  final Widget? icon;

  const DropdownItem({
    super.key,
    required this.value,
    required this.label,
    this.icon,
  });

  DropdownMenuItem<T> toDropdownMenuItem() {
    return DropdownMenuItem<T>(
      value: value,
      child: Row(
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return toDropdownMenuItem();
  }
}
