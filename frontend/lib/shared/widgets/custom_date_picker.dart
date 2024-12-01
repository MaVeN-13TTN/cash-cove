import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatelessWidget {
  final String label;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime?)? onDateSelected;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  const CustomDatePicker({
    Key? key,
    required this.label,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(
          Icons.calendar_today,
          color: enabled 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).disabledColor,
        ),
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
      ),
      controller: TextEditingController(
        text: initialDate != null 
          ? DateFormat('yyyy-MM-dd').format(initialDate!) 
          : '',
      ),
      readOnly: true,
      enabled: enabled,
      onTap: enabled ? () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: initialDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (selectedDate != null) {
          onDateSelected?.call(selectedDate);
        }
      } : null,
      validator: (value) {
        return validator?.call(initialDate);
      },
    );
  }
}
