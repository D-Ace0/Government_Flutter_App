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

    // store this message into the database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(message.toMap());
  }

  // get my messages
  Stream<QuerySnapshot> getMessages(String userId, otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // get chat rooms
  // Stream<DocumentSnapshot> getChatRooms(String userId, otherUserId) {
  //   List<String> ids = [userId, otherUserId];
  //   ids.sort();
  //   String chatRoomId = ids.join("_");

  //   return _firestore.collection("chat_rooms").doc(chatRoomId).snapshots();
  // }

  Stream<List<QueryDocumentSnapshot>> getChatRoomsForCurrentUser() {
    final currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collectionGroup("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) {
          final Map<String, QueryDocumentSnapshot> latestMessages = {};

          for (final doc in snapshot.docs) {
            final senderId = doc['senderId'];
            final receiverId = doc['receiverId'];

            // Only include messages that the current user is involved in
            if (senderId != currentUserId && receiverId != currentUserId)
              continue;

            final ids = [senderId, receiverId]..sort();
            final chatRoomId = ids.join('_');

            if (!latestMessages.containsKey(chatRoomId)) {
              latestMessages[chatRoomId] = doc;
            }
          }

          return latestMessages.values.toList();
        });
  }
}
