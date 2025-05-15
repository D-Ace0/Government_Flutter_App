import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String content;
  final String userId;
  final bool isAnonymous;
  final DateTime timestamp;
  final String parentId;
  final String parentType;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.isAnonymous,
    required this.timestamp,
    required this.parentId,
    required this.parentType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'userId': userId,
      'isAnonymous': isAnonymous,
      'timestamp': Timestamp.fromDate(timestamp),
      'parentId': parentId,
      'parentType': parentType,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      userId: map['userId'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      parentId: map['parentId'] ?? '',
      parentType: map['parentType'] ?? '',
    );
  }
} 