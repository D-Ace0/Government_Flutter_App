class Report {
  final String id;
  final String title;
  final String description;
  final String status;
  final String location;
  final String reporterId;
  final List<String> imageUrls;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.location,
    required this.reporterId,
    required this.imageUrls,
    required this.latitude,
    required this.longitude,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'location': location,
      'reporterId': reporterId,
      'imageUrls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      location: map['location'],
      reporterId: map['reporterId'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : null,
    );
  }
}
