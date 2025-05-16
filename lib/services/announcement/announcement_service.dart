import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/announcement.dart';
import '../../models/comment.dart';
import '../../services/notification/notification_service.dart';
import '../../utils/logger.dart';
import '../google_drive/google_drive_service.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class AnnouncementService {
  final FirebaseFirestore _firestore;
  final GoogleDriveService _driveService;
  final NotificationService _notificationService = NotificationService();

  AnnouncementService({
    FirebaseFirestore? firestore,
    GoogleDriveService? driveService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _driveService = driveService ?? GoogleDriveService();

  Future<void> createAnnouncement(Announcement announcement) async {
    await _firestore.collection('announcements').doc(announcement.id).set(announcement.toMap());
    
    // Only create notification for published, non-draft announcements
    // that are already publishable (publish date is in the past or now)
    final now = DateTime.now();
    if (!announcement.isDraft && announcement.publishDate.compareTo(now) <= 0) {
      try {
        await _notificationService.showAnnouncementNotification(announcement);
        AppLogger.i('Announcement notification created for: ${announcement.id}');
      } catch (e) {
        AppLogger.e('Error creating announcement notification', e);
        // Continue execution even if notification fails
      }
    }
  }

  Future<String> uploadAttachment(File file) async {
    try {
      // Initialize Drive service first
      await _driveService.initialize();
      
      final fileName = 'announcement_${DateTime.now().millisecondsSinceEpoch}';
      final url = await _driveService.uploadImageToDrive(file, fileName);
      
      // Verify the uploaded file is accessible
      final response = await http.head(Uri.parse(url));
      if (response.statusCode != 200) {
        AppLogger.w('Uploaded file might not be immediately accessible: $url');
        // Add a short delay to allow Google Drive to process the file
        await Future.delayed(const Duration(seconds: 1));
      }
      
      // Log success
      AppLogger.i('Successfully uploaded attachment: $fileName, URL: $url');
      
      return url;
    } catch (e) {
      // Log error
      AppLogger.e('Error uploading attachment', e);
      throw Exception('Failed to upload attachment: $e');
    }
  }

  // Get all announcements without filtering
  Future<List<Announcement>> getAnnouncements() async {
    final snapshot = await _firestore.collection('announcements').orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => Announcement.fromMap(doc.data())).toList();
  }

  // Get active announcements (published, not expired)
  Future<List<Announcement>> getActiveAnnouncements() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('announcements')
        .where('isDraft', isEqualTo: false)
        .get();
    
    final announcements = snapshot.docs.map((doc) => Announcement.fromMap(doc.data())).toList();
    
    // Filter for active announcements (publishDate in past, expiry date in future or null)
    return announcements.where((a) => 
      a.publishDate.isBefore(now) && 
      (a.expiryDate == null || a.expiryDate!.isAfter(now))
    ).toList();
  }

  Future<List<Announcement>> getDraftAnnouncements() async {
    final snapshot = await _firestore
        .collection('announcements')
        .where('isDraft', isEqualTo: true)
        .orderBy('date', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => Announcement.fromMap(doc.data())).toList();
  }

  Future<List<Announcement>> getScheduledAnnouncements() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('announcements')
        .where('isDraft', isEqualTo: false)
        .get();
    
    final announcements = snapshot.docs.map((doc) => Announcement.fromMap(doc.data())).toList();
    
    return announcements.where((a) => a.publishDate.isAfter(now)).toList();
  }

  Future<List<Announcement>> getExpiredAnnouncements() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('announcements')
        .where('isDraft', isEqualTo: false)
        .get();
    
    final announcements = snapshot.docs.map((doc) => Announcement.fromMap(doc.data())).toList();
    
    return announcements.where((a) => 
      a.expiryDate != null && a.expiryDate!.isBefore(now)
    ).toList();
  }

  Future<void> processRecurringAnnouncements() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('announcements')
        .where('recurringPattern', isNull: false) 
        .get();
    
    final recurringAnnouncements = snapshot.docs.map((doc) => Announcement.fromMap(doc.data())).toList();
    
    for (final announcement in recurringAnnouncements) {
      if (announcement.lastRecurrence == null || _shouldRecur(announcement, now)) {
        final newAnnouncement = announcement.copyWith(
          id: const Uuid().v4(),
          date: now,
          publishDate: now,
          lastRecurrence: now,
        );
        
        await createAnnouncement(newAnnouncement);
        
        // Update the original recurring announcement with new lastRecurrence
        await updateAnnouncement(announcement.copyWith(lastRecurrence: now));
      }
    }
  }

  // Helper to determine if an announcement should recur based on pattern and last recurrence
  bool _shouldRecur(Announcement announcement, DateTime now) {
    if (announcement.lastRecurrence == null) return true;
    
    final lastRecurrence = announcement.lastRecurrence!;
    
    switch (announcement.recurringPattern) {
      case 'daily':
        return now.difference(lastRecurrence).inDays >= 1;
      case 'weekly':
        return now.difference(lastRecurrence).inDays >= 7;
      case 'monthly':
        return (now.year - lastRecurrence.year) * 12 + now.month - lastRecurrence.month >= 1;
      case 'quarterly':
        return (now.year - lastRecurrence.year) * 12 + now.month - lastRecurrence.month >= 3;
      case 'yearly':
        return now.year > lastRecurrence.year;
      default:
        return false;
    }
  }

  Future<void> addComment(String announcementId, Comment comment) async {
    final announcementRef = _firestore.collection('announcements').doc(announcementId);
    await announcementRef.update({
      'comments': FieldValue.arrayUnion([comment.toMap()])
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    await _firestore.collection('announcements').doc(announcement.id).update(announcement.toMap());
  }
} 