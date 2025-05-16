import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Post an announcement (GOV01)
  Future<void> postAnnouncement({
    required String title,
    required String description,
    File? attachment, // optional image or PDF
    String? category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    if (title.trim().isEmpty || description.trim().isEmpty) {
      throw Exception("Title and description are required");
    }

    String? attachmentUrl;
    String? attachmentType;

    // Upload image/pdf if available
    if (attachment != null) {
      final int fileSize = await attachment.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception("Attachment exceeds 5MB");
      }

      final fileExtension = attachment.path.split('.').last.toLowerCase();
      attachmentType = (fileExtension == 'pdf') ? 'pdf' : 'image';

      final ref = _storage.ref().child('announcements/${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
      await ref.putFile(attachment);
      attachmentUrl = await ref.getDownloadURL();
    }

    await _firestore.collection('announcements').add({
      'title': title,
      'description': description,
      'category': category,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'timestamp': Timestamp.now(),
      'authorId': user.uid,
      'authorEmail': user.email,
    });
  }

  /// Get all announcements (CIT01)
  Stream<QuerySnapshot> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Post comment to an announcement (CIT01)
  Future<void> postComment({
    required String announcementId,
    required String text,
    required bool isAnonymous,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not authenticated");
    if (text.trim().isEmpty) throw Exception("Comment cannot be empty");

    await _firestore
        .collection('announcements')
        .doc(announcementId)
        .collection('comments')
        .add({
      'text': text.trim(),
      'senderId': isAnonymous ? 'anonymous' : user.uid,
      'senderEmail': isAnonymous ? null : user.email,
      'timestamp': Timestamp.now(),
    });
  }

  /// Get comments under an announcement
  Stream<QuerySnapshot> getComments(String announcementId) {
    return _firestore
        .collection('announcements')
        .doc(announcementId)
        .collection('comments')
        .orderBy('timestamp')
        .snapshots();
  }
}
