import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? value;
  final void Function(DateTime) onChanged;
  final String? label;
  final String? hint;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateFormat? dateFormat;
  final String? errorText;
  final bool enabled;

  const DatePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.dateFormat,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = dateFormat ?? DateFormat.yMMMd();

    return TextFormField(
      controller: TextEditingController(
        text: value != null ? format.format(value!) : '',
      ),
      style: enabled 
          ? theme.textTheme.bodyMedium 
          : theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? 'Select date',
        errorText: errorText,
        filled: true,
        fillColor: enabled 
            ? theme.inputDecorationTheme.fillColor 
            : theme.disabledColor.withOpacity(0.05),
        suffixIcon: enabled
            ? IconButton(
                icon: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: () => _showDatePicker(context),
              )
            : Icon(
                Icons.calendar_today,
                color: theme.disabledColor,
                size: 20,
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.disabledColor.withOpacity(0.2),
          ),
        ),
      ),
      readOnly: true,
      enabled: enabled,
      onTap: enabled ? () => _showDatePicker(context) : null,
      validator: required && value == null
          ? (_) => 'Please select a date'
          : null,
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = value ?? now;
    final first = firstDate ?? DateTime(now.year - 100);
    final last = lastDate ?? DateTime(now.year + 100);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      onChanged(date);
    }
  }
}