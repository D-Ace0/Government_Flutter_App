import 'package:flutter/material.dart';

class MyDropdownField extends StatelessWidget {
  final String hintText;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const MyDropdownField({
    super.key,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Cache these theme values to avoid multiple lookups
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final tertiary = colorScheme.tertiary;
    final secondary = colorScheme.secondary;
    final onPrimary = colorScheme.onPrimary;
    
    // Create dropdown items only once
    final dropdownItems = items.map((role) {
      return DropdownMenuItem<String>(
        value: role,
        child: Text(role[0].toUpperCase() + role.substring(1)),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: tertiary),
          ),
          fillColor: secondary,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: primary),
        ),
        dropdownColor: secondary,
        style: TextStyle(color: onPrimary),
        iconEnabledColor: primary,
        onChanged: onChanged,
        items: dropdownItems,
      ),
    );
  }
}
