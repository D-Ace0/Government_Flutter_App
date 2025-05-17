import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:governmentapp/services/chat/chat_service.dart';
import 'package:intl/intl.dart';

class ChatRoomPage extends StatefulWidget {
  final String receiverUserId;
  final String chatRoomId;

  const ChatRoomPage({
    super.key,
    required this.receiverUserId,
    required this.chatRoomId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  // Store user display info
  String _receiverName = "User";

  @override
  void initState() {
    super.initState();
    // Fetch user info for the receiver
    _fetchReceiverInfo();
  }

  void _fetchReceiverInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.receiverUserId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _receiverName = doc.data()?['email'] ?? "User";
        });
      }
    } catch (e) {
      print("Error fetching user info: $e");
    }
  }

  void _sendMessage() async {
    // Get message text and validate
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Clear input field
    _messageController.clear();

    // Find the subject from previous messages or use a default
    String subject = "Chat";
    try {
      final messagesQuery = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messagesQuery.docs.isNotEmpty) {
        subject = messagesQuery.docs.first.data()['subject'] ?? "Chat";
      }
    } catch (e) {
      print("Error getting subject: $e");
    }
    try {
      // Send the message using the chat service
      await _chatService.sendMessage(
          widget.receiverUserId, subject, messageText);
    } catch (e) {
      if (mounted) {
        // Check if this is a profanity-related error
        if (e.toString().toLowerCase().contains('inappropriate') ||
            e.toString().toLowerCase().contains('offensive')) {
          // Show a detailed dialog explaining the issue
          showDialog(
            context: context,
            barrierDismissible: false, // Force user to press OK
            builder: (context) => AlertDialog(
              icon: Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 48),
              title: Text("Inappropriate Content Detected",
                  style: TextStyle(color: Colors.red)),
              content: Text(
                "Your message contains content that violates our community guidelines. "
                "Please review your message and try again with appropriate language.",
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  child:
                      Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        } else {
          // For other types of errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending message: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Restore the message text since it wasn't sent
        _messageController.text = messageText;
      }
      return; // Don't proceed with scrolling
    }

    // Scroll to bottom after message is sent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _receiverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Online",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show chat info if needed
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getLatestMessageForChatRoom(
                  widget.chatRoomId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No messages yet",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Start a conversation!",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort messages by timestamp
                  final messages = snapshot.data!.docs;

                  // Scroll to bottom when new messages come in
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe =
                          message['senderId'] == _auth.currentUser!.uid;

                      // Format timestamp
                      String timeString = "Just now";
                      if (message['timestamp'] != null) {
                        final timestamp = message['timestamp'] as Timestamp;
                        final dateTime = timestamp.toDate();
                        timeString = DateFormat.jm().format(dateTime);
                      }

                      return _buildMessageBubble(
                        message: message['message'],
                        isMe: isMe,
                        time: timeString,
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -1),
                  blurRadius: 5,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      // File attachment functionality would go here
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: Theme.of(context).colorScheme.onPrimary,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe
                          ? Theme.of(
                              context,
                            ).colorScheme.onPrimary.withOpacity(0.7)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
