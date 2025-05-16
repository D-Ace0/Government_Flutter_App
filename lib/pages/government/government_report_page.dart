import 'package:flutter/material.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';

class GovernmentReportPage extends StatefulWidget {
  const GovernmentReportPage({super.key});

  @override
  State<GovernmentReportPage> createState() => _GovernmentReportPageState();
}

class _GovernmentReportPageState extends State<GovernmentReportPage> {
  int currentIndex = 3; // Set to 3 for "Report" tab in bottom navigation

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/government_home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/announcements');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/polls');
    } else if (index == 3) {
      // Already on report page - no navigation needed
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Reports",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        leading: Icon(
          Icons.report_problem_outlined,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 36,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Citizen Reports",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          
          // Main content - Can be expanded in the future
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.report_outlined,
                    size: 100,
                    color: Colors.blue[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No reports to display",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "When citizens submit reports, they will appear here for you to review and respond.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
} 