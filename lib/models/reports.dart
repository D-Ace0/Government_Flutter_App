import 'package:googleapis/androidpublisher/v3.dart';

class Report {
  final String id;
  final String title;
  final String description;
  final String status;
  final String location;
  final DateTime timestamp = DateTime.now();

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'location': location,
      'timestamp': timestamp,
    };
  }
}
