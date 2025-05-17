import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/poll.dart';
import '../../models/comment.dart';
import '../../services/notification/notification_service.dart';
import '../../services/moderation/moderation_service.dart';
import '../../utils/logger.dart';
import 'package:uuid/uuid.dart';

class PollService {
  final FirebaseFirestore _firestore;
  final CollectionReference _pollsCollection;
  final NotificationService _notificationService = NotificationService();

  PollService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _pollsCollection = FirebaseFirestore.instance.collection('polls');

  Future<void> createPoll(Poll poll) async {
    try {
      // Create the poll in Firestore
      final docRef = await _pollsCollection.add(poll.toMap());

      // Get the poll ID from the document reference
      final String pollId = docRef.id;

      // Create a notification for the new poll
      try {
        final pollWithId = poll.copyWith(id: pollId);
        await _notificationService.showPollNotification(pollWithId);
        AppLogger.i('Poll notification created for poll: $pollId');
      } catch (e) {
        AppLogger.e('Error creating poll notification', e);
        // Continue execution even if notification fails
      }
    } catch (e) {
      throw Exception('Error creating poll: $e');
    }
  }

  Future<void> vote(String pollId, String userId, int voteValue) async {
    if (voteValue != 1 && voteValue != -1) {
      throw Exception('Invalid vote value. Must be 1 (yes) or -1 (no)');
    }

    try {
      await _pollsCollection.doc(pollId).update({
        'votes.$userId': voteValue,
      });
    } catch (e) {
      throw Exception('Error voting on poll: $e');
    }
  }

  Future<Map<String, int>> getResults(String pollId) async {
    final pollDoc = await _pollsCollection.doc(pollId).get();
    if (!pollDoc.exists) {
      throw Exception('Poll not found');
    }

    final poll = Poll.fromFirestore(pollDoc);
    return poll.votes;
  }

  Future<void> addComment(
      String pollId, String userId, String content, bool isAnonymous) async {
    try {
      // Check for profanity in comment
      final moderationService = ModerationService();
      bool hasOffensiveContent = false;

      try {
        hasOffensiveContent =
            await moderationService.containsOffensiveContent(content);
      } catch (e) {
        // If moderation service fails, do a simple check
        final List<String> bannedWords = [
          'nigga',
          'nigger',
          'fuck',
          'shit',
          'كس',
          'طيز',
          'ass',
          'bitch'
        ];

        String lowerContent = content.toLowerCase();
        for (final word in bannedWords) {
          if (lowerContent.contains(word)) {
            hasOffensiveContent = true;
            break;
          }
        }
      }

      if (hasOffensiveContent) {
        throw Exception('Comment contains inappropriate or offensive content');
      }

      final comment = Comment(
        id: const Uuid().v4(),
        content: content,
        userId: userId,
        isAnonymous: isAnonymous,
        timestamp: DateTime.now(),
        parentId: pollId,
        parentType: 'poll',
      );

      final pollDoc = await _pollsCollection.doc(pollId).get();
      final pollData = pollDoc.data() as Map<String, dynamic>;

      List<dynamic> comments = List.from(pollData['comments'] ?? []);
      comments.add(comment.toMap());

      await _pollsCollection.doc(pollId).update({
        'comments': comments,
      });
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  Future<List<Poll>> getActivePolls() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _pollsCollection
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('endDate')
          .get();

      return querySnapshot.docs
          .map((doc) => Poll.fromFirestore(doc))
          .where((poll) =>
              poll.startDate.isBefore(now) ||
              poll.startDate.isAtSameMomentAs(now))
          .toList();
    } catch (e) {
      throw Exception('Error fetching active polls: $e');
    }
  }

  Future<List<Poll>> getEndedPolls() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('polls')
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('endDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching ended polls: $e');
    }
  }

  Future<void> deletePoll(String id) async {
    await _firestore.collection('polls').doc(id).delete();
  }

  Future<void> updatePoll(Poll poll) async {
    await _firestore.collection('polls').doc(poll.id).set(poll.toMap());
  }

  Future<List<Poll>> getPolls() async {
    try {
      final querySnapshot = await _pollsCollection.get();
      return querySnapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching polls: $e');
    }
  }

  Future<Poll?> getPoll(String pollId) async {
    try {
      final docSnapshot = await _pollsCollection.doc(pollId).get();
      if (!docSnapshot.exists) {
        return null;
      }
      return Poll.fromFirestore(docSnapshot);
    } catch (e) {
      throw Exception('Error fetching poll: $e');
    }
  }

  Future<Map<String, dynamic>> getPollStatistics(String pollId) async {
    try {
      final poll = await getPoll(pollId);
      if (poll == null) {
        throw Exception('Poll not found');
      }

      final totalVotes = poll.getTotalVotes();
      final yesPercentage = poll.getYesPercentage();
      final noPercentage = poll.getNoPercentage();

      return {
        'totalVotes': totalVotes,
        'yesPercentage': yesPercentage,
        'noPercentage': noPercentage,
      };
    } catch (e) {
      throw Exception('Error getting poll statistics: $e');
    }
  }

  Future<List<Poll>> getPollsByCategory(String category) async {
    final snapshot = await _firestore
        .collection('polls')
        .where('category', isEqualTo: category)
        .get();
    return snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
  }
}
