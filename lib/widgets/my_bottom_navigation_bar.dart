import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user/user_provider.dart';

class MyBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MyBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isGovernment = userProvider.user?.isAdmin ?? false;
    final isAdvertiser = userProvider.user?.isAdvertiser ?? false;
    final isCitizen = userProvider.user?.isCitizen ?? false;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final isCitizen = userProvider.user?.isCitizen ?? false;

        if (isCitizen && index == 0) {
          // Citizen Home
          if (ModalRoute.of(context)?.settings.name != '/citizen_home') {
            Navigator.pushReplacementNamed(context, '/citizen_home');
          }
        } else {
          onTap(index);
        }
      },
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        if (isGovernment) ...[
          const BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: "Announcements",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.poll),
            label: "Polls",
          ),
        ],
        if (isCitizen) ...[
          const BottomNavigationBarItem(
            icon: Icon(Icons.announcement_outlined),
            label: "Announcements",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.poll_outlined),
            label: "Polls",
          ),
        ],
        if (!isAdvertiser)
          const BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            label: "Report",
          ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: "Messages",
        ),
      ],
    );
  }
}
