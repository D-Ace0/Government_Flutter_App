import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../models/announcement.dart';
import '../models/comment.dart';
import '../services/announcement/announcement_service.dart';
import '../widgets/my_comment_card.dart';

class AnnouncementDetailPage extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailPage({
    super.key,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailPage> createState() => _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState extends State<AnnouncementDetailPage> {
  final AnnouncementService _announcementService = AnnouncementService();
  late Announcement _announcement;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
  }

  Future<void> _addComment(String content, bool isAnonymous) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final comment = Comment(
        id: const Uuid().v4(),
        content: content,
        userId: currentUser.uid,
        isAnonymous: isAnonymous,
        timestamp: DateTime.now(),
        parentId: _announcement.id,
        parentType: 'announcement',
      );

      await _announcementService.addComment(_announcement.id, comment);

      // Update local state
      setState(() {
                _announcement = Announcement(
          id: _announcement.id,
          title: _announcement.title,
          content: _announcement.content,
          date: _announcement.date,
          publishDate: _announcement.publishDate,
          expiryDate: _announcement.expiryDate,
          recurringPattern: _announcement.recurringPattern,
          lastRecurrence: _announcement.lastRecurrence,
          category: _announcement.category,
          attachments: _announcement.attachments,
          comments: [..._announcement.comments, comment],
          authorId: _announcement.authorId,
          isUrgent: _announcement.isUrgent,
          isDraft: _announcement.isDraft,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAttachmentGallery() {
    if (_announcement.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _announcement.attachments.length,
        itemBuilder: (context, index) {
          final attachment = _announcement.attachments[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          title: const Text('Attachment'),
                          leading: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        InteractiveViewer(
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(20),
                          minScale: 0.5,
                          maxScale: 4,
                          child: Image.network(
                            attachment,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, size: 100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Image.network(
                attachment,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 100),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
            appBar: AppBar(        title: Text(_announcement.title),        leading: IconButton(          icon: const Icon(Icons.arrow_back),          onPressed: () {            Navigator.pop(context);          },        ),      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Announcement header
                        Row(
                          children: [
                            Chip(
                              label: Text(_announcement.category),
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                            ),
                            if (_announcement.isUrgent)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Chip(
                                  label: const Text('Urgent'),
                                  backgroundColor: Colors.red,
                                  labelStyle: const TextStyle(color: Colors.white),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              dateFormat.format(_announcement.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Status information
                        if (_announcement.isScheduled || _announcement.expiryDate != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_announcement.isScheduled)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Scheduled for: ${dateFormat.format(_announcement.publishDate)}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_announcement.expiryDate != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.event_busy, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Expires on: ${dateFormat.format(_announcement.expiryDate!)}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                if (_announcement.recurringPattern != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.repeat, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Recurring: ${_announcement.recurringPattern}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Announcement content
                        Text(
                          _announcement.content,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        
                        // Attachments
                        if (_announcement.attachments.isNotEmpty) ...[
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAttachmentGallery(),
                          const SizedBox(height: 24),
                        ],
                        
                        // Comments section
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CommentsList(
                          comments: _announcement.comments,
                          currentUserId: currentUser?.uid,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Comment input
                CommentInput(onSubmit: _addComment),
              ],
            ),
    );
  }
} 