import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:governmentapp/models/comment.dart';

class Poll {
  final String id;
  final String question;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> votes; // userId: vote (1 for yes, -1 for no)
  final List<Comment> comments;
  final bool isAnonymous;
  final String creatorId;
  final String category;

  Poll({
    required this.id,
    required this.question,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.votes,
    required this.comments,
    required this.isAnonymous,
    required this.creatorId,
    required this.category,
  });

  // Factory constructor to create a Poll from Firestore data
  factory Poll.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Poll(
      id: doc.id,
      question: data['question'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      votes: Map<String, int>.from(data['votes'] ?? {}),
      comments: (data['comments'] as List<dynamic>?)
          ?.map((c) => Comment.fromMap(c as Map<String, dynamic>))
          .toList() ?? [],
      isAnonymous: data['isAnonymous'] ?? false,
      creatorId: data['creatorId'] ?? '',
      category: data['category'] ?? 'General',
    );
  }

  // Check if the poll is active based on start and end dates
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Check if a specific user has voted
  bool hasVoted(String userId) {
    return votes.containsKey(userId);
  }

  // Get total number of votes
  int getTotalVotes() {
    return votes.length;
  }

  // Get percentage of "yes" votes (1)
  double getYesPercentage() {
    if (votes.isEmpty) return 0;
    final yesVotes = votes.values.where((vote) => vote == 1).length;
    return (yesVotes / votes.length) * 100;
  }

  // Get percentage of "no" votes (-1)
  double getNoPercentage() {
    if (votes.isEmpty) return 0;
    final noVotes = votes.values.where((vote) => vote == -1).length;
    return (noVotes / votes.length) * 100;
  }

  // Convert Poll to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'votes': votes,
      'comments': comments.map((c) => c.toMap()).toList(),
      'isAnonymous': isAnonymous,
      'creatorId': creatorId,
      'category': category,
    };
  }
} 