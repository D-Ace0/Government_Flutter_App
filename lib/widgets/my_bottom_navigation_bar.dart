import 'package:flutter/material.dart';

class MyBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MyBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: theme.colorScheme.onPrimary,
      unselectedItemColor: theme.colorScheme.primary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      backgroundColor: theme.colorScheme.tertiary,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_box_outlined),
          label: "Polls",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_problem_outlined),
          label: "Report",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.messenger_outline_rounded),
          label: "Messages",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_sharp),
          label: "Profile",
        ),
      ],
    );
  }
}
