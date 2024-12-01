import 'package:flutter/material.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? selectedColor;
  final Color? unselectedColor;

  const CustomFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.selectedColor,
    this.unselectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: unselectedColor ?? Theme.of(context).colorScheme.surface,
      selectedColor: selectedColor ?? Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: selectedColor ?? Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected 
          ? (selectedColor ?? Theme.of(context).colorScheme.primary)
          : Theme.of(context).textTheme.bodyMedium?.color,
      ),
      side: BorderSide(
        color: isSelected 
          ? (selectedColor ?? Theme.of(context).colorScheme.primary)
          : Theme.of(context).dividerColor,
      ),
    );
  }
}
