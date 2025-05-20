import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/announcement.dart';
import '../../services/announcement/announcement_service.dart';
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
  bool _isDraft = true;

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
    
    // Add listener to tab controller to refresh data when tab changes
    _tabController.addListener(_handleTabChange);
    
    // Delayed initialization to avoid initial rendering issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _silentRefresh();
      }
    });
  }
  
  void _handleTabChange() {
    // Check if the widget is still mounted before proceeding
    if (_tabController.indexIsChanging && mounted) {
      // Use a slight delay to let animations complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadAnnouncements();
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _publishDateController.dispose();
    _expiryDateController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    
    bool wasNotLoading = !_isLoading;

    if (wasNotLoading && mounted) {
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
          
          // Initialize with empty lists to prevent null errors
          _activeAnnouncements = [];
          _scheduledAnnouncements = [];
          _draftAnnouncements = [];
          _archivedAnnouncements = [];
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
        imageQuality: 85,
        maxWidth: 1200,
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

        // Force rebuild of the UI
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image added: ${file.path.split('/').last}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
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
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bottomSheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title area
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Announcement',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Announcements will be visible to all citizens',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Form heading - Title
                _buildFormLabel('Announcement Title', Icons.title_rounded),
                const SizedBox(height: 8),
                _buildFormTextField(
                  controller: _titleController,
                  hintText: 'Enter a concise and descriptive title',
                  maxLines: 1,
                ),

                const SizedBox(height: 24),

                // Form heading - Content
                _buildFormLabel(
                    'Announcement Content', Icons.description_rounded),
                const SizedBox(height: 8),
                _buildFormTextField(
                  controller: _contentController,
                  hintText:
                      'Provide detailed information for this announcement...',
                  maxLines: 5,
                ),

                const SizedBox(height: 24),

                // Form heading - Category
                _buildFormLabel('Category', Icons.category_rounded),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(50)),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      hint: Text(
                        'Select a category',
                        style: TextStyle(
                          color:
                              theme.colorScheme.onSurfaceVariant.withAlpha(179),
                        ),
                      ),
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedCategory = value;
                        });
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Urgent toggle - Updated with StatefulBuilder
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isUrgent
                        ? Colors.red[50]
                        : theme.colorScheme.surfaceContainerHighest
                            .withAlpha(77),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isUrgent
                          ? Colors.red.withAlpha(100)
                          : theme.colorScheme.outlineVariant.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isUrgent
                              ? Colors.red[100]
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.priority_high_rounded,
                          size: 20,
                          color: _isUrgent
                              ? Colors.red
                              : theme.colorScheme.onSurfaceVariant
                                  .withAlpha(179),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mark as Urgent',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _isUrgent
                                    ? Colors.red
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Urgent announcements are highlighted and shown at the top',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 1.2,
                        child: Switch(
                          value: _isUrgent,
                          activeColor: Colors.red,
                          activeTrackColor: Colors.red[100],
                          onChanged: (bool? value) {
                            setModalState(() {
                              _isUrgent = value ?? false;
                            });
                            setState(() {
                              _isUrgent = value ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Attachments section
                _buildFormLabel('Attachments', Icons.attach_file_rounded),
                const SizedBox(height: 12),
                if (_selectedFiles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(77),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.file_upload_outlined,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant
                                .withAlpha(179),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No attachments added',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withAlpha(179),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Image'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: theme.colorScheme.onPrimary,
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedFiles.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(_selectedFiles[index]),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(26),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeFile(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(51),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.black,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(51),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Image ${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add More Images'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withAlpha(50)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          // First hide the modal
                          Navigator.pop(context);
                          // Then call create announcement (already has setState inside)
                          await _createAnnouncement();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onPrimary,
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Create Announcement'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      style: TextStyle(
        fontSize: 16,
        color: theme.colorScheme.onSurface,
      ),
    );
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

    // Ensure widget is still mounted before setting state
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload attachments and get URLs
      List<String> attachmentUrls = [];

      // Show a progress indicator for uploads
      if (_selectedFiles.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                SizedBox(width: 10),
                Text('Uploading attachments...'),
              ],
            ),
            duration: Duration(minutes: 2),
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
        }
      }

      // Create announcement - always as a draft initially
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
        isDraft: true, // Always create as draft initially
      );

      await _announcementService.createAnnouncement(announcement);

      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        // Reset form and state
        _titleController.clear();
        _contentController.clear();
        _selectedCategory = null;
        _isUrgent = false;
        _selectedFiles = [];
        
        // Set a flag to avoid visual flicker
        setState(() {
          _isLoading = true;
        });

        // Small delay to ensure UI updates properly
        await Future.delayed(const Duration(milliseconds: 150));
        
        // Only if still mounted, perform a full reload to ensure data consistency
        if (mounted) {
          await _loadAnnouncements();
          
          setState(() {
            _isLoading = false;
          });

          // Navigate to Drafts tab with proper timing
          _tabController.animateTo(2);
          
          // Display success message after the navigation animation completes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Announcement draft created with ${attachmentUrls.length} attachment(s)',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

  void _markAsUrgent(Announcement announcement, bool urgent) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update the announcement with new urgent status
      final updatedAnnouncement = announcement.copyWith(
        isUrgent: urgent,
      );

      await _announcementService.updateAnnouncement(updatedAnnouncement);

      if (mounted) {
        setState(() {
          // Update the announcement in all relevant lists
          final lists = [
            _activeAnnouncements,
            _scheduledAnnouncements,
            _draftAnnouncements,
            _archivedAnnouncements
          ];

          for (var list in lists) {
            final index = list.indexWhere((a) => a.id == announcement.id);
            if (index != -1) {
              list[index] = updatedAnnouncement;
            }
          }

          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(urgent ? 'Marked as urgent' : 'Removed urgent status'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the data
        _loadAnnouncements();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating urgent status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                      border:
                          Border.all(color: Colors.grey[300]!.withAlpha(179)),
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
                        border:
                            Border.all(color: Colors.grey[300]!.withAlpha(179)),
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
    final theme = Theme.of(context);

    return RouteGuardWrapper(
      allowedRoles: const ['government'],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/government_home'),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Announcements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            // New Announcement button in header
            Padding(
              padding:
                  const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
              child: StandardActionButton(
                label: 'New',
                icon: Icons.add_rounded,
                onPressed: _showCreateAnnouncementSheet,
                style: ActionButtonStyle.primary,
                size: ActionButtonSize.small,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  _buildTabItem(Icons.check_circle_outline_rounded, 'Active'),
                  _buildTabItem(Icons.pending_actions_rounded, 'Scheduled'),
                  _buildTabItem(Icons.edit_note_rounded, 'Drafts'),
                  _buildTabItem(Icons.inventory_2_rounded, 'Archived'),
                ],
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                dividerColor: Colors.transparent,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Tab content
            Expanded(
              child: Container(
                color: theme.colorScheme.surface,
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

  Widget _buildTabItem(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList(List<Announcement> announcements) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading announcements...',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
              ),
            ),
          ],
        ),
      );
    }

    if (announcements.isEmpty) {
      String message;
      IconData icon;
      String actionText;

      if (_tabController.index == 0) {
        // Active tab
        message = 'No active announcements available';
        icon = Icons.campaign_outlined;
        actionText = 'Create a new announcement using the button above';
      } else if (_tabController.index == 1) {
        // Scheduled tab
        message = 'No scheduled announcements';
        icon = Icons.pending_actions_rounded;
        actionText = 'Create and schedule announcements for future publication';
      } else if (_tabController.index == 2) {
        // Drafts tab
        message = 'No draft announcements';
        icon = Icons.edit_note_rounded;
        actionText = 'Drafts are saved here until they are ready to publish';
      } else {
        // Archived tab
        message = 'No archived announcements';
        icon = Icons.inventory_2_rounded;
        actionText = 'Expired and archived announcements will appear here';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary.withAlpha(128),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                actionText,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateAnnouncementSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Announcement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
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
    final theme = Theme.of(context);
    final isUrgent = announcement.isUrgent;
    final isDraft = announcement.isDraft;
    final isScheduled = announcement.isScheduled;
    final isExpired = announcement.isExpired;

    final createdDate = DateFormat('MMM dd, yyyy').format(announcement.date);

    // Select appropriate colors for each state
    final Color primaryColor = isUrgent
        ? const Color(0xFFE53935)
        : isDraft
            ? const Color(0xFFFFA000)
            : isScheduled
                ? const Color(0xFF8E24AA)
                : isExpired
                    ? const Color(0xFF757575)
                    : theme.colorScheme.primary;

    final Color surfaceColor = isUrgent
        ? const Color(0xFFFFEBEE)
        : isDraft
            ? const Color(0xFFFFF8E1)
            : isScheduled
                ? const Color(0xFFF3E5F5)
                : isExpired
                    ? const Color(0xFFF5F5F5)
                    : theme.colorScheme.surfaceContainerHighest;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: primaryColor.withAlpha(50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar at top
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isUrgent
                            ? Icons.priority_high_rounded
                            : isDraft
                                ? Icons.edit_note_rounded
                                : isScheduled
                                    ? Icons.event_rounded
                                    : isExpired
                                        ? Icons.archive_rounded
                                        : Icons.campaign_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and status badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Status badges in a wrap
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (isUrgent)
                                _buildStatusBadge(
                                    'Urgent',
                                    const Color(0xFFE53935),
                                    const Color(0xFFFFEBEE)),
                              _buildStatusBadge(
                                  isDraft
                                      ? 'Draft'
                                      : isScheduled
                                          ? 'Scheduled'
                                          : isExpired
                                              ? 'Archived'
                                              : 'Active',
                                  primaryColor,
                                  surfaceColor),
                              if (announcement.recurringPattern != null)
                                _buildStatusBadge(
                                    'Recurring',
                                    const Color(0xFF43A047),
                                    const Color(0xFFE8F5E9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Schedule information
                if (isScheduled ||
                    announcement.expiryDate != null ||
                    announcement.recurringPattern != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: primaryColor.withAlpha(50), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isScheduled)
                          _buildInfoRow(
                              Icons.event_rounded,
                              'Publishes: ${DateFormat('MMM dd, yyyy').format(announcement.publishDate)}',
                              primaryColor),
                        if (announcement.expiryDate != null)
                          _buildInfoRow(
                              Icons.event_busy,
                              'Expires: ${DateFormat('MMM dd, yyyy').format(announcement.expiryDate!)}',
                              primaryColor),
                        if (announcement.recurringPattern != null)
                          _buildInfoRow(
                              Icons.repeat,
                              'Recurring: ${announcement.recurringPattern}',
                              primaryColor),
                      ],
                    ),
                  ),

                // Category and metadata
                Row(
                  children: [
                    // Category pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        announcement.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              theme.colorScheme.onSurfaceVariant.withAlpha(179),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        '• Created: $createdDate',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              theme.colorScheme.onSurfaceVariant.withAlpha(179),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Content preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(50)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    announcement.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Display first image if attachments exist
                if (announcement.attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Image.network(
                            announcement.attachments.first,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            cacheHeight: 320,
                            cacheWidth: 640,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 80,
                                width: double.infinity,
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withAlpha(128),
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
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Attachment count badge
                          if (announcement.attachments.length > 1)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(26),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_library,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+${announcement.attachments.length - 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // View Details button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnnouncementDetailPage(
                                announcement: announcement),
                          ),
                        ).then((_) => _silentRefresh());
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: Text(
                        'Details',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        foregroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    // Action buttons
                    Row(
                      children: [
                        // Edit button
                        _buildActionButton(
                          label: 'Edit',
                          icon: Icons.edit,
                          color: theme.colorScheme.primary,
                          onPressed: () => _showEditAnnouncementSheet(announcement),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Primary action based on state
                        if (isDraft)
                          _buildActionButton(
                            label: 'Publish',
                            icon: Icons.publish,
                            color: Colors.green[700]!,
                            onPressed: () {
                              _showPublishDialog(announcement);
                            },
                          )
                        else if (!isUrgent && !isExpired)
                          _buildActionButton(
                            label: 'Urgent',
                            icon: Icons.priority_high,
                            color: Colors.red[700]!,
                            onPressed: () => _markAsUrgent(announcement, true),
                          )
                        else if (isUrgent)
                          _buildActionButton(
                            label: 'Normal',
                            icon: Icons.remove_circle_outline,
                            color: Colors.grey[700]!,
                            onPressed: () => _markAsUrgent(announcement, false),
                          ),

                        const SizedBox(width: 8),

                        // Common actions menu
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.more_vert,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withAlpha(179),
                              size: 18,
                            ),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditAnnouncementSheet(announcement);
                                break;
                              case 'schedule':
                                _showScheduleDialog(announcement);
                                break;
                              case 'archive':
                                _archiveAnnouncement(announcement);
                                break;
                              case 'delete':
                                _deleteAnnouncement(announcement);
                                break;
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => [
                            _buildPopupMenuItem(
                              value: 'edit',
                              label: 'Edit',
                              icon: Icons.edit_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            _buildPopupMenuItem(
                              value: 'schedule',
                              label: 'Schedule',
                              icon: Icons.schedule,
                              color: theme.colorScheme.primary,
                            ),
                            if (!isExpired)
                              _buildPopupMenuItem(
                                value: 'archive',
                                label: 'Archive',
                                icon: Icons.archive_outlined,
                                color: Colors.grey[700]!,
                              ),
                            _buildPopupMenuItem(
                              value: 'delete',
                              label: 'Delete',
                              icon: Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build status badges
  Widget _buildStatusBadge(String text, Color color, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 14, color: color),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Show dialog to publish draft announcement
  void _showPublishDialog(Announcement announcement) {
    bool publishNow = true;
    DateTime scheduledDate = DateTime.now().add(const Duration(hours: 1));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Publish Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option to publish now or schedule
                ListTile(
                  title: const Text('Publish immediately'),
                  leading: Radio<bool>(
                    value: true,
                    groupValue: publishNow,
                    onChanged: (value) {
                      setState(() {
                        publishNow = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Schedule for later'),
                  leading: Radio<bool>(
                    value: false,
                    groupValue: publishNow,
                    onChanged: (value) {
                      setState(() {
                        publishNow = value!;
                      });
                    },
                  ),
                ),
                
                if (!publishNow) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Select date and time:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: scheduledDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(scheduledDate),
                        );
                        
                        if (pickedTime != null) {
                          setState(() {
                            scheduledDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // First close the dialog (to avoid black screens)
                Navigator.pop(context);
                // Then perform the action
                await _publishAnnouncement(
                  announcement,
                  publishNow ? DateTime.now() : scheduledDate,
                );
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Method to publish an announcement
  Future<void> _publishAnnouncement(Announcement announcement, DateTime publishDate) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedAnnouncement = announcement.copyWith(
        isDraft: false,
        publishDate: publishDate,
      );
      
      await _announcementService.updateAnnouncement(updatedAnnouncement);
      
      if (mounted) {
        // Full reload instead of manual list manipulation to ensure UI consistency
        await _loadAnnouncements();
        
        // Set loading to false after data is loaded
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to the appropriate tab
        final bool isScheduled = DateTime.now().isBefore(publishDate);
        final int tabIndex = isScheduled ? 1 : 0;  // 1 for Scheduled, 0 for Active
        
        // Animate to tab with proper timing
        _tabController.animateTo(tabIndex);
        
        // Show success message after navigation completes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isScheduled 
                  ? 'Announcement scheduled successfully'
                  : 'Announcement published successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to build popup menu items
  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to load data in background without blocking UI
  Future<void> _silentRefresh() async {
    if (!mounted) return;
    
    try {
      final announcements = await _announcementService.getAnnouncements();

      // Sort announcements by date - newest first
      announcements.sort((a, b) => b.date.compareTo(a.date));

      // Check again if the widget is still mounted before updating state
      if (!mounted) return;
      
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
    } catch (e) {
      // Silent error handling - don't show errors during background refresh
      // Just log error but keep UI stable with current data
      print('Silent refresh error: $e');
    }
  }

  void _showEditAnnouncementSheet(Announcement announcement) {
    // Create temporary controllers to hold the edited values
    final titleController = TextEditingController(text: announcement.title);
    final contentController = TextEditingController(text: announcement.content);
    String selectedCategory = announcement.category;
    bool isUrgent = announcement.isUrgent;
    List<File> selectedFiles = []; // Will hold new files
    List<String> existingAttachments = List.from(announcement.attachments); // Existing attachments

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bottomSheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title area
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Announcement',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            announcement.isDraft ? 'Edit draft announcement' : 'Edit published announcement',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Form heading - Title
                _buildFormLabel('Announcement Title', Icons.title_rounded),
                const SizedBox(height: 8),
                _buildFormTextField(
                  controller: titleController,
                  hintText: 'Enter a concise and descriptive title',
                  maxLines: 1,
                ),

                const SizedBox(height: 24),

                // Form heading - Content
                _buildFormLabel('Announcement Content', Icons.description_rounded),
                const SizedBox(height: 8),
                _buildFormTextField(
                  controller: contentController,
                  hintText: 'Provide detailed information for this announcement...',
                  maxLines: 5,
                ),

                const SizedBox(height: 24),

                // Form heading - Category
                _buildFormLabel('Category', Icons.category_rounded),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50)),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Urgent toggle - Updated with StatefulBuilder
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? Colors.red[50]
                        : theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUrgent
                          ? Colors.red.withAlpha(100)
                          : theme.colorScheme.outlineVariant.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? Colors.red[100]
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.priority_high_rounded,
                          size: 20,
                          color: isUrgent
                              ? Colors.red
                              : theme.colorScheme.onSurfaceVariant
                                  .withAlpha(179),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mark as Urgent',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isUrgent
                                    ? Colors.red
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Urgent announcements are highlighted and shown at the top',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 1.2,
                        child: Switch(
                          value: isUrgent,
                          activeColor: Colors.red,
                          activeTrackColor: Colors.red[100],
                          onChanged: (bool? value) {
                            setModalState(() {
                              isUrgent = value ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Existing attachments section
                if (existingAttachments.isNotEmpty) ...[
                  _buildFormLabel('Current Attachments', Icons.photo_library_rounded),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: existingAttachments.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  existingAttachments[index],
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 120,
                                      width: 120,
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 120,
                                      width: 120,
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 32),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      existingAttachments.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(179),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.black,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // New attachments section
                _buildFormLabel('Add New Attachments', Icons.attach_file_rounded),
                const SizedBox(height: 12),
                if (selectedFiles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.file_upload_outlined,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No new attachments added',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final XFile? image = await _picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                  maxWidth: 1200,
                                );
                          
                                if (image != null) {
                                  final File file = File(image.path);
                          
                                  // Validate file size (limit to 5MB)
                                  final fileSize = await file.length();
                                  if (fileSize > 5 * 1024 * 1024) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Image is too large. Please select an image under 5MB.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                          
                                  // Validate file type
                                  final fileName = file.path.toLowerCase();
                                  if (!fileName.endsWith('.jpg') &&
                                      !fileName.endsWith('.jpeg') &&
                                      !fileName.endsWith('.png')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Unsupported file type. Please select a JPG or PNG image.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                          
                                  setModalState(() {
                                    selectedFiles.add(file);
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error picking image: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Image'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: theme.colorScheme.onPrimary,
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedFiles.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(selectedFiles[index]),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(26),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedFiles.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(51),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.black,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(51),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'New ${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final XFile? image = await _picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                                maxWidth: 1200,
                              );
                        
                              if (image != null) {
                                final File file = File(image.path);
                        
                                // Validate file size (limit to 5MB)
                                final fileSize = await file.length();
                                if (fileSize > 5 * 1024 * 1024) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Image is too large. Please select an image under 5MB.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                        
                                // Validate file type
                                final fileName = file.path.toLowerCase();
                                if (!fileName.endsWith('.jpg') &&
                                    !fileName.endsWith('.jpeg') &&
                                    !fileName.endsWith('.png')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Unsupported file type. Please select a JPG or PNG image.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                        
                                setModalState(() {
                                  selectedFiles.add(file);
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error picking image: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add More Images'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withAlpha(50)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          // First hide the modal
                          Navigator.pop(context);
                          
                          // Then update announcement
                          await _updateAnnouncement(
                            announcement,
                            titleController.text,
                            contentController.text,
                            selectedCategory,
                            isUrgent,
                            existingAttachments,
                            selectedFiles,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onPrimary,
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateAnnouncement(
    Announcement announcement,
    String title,
    String content,
    String category,
    bool isUrgent,
    List<String> existingAttachments,
    List<File> newFiles,
  ) async {
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and content cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ensure widget is still mounted before setting state
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Upload any new attachments
      List<String> newAttachmentUrls = [];

      if (newFiles.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                SizedBox(width: 10),
                Text('Uploading new attachments...'),
              ],
            ),
            duration: Duration(minutes: 1),
            backgroundColor: Colors.blue,
          ),
        );
      }

      for (var i = 0; i < newFiles.length; i++) {
        try {
          final url = await _announcementService.uploadAttachment(newFiles[i]);
          newAttachmentUrls.add(url);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Uploaded new image ${i + 1} of ${newFiles.length}'),
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
        }
      }

      // Combine existing and new attachments
      final List<String> allAttachments = [
        ...existingAttachments,
        ...newAttachmentUrls,
      ];

      // Create updated announcement with the same ID
      final updatedAnnouncement = announcement.copyWith(
        title: title,
        content: content,
        category: category,
        isUrgent: isUrgent,
        attachments: allAttachments,
      );

      // Update in Firestore
      await _announcementService.updateAnnouncement(updatedAnnouncement);

      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload announcements to reflect changes
        await _loadAnnouncements();
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
