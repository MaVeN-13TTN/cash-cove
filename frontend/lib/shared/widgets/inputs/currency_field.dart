import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final void Function(double)? onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final String currencySymbol;
  final String locale;
  final int decimalDigits;
  final bool required;
  final String? Function(String?)? validator;

  const CurrencyField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.currencySymbol = '\$',
    this.locale = 'en_US',
    this.decimalDigits = 2,
    this.required = false,
    this.validator,
  }) : assert(
          controller == null || initialValue == null,
          'Cannot provide both a controller and an initialValue',
        );

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(
      symbol: currencySymbol,
      locale: locale,
      decimalDigits: decimalDigits,
    );

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? format.format(0),
        errorText: errorText,
        prefixText: currencySymbol,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          try {
            final text = newValue.text;
            if (text.isEmpty) return newValue;
            
            // Only allow one decimal point
            if (text.contains('.') && 
                text.indexOf('.') != text.lastIndexOf('.')) {
              return oldValue;
            }
            
            // Limit decimal places
            if (text.contains('.')) {
              final decimalPlaces = text.split('.')[1].length;
              if (decimalPlaces > decimalDigits) return oldValue;
            }
            
            return newValue;
          } catch (e) {
            return oldValue;
          }
        }),
      ],
      enabled: enabled,
      onChanged: (value) {
        if (onChanged != null && value.isNotEmpty) {
          try {
            final numericValue = double.parse(value);
            onChanged!(numericValue);
          } catch (e) {
            // Invalid number format
          }
        }
      },
      validator: (value) {
        if (validator != null) {
          return validator!(value);
        }
        if (required && (value == null || value.isEmpty)) {
          return 'Please enter an amount';
        }
        if (value != null && value.isNotEmpty) {
          try {
            double.parse(value);
          } catch (e) {
            return 'Please enter a valid amount';
          }
        }
        return null;
      },
    );
  }
}
