import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:governmentapp/models/notification_model.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // Get collection reference for user notifications
  CollectionReference<Map<String, dynamic>> _getNotificationsRef(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('notifications');
  }

  // Get current user ID
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get notifications for current user
  Stream<List<NotificationModel>> getNotifications() {
    final userId = _getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }

    return _getNotificationsRef(userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get unread notifications count
  Stream<int> getUnreadCount() {
    final userId = _getCurrentUserId();
    if (userId == null) {
      return Stream.value(0);
    }

    return _getNotificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Check if a notification for a specific item already exists
  Future<bool> notificationExists(String type, String targetId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      AppLogger.e('Failed to check notification: No user logged in');
      return false;
    }

    try {
      final snapshot = await _getNotificationsRef(userId)
          .where('type', isEqualTo: type)
          .where('targetId', isEqualTo: targetId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.e('Error checking notification existence', e);
      return false;
    }
  }

  // Create a new notification
  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    required String targetId,
    Map<String, dynamic>? additionalData,
  }) async {
    // First check if notifications are enabled
    if (!(await areNotificationsEnabled())) {
      AppLogger.i('Notifications are disabled, skipping creating notification in database');
      return;
    }
    
    final userId = _getCurrentUserId();
    if (userId == null) {
      AppLogger.e('Failed to create notification: No user logged in');
      return;
    }

    // For announcements and polls, check if a notification already exists
    if (type == 'announcement' || type == 'poll') {
      final exists = await notificationExists(type, targetId);
      if (exists) {
        AppLogger.i('Notification for $type $targetId already exists, skipping');
        return;
      }
    }

    try {
      await _getNotificationsRef(userId).add({
        'title': title,
        'message': message,
        'type': type,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'targetId': targetId,
        'additionalData': additionalData,
      });
      AppLogger.i('Notification created: $title');
    } catch (e) {
      AppLogger.e('Error creating notification', e);
      throw Exception('Failed to create notification: $e');
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      AppLogger.e('Failed to mark notification as read: No user logged in');
      return;
    }

    try {
      await _getNotificationsRef(userId).doc(notificationId).update({
        'isRead': true,
      });
      AppLogger.i('Notification marked as read: $notificationId');
    } catch (e) {
      AppLogger.e('Error marking notification as read', e);
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      AppLogger.e('Failed to mark notifications as read: No user logged in');
      return;
    }

    try {
      // Get all unread notifications
      final unreadDocs = await _getNotificationsRef(userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Batch update all unread notifications
      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      AppLogger.i('All notifications marked as read');
    } catch (e) {
      AppLogger.e('Error marking all notifications as read', e);
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      AppLogger.e('Failed to delete notification: No user logged in');
      return;
    }

    try {
      await _getNotificationsRef(userId).doc(notificationId).delete();
      AppLogger.i('Notification deleted: $notificationId');
    } catch (e) {
      AppLogger.e('Error deleting notification', e);
      throw Exception('Failed to delete notification: $e');
    }
  }
} 