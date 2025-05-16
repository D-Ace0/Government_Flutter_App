import 'package:flutter/material.dart';

class MyBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  
  const MyBackButton({
    super.key, 
    this.onPressed,
    this.label = 'Back',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed ?? () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
} 