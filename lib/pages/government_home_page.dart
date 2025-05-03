import 'package:flutter/material.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart'; // Import the custom widget

class GovernmentHomePage extends StatelessWidget {
  const GovernmentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Public Square",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
        elevation: 0,
        actions: [
          Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                "Government",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded),
            onPressed: () {
              authService.signOut(); // Call the signOut method from AuthService
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Align items vertically
                children: [
                  // Bell icon
                  Icon(
                    Icons.notifications_outlined,
                    color: Colors.blue,
                    size: 28,
                  ),

                  // Manage Announcements text
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text(
                        "Manage Announcements",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),

                  // New Announcement button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          Text(
                            "New Announcement",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
        currentIndex: 0, // Set the default selected index
        onTap: (index) {
          // Handle navigation logic here
        },
      ),
    );
  }
}
