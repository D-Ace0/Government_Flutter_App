import 'package:flutter/material.dart';

class MyDropdownField extends StatelessWidget {
  final String hintText;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final FocusNode? focusNode;

  const MyDropdownField({
    super.key,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Create dropdown items with properly capitalized labels
    final dropdownItems = items.map((item) {
      // Format item for better readability (capitalize first letter)
      String displayText = item;
      if (item.isNotEmpty) {
        displayText = item[0].toUpperCase() + item.substring(1);
      }
      
      return DropdownMenuItem<String>(
        value: item,
        child: Text(displayText),
      );
    }).toList();

    return DropdownButtonFormField<String>(
      value: value,
      focusNode: focusNode,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.error),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        fillColor: theme.colorScheme.surface,
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(153)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      dropdownColor: theme.colorScheme.surface,
      style: TextStyle(color: theme.colorScheme.onSurface),
      icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
      isExpanded: true,
      onChanged: onChanged,
      items: dropdownItems,
      menuMaxHeight: 300,
    );
  }
}
