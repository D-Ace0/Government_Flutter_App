import 'package:cloud_firestore/cloud_firestore.dart';

class OfficialPhone {
  final String id;
  final String department;
  final String phoneNumber;
  final String description;
  final Timestamp timestamp;

  OfficialPhone({
    required this.id,
    required this.department,
    required this.phoneNumber,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'department': department,
      'phoneNumber': phoneNumber,
      'description': description,
      'timestamp': timestamp,
    };
  }
}
