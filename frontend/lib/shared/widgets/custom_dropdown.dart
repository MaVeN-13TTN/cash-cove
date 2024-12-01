import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T)? displayText;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const CustomDropdown({
    Key? key,
    required this.label,
    required this.items,
    this.value,
    this.displayText,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            displayText?.call(item) ?? item.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
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
      dropdownColor: Theme.of(context).cardColor,
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
  }
}
