import 'package:flutter/material.dart';

class MySmallButton extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  const MySmallButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.add, color: Theme.of(context).colorScheme.secondary),
            SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
