import 'package:cloud_firestore/cloud_firestore.dart';

class Advertisement {
  final String id;
  final String advertiserId;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final Timestamp? timestamp = Timestamp.now();
  bool isApproved = false;
  String? status = 'pending';

  Advertisement({
    required this.id,
    required this.advertiserId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'advertiserId': advertiserId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'timestamp': timestamp,
      'isApproved': isApproved,
      'status': status,
    };
  }
}
