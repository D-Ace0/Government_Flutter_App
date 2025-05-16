import 'package:flutter/material.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart'; // Import the custom widget

class GovernmentHomePage extends StatefulWidget {
  const GovernmentHomePage({super.key});

  @override
  State<GovernmentHomePage> createState() => _GovernmentHomePageState();
}

class _GovernmentHomePageState extends State<GovernmentHomePage> {
  int selectedIndex = 0;

  void onTap(int index) {
    setState(() {
      selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/government_home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/polls');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/report');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/government_message');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Public Square",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.phone),
            tooltip: 'Manage Official Phones',
            onPressed: () {
              Navigator.pushNamed(context, '/government_phone_management');
            },
          ),
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
        ],
      ),
      drawer: MyDrawer(),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/government_advertisements_management',
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          size: 16,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Advertisements Management",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
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
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: selectedIndex, // Set the default selected index
        onTap: onTap,
      ),
    );
  }
}
