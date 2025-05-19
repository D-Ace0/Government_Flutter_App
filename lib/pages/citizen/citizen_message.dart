import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:governmentapp/pages/chat_room_page.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/services/chat/chat_service.dart';
import 'package:intl/intl.dart';

class CitizenMessage extends StatefulWidget {
  const CitizenMessage({super.key});

  @override
  State<CitizenMessage> createState() => _CitizenMessageState();
}

class _CitizenMessageState extends State<CitizenMessage> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void navigateBack() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacementNamed(context, '/citizen_home');
  }

  Future<void> sendMessage() async {
    if (subjectController.text.isEmpty || messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both subject and message fields'))
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.mediumImpact();
    
    try {
      await _chatService.sendMessage(
        "V2PwnX1q7Ceeabt7zmMf5GYfjx83", // receiver ID (admin)
        subjectController.text,
        messageController.text,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message sent successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        )
      );
      
      setState(() {
      subjectController.clear();
      messageController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        )
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = _authService.getCurrentUser();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: navigateBack,
        ),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message center refreshed'),
                  duration: Duration(seconds: 1),
                )
              );
              setState(() {}); // Force refresh
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          )
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Message Stats bar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
          ),
        ],
      ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
        children: [
                  _buildStatItem(
                    icon: Icons.message_outlined, 
                    label: 'Official Messages',
                    color: theme.colorScheme.primary
                  ),
                  const Spacer(),
                  StreamBuilder<QuerySnapshot>(
                    stream: _chatService.getUserChatRooms(),
                    builder: (context, snapshot) {
                      int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildStatItem(
                        icon: Icons.forum_outlined, 
                        label: 'Conversations: $count',
                        color: theme.colorScheme.secondary
                      );
                    }
              ),
                ],
            ),
          ),
            
            // Chat rooms section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getUserChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                }

                final chatRooms = snapshot.data!.docs;

                return ListView.builder(
                    padding: const EdgeInsets.only(top: 12),
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

                      // Create staggered animation for each list item
                      final itemAnimation = SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.05 * (index + 1)),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              0.2 + (index * 0.1),
                              min(0.2 + (index * 0.1) + 0.5, 1.0),
                              curve: Curves.easeOutQuart,
                            ),
                          ),
                        ),
                        child: FadeTransition(
                          opacity: Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                0.2 + (index * 0.1),
                                min(0.2 + (index * 0.1) + 0.5, 1.0),
                              ),
                            ),
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                      stream: _chatService.getLatestMessageForChatRoom(
                        chatRoomId,
                      ),
                      builder: (context, msgSnapshot) {
                        if (msgSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                                  child: LinearProgressIndicator(),
                          );
                        }

                        // Default values if no messages yet
                        String subject = "New Conversation";
                        String message = "No messages yet";
                        String? reply;
                        String date = "Today";
                              bool hasUnread = false;

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
                                hasUnread = latestMsg['senderId'] != currentUser!.uid && 
                                           !(latestMsg['read'] ?? false);

                          // Format the date
                          if (latestMsg['timestamp'] != null) {
                                  final timestamp = latestMsg['timestamp'] as Timestamp;
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  final messageDate = timestamp.toDate();
                                  final messageDay = DateTime(
                                    messageDate.year, messageDate.month, messageDate.day);
                                  
                                  if (messageDay.isAtSameMomentAs(today)) {
                                    date = DateFormat('h:mm a').format(messageDate);
                                  } else if (messageDay.isAfter(today.subtract(const Duration(days: 1)))) {
                                    date = "Yesterday";
                                  } else {
                                    date = DateFormat('MMM d').format(messageDate);
                                  }
                          }
                        }

                              return _buildChatRoomCard(
                                subject: subject,
                                message: message,
                          reply: reply,
                          date: date,
                                hasUnread: hasUnread,
                          onTap: () {
                                  HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                      builder: (context) => ChatRoomPage(
                                      receiverUserId: otherUserId,
                                      chatRoomId: chatRoomId,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                          ),
                        ),
                    );
                      
                      return itemAnimation;
                  },
                );
              },
            ),
          ),

            // New message composer section
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required Color color}) {
    return Row(
      children: [
        Icon(
          icon, 
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.forum_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                "No conversations yet",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Send a message to start a conversation with the government officials",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              const Icon(
                Icons.arrow_downward,
                size: 36,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatRoomCard({
    required String subject,
    required String message,
    String? reply,
    required String date,
    required bool hasUnread,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      radius: 20,
                      child: Icon(
                        Icons.apartment_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Ministry of Services",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasUnread 
                                    ? theme.colorScheme.primary 
                                    : Colors.grey.shade600,
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Subject: $subject",
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Message",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: hasUnread 
                            ? theme.colorScheme.onSurface 
                            : Colors.grey.shade700,
                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                if (reply != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasUnread 
                        ? theme.colorScheme.secondary.withAlpha(15) 
                        : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.secondary,
                          width: 3,
                        ),
                        top: BorderSide(color: Colors.grey.shade200),
                        right: BorderSide(color: Colors.grey.shade200),
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.reply,
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Reply from Government",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reply,
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread 
                              ? theme.colorScheme.onSurface 
                              : Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hourglass_top,
                            size: 14,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Awaiting Response",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                if (hasUnread) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            offset: const Offset(0, -2),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(10),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  "Send Message to Government",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Subject field
                TextFormField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: "Subject",
                    hintText: "What's this about?",
                    prefixIcon: const Icon(Icons.subject),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                
                // Message field
                TextFormField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: "Message",
                    hintText: "Type your message here",
                    prefixIcon: const Icon(Icons.message_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Send button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : sendMessage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _isSubmitting 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting ? "Sending..." : "Send Message",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
