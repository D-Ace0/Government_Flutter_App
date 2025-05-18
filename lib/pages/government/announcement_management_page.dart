import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../models/announcement.dart';
import '../../services/announcement/announcement_service.dart';
import '../../widgets/my_button.dart';
import '../../widgets/my_dropdown.dart';
import '../../widgets/my_text_field.dart';
import '../../widgets/my_bottom_navigation_bar.dart';
import '../../widgets/my_action_button.dart';
import '../announcement_detail_page.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';

class AnnouncementManagementPage extends StatefulWidget {
  const AnnouncementManagementPage({super.key});

  @override
  State<AnnouncementManagementPage> createState() =>
      _AnnouncementManagementPageState();
}

class _AnnouncementManagementPageState extends State<AnnouncementManagementPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  final AnnouncementService _announcementService = AnnouncementService();
  final ImagePicker _picker = ImagePicker();

  List<File> _selectedFiles = [];
  String? _selectedCategory;
  bool _isUrgent = false;
  bool _isLoading = false;

  late TabController _tabController;
  List<Announcement> _activeAnnouncements = [];
  List<Announcement> _scheduledAnnouncements = [];
  List<Announcement> _draftAnnouncements = [];
  List<Announcement> _archivedAnnouncements = [];
  final List<Announcement> _urgentAnnouncements = [];

  int _selectedIndex =
      1; // Set to 1 for "Announcements" tab in the bottom navigation

  final List<String> categories = [
    'General',
    'Infrastructure',
    'Health',
    'Education',
    'Events',
    'Emergency',
  ];

  // Additional controllers for scheduling
  final TextEditingController _publishDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final DateTime _selectedPublishDate = DateTime.now();
  DateTime? _selectedExpiryDate;
  String? _selectedRecurringPattern;
  final bool _isDraft = true;

  final List<String> recurringPatterns = [
    'None',
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnnouncements();

    // Initialize date controllers
    _updatePublishDateText();
  }

  Future<void> _loadAnnouncements() async {
    bool wasNotLoading = !_isLoading;

    if (wasNotLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final announcements = await _announcementService.getAnnouncements();

      // Sort announcements by date - newest first
      announcements.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          // Active announcements - published and not expired
          _activeAnnouncements = announcements
              .where((a) => a.isPublished && !a.isExpired)
              .toList();

          // Scheduled announcements - scheduled to be published in future
          _scheduledAnnouncements =
              announcements.where((a) => a.isScheduled).toList();

          // Draft announcements
          _draftAnnouncements = announcements.where((a) => a.isDraft).toList();

          // Archived announcements - expired announcements
          _archivedAnnouncements =
              announcements.where((a) => a.isExpired).toList();

          if (wasNotLoading) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted && wasNotLoading) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading announcements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _publishDateController.dispose();
    _expiryDateController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to update publish date text field
  void _updatePublishDateText() {
    _publishDateController.text =
        DateFormat('MMM dd, yyyy').format(_selectedPublishDate);

    if (_selectedExpiryDate != null) {
      _expiryDateController.text =
          DateFormat('MMM dd, yyyy').format(_selectedExpiryDate!);
    } else {
      _expiryDateController.text = 'No Expiry';
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Reduce image quality to improve upload speed
        maxWidth: 1200, // Constrain dimensions for better performance
      );

      if (image != null) {
        final File file = File(image.path);

        // Validate file size (limit to 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Image is too large. Please select an image under 5MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Validate file type
        final fileName = file.path.toLowerCase();
        if (!fileName.endsWith('.jpg') &&
            !fileName.endsWith('.jpeg') &&
            !fileName.endsWith('.png')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Unsupported file type. Please select a JPG or PNG image.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles.add(file);
        });

        // Show feedback to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image added: ${file.path.split('/').last}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // User canceled image selection
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedCategory = null;
      _isUrgent = false;
      _selectedFiles = [];
    });
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/government_home');
    } else if (index == 1) {
      // Already on announcements page
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/polls');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/report');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/government_message');
    }
  }

  void _showCreateAnnouncementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Create New Announcement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MyTextfield(
                hintText: 'Title',
                controller: _titleController,
                obSecure: false,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Content',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MyDropdownField(
                hintText: 'Category',
                value: _selectedCategory,
                items: categories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: StatefulBuilder(
                  builder: (context, setStateLocal) => Row(
                    children: [
                      Transform.scale(
                        scale: 1.1,
                        child: Checkbox(
                          value: _isUrgent,
                          activeColor: Colors.red,
                          onChanged: (bool? value) {
                            setStateLocal(() {
                              _isUrgent = value ?? false;
                            });
                            setState(() {
                              _isUrgent = value ?? false;
                            });
                          },
                        ),
                      ),
                      const Text(
                        'Mark as Urgent',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message:
                            'Urgent announcements are highlighted and shown at the top',
                        child: Icon(Icons.info_outline,
                            size: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Attachments section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedFiles.isEmpty)
                      Text(
                        'No attachments added',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedFiles.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: FileImage(_selectedFiles[index]),
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeFile(index),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    StandardActionButton(
                      label: 'Add Attachment',
                      icon: Icons.add_photo_alternate,
                      onPressed: _pickImage,
                      style: ActionButtonStyle.info,
                      isOutlined: true,
                      size: ActionButtonSize.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: MyButton(
                  text: 'Create Announcement',
                  onTap: _createAnnouncement,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to load data in background without blocking UI
  Future<void> _silentRefresh() async {
    try {
      final announcements = await _announcementService.getAnnouncements();

      // Sort announcements by date - newest first
      announcements.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          // Active announcements - published and not expired
          _activeAnnouncements = announcements
              .where((a) => a.isPublished && !a.isExpired)
              .toList();

          // Scheduled announcements - scheduled to be published in future
          _scheduledAnnouncements =
              announcements.where((a) => a.isScheduled).toList();

          // Draft announcements
          _draftAnnouncements = announcements.where((a) => a.isDraft).toList();

          // Archived announcements - expired announcements
          _archivedAnnouncements =
              announcements.where((a) => a.isExpired).toList();
        });
      }
    } catch (e) {
      // Silent error handling - don't show errors during background refresh
    }
  }

  Future<void> _createAnnouncement() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Upload attachments and get URLs
      List<String> attachmentUrls = [];

      // Show a progress indicator for uploads
      if (_selectedFiles.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                const SizedBox(width: 10),
                Text('Uploading ${_selectedFiles.length} attachment(s)...'),
              ],
            ),
            duration:
                const Duration(minutes: 2), // Extended duration for upload
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Upload each file with individual error handling
      for (var i = 0; i < _selectedFiles.length; i++) {
        try {
          final url =
              await _announcementService.uploadAttachment(_selectedFiles[i]);
          attachmentUrls.add(url);

          // Update progress
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Uploaded image ${i + 1} of ${_selectedFiles.length}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading image ${i + 1}: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          // Continue with other uploads despite this failure
        }
      }

      // Create announcement
      final announcement = Announcement(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: DateTime.now(),
        publishDate: _selectedPublishDate,
        expiryDate: _selectedExpiryDate,
        recurringPattern: _selectedRecurringPattern,
        category: _selectedCategory!,
        attachments: attachmentUrls,
        comments: [],
        authorId: currentUser.uid,
        isUrgent: _isUrgent,
        isDraft: _isDraft,
      );

      await _announcementService.createAnnouncement(announcement);

      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        Navigator.pop(context); // Close the creation modal

        // Switch to the appropriate tab
        if (_isDraft) {
          _tabController.animateTo(2); // Switch to Drafts tab
        } else if (_selectedPublishDate.isAfter(DateTime.now())) {
          _tabController.animateTo(1); // Switch to Scheduled tab
        } else {
          _tabController.animateTo(0); // Switch to Active tab
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Announcement created successfully with ${attachmentUrls.length} attachment(s)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Reset form
        _resetForm();

        // Perform a full reload rather than silent refresh
        if (attachmentUrls.isNotEmpty) {
          await _loadAnnouncements();
        } else {
          _silentRefresh(); // Use silent refresh for announcements without attachments
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating announcement: $e'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text(
            'Are you sure you want to delete "${announcement.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                await _announcementService.deleteAnnouncement(announcement.id);

                if (mounted) {
                  // Immediately update local state for UI refresh
                  setState(() {
                    // Remove the announcement from all local lists
                    _activeAnnouncements
                        .removeWhere((a) => a.id == announcement.id);
                    _urgentAnnouncements
                        .removeWhere((a) => a.id == announcement.id);
                    _archivedAnnouncements
                        .removeWhere((a) => a.id == announcement.id);
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh data from server in background without UI blocking
                  _silentRefresh();
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting announcement: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _markAsUrgent(Announcement announcement, bool urgent) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(urgent ? 'Mark as Urgent' : 'Remove Urgent Status'),
        content: Text(urgent
            ? 'This will mark the announcement as urgent and highlight it for all users.'
            : 'This will remove the urgent status from this announcement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                // Update the announcement with new urgent status
                final updatedAnnouncement = Announcement(
                  id: announcement.id,
                  title: announcement.title,
                  content: announcement.content,
                  date: announcement.date,
                  publishDate: announcement.publishDate,
                  expiryDate: announcement.expiryDate,
                  recurringPattern: announcement.recurringPattern,
                  lastRecurrence: announcement.lastRecurrence,
                  category: announcement.category,
                  attachments: announcement.attachments,
                  comments: announcement.comments,
                  authorId: announcement.authorId,
                  isUrgent: urgent,
                  isDraft: announcement.isDraft,
                );

                await _announcementService
                    .updateAnnouncement(updatedAnnouncement);

                if (mounted) {
                  // Immediately update local state for UI refresh
                  setState(() {
                    // Update the announcement in its current list rather than moving it
                    // Find the announcement in all lists
                    int activeIndex = _activeAnnouncements
                        .indexWhere((a) => a.id == announcement.id);
                    int scheduledIndex = _scheduledAnnouncements
                        .indexWhere((a) => a.id == announcement.id);
                    int draftIndex = _draftAnnouncements
                        .indexWhere((a) => a.id == announcement.id);
                    int archivedIndex = _archivedAnnouncements
                        .indexWhere((a) => a.id == announcement.id);

                    // Update the announcement in whichever list it's found
                    if (activeIndex != -1) {
                      _activeAnnouncements[activeIndex] = updatedAnnouncement;
                    } else if (scheduledIndex != -1) {
                      _scheduledAnnouncements[scheduledIndex] =
                          updatedAnnouncement;
                    } else if (draftIndex != -1) {
                      _draftAnnouncements[draftIndex] = updatedAnnouncement;
                    } else if (archivedIndex != -1) {
                      _archivedAnnouncements[archivedIndex] =
                          updatedAnnouncement;
                    }

                    _isLoading = false;
                  });

                  // Don't change tabs automatically

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(urgent
                          ? 'Announcement marked as urgent'
                          : 'Urgent status removed'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh data from server in background without UI blocking
                  _silentRefresh();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating announcement: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: Text(
              urgent ? 'Mark as Urgent' : 'Remove Urgent Status',
              style: TextStyle(
                color: urgent ? Colors.red : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _archiveAnnouncement(Announcement announcement) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Announcement'),
        content: const Text(
            'This will move the announcement to the archived section. Archived announcements are less visible but still accessible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                // Create a new date 31 days ago to force it into archived status
                final archiveDate =
                    DateTime.now().subtract(const Duration(days: 31));

                // Update the announcement with the archive date
                final updatedAnnouncement = Announcement(
                  id: announcement.id,
                  title: announcement.title,
                  content: announcement.content,
                  date: archiveDate, // Set date to archive threshold
                  publishDate: announcement.publishDate,
                  expiryDate: announcement.expiryDate,
                  recurringPattern: announcement.recurringPattern,
                  lastRecurrence: announcement.lastRecurrence,
                  category: announcement.category,
                  attachments: announcement.attachments,
                  comments: announcement.comments,
                  authorId: announcement.authorId,
                  isUrgent: false, // Remove urgent status when archiving
                  isDraft: announcement.isDraft,
                );

                await _announcementService
                    .updateAnnouncement(updatedAnnouncement);

                if (mounted) {
                  // Immediately update local state for UI refresh
                  setState(() {
                    // Remove from active or urgent lists and add to archived list
                    _activeAnnouncements
                        .removeWhere((a) => a.id == announcement.id);
                    _urgentAnnouncements
                        .removeWhere((a) => a.id == announcement.id);
                    _archivedAnnouncements.add(updatedAnnouncement);
                    _isLoading = false;
                  });

                  // Switch to archived tab
                  _tabController.animateTo(3);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement archived successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh data from server in background without UI blocking
                  _silentRefresh();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error archiving announcement: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(Announcement announcement) {
    DateTime selectedPublishDate = announcement.publishDate;
    DateTime? selectedExpiryDate = announcement.expiryDate;
    String? selectedRecurringPattern = announcement.recurringPattern;
    bool isDraft = announcement.isDraft;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Schedule Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Publish date selector
                const Text(
                  'Publish Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedPublishDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedPublishDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy')
                              .format(selectedPublishDate),
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Draft status toggle
                if (isDraft)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: !isDraft,
                          onChanged: (value) {
                            setState(() {
                              isDraft = !(value ?? false);
                            });
                          },
                        ),
                        const Text(
                          'Publish (remove from drafts)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // Expiry date selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Expiry Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedExpiryDate = selectedExpiryDate == null
                              ? DateTime.now().add(const Duration(days: 30))
                              : null;
                        });
                      },
                      child: Text(
                        selectedExpiryDate == null
                            ? 'Add Expiry'
                            : 'Remove Expiry',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedExpiryDate != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedExpiryDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate:
                            selectedPublishDate.add(const Duration(days: 1)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedExpiryDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedExpiryDate != null
                                ? DateFormat('MMM dd, yyyy')
                                    .format(selectedExpiryDate!)
                                : 'No expiry date',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Recurring pattern selector
                const Text(
                  'Recurring Pattern',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedRecurringPattern,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None'),
                    ),
                    ...recurringPatterns
                        .where((pattern) => pattern != 'None')
                        .map((pattern) => DropdownMenuItem(
                              value: pattern,
                              child: Text(pattern),
                            )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRecurringPattern = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateAnnouncementSchedule(
                  announcement,
                  selectedPublishDate,
                  selectedExpiryDate,
                  selectedRecurringPattern,
                  isDraft,
                );
              },
              child: const Text('Save Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateAnnouncementSchedule(
    Announcement announcement,
    DateTime publishDate,
    DateTime? expiryDate,
    String? recurringPattern,
    bool isDraft,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedAnnouncement = announcement.copyWith(
        publishDate: publishDate,
        expiryDate: expiryDate,
        recurringPattern: recurringPattern,
        isDraft: isDraft,
      );

      await _announcementService.updateAnnouncement(updatedAnnouncement);

      if (mounted) {
        // If an announcement was moved from draft to scheduled/active, update the lists
        if (announcement.isDraft && !isDraft) {
          setState(() {
            // Remove from drafts
            _draftAnnouncements.removeWhere((a) => a.id == announcement.id);

            // Add to appropriate list based on publish date
            if (DateTime.now().isBefore(publishDate)) {
              _scheduledAnnouncements.add(updatedAnnouncement);
            } else {
              _activeAnnouncements.add(updatedAnnouncement);
            }
          });

          // Navigate to the appropriate tab
          if (DateTime.now().isBefore(publishDate)) {
            _tabController.animateTo(1); // Scheduled tab
          } else {
            _tabController.animateTo(0); // Active tab
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement schedule updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh data
        _silentRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating schedule: $e'),
            backgroundColor: Colors.red,
          ),
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

  @override
  Widget build(BuildContext context) {
    return RouteGuardWrapper(
      allowedRoles: const ['government'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Announcements'),
          centerTitle: false,
          automaticallyImplyLeading: false,
          actions: [
            // New Announcement button in header
            Padding(
              padding:
                  const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
              child: SizedBox(
                height: 36,
                child: StandardActionButton(
                  label: 'New Announcement',
                  icon: Icons.add_rounded,
                  onPressed: _showCreateAnnouncementSheet,
                  style: ActionButtonStyle.primary,
                  size: ActionButtonSize.small,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Scheduled'),
                  Tab(text: 'Drafts'),
                  Tab(text: 'Archived'),
                ],
                labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.normal),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.blue.shade600,
                unselectedLabelColor: Colors.grey[700],
                indicatorColor: Colors.blue.shade600,
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAnnouncementList(_activeAnnouncements),
                  _buildAnnouncementList(_scheduledAnnouncements),
                  _buildAnnouncementList(_draftAnnouncements),
                  _buildAnnouncementList(_archivedAnnouncements),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }

  Widget _buildAnnouncementList(List<Announcement> announcements) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No announcements available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: announcements.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) =>
          _buildAnnouncementCard(announcements[index]),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final isUrgent = announcement.isUrgent;
    final isDraft = announcement.isDraft;
    final isScheduled = announcement.isScheduled;
    final isExpired = announcement.isExpired;

    // For government view, display static "Government" as creator
    final creatorId = "Government";

    final createdDate = DateFormat('MMM dd, yyyy').format(announcement.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? Colors.red.withAlpha(40)
                : isDraft
                    ? Colors.amber.withAlpha(40)
                    : isScheduled
                        ? Colors.purple.withAlpha(40)
                        : isExpired
                            ? Colors.grey.withAlpha(40)
                            : Colors.blue.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isUrgent
            ? Border.all(color: Colors.red.withAlpha(100), width: 1)
            : isDraft
                ? Border.all(color: Colors.amber.withAlpha(100), width: 1)
                : isScheduled
                    ? Border.all(color: Colors.purple.withAlpha(100), width: 1)
                    : isExpired
                        ? Border.all(color: Colors.grey[300]!, width: 1)
                        : Border.all(
                            color: Colors.blue.withAlpha(100), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    if (isUrgent)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Urgent',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDraft
                            ? Colors.amber.withAlpha(25)
                            : isScheduled
                                ? Colors.purple.withAlpha(25)
                                : isExpired
                                    ? Colors.grey.withAlpha(25)
                                    : Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isDraft
                            ? 'Draft'
                            : isScheduled
                                ? 'Scheduled'
                                : isExpired
                                    ? 'Archived'
                                    : 'Active',
                        style: TextStyle(
                          color: isDraft
                              ? Colors.amber.shade800
                              : isScheduled
                                  ? Colors.purple
                                  : isExpired
                                      ? Colors.grey
                                      : Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (announcement.recurringPattern != null)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Recurring',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Schedule information
            if (isScheduled ||
                announcement.expiryDate != null ||
                announcement.recurringPattern != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isScheduled)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule,
                              size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Publishes: ${DateFormat('MMM dd, yyyy').format(announcement.publishDate)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    if (announcement.expiryDate != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Expires: ${DateFormat('MMM dd, yyyy').format(announcement.expiryDate!)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    if (announcement.recurringPattern != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.repeat, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Recurring: ${announcement.recurringPattern}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

            // Creator and date in a more compact format
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                children: [
                  TextSpan(text: 'Created by: '),
                  TextSpan(
                    text: creatorId,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: ' • '),
                  TextSpan(text: createdDate),
                ],
              ),
            ),

            // Category tag - more compact
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  announcement.category,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Content - more compact
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                announcement.content,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Display first image if attachments exist
            if (announcement.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    announcement.attachments.first,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheHeight: 320, // Add caching for better performance
                    cacheWidth: 640,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Attachments indicator - more compact
            if (announcement.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Text(
                      '${announcement.attachments.length} ${announcement.attachments.length == 1 ? 'file' : 'files'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

            // Action buttons row - Using Column and Wrap for better layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // View Details button
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AnnouncementDetailPage(announcement: announcement),
                      ),
                    ).then((_) => _silentRefresh());
                  },
                  icon: const Icon(Icons.description_outlined,
                      size: 16, color: Colors.grey),
                  label: Text(
                    'View Details (${announcement.comments.length})',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                // Action buttons in a Wrap widget to prevent overflow
                Wrap(
                  spacing: 8, // horizontal spacing
                  runSpacing: 4, // vertical spacing
                  children: [
                    // Publish button for draft announcements
                    if (isDraft)
                      TextButton.icon(
                        onPressed: () {
                          // Update the announcement to not be a draft and use current date as publish date
                          _updateAnnouncementSchedule(
                            announcement,
                            DateTime.now(), // Publish immediately
                            announcement.expiryDate,
                            announcement.recurringPattern,
                            false, // Not a draft anymore
                          );
                        },
                        icon: Icon(Icons.publish,
                            size: 14, color: Colors.green[700]),
                        label: Text(
                          'Publish Now',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),

                    if (!isUrgent && !isExpired)
                      TextButton.icon(
                        onPressed: () => _markAsUrgent(announcement, true),
                        icon: Icon(Icons.priority_high,
                            size: 14, color: Colors.red[700]),
                        label: Text(
                          'Mark Urgent',
                          style:
                              TextStyle(fontSize: 12, color: Colors.red[700]),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    else if (isUrgent)
                      TextButton.icon(
                        onPressed: () => _markAsUrgent(announcement, false),
                        icon: Icon(Icons.remove_circle_outline,
                            size: 14, color: Colors.grey[700]),
                        label: Text(
                          'Remove Urgent',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),

                    if (!isExpired)
                      TextButton.icon(
                        onPressed: () => _archiveAnnouncement(announcement),
                        icon: Icon(Icons.archive_outlined,
                            size: 14, color: Colors.grey[700]),
                        label: Text(
                          'Archive',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),

                    TextButton.icon(
                      onPressed: () => _showScheduleDialog(announcement),
                      icon: Icon(Icons.schedule,
                          size: 14, color: Colors.blue[700]),
                      label: Text(
                        'Schedule',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),

                    TextButton.icon(
                      onPressed: () => _deleteAnnouncement(announcement),
                      icon: const Icon(Icons.delete_outline,
                          size: 14, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
