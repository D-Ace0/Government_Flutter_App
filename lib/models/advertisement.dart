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
  String status;

  Advertisement({
    required this.id,
    required this.advertiserId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.status = 'pending',
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

  factory Advertisement.fromMap(Map<String, dynamic> map) {
    return Advertisement(
      id: map['id'] ?? '',
      advertiserId: map['advertiserId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}
