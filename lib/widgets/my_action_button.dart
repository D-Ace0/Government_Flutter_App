import 'package:flutter/material.dart';

class MyActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final void Function()? onTap;
  final Color? iconColor;
  final Color? textColor;
  final Color? containerColor;
  const MyActionButton({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: containerColor ?? Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 8.0),
            Text(
              title,
              style: TextStyle(
                color: textColor ?? Theme.of(context).colorScheme.primary,
                fontSize: 18.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
