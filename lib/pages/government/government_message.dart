import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:governmentapp/pages/chat_room_page.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/services/chat/chat_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_chat_room_card.dart';

class GovernmentMessage extends StatefulWidget {
  const GovernmentMessage({super.key});

  @override
  State<GovernmentMessage> createState() => _GovernmentMessageState();
}

class _GovernmentMessageState extends State<GovernmentMessage> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  int currentIndex = 4;

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
      Navigator.pushReplacementNamed(context, '/report');
    } else if (index == 4) {
      // Already on messages page - no navigation needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();

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
              Navigator.pushReplacementNamed(context, '/government_home');
            },
            icon: Icon(Icons.arrow_back),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Chat Rooms",
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getUserChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No chat rooms found"));
                }

                final chatRooms = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    final chatRoom = chatRooms[index];
                    final chatRoomId = chatRoom.id;
                    final participants = List<String>.from(
                      chatRoom['participants'],
                    );

                    final otherUserId = participants.firstWhere(
                      (id) => id != currentUser!.uid,
                      orElse: () => "Unknown",
                    );

                    // Use the ChatService to fetch the latest message
                    return StreamBuilder<QuerySnapshot>(
                      stream: _chatService.getLatestMessageForChatRoom(
                        chatRoomId,
                      ),
                      builder: (context, msgSnapshot) {
                        if (msgSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Default values if no messages yet
                        String subject = "New Conversation";
                        String message = "No messages yet";
                        String? reply;
                        String date = "Today";

                        // If there's a message, extract its data
                        if (msgSnapshot.hasData &&
                            msgSnapshot.data!.docs.isNotEmpty) {
                          final latestMsg =
                              msgSnapshot.data!.docs.first.data()
                                  as Map<String, dynamic>;
                          subject = latestMsg['subject'] ?? "New Conversation";
                          message =
                              latestMsg['message'] ?? "No message content";
                          reply = latestMsg['reply'];

                          // Format the date
                          if (latestMsg['timestamp'] != null) {
                            date = latestMsg['formattedDate'] ?? "Today";
                          }
                        }

                        // Get user information to display in the chat card
                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(otherUserId)
                                  .get(),
                          builder: (context, userSnapshot) {
                            String userName = "User";
                            if (userSnapshot.hasData &&
                                userSnapshot.data!.exists) {
                              userName =
                                  userSnapshot.data!.get('email') ?? "User";
                            }

                            return MyChatRoomCard(
                              msgTitle: "$subject - From: $userName",
                              msgContent: message,
                              reply: reply,
                              date: date,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChatRoomPage(
                                          receiverUserId: otherUserId,
                                          chatRoomId: chatRoomId,
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
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
