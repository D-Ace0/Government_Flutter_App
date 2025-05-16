import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:governmentapp/models/message.dart';

class ChatService {
  // firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // firebase auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // send message
  Future<void> sendMessage(
    String receiverId,
    String subject,
    String messageContent,
  ) async {
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
