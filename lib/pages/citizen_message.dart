import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:governmentapp/pages/chat_room_page.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/services/chat/chat_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_chat_room_card.dart';
import 'package:governmentapp/widgets/my_send_message_card.dart';

class CitizenMessage extends StatefulWidget {
  const CitizenMessage({super.key});

  @override
  State<CitizenMessage> createState() => _CitizenMessageState();
}

class _CitizenMessageState extends State<CitizenMessage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

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

  void sendMessage() async {
    if (subjectController.text.isNotEmpty &&
        messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        "V2PwnX1q7Ceeabt7zmMf5GYfjx83",
        subjectController.text,
        messageController.text,
      );
      subjectController.clear();
      messageController.clear();
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
        // this column will contain the send message card and the chat rooms
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //this column will contain the messages cards
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16),
                  child: Text(
                    "Chat Rooms",
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),

                // Add your chat rooms here
                Expanded(
                  child: StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: _chatService.getChatRoomsForCurrentUser(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No messages yet."),
                        );
                      }

                      final currentUserId = _authService.getCurrentUser()!.uid;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final msg = snapshot.data![index];
                          final senderId = msg['senderId'];
                          final receiverId = msg['receiverId'];
                          final ids = [senderId, receiverId]..sort();
                          final chatRoomId = ids.join('_');

                          final isUnread =
                              msg['receiverId'] == currentUserId &&
                              msg['reply'] == null;

                          return Stack(
                            children: [
                              MyChatRoomCard(
                                msgTitle: msg['subject'],
                                msgContent: msg['message'],
                                reply: msg['reply'],
                                date: msg['formattedDate'] ?? "",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ChatRoomPage(
                                            chatRoomId: chatRoomId,
                                            receiverId:
                                                currentUserId == senderId
                                                    ? receiverId
                                                    : senderId,
                                            subject: msg['subject'],
                                          ),
                                    ),
                                  );
                                },
                              ),
                              if (isUnread)
                                Positioned(
                                  top: 12,
                                  right: 24,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: MySendMessageCard(
              subjectController: subjectController,
              messageController: messageController,
              onTap: () {
                // Handle send message action here
                sendMessage();
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
