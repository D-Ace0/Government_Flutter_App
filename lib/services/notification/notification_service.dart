import 'package:flutter/material.dart';
import 'package:governmentapp/models/announcement.dart';
import 'package:governmentapp/models/message.dart';
import 'package:governmentapp/models/poll.dart';
import 'package:governmentapp/services/notification/notification_manager.dart';
import 'package:governmentapp/utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  final NotificationManager _notificationManager = NotificationManager();
  
  NotificationService._internal();
  
  // In-app global key for showing overlay notifications
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Keep track of when notifications were last shown to avoid duplicates
  final Map<String, DateTime> _lastNotificationTimes = {};
  
  // Initialize notification service
  Future<void> initialize() async {
    // Nothing needed for initialization since we're using in-app notifications
    AppLogger.i('Notification service initialized');
  }
  
  // Request permissions - not needed for in-app notifications
  Future<void> requestPermissions() async {
    // No permissions needed for in-app notifications
    AppLogger.i('No permissions needed for in-app notifications');
  }
  
  // Show an in-app notification for a new poll and save to storage
  Future<void> showPollNotification(Poll poll, {BuildContext? context}) async {
    final now = DateTime.now();
    final lastShown = _lastNotificationTimes['poll_${poll.id}'];
    
    // Don't show the same notification if it was shown in the last hour
    if (lastShown != null && now.difference(lastShown).inHours < 1) {
      return;
    }
    
    _lastNotificationTimes['poll_${poll.id}'] = now;
    
    // Show UI notification if context is available
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx != null) {
      _showOverlayNotification(
        ctx,
        title: 'New Poll Available',
        message: poll.question,
        icon: Icons.poll,
        backgroundColor: Colors.blue,
      );
    }
    
    // Save notification to persistent storage
    try {
      await _notificationManager.createNotification(
        title: 'New Poll Available',
        message: poll.question,
        type: 'poll',
        targetId: poll.id,
        additionalData: {'pollEndDate': poll.endDate.millisecondsSinceEpoch},
      );
      AppLogger.i('Poll notification saved to storage: ${poll.id}');
    } catch (e) {
      AppLogger.e('Error saving poll notification', e);
    }
  }
  
  // Show an in-app notification for a new announcement and save to storage
  Future<void> showAnnouncementNotification(Announcement announcement, {BuildContext? context}) async {
    final now = DateTime.now();
    final lastShown = _lastNotificationTimes['announcement_${announcement.id}'];
    
    // Don't show the same notification if it was shown in the last hour
    if (lastShown != null && now.difference(lastShown).inHours < 1) {
      return;
    }
    
    _lastNotificationTimes['announcement_${announcement.id}'] = now;
    
    // Show UI notification if context is available
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx != null) {
      _showOverlayNotification(
        ctx,
        title: announcement.isUrgent ? 'Urgent Announcement' : 'New Announcement',
        message: announcement.title,
        icon: Icons.announcement,
        backgroundColor: announcement.isUrgent ? Colors.red : Colors.green,
      );
    }
    
    // Save notification to persistent storage
    try {
      await _notificationManager.createNotification(
        title: announcement.isUrgent ? 'Urgent Announcement' : 'New Announcement',
        message: announcement.title,
        type: 'announcement',
        targetId: announcement.id,
        additionalData: {
          'isUrgent': announcement.isUrgent,
          'expiryDate': announcement.expiryDate?.millisecondsSinceEpoch,
        },
      );
      AppLogger.i('Announcement notification saved to storage: ${announcement.id}');
    } catch (e) {
      AppLogger.e('Error saving announcement notification', e);
    }
  }
  
  // Show an in-app notification for a new message and save to storage
  Future<void> showMessageNotification(Message message, {BuildContext? context}) async {
    final now = DateTime.now();
    final messageId = '${message.senderId}_${message.receiverId}_${message.timestamp.millisecondsSinceEpoch}';
    final lastShown = _lastNotificationTimes['message_$messageId'];
    
    // Don't show the same notification if it was shown in the last hour
    if (lastShown != null && now.difference(lastShown).inHours < 1) {
      return;
    }
    
    _lastNotificationTimes['message_$messageId'] = now;
    
    // Show UI notification if context is available
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx != null) {
      _showOverlayNotification(
        ctx,
        title: 'New Message',
        message: 'From ${message.senderEmail}: ${message.subject}',
        icon: Icons.message,
        backgroundColor: Colors.indigo,
      );
    }
    
    // Save notification to persistent storage
    try {
      // Create chat room ID for the message
      List<String> ids = [message.senderId, message.receiverId];
      ids.sort();
      String chatRoomId = ids.join('_');
      
      await _notificationManager.createNotification(
        title: 'New Message',
        message: 'From ${message.senderEmail}: ${message.subject}',
        type: 'message',
        targetId: chatRoomId,
        additionalData: {
          'senderId': message.senderId,
          'senderEmail': message.senderEmail,
          'timestamp': message.timestamp.millisecondsSinceEpoch,
        },
      );
      AppLogger.i('Message notification saved to storage: $messageId');
    } catch (e) {
      AppLogger.e('Error saving message notification', e);
    }
  }
  
  // Check for new polls to notify about
  Future<void> checkForNewPolls(List<Poll> polls, DateTime lastCheckTime, BuildContext context) async {
    final newPolls = polls.where((poll) => 
      poll.startDate.isAfter(lastCheckTime) && poll.isActive
    ).toList();
    
    if (newPolls.isNotEmpty) {
      for (final poll in newPolls) {
        // Check if a notification for this poll already exists
        final exists = await _notificationManager.notificationExists('poll', poll.id);
        if (!exists) {
          await showPollNotification(poll, context: context);
        } else {
          AppLogger.i('Poll notification already exists, skipping: ${poll.id}');
        }
      }
    }
  }
  
  // Check for new announcements to notify about
  Future<void> checkForNewAnnouncements(
    List<Announcement> announcements, 
    DateTime lastCheckTime,
    BuildContext context
  ) async {
    final newAnnouncements = announcements.where((announcement) => 
      announcement.date.isAfter(lastCheckTime) && 
      !announcement.isDraft &&
      (announcement.expiryDate == null || announcement.expiryDate!.isAfter(DateTime.now()))
    ).toList();
    
    if (newAnnouncements.isNotEmpty) {
      for (final announcement in newAnnouncements) {
        // Check if a notification for this announcement already exists
        final exists = await _notificationManager.notificationExists('announcement', announcement.id);
        if (!exists) {
          await showAnnouncementNotification(announcement, context: context);
        } else {
          AppLogger.i('Announcement notification already exists, skipping: ${announcement.id}');
        }
      }
    }
  }
  
  // Check for new messages to notify about
  Future<void> checkForNewMessages(
    List<Message> messages, 
    DateTime lastCheckTime,
    BuildContext context
  ) async {
    final newMessages = messages.where((message) => 
      message.timestamp.toDate().isAfter(lastCheckTime)
    ).toList();
    
    if (newMessages.isNotEmpty) {
      for (final message in newMessages) {
        await showMessageNotification(message, context: context);
      }
    }
  }
  
  // Helper to show an overlay notification that auto-dismisses
  void _showOverlayNotification(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    final overlay = ScaffoldMessenger.of(context);
    
    overlay.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 8,
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            overlay.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
} 