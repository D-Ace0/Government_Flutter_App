import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:governmentapp/pages/chat_room_page.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/services/chat/chat_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_chat_room_card.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';

class GovernmentMessage extends StatefulWidget {
  const GovernmentMessage({super.key});

  @override
  State<GovernmentMessage> createState() => _GovernmentMessageState();
}

class _GovernmentMessageState extends State<GovernmentMessage> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  int currentIndex = 3; // Index for messages in bottom nav

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
      // Already on messages page - no navigation needed
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    final theme = Theme.of(context);

    return RouteGuardWrapper(
      allowedRoles: const ['government'],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.message_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Admin Messages",
          style: TextStyle(
            fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: theme.colorScheme.primary,
          ),
        ),
            ],
        ),
        actions: [
          IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            onPressed: () {
                // Implement search functionality if needed
            },
          ),
            const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
            // Stats Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primary.withAlpha(204), // ~0.8 opacity
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(51), // ~0.2 opacity
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getUserChatRooms(),
                builder: (context, snapshot) {
                  int totalChats = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  int pendingChats = 0;
                  
                  if (snapshot.hasData) {
                    // We might implement unread messages counting in the future
                    // Currently not using the docs
                  }
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.message_rounded,
                        value: totalChats.toString(),
                        label: 'Total Chats',
                        iconColor: Colors.white,
                        valueColor: Colors.white,
                      ),
                      _buildStatItem(
                        icon: Icons.pending_actions_rounded,
                        value: pendingChats.toString(),
                        label: 'Awaiting Response',
                        iconColor: Colors.white,
                        valueColor: Colors.white,
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Section Header
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Active Conversations",
                style: TextStyle(
                  fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded, 
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Filter",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                ),
              ),
                      ],
            ),
          ),
                ],
              ),
            ),
            
            // Message List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getUserChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mark_chat_unread_outlined,
                            size: 70,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No messages yet",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Messages from citizens will appear here",
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant.withAlpha(178), // ~0.7 opacity
                            ),
                          ),
                        ],
                      ),
                    );
                }

                final chatRooms = snapshot.data!.docs;

                return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
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
                            return Container(
                              height: 100,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withAlpha(76), // ~0.3 opacity
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
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
                              String userName = "Citizen";
                              String userAvatar = "";
                              
                            if (userSnapshot.hasData &&
                                userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                userName = userData?['name'] ?? userData?['email'] ?? "Citizen";
                                userAvatar = userData?['photoURL'] ?? "";
                            }

                            return MyChatRoomCard(
                                msgTitle: subject,
                              msgContent: message,
                                senderName: userName,
                                senderAvatar: userAvatar,
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
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51), // ~0.2 opacity
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: valueColor.withAlpha(204), // ~0.8 opacity
          ),
        ),
      ],
    );
  }
}
