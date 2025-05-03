import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Message {
  final String senderId;
  final String receiverId;
  final String senderEmail;
  final String message;
  final String subject;
  final Timestamp timestamp;

  Message(
    this.subject, {
    required this.senderId,
    required this.receiverId,
    required this.senderEmail,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    DateTime date = timestamp.toDate();
    String formattedDate = DateFormat('MMMM d, y').format(date);

    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'subject': subject,
      'timestamp': timestamp,
      'formattedDate': formattedDate,
      'reply': null, // if you expect replies later
    };
  }
}
