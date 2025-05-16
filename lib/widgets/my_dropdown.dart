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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          fillColor: Theme.of(context).colorScheme.secondary,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        dropdownColor: Theme.of(context).colorScheme.secondary,
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        iconEnabledColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
        items:
            items.map((role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(role[0].toUpperCase() + role.substring(1)),
              );
            }).toList(),
      ),
    );
  }
}
