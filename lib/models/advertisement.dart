import 'package:cloud_firestore/cloud_firestore.dart';

class Advertisement {
  final String advertiserId;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final Timestamp timestamp;
  bool isApproved = false;

  Advertisement({
    required this.advertiserId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'advertiserId': advertiserId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'timestamp': timestamp,
      'isApproved': isApproved,
    };
  }
}
