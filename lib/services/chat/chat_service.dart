import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:governmentapp/models/message.dart';
import 'package:governmentapp/services/moderation/moderation_service.dart';
import 'package:governmentapp/services/notification/notification_service.dart';
import 'package:governmentapp/utils/logger.dart';

class ChatService {
  // firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // firebase auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // notification service
  final NotificationService _notificationService = NotificationService();

  // moderation service
  final ModerationService _moderationService =
      ModerationService(); // send message
  Future<void> sendMessage(
    String receiverId,
    String subject,
    String messageContent,
  ) async {
    // Direct check for common offensive words that must always be blocked
    // This is a failsafe in case the moderation service fails
    final List<String> bannedWords = [
      'nigga',
      'nigger',
      'fuck',
      'shit',
      'كس',
      'طيز',
      'ass',
      'bitch'
    ];

    String lowerSubject = subject.toLowerCase();
    String lowerMessage = messageContent.toLowerCase();

    for (final word in bannedWords) {
      if (lowerSubject.contains(word) || lowerMessage.contains(word)) {
        AppLogger.w('Offensive content blocked by direct check: "$word"');
        throw Exception(
            'Your message contains inappropriate or offensive content.');
      }
    }

    // Then use the moderation service as a second layer of detection
    bool subjectHasOffensiveContent = false;
    bool messageHasOffensiveContent = false;

    try {
      subjectHasOffensiveContent =
          await _moderationService.containsOffensiveContent(subject);
      messageHasOffensiveContent =
          await _moderationService.containsOffensiveContent(messageContent);

      if (subjectHasOffensiveContent || messageHasOffensiveContent) {
        throw Exception(
            'Your message contains inappropriate or offensive content.');
      }
    } catch (e) {
      // If there's an error with the moderation service, log it and
      // continue with our direct check only
      AppLogger.e('Moderation service error: $e');
      // We've already done the direct check above, so we can continue
    }

    // current user info (sender)
    final String currUserUid = _auth.currentUser!.uid;
    final String? currUserEmail = _auth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();

    // create a message model
    Message message = Message(
      subject,
      senderId: currUserUid,
      receiverId: receiverId,
      senderEmail: currUserEmail!,
      message: messageContent,
      timestamp: timestamp,
    );

    // construct chat room ID for the two users
    List<String> ids = [currUserUid, receiverId];
    ids.sort(); // ensure uniqueness of the message (chat room is the same for any 2 peopole)
    String chatRoomId = ids.join('_');
    // Create or update the chat room document
    await _firestore.collection("chat_rooms").doc(chatRoomId).set({
      "participants": ids,
      "last_updated": timestamp,
      // Optionally: add "last_message": messageContent
    });

    // store this message into the database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(message.toMap());

    // Create notification for the receiver
    try {
      await _notificationService.showMessageNotification(message);
      AppLogger.i('Message notification created for receiver: $receiverId');
    } catch (e) {
      AppLogger.e('Error creating message notification', e);
      // Continue execution even if notification fails
    }
  }

  // Get all chat rooms for the current user
  Stream<QuerySnapshot> getUserChatRooms() {
    final String currUserUid = _auth.currentUser!.uid;

    return _firestore
        .collection("chat_rooms")
        .where("participants", arrayContains: currUserUid)
        .snapshots();
  }

  // Get the latest message for a specific chat room
  Stream<QuerySnapshot> getLatestMessageForChatRoom(String chatRoomId) {
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}
