import 'package:flutter/material.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_send_message_card.dart';

class CitizenMessage extends StatefulWidget {
  const CitizenMessage({super.key});

  @override
  State<CitizenMessage> createState() => _CitizenMessageState();
}

class _CitizenMessageState extends State<CitizenMessage> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  int currentIndex = 3; // Set the initial index to the Messages tab
  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
    // Handle navigation to other pages if needed

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home'); // Navigate to Home
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/polls'); // Navigate to Polls
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/report'); // Navigate to Report
    } else if (index == 4) {
      Navigator.pushReplacementNamed(
        context,
        '/profile',
      ); // Navigate to Profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Messages",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        leading: Icon(
          Icons.messenger_outline_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 36,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back),
          ),
        ],
      ),
      body: Column(
        // this column will contain the send message card and the messages cards
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //this column will contain the messages cards
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "My Messages",
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
              // Add your messages cards here

              // For example:
              // MessageCard(title: "Message 1", content: "This is the content of message 1"),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: MySendMessageCard(
              subjectController: subjectController,
              messageController: messageController,
              onTap: () {
                // Handle send message action here
              },
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
